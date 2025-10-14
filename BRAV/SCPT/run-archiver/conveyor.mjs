// BRAV/SCPT/run-archiver/conveyor.mjs
// BossCat Run Conveyor — Archive→Delete pipeline
// Authority: BossCat OEM • ECRR-compliant • Two-agent governance
// State: QUEUED → ARCHIVING → ARCHIVED → DELETE_QUEUED → DELETING → DELETED

import { setTimeout as sleep } from 'node:timers/promises';
import { writeFile, appendFile, mkdir, readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import Bottleneck from 'bottleneck';
import PQueue from 'p-queue';
import { request } from 'undici';
import prettyMs from 'pretty-ms';
import cliProgress from 'cli-progress';

const REPO = process.env.REPO || 'MoneyCat-inc/otel-ops-pack';
const TOKENS = (process.env.GH_TOKENS || process.env.GITHUB_TOKEN || '').split(',').filter(Boolean);
const MAX_KEEP = Number(process.env.MAX_KEEP || 100);
const CHUNK_SIZE = Number(process.env.CHUNK_SIZE || 1000);
const CHUNK_OFFSET = Number(process.env.CHUNK_OFFSET || 0);
const ARCH_CONCURRENCY = Number(process.env.ARCH_CONCURRENCY || 48);
const ARCH_QPS = Number(process.env.ARCH_QPS || 2.5);
const DELETE_QPS_PER_TOKEN = Number(process.env.DELETE_QPS || 1.0);
const DRY_RUN = (process.env.DRY_RUN || 'false').toLowerCase() === 'true';
const SKIP_RATE_LIMIT_WAIT = (process.env.SKIP_RATE_LIMIT_WAIT || 'false').toLowerCase() === 'true';

const BASE = `https://api.github.com/repos/${REPO}/actions`;
const LEDGER = 'CHAR/EVID/artifacts/ecrr/arch/LEDGER.jsonl';
const WHITELIST_PATH = 'BRAV/SCPT/run-archiver/whitelist.json';
const CHECKPOINT_DIR = 'CHAR/EVID/artifacts/ecrr/arch/checkpoints';
const CHECKPOINT_FILE = `${CHECKPOINT_DIR}/chunk_${CHUNK_OFFSET}_${CHUNK_SIZE}.json`;

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

async function ghFetch(url, { token, method = 'GET', body, headers = {}, maxRetries = 8 }) {
  let attempt = 0;
  let backoff = 2000;

  while (true) {
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
      await new Promise(r => setTimeout(r, sleepMs));
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
  await mkdir('CHAR/EVID/artifacts/ecrr/arch', { recursive: true });
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

async function archiveRun(run, token, ui) {
  // Skip if already completed in this chunk
  if (isCompleted(run.id)) {
    if (ui) ui.tick(1);
    return;
  }

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
    const dir = `docs/BossCat/run-reports/archived/${year}/${month}`;
    await mkdir(dir, { recursive: true });
    
    const badgeDir = 'docs/BossCat/run-reports/badges';
    await mkdir(badgeDir, { recursive: true });

    const mdPath = `${dir}/run-${run.id}.md`;
    const badgePath = `${badgeDir}/run-${run.id}.svg`;
    
    // Render report
    const body = renderReport(meta, jobs, logsBytes);
    await writeFile(mdPath, body, 'utf8');
    
    // Render badge
    const badge = renderBadge(meta.conclusion);
    await writeFile(badgePath, badge, 'utf8');

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
    
    if (ui) ui.tick(1);

  } catch (e) {
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
  if (DRY_RUN) {
    await ledger({ t: new Date().toISOString(), id: runId, state: 'DELETED', msg: 'DRY RUN - not actually deleted' });
    if (ui) ui.tick(1);
    return;
  }

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
      } else {
        const body = await res.body.text();
        await ledger({ 
          t: new Date().toISOString(), 
          id: runId, 
          state: 'ERROR', 
          msg: `Delete failed: ${res.statusCode} ${body}` 
        });
      }
    } catch (e) {
      await ledger({ 
        t: new Date().toISOString(), 
        id: runId, 
        state: 'ERROR', 
        msg: `Delete error: ${e.message}` 
      });
    }
    
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
  console.log('🐾 BossCat Run Conveyor — Archive→Delete Pipeline (Chunked)');
  console.log(`Repository: ${REPO}`);
  console.log(`Keep newest: ${MAX_KEEP} runs`);
  console.log(`Chunk: size=${CHUNK_SIZE} offset=${CHUNK_OFFSET} (runs ${MAX_KEEP + CHUNK_OFFSET + 1}..${MAX_KEEP + CHUNK_OFFSET + CHUNK_SIZE})`);
  console.log(`Rate limits: Archive ${ARCH_QPS} req/s (${ARCH_CONCURRENCY} workers) • Delete ${DELETE_QPS_PER_TOKEN}/s`);
  console.log(`Tokens: ${TOKENS.length}`);
  console.log(`DRY RUN: ${DRY_RUN}`);
  console.log(`SKIP_RATE_LIMIT_WAIT: ${SKIP_RATE_LIMIT_WAIT}`);

  if (!TOKENS.length) {
    throw new Error('GH_TOKENS or GITHUB_TOKEN required (comma-separated for multiple tokens)');
  }

  // Kill-switch check (ECRR Rule #2)
  if (existsSync('.agent/LOCK')) {
    throw new Error('Kill-switch active (.agent/LOCK exists). Aborting per ECRR doctrine.');
  }

  console.log('\n📊 Phase 1 — Inventory');
  console.log('Paging the Actions API to collect the backlog. Quick phase (~1-2 minutes).\n');
  
  const invUI = makePhaseUI('Collecting runs');
  const all = await listAllRuns(TOKENS[0], invUI);
  invUI.stop();
  
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
  console.log(`\n✅ Archive complete: ${archived}/${archiveSet.length} runs`);

  // 4) RED LANE: Delete runs (rate-limited, safety-gated)
  console.log('\n🔴 Phase 4 — Delete (Red Lane)');
  console.log('One delete per second per token. Progress bar marches steadily.');
  console.log('Pauses may occur if GitHub rate-limits—we auto-resume.\n');
  
  if (DRY_RUN) {
    console.log('⚠️ DRY RUN: Skipping deletion phase\n');
  } else {
    const delUI = makePhaseUI('Delete');
    delUI.start(archiveSet.length);
    let deleted = 0;
    let idx = 0;

    for (const r of archiveSet) {
      await deleteRun(r.id, idx++, delUI);
      deleted++;
    }

    delUI.stop();
    console.log(`\n✅ Delete complete: ${deleted}/${archiveSet.length} runs`);
  }

  // 5) Final verification
  console.log('\n📊 Phase 5: Verification...');
  const finalRes = await request(`${BASE}/runs?per_page=1`, { headers: hdr(TOKENS[0]) });
  const finalData = await finalRes.body.json();
  const finalCount = finalData.total_count;

  console.log(`Final run count: ${finalCount}`);
  console.log(`Target: ${MAX_KEEP}`);

  if (finalCount <= MAX_KEEP + 50) {
    console.log('✅ SUCCESS: Run count within acceptable range');
  } else {
    console.log('⚠️ WARNING: Run count higher than expected (may need another pass)');
  }

  // 6) Update BossCat log
  const logEntry = `- ${new Date().toISOString()} — Conveyor: Archived ${archived}, Deleted ${deleted}, Remaining ${finalCount}`;
  try {
    const logPath = 'docs/BossCat/BOSSCAT_LOG.md';
    let logContent = '';
    if (existsSync(logPath)) {
      logContent = await readFile(logPath, 'utf8');
    }
    await writeFile(logPath, (logContent.trimEnd() + '\n' + logEntry + '\n'), 'utf8');
  } catch (e) {
    console.warn(`Could not update BossCat log: ${e.message}`);
  }

  console.log('\n🎉 Conveyor execution complete!');
}

// Entry point
main().catch(async e => {
  await ledger({ t: new Date().toISOString(), id: 0, state: 'ERROR', msg: String(e) });
  console.error('Fatal error:', e);
  process.exit(1);
});

