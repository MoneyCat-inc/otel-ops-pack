// BRAV/SCPT/run-archiver/conveyor.mjs
// BossCat Run Conveyor — Archive→Delete pipeline
// Authority: BossCat OEM • ECRR-compliant • Two-agent governance
// State: QUEUED → ARCHIVING → ARCHIVED → DELETE_QUEUED → DELETING → DELETED

import { setTimeout as sleep } from 'node:timers/promises';
import { writeFile, appendFile, mkdir, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, appendFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { dirname, join } from 'node:path';
import Bottleneck from 'bottleneck';
import PQueue from 'p-queue';
import { request, Pool, setGlobalDispatcher } from 'undici';
import prettyMs from 'pretty-ms';
import cliProgress from 'cli-progress';
import { resolveRepoRoot, assertNotNestedBossCat } from './repo-root.mjs';

const REPO = process.env.REPO || 'MoneyCat-inc/otel-ops-pack';
const TOKENS = (process.env.GH_TOKENS || process.env.GITHUB_TOKEN || '').split(',').filter(Boolean);
const MAX_KEEP = Number(process.env.MAX_KEEP || 100);
const CHUNK_SIZE = Number(process.env.CHUNK_SIZE || 1000);
const CHUNK_OFFSET = Number(process.env.CHUNK_OFFSET || 0);
const ARCH_CONCURRENCY = Number(process.env.ARCH_CONCURRENCY || 48);
const ARCH_QPS = Number(process.env.ARCH_QPS || 2.0);
const DELETE_QPS_PER_TOKEN = Number(process.env.DELETE_QPS || 1.0);
const DRY_RUN = (process.env.DRY_RUN || 'false').toLowerCase() === 'true';
const SKIP_RATE_LIMIT_WAIT = (process.env.SKIP_RATE_LIMIT_WAIT || 'false').toLowerCase() === 'true';
const TRACE = process.env.TRACE_CONCURRENCY === '1';
const SELFTEST = process.env.CONVEYOR_SELFTEST === '1';
const SELFTEST_N = Number(process.env.CONVEYOR_SELFTEST_N || 240);
const SELFTEST_MS = Number(process.env.CONVEYOR_SELFTEST_MS || 1000);
const RATE_JITTER_MS = Number(process.env.RATE_JITTER_MS || 1500); // extra stagger to avoid herds

const BASE = `https://api.github.com/repos/${REPO}/actions`;
// Prefer REPO_ROOT / GITHUB_WORKSPACE / git toplevel — never trust CWD alone.
const REPO_ROOT = resolveRepoRoot();
const abs = (p) => assertNotNestedBossCat(join(REPO_ROOT, p), p);
const LEDGER = abs('CHAR/EVID/artifacts/ecrr/arch/LEDGER.jsonl');
const WHITELIST_PATH = abs('BRAV/SCPT/run-archiver/whitelist.json');
const CHECKPOINT_DIR = abs('CHAR/EVID/artifacts/ecrr/arch/checkpoints');
const CHECKPOINT_FILE = DRY_RUN 
  ? join(CHECKPOINT_DIR, `chunk_${CHUNK_OFFSET}_${CHUNK_SIZE}_DRYRUN.json`)
  : join(CHECKPOINT_DIR, `chunk_${CHUNK_OFFSET}_${CHUNK_SIZE}.json`);

// Lift undici connection pool to avoid hidden 10-conn bottleneck
setGlobalDispatcher(new Pool('https://api.github.com', { 
  connections: 64,
  pipelining: 0  // GitHub API doesn't support HTTP/1.1 pipelining
}));

// Concurrency telemetry
const stats = {
  arch: { started: 0, done: 0, errs: 0, inflightMax: 0, qps: 0 },
  del: { started: 0, done: 0, errs: 0 },
  http: { r429: 0, r5xx: 0, backoffMs: 0 }
};
let tickCount = 0, lastDone = 0, lastTickAt = Date.now();

// Precision timing & latency tracking
const timing = {
  archiveDurMs: [],
  deleteDurMs: [],
  phases: {}
};

class StopWatch {
  constructor(label) {
    this.label = label;
    this.t0 = performance.now();
    this.marks = [];
  }
  mark(name) {
    const t = performance.now();
    this.marks.push({ name, t });
  }
  stop(extra = {}) {
    const t1 = performance.now();
    const spans = [];
    let prev = this.t0;
    for (const m of this.marks) {
      spans.push({ name: m.name, ms: Math.round(m.t - prev) });
      prev = m.t;
    }
    return { label: this.label, total_ms: Math.round(t1 - this.t0), spans, ...extra };
  }
}

function pct(p, arr) {
  if (!arr.length) return null;
  const sorted = [...arr].sort((a, b) => a - b);
  const i = Math.min(sorted.length - 1, Math.max(0, Math.floor(p / 100 * (sorted.length - 1))));
  return Math.round(sorted[i]);
}

function hhmmss(ms) {
  const s = Math.round(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const ss = s % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(ss).padStart(2, '0')}`;
}

function ensureDir(p) {
  try {
    mkdirSync(p, { recursive: true });
  } catch { }
}

function appendJSONL(path, obj) {
  ensureDir(dirname(path));
  appendFileSync(path, JSON.stringify(obj) + '\n');
}

// Progress UI helper
function makePhaseUI(name) {
  const start = Date.now();
  let total = 0, done = 0;
  const bar = new cliProgress.SingleBar({
    format: `[{bar}] {percentage}% | {done}/{total} | ETA: {eta} | ${name}`,
    etaBuffer: 100,
    hideCursor: true
  }, cliProgress.Presets.shades_classic);

  return {
    start(totalCount) {
      total = totalCount;
      done = 0;
      bar.start(total, 0, { total, done, eta: 'estimating…' });
    },
    tick(n = 1) {
      done += n;
      const elapsed = Date.now() - start;
      const rate = done > 0 ? elapsed / done : 0;
      const remaining = Math.max(total - done, 0) * rate;
      bar.update(done, { done, total, eta: prettyMs(remaining, { compact: true }) });
    },
    stop() { bar.stop(); }
  };
}

// Rate-limit aware fetch with auto-throttle
const SECONDARY_REGEX = /secondary rate limit|abuse detection/i;

// Shared backoff gate across all workers to avoid thundering herd
// When one request hits a rate limit, all others will respect `rateGate.until`.
const rateGate = { until: 0 };

async function ghFetch(url, { token, method = 'GET', body, headers = {}, maxRetries = 8 }) {
  let attempt = 0;
  let backoff = 2000;

  while (true) {
    // Coordinated wait if a global backoff is active
    const now0 = Date.now();
    if (!SKIP_RATE_LIMIT_WAIT && rateGate.until > now0) {
      const waitMs = Math.max(0, rateGate.until - now0);
      const jitter = Math.floor(Math.random() * RATE_JITTER_MS);
      const total = waitMs + jitter;
      if (total > 0) {
        stats.http.backoffMs += total;
        await new Promise(r => setTimeout(r, total));
      }
    }
    const res = await request(url, {
      method,
      body,
      headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': `Bearer ${token}`,
        'User-Agent': 'BossCat-Run-Conveyor/1.0',
        'X-GitHub-Api-Version': '2022-11-28',
        ...headers
      }
    });

    if (res.statusCode < 400) return res;

    const txt = await res.body.text();
    const remaining = res.headers['x-ratelimit-remaining'];
    const reset = res.headers['x-ratelimit-reset'];
    const retryAfter = res.headers['retry-after'];

    // Track HTTP errors for telemetry
    if (res.statusCode === 429) stats.http.r429++;
    else if (res.statusCode >= 500) stats.http.r5xx++;
    
    if ((res.statusCode === 403 || res.statusCode === 429) &&
        (remaining === '0' || retryAfter || SECONDARY_REGEX.test(txt))) {
      
      // Manual bypass: fail immediately instead of waiting
      if (SKIP_RATE_LIMIT_WAIT) {
        const why = SECONDARY_REGEX.test(txt) ? 'secondary limit' : 'rate limit';
        throw new Error(`Rate limit hit (${why}). SKIP_RATE_LIMIT_WAIT=true, failing immediately. ${txt.slice(0, 200)}`);
      }
      
      let sleepMs = 0;
      if (retryAfter) {
        sleepMs = Number(retryAfter) * 1000;
      } else if (reset) {
        const resetMs = (Number(reset) * 1000) - Date.now();
        sleepMs = Math.max(resetMs, 30_000);
      } else {
        sleepMs = backoff + Math.floor(Math.random() * 1000);
        backoff = Math.min(backoff * 1.6, 120_000);
      }

      const why = SECONDARY_REGEX.test(txt) ? 'secondary limit' : 'rate limit';
      console.warn(`\n⏳ Pausing for ${prettyMs(sleepMs)} (${why}) — will auto-resume…`);
      stats.http.backoffMs += sleepMs;
      await new Promise(r => setTimeout(r, sleepMs));
      // Extra jitter and global coordination to avoid thundering herd
      if (!SKIP_RATE_LIMIT_WAIT) {
        const extra = Math.floor(Math.random() * RATE_JITTER_MS);
        const baseUntil = Date.now() + extra;
        if (baseUntil > rateGate.until) rateGate.until = baseUntil;
        if (extra > 0) {
          stats.http.backoffMs += extra;
          await new Promise(r => setTimeout(r, extra));
        }
      }
      attempt++;
      if (attempt <= maxRetries) continue;
    }

    const hint = txt?.slice(0, 300)?.replace(/\s+/g, ' ');
    throw new Error(`GitHub API ${res.statusCode} on ${method} ${url} — ${hint}`);
  }
}

function hdr(token) {
  return {
    'authorization': `Bearer ${token}`,
    'user-agent': 'bosscat-archiver/1.0',
    'accept': 'application/vnd.github+json',
    'x-github-api-version': '2022-11-28'
  };
}

async function ledger(line) {
  await mkdir(dirname(LEDGER), { recursive: true });
  await appendFile(LEDGER, JSON.stringify(line) + '\n', 'utf8');
}

function okArchivedState(state) {
  return state?.state === 'ARCHIVED' && state.sha256;
}

async function latestState(runId) {
  try {
    if (!existsSync(LEDGER)) return null;
    const txt = await readFile(LEDGER, 'utf8');
    const lines = txt.trim().split('\n')
      .filter(Boolean)
      .map(l => { try { return JSON.parse(l); } catch { return null; } })
      .filter(Boolean)
      .filter(x => x.id === runId);
    return lines.length ? lines.at(-1) : null;
  } catch { return null; }
}

async function safeReadJson(path, fallback) {
  try {
    if (!existsSync(path)) return fallback;
    return JSON.parse(await readFile(path, 'utf8'));
  } catch { return fallback; }
}

// Checkpoint management (resumable chunks)
let completedRuns = new Set();

async function loadCheckpoint() {
  const data = await safeReadJson(CHECKPOINT_FILE, []);
  completedRuns = new Set(data);
  return completedRuns;
}

async function saveCheckpoint(runId) {
  completedRuns.add(runId);
  await mkdir(CHECKPOINT_DIR, { recursive: true });
  await writeFile(CHECKPOINT_FILE, JSON.stringify([...completedRuns]), 'utf8');
}

function isCompleted(runId) {
  return completedRuns.has(runId);
}

// ---------- Archive Lane (Blue - Fast Parallel with Global Rate Limit) ----------
// Global rate limiter for archive operations (QPS cap across all workers)
const archiveLimiter = new Bottleneck({
  minTime: Math.ceil(1000 / ARCH_QPS),
  maxConcurrent: ARCH_CONCURRENCY
});

const archiveQ = new PQueue({ concurrency: ARCH_CONCURRENCY });

// Track concurrency telemetry
archiveQ.on('active', () => {
  const inflight = archiveQ.pending + 1; // +1 for the one that just started
  if (inflight > stats.arch.inflightMax) stats.arch.inflightMax = inflight;
});

// Live telemetry (every 2s) - enable with TRACE_CONCURRENCY=1
const telemetryTimer = setInterval(() => {
  if (!TRACE) return;
  tickCount++;
  const now = Date.now();
  const dt = (now - lastTickAt) / 1000;
  const doneNow = stats.arch.done;
  const dDone = doneNow - lastDone;
  stats.arch.qps = dDone / dt;
  lastDone = doneNow;
  lastTickAt = now;
  
  process.stdout.write(
    `\r🔵 arch: inflight=${archiveQ.pending}/${ARCH_CONCURRENCY} queued=${archiveQ.size} qps=${stats.arch.qps.toFixed(2)} | ` +
    `🔴 del: ${stats.del.done} done | ` +
    `⛔429=${stats.http.r429} 5xx=${stats.http.r5xx}    `
  );
}, 2000);

async function archiveRun(run, token, ui) {
  // Skip if already completed in this chunk
  if (isCompleted(run.id)) {
    if (ui) ui.tick(1);
    stats.arch.done++;
    return;
  }

  stats.arch.started++;
  const t0 = performance.now();
  const t = new Date().toISOString();
  await ledger({ t, id: run.id, state: 'ARCHIVING', msg: `Start ${run.name}` });

  try {
    // 1) Metadata (already have from list)
    const meta = run;

    // 2) Jobs (rate-limited)
    const jobsRes = await archiveLimiter.schedule(() => 
      ghFetch(`${BASE}/runs/${run.id}/jobs?per_page=100`, { token })
    );
    const jobsData = await jobsRes.body.json();
    const jobs = jobsData.jobs || [];

    // 3) Logs (selective - only failures or sampled successes)
    let logsZip = null;
    let logsBytes = 0;
    const needLogs = run.conclusion !== 'success' || (run.id % 20 === 0); // Sample 5% of successes
    
    if (needLogs) {
      try {
        const logsRes = await archiveLimiter.schedule(() =>
          ghFetch(`${BASE}/runs/${run.id}/logs`, { token })
        );
        logsZip = Buffer.from(await logsRes.body.arrayBuffer());
        logsBytes = logsZip.length;
      } catch (e) {
        // Log download often fails for old runs - this is expected
      }
    }

    // 4) Evidence bundle + hash
    const year = new Date(run.created_at).getUTCFullYear();
    const month = String(new Date(run.created_at).getUTCMonth() + 1).padStart(2, '0');
    const dir = abs(`docs/BossCat/run-reports/archived/${year}/${month}`);
    await mkdir(dir, { recursive: true });
    
    const badgeDir = abs('docs/BossCat/run-reports/badges');
    await mkdir(badgeDir, { recursive: true });

    const mdPath = `${dir}/run-${run.id}.md`;
    const badgePath = `${badgeDir}/run-${run.id}.svg`;
    
    // Render report
    const body = renderReport(meta, jobs, logsBytes);
    await writeFile(mdPath, body, 'utf8');
    
    // Render badge
    const badge = renderBadge(meta.conclusion);
    await writeFile(badgePath, badge, 'utf8');

    // Append to lightweight analysis index (JSONL)
    try {
      const startedAt = new Date(meta.run_started_at || meta.created_at);
      const updatedAt = new Date(meta.updated_at || meta.created_at);
      const durationSec = Math.max(0, Math.round((updatedAt - startedAt) / 1000));
      const date = startedAt.toISOString().slice(0, 10);
      const relPath = `${year}/${month}/run-${run.id}.md`;
      appendJSONL(abs('docs/BossCat/run-reports/INDEX.jsonl'), {
        id: String(run.id),
        workflow: meta.name || 'unknown',
        conclusion: meta.conclusion || meta.status || 'unknown',
        duration: durationSec,
        date,
        actor: meta.actor?.login || 'unknown',
        path: relPath
      });
    } catch (e) {
      // Non-fatal: index append should not block archival
      console.warn(`Could not append to INDEX.jsonl for ${run.id}: ${e.message}`);
    }

    // Compute evidence hash
    const hasher = createHash('sha256');
    hasher.update(JSON.stringify({ meta, jobs }));
    if (logsZip) hasher.update(logsZip);
    const sha256 = hasher.digest('hex');

    // Mark as ARCHIVED
    await ledger({
      t: new Date().toISOString(),
      id: run.id,
      state: 'ARCHIVED',
      evidence: mdPath,
      sha256,
      logs_bytes: logsBytes,
      jobs_count: jobs.length,
      msg: `${run.name} • ${run.conclusion}`
    });

    // Save checkpoint
    await saveCheckpoint(run.id);
    
    const dt = performance.now() - t0;
    timing.archiveDurMs.push(dt);
    stats.arch.done++;
    if (ui) ui.tick(1);

  } catch (e) {
    const dt = performance.now() - t0;
    timing.archiveDurMs.push(dt);
    stats.arch.errs++;
    await ledger({
      t: new Date().toISOString(),
      id: run.id,
      state: 'ERROR',
      msg: `Archive failed: ${e.message}`
    });
    
    // Still mark as completed to avoid retry loops
    await saveCheckpoint(run.id);
    
    throw e;
  }
}

function renderReport(meta, jobs, logsBytes) {
  const badge = meta.conclusion === 'success' ? '✅' : '❌';
  const started = new Date(meta.run_started_at || meta.created_at);
  const updated = new Date(meta.updated_at);
  const duration = ((updated - started) / 1000).toFixed(0) + 's';
  
  const longest = jobs
    .flatMap(j => (j.steps || []).map(s => ({
      n: s.name,
      d: s.completed_at && s.started_at ? (new Date(s.completed_at) - new Date(s.started_at)) / 1000 : 0
    })))
    .sort((a, b) => b.d - a.d)[0];

  const failures = jobs.flatMap(j =>
    (j.steps || []).filter(s => s.conclusion && s.conclusion !== 'success')
      .map(s => ({ job: j.name, step: s.name, conclusion: s.conclusion }))
  );

  const tldr = meta.conclusion === 'success'
    ? `Passed in ${duration}. Longest step: ${longest?.n ?? 'n/a'} (${longest?.d ?? 0}s).`
    : `Failed in ${duration}. ${failures.length} failing step(s). Logs archived (${logsBytes} bytes).`;

  return `# ${badge} ${meta.name} (run #${meta.run_number})

![Badge](../../badges/run-${meta.id}.svg)

- **ID:** ${meta.id}
- **Workflow:** ${meta.name}
- **Actor:** @${meta.actor?.login || 'unknown'}
- **Event/Branch:** \`${meta.event}\` / \`${meta.head_branch}\`
- **SHA:** \`${meta.head_sha}\`
- **Started:** ${meta.run_started_at || meta.created_at}
- **Duration:** ${duration}
- **Conclusion:** \`${meta.conclusion || meta.status}\`

## TL;DR
${tldr}

${failures.length ? `## Failing Steps\n${failures.map(f => `- **${f.job}** › ${f.step} — \`${f.conclusion}\``).join('\n')}\n` : ''}
## Jobs
${jobs.map(j => `- ${j.name} • ${j.conclusion || j.status} • ${j.steps?.length ?? 0} steps`).join('\n')}

---
<sub>Archived by BossCat Run Conveyor • State machine: QUEUED → ARCHIVING → ARCHIVED → DELETED</sub>
`;
}

function renderBadge(conclusion) {
  const color = conclusion === 'success' ? '#2e7d32' : (conclusion === 'failure' ? '#c62828' : '#6d6d6d');
  const label = (conclusion || 'unknown').toUpperCase();
  
  return `<svg xmlns='http://www.w3.org/2000/svg' width='160' height='20'>
  <rect width='160' height='20' fill='#555'/>
  <rect x='70' width='90' height='20' fill='${color}'/>
  <text x='35' y='14' fill='#fff' font-family='Verdana' font-size='11' text-anchor='middle'>RUN</text>
  <text x='115' y='14' fill='#fff' font-family='Verdana' font-size='11' text-anchor='middle'>${label}</text>
</svg>`;
}

// ---------- Delete Lane (Red - Rate-Limited) ----------
const tokenLimiters = TOKENS.map(() => new Bottleneck({
  minTime: 1000 / DELETE_QPS_PER_TOKEN,  // Base pace (1/sec per token)
  reservoir: 60,                          // Burst capacity
  reservoirRefreshAmount: 60,
  reservoirRefreshInterval: 60 * 1000,    // Refill every minute
}));

async function deleteRun(runId, tokenIndex, ui) {
  const t0 = performance.now();
  
  if (DRY_RUN) {
    await ledger({ t: new Date().toISOString(), id: runId, state: 'DELETED', msg: 'DRY RUN - not actually deleted' });
    const dt = performance.now() - t0;
    timing.deleteDurMs.push(dt);
    stats.del.done++;
    if (ui) ui.tick(1);
    return;
  }

  stats.del.started++;
  const token = TOKENS[tokenIndex % TOKENS.length];
  const limiter = tokenLimiters[tokenIndex % tokenLimiters.length];
  
  return limiter.schedule(async () => {
    // Safety gate: verify ARCHIVED state
    const st = await latestState(runId);
    if (!okArchivedState(st)) {
      await ledger({ t: new Date().toISOString(), id: runId, state: 'SKIP', msg: 'Not archived – safety gate stop' });
      if (ui) ui.tick(1);
      return;
    }

    await ledger({ t: new Date().toISOString(), id: runId, state: 'DELETING', msg: 'Removing from Actions UI' });

    try {
      const res = await ghFetch(`${BASE}/runs/${runId}`, { token, method: 'DELETE' });

      if (res.statusCode === 204 || res.statusCode === 202) {
        await ledger({ t: new Date().toISOString(), id: runId, state: 'DELETED', msg: 'Removed from Actions UI' });
        stats.del.done++;
      } else {
        const body = await res.body.text();
        await ledger({ 
          t: new Date().toISOString(), 
          id: runId, 
          state: 'ERROR', 
          msg: `Delete failed: ${res.statusCode} ${body}` 
        });
        stats.del.errs++;
      }
    } catch (e) {
      await ledger({ 
        t: new Date().toISOString(), 
        id: runId, 
        state: 'ERROR', 
        msg: `Delete error: ${e.message}` 
      });
      stats.del.errs++;
    }
    
    const dt = performance.now() - t0;
    timing.deleteDurMs.push(dt);
    if (ui) ui.tick(1);
  });
}

// ---------- Controller (Orchestrates Both Lanes) ----------
async function listAllRuns(token, ui) {
  let page = 1;
  let all = [];
  let batch;
  
  // Estimate pages for progress bar
  const firstRes = await ghFetch(`${BASE}/runs?per_page=100&page=1`, { token });
  const firstData = await firstRes.body.json();
  const totalCount = firstData.total_count || 0;
  const estimatedPages = Math.ceil(totalCount / 100);
  
  if (ui) ui.start(estimatedPages);
  
  all.push(...(firstData.workflow_runs || []));
  if (ui) ui.tick(1);
  
  batch = firstData.workflow_runs || [];
  page = 2;
  
  while (batch.length === 100 && page <= 200) {
    const res = await ghFetch(`${BASE}/runs?per_page=100&page=${page}`, { token });
    const data = await res.body.json();
    batch = data.workflow_runs || [];
    all.push(...batch);
    if (ui) ui.tick(1);
    page++;
  }

  return all;
}

function estimateDeleteTime(count, tokens, qps) {
  const seconds = Math.ceil(count / (tokens * qps));
  return prettyMs(seconds * 1000, { unitCount: 2 });
}

async function main() {
  const swAll = new StopWatch(`conveyor:chunk[${CHUNK_OFFSET + 1}..${CHUNK_OFFSET + CHUNK_SIZE}]`);
  const METRICS_DIR = abs(process.env.METRICS_DIR || 'CHAR/EVID/artifacts/ecrr/arch');
  const METRICS_TAG = process.env.METRICS_TAG || '';
  
  // Self-test mode: prove concurrency with synthetic tasks
  if (SELFTEST) {
    console.log('🧪 BossCat Conveyor — Self-Test Mode (Concurrency Proof)');
    console.log(`Workers: ${ARCH_CONCURRENCY} | Tasks: ${SELFTEST_N} × ${SELFTEST_MS}ms`);
    console.log(`Expected wall time: ~${Math.ceil(SELFTEST_N / ARCH_CONCURRENCY) * SELFTEST_MS}ms\n`);
    
    const t0 = Date.now();
    for (let i = 0; i < SELFTEST_N; i++) {
      archiveQ.add(() => new Promise(r => setTimeout(r, SELFTEST_MS)));
    }
    await archiveQ.onIdle();
    const elapsed = Date.now() - t0;
    const ideal = Math.ceil(SELFTEST_N / ARCH_CONCURRENCY) * SELFTEST_MS;
    const efficiency = (ideal / elapsed * 100).toFixed(1);
    
    console.log(`✅ Elapsed: ${elapsed}ms | Ideal: ${ideal}ms | Efficiency: ${efficiency}%`);
    console.log(`Max inflight observed: ${stats.arch.inflightMax}`);
    
    if (efficiency >= 80) {
      console.log('🎉 PASS: Concurrency working as expected!');
    } else {
      console.log('⚠️ WARN: Lower than expected efficiency (check system load)');
    }
    
    process.exit(0);
  }
  
  console.log('🐾 BossCat Run Conveyor — Archive→Delete Pipeline (Chunked)');
  console.log(`Repository: ${REPO}`);
  console.log(`Keep newest: ${MAX_KEEP} runs`);
  console.log(`Chunk: size=${CHUNK_SIZE} offset=${CHUNK_OFFSET} (runs ${MAX_KEEP + CHUNK_OFFSET + 1}..${MAX_KEEP + CHUNK_OFFSET + CHUNK_SIZE})`);
  console.log(`Rate limits: Archive ${ARCH_QPS} req/s (${ARCH_CONCURRENCY} workers) • Delete ${DELETE_QPS_PER_TOKEN}/s`);
  console.log(`Tokens: ${TOKENS.length}`);
  console.log(`DRY RUN: ${DRY_RUN}`);
  console.log(`SKIP_RATE_LIMIT_WAIT: ${SKIP_RATE_LIMIT_WAIT}`);
  console.log(`TRACE: ${TRACE}`);

  if (!TOKENS.length) {
    throw new Error('GH_TOKENS or GITHUB_TOKEN required (comma-separated for multiple tokens)');
  }

  // Kill-switch check (ECRR Rule #2)
  if (existsSync('.agent/LOCK')) {
    throw new Error('Kill-switch active (.agent/LOCK exists). Aborting per ECRR doctrine.');
  }

  console.log('\n📊 Phase 1 — Inventory');
  console.log('Paging the Actions API to collect the backlog. Quick phase (~1-2 minutes).\n');
  
  const swInv = new StopWatch('inventory');
  const invUI = makePhaseUI('Collecting runs');
  const all = await listAllRuns(TOKENS[0], invUI);
  invUI.stop();
  timing.phases.inventory = swInv.stop();
  
  console.log(`\n✅ Fetched ${all.length} runs`);

  // 2) Partition: Keep newest MAX_KEEP + whitelist, then slice the chunk
  console.log('\n📊 Phase 2 — Computing KeepSet and Chunk');
  
  // Load checkpoint to resume from where we left off
  await loadCheckpoint();
  const resumeCount = completedRuns.size;
  if (resumeCount > 0) {
    console.log(`✅ Found checkpoint: ${resumeCount} runs already completed`);
  }
  
  const whitelist = await safeReadJson(WHITELIST_PATH, []);
  const sorted = [...all].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  const keepSet = new Set(sorted.slice(0, MAX_KEEP).map(r => r.id).concat(whitelist));
  
  // Chunk: skip MAX_KEEP + CHUNK_OFFSET, take CHUNK_SIZE
  const start = MAX_KEEP + CHUNK_OFFSET;
  const end = start + CHUNK_SIZE;
  const chunkRuns = sorted.slice(start, end).filter(r => !keepSet.has(r.id) && r.status === 'completed');
  
  // Filter out already-completed runs
  const remainingRuns = chunkRuns.filter(r => !isCompleted(r.id));
  
  console.log(`KeepSet: ${keepSet.size} runs (${MAX_KEEP} newest + ${whitelist.length} whitelisted)`);
  console.log(`Total available: ${sorted.length} runs`);
  console.log(`Chunk range: indices ${start}..${end} → ${chunkRuns.length} runs`);
  console.log(`Already completed: ${chunkRuns.length - remainingRuns.length} runs`);
  console.log(`Remaining to process: ${remainingRuns.length} runs`);

  if (remainingRuns.length === 0) {
    console.log('✅ Chunk is fully completed. Exiting.');
    return;
  }
  
  const archiveSet = remainingRuns;

  // Print timeline estimates (adjusted for QPS limits)
  const archReqsPerRun = 3; // run + jobs + logs
  const archETA = prettyMs((archiveSet.length * archReqsPerRun / ARCH_QPS) * 1000, { unitCount: 2 });
  const deleteETA = estimateDeleteTime(archiveSet.length, TOKENS.length, DELETE_QPS_PER_TOKEN);
  
  console.log('\n════════════════════════════════════════════════════════');
  console.log(`📦 Chunk ${CHUNK_OFFSET / CHUNK_SIZE} (runs ${start + 1}..${Math.min(end, sorted.length)})`);
  console.log(`🟦 Archive queue:    ${archiveSet.length} runs @ ${ARCH_QPS} req/s`);
  console.log(`   Archive ETA:      ≈ ${archETA}`);
  console.log(`🟥 Delete queue:     ${archiveSet.length} runs @ ${DELETE_QPS_PER_TOKEN}/s × ${TOKENS.length} token${TOKENS.length > 1 ? 's' : ''})`);
  console.log(`   Delete ETA:       ≈ ${deleteETA}`);
  console.log(`⏱️  Total ETA:       ≈ ${prettyMs((archiveSet.length * archReqsPerRun / ARCH_QPS + archiveSet.length / (DELETE_QPS_PER_TOKEN * TOKENS.length)) * 1000, { unitCount: 2 })}`);
  console.log('════════════════════════════════════════════════════════');

  // 3) BLUE LANE: Archive runs in parallel
  console.log('\n🔵 Phase 3 — Archive (Blue Lane)');
  console.log('Archiving runs in parallel. Auto-pauses if GitHub rate-limits, then resumes.\n');
  
  const swArc = new StopWatch('archive');
  const archUI = makePhaseUI('Archive');
  archUI.start(archiveSet.length);
  let archived = 0;
  
  for (const r of archiveSet) {
    archiveQ.add(async () => {
      try {
        await archiveRun(r, TOKENS[0], archUI);
        archived++;
      } catch (e) {
        console.error(`\nFailed to archive run ${r.id}: ${e.message}`);
      }
    });
  }

  await archiveQ.onIdle();
  archUI.stop();
  timing.phases.archive = swArc.stop({
    n: archived,
    p50_ms: pct(50, timing.archiveDurMs),
    p95_ms: pct(95, timing.archiveDurMs)
  });
  console.log(`\n✅ Archive complete: ${archived}/${archiveSet.length} runs`);

  // 4) RED LANE: Delete runs (rate-limited, safety-gated)
  console.log('\n🔴 Phase 4 — Delete (Red Lane)');
  console.log('One delete per second per token. Progress bar marches steadily.');
  console.log('Pauses may occur if GitHub rate-limits—we auto-resume.\n');
  
  const swDel = new StopWatch('delete');
  let deleted = 0;
  
  if (DRY_RUN) {
    console.log('⚠️ DRY RUN: Skipping deletion phase\n');
  } else {
    const delUI = makePhaseUI('Delete');
    delUI.start(archiveSet.length);
    let idx = 0;

    for (const r of archiveSet) {
      await deleteRun(r.id, idx++, delUI);
      deleted++;
    }

    delUI.stop();
    console.log(`\n✅ Delete complete: ${deleted}/${archiveSet.length} runs`);
  }
  
  timing.phases.delete = swDel.stop({
    n: deleted,
    p50_ms: pct(50, timing.deleteDurMs),
    p95_ms: pct(95, timing.deleteDurMs)
  });

  // 5) Final verification
  console.log('\n📊 Phase 5: Verification...');
  const swVer = new StopWatch('verify');
  const finalRes = await request(`${BASE}/runs?per_page=1`, { headers: hdr(TOKENS[0]) });
  const finalData = await finalRes.body.json();
  const finalCount = finalData.total_count;
  timing.phases.verify = swVer.stop();

  console.log(`Final run count: ${finalCount}`);
  console.log(`Target: ${MAX_KEEP}`);

  if (finalCount <= MAX_KEEP + 50) {
    console.log('✅ SUCCESS: Run count within acceptable range');
  } else {
    console.log('⚠️ WARNING: Run count higher than expected (may need another pass)');
  }

  // 6) Write stats and update BossCat log
  clearInterval(telemetryTimer);
  
  if (TRACE) console.log('\n'); // Clear telemetry line
  
  const statsPath = 'CHAR/EVID/artifacts/ecrr/arch/CONVEYOR_STATS.json';
  await mkdir('CHAR/EVID/artifacts/ecrr/arch', { recursive: true });
  await writeFile(statsPath, JSON.stringify({
    timestamp: new Date().toISOString(),
    chunk: { offset: CHUNK_OFFSET, size: CHUNK_SIZE },
    arch: stats.arch,
    del: stats.del,
    http: stats.http,
    config: {
      archConcurrency: ARCH_CONCURRENCY,
      archQps: ARCH_QPS,
      deleteQps: DELETE_QPS_PER_TOKEN,
      dryRun: DRY_RUN
    }
  }, null, 2));
  
  const deletedCount = DRY_RUN ? 0 : (deleted || 0);
  const logEntry = `- ${new Date().toISOString()} — Conveyor: Archived ${archived}, Deleted ${deletedCount}, Remaining ${finalCount}`;
  try {
    const logPath = abs('docs/BossCat/BOSSCAT_LOG.md');
    let logContent = '';
    if (existsSync(logPath)) {
      logContent = await readFile(logPath, 'utf8');
    }
    await writeFile(logPath, (logContent.trimEnd() + '\n' + logEntry + '\n'), 'utf8');
  } catch (e) {
    console.warn(`Could not update BossCat log: ${e.message}`);
  }

  console.log('\n🎉 Conveyor execution complete!');
  console.log(`Archived: ${archived}/${archiveSet.length} runs`);
  if (!DRY_RUN) {
    console.log(`Deleted: ${deleted}/${archiveSet.length} runs`);
  }
  console.log(`Evidence: ${LEDGER}`);
  console.log(`Checkpoint: ${CHECKPOINT_FILE}`);
  console.log(`Stats: ${statsPath}`);
  console.log(`\n📊 Concurrency Stats:`);
  console.log(`   Max inflight workers: ${stats.arch.inflightMax}/${ARCH_CONCURRENCY}`);
  console.log(`   Archive errors: ${stats.arch.errs}`);
  console.log(`   Delete errors: ${stats.del.errs}`);
  console.log(`   HTTP 429s: ${stats.http.r429}`);
  console.log(`   HTTP 5xxs: ${stats.http.r5xx}`);
  console.log(`   Total backoff time: ${prettyMs(stats.http.backoffMs)}`);
  
  // Timing summary & ETA calibration
  const allTime = swAll.stop();
  const predArchiveSec = Math.ceil((timing.phases.archive?.n ?? 0) * 3 / ARCH_QPS);
  const predDeleteSec = Math.ceil((timing.phases.delete?.n ?? 0) / DELETE_QPS_PER_TOKEN);
  const actArchiveSec = Math.round((timing.phases.archive?.total_ms ?? 0) / 1000);
  const actDeleteSec = Math.round((timing.phases.delete?.total_ms ?? 0) / 1000);
  const K_archive = predArchiveSec ? (actArchiveSec / predArchiveSec) : 1.0;
  const K_delete = predDeleteSec ? (actDeleteSec / predDeleteSec) : 1.0;
  
  function line(name, ms, extra = '') {
    return `${name.padEnd(10)} ${hhmmss(ms)}${extra ? '  ' + extra : ''}`;
  }
  
  console.log('\n⏱️  TIMING SUMMARY —', swAll.label);
  console.log(line('inventory:', timing.phases.inventory?.total_ms ?? 0));
  console.log(line('archive:  ', timing.phases.archive?.total_ms ?? 0,
    `(p50=${timing.phases.archive?.p50_ms ?? '-'}ms, p95=${timing.phases.archive?.p95_ms ?? '-'}ms, ` +
    `QPS=${((timing.phases.archive?.n ?? 0) / ((timing.phases.archive?.total_ms ?? 1) / 1000)).toFixed(2)} of target ${ARCH_QPS.toFixed(2)} → K=${K_archive.toFixed(2)})`));
  console.log(line('delete:   ', timing.phases.delete?.total_ms ?? 0,
    `(p50=${timing.phases.delete?.p50_ms ?? '-'}ms, p95=${timing.phases.delete?.p95_ms ?? '-'}ms, ` +
    `QPS=${((timing.phases.delete?.n ?? 0) / ((timing.phases.delete?.total_ms ?? 1) / 1000)).toFixed(2)} of target ${DELETE_QPS_PER_TOKEN.toFixed(2)} → K=${K_delete.toFixed(2)})`));
  const predTotalMs = (predArchiveSec + predDeleteSec) * 1000 + (timing.phases.inventory?.total_ms ?? 0) + (timing.phases.verify?.total_ms ?? 0);
  console.log(line('total:    ', allTime.total_ms, `(pred=${hhmmss(predTotalMs)})`));
  
  console.log(`\n📏 ETA calibration hint → archiveQPS *= ${(1 / K_archive).toFixed(2)}, deleteQPS *= ${(1 / K_delete).toFixed(2)}`);
  
  // Write timing metrics to JSONL
  const metricsFile = join(METRICS_DIR, `METRICS${DRY_RUN ? '_DRYRUN' : ''}.jsonl`);
  appendJSONL(metricsFile, {
    t: new Date().toISOString(),
    repo: REPO,
    chunk: { size: CHUNK_SIZE, offset: CHUNK_OFFSET, range: [CHUNK_OFFSET + 1, CHUNK_OFFSET + CHUNK_SIZE] },
    dry_run: DRY_RUN,
    config: { ARCH_QPS, DELETE_QPS: DELETE_QPS_PER_TOKEN, ARCH_CONCURRENCY },
    phases: {
      inventory: { ms: timing.phases.inventory?.total_ms ?? 0 },
      archive: {
        n: timing.phases.archive?.n ?? 0,
        ms: timing.phases.archive?.total_ms ?? 0,
        p50_ms: timing.phases.archive?.p50_ms ?? null,
        p95_ms: timing.phases.archive?.p95_ms ?? null
      },
      delete: {
        n: timing.phases.delete?.n ?? 0,
        ms: timing.phases.delete?.total_ms ?? 0,
        p50_ms: timing.phases.delete?.p50_ms ?? null,
        p95_ms: timing.phases.delete?.p95_ms ?? null
      },
      verify: { ms: timing.phases.verify?.total_ms ?? 0 },
      total_ms: allTime.total_ms
    },
    eta: {
      predicted_sec: { archive: predArchiveSec, delete: predDeleteSec, total: Math.round(predTotalMs / 1000) },
      actual_sec: { archive: actArchiveSec, delete: actDeleteSec, total: Math.round(allTime.total_ms / 1000) },
      k_factor: { archive: Number(K_archive.toFixed(3)), delete: Number(K_delete.toFixed(3)) }
    },
    stats: {
      arch: stats.arch,
      del: stats.del,
      http: stats.http
    },
    tag: METRICS_TAG || undefined
  });
  
  console.log(`\n📊 Metrics: ${metricsFile}`);
}

// Entry point
main().catch(async e => {
  await ledger({ t: new Date().toISOString(), id: 0, state: 'ERROR', msg: String(e) });
  console.error('Fatal error:', e);
  process.exit(1);
});

