import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { Octokit } from '@octokit/rest';

const REPO = process.env.GITHUB_REPOSITORY || '';
const [owner, repo] = REPO.split('/')
  .length === 2 ? REPO.split('/') : [process.env.OWNER, process.env.REPO];
const token = process.env.GITHUB_TOKEN || process.env.TOKEN;
const MAX_ON_REPO = parseInt(process.env.MAX_ON_REPO || '100', 10);
const DRY_RUN = (process.env.DRY_RUN || 'false').toLowerCase() === 'true';

if (!owner || !repo) {
  console.error('OWNER/REPO unresolved. Set GITHUB_REPOSITORY or OWNER/REPO env.');
  process.exit(1);
}
if (!token) {
  console.error('GITHUB_TOKEN is required.');
  process.exit(1);
}

const octokit = new Octokit({ auth: token });

const OUT_ROOT = path.join('docs', 'BossCat', 'run-reports');
const OUT_ARCH = path.join(OUT_ROOT, 'archived');
const OUT_LATEST = path.join(OUT_ROOT, 'latest');
const OUT_BADGES = path.join(OUT_ROOT, 'badges');
const EVID_ROOT = path.join('CHAR', 'EVID', 'artifacts', 'ecrr', 'arch');
const RSI_JSON = path.join('docs', 'BossCat', 'RSI_METRICS.json');
const RSI_MD = path.join('docs', 'BossCat', 'RSI_METRICS.md');

function ensureDir(p) { fs.mkdirSync(p, { recursive: true }); }
function iso(dt) { return new Date(dt).toISOString(); }
function durMs(a, b) { return new Date(b).getTime() - new Date(a).getTime(); }
function fmtDur(ms) {
  if (!Number.isFinite(ms) || ms < 0) return 'n/a';
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}m ${r}s`;
}
function statusColor(conclusion) {
  switch (conclusion) {
    case 'success': return '#2e7d32';
    case 'failure': return '#c62828';
    case 'cancelled': return '#6d6d6d';
    case 'timed_out': return '#ef6c00';
    default: return '#1976d2';
  }
}
function badgeSvg(label, msg, color) {
  const text = `${label}: ${msg}`;
  return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"${120 + text.length * 6}\" height=\"20\">\n  <rect width=\"100%\" height=\"20\" fill=\"#555\"/>\n  <rect x=\"70\" width=\"100%\" height=\"20\" fill=\"${color}\"/>\n  <text x=\"8\" y=\"14\" fill=\"#fff\" font-family=\"Verdana\" font-size=\"11\">${label}</text>\n  <text x=\"78\" y=\"14\" fill=\"#fff\" font-family=\"Verdana\" font-size=\"11\">${msg}</text>\n</svg>`;
}

async function listRecentRuns(limit = 150) {
  const per_page = Math.min(limit, 100);
  let page = 1;
  const acc = [];
  while (acc.length < limit) {
    const { data } = await octokit.actions.listWorkflowRunsForRepo({ owner, repo, per_page, page });
    acc.push(...data.workflow_runs);
    if (!data.workflow_runs?.length) break;
    if (data.total_count && acc.length >= data.total_count) break;
    page += 1;
  }
  return acc.slice(0, limit);
}

function tldr(run, jobs, tests) {
  const ok = run.conclusion === 'success';
  const icon = ok ? '✅' : '❌';
  const d = fmtDur(durMs(run.created_at, run.updated_at || run.run_started_at || run.created_at));
  const testsStr = tests ? ` • 🧪 ${tests.total} tests (❌ ${tests.failed || 0})` : '';
  return `${icon} ${run.name || 'Workflow'} ${ok ? 'SUCCESS' : (run.conclusion || run.status)} in ${d} on ${run.head_branch}@${(run.head_sha || '').slice(0,7)} • #${run.run_number} • ${iso(run.created_at)}${testsStr}`;
}

async function getJobs(runId) {
  try {
    const { data } = await octokit.actions.listJobsForWorkflowRun({ owner, repo, run_id: runId, per_page: 100 });
    return data.jobs || [];
  } catch { return []; }
}

function runMd(run, jobs, badgePath, tests) {
  const title = `${run.name || 'Workflow'} — #${run.run_number}`;
  const tl = tldr(run, jobs, tests);
  const created = iso(run.created_at);
  const completed = iso(run.updated_at || run.run_started_at || run.created_at);
  const duration = fmtDur(durMs(run.created_at, run.updated_at || run.run_started_at || run.created_at));
  const jobsList = (jobs || []).map(j => `- ${j.name} — ${j.conclusion || j.status}`).join('\n');
  const testsBlock = tests ? `\n### Tests\n- total: ${tests.total}\n- failed: ${tests.failed || 0}\n` : '';
  return `# ${title}\n\n![](${badgePath})\n\n- Status: ${run.status}\n- Conclusion: ${run.conclusion}\n- Actor: ${run.actor?.login || ''}\n- Branch: ${run.head_branch}\n- Commit: ${run.head_sha}\n- Created: ${created}\n- Completed: ${completed}\n- Duration: ${duration}\n- URL: ${run.html_url}\n\n## Jobs\n${jobsList || '- (none listed)'}\n${testsBlock}\n---\n\nTL;DR — ${tl}\n`;
}

async function writeReport(run) {
  const y = new Date(run.created_at).getUTCFullYear();
  const m = String(new Date(run.created_at).getUTCMonth() + 1).padStart(2, '0');
  const archDir = path.join(OUT_ARCH, String(y), String(m));
  ensureDir(archDir);
  ensureDir(OUT_LATEST);
  ensureDir(OUT_BADGES);
  ensureDir(EVID_ROOT);
  const badgeFile = path.join(OUT_BADGES, `run-${run.id}.svg`);
  const badgeRel = path.relative(path.join(OUT_ROOT), badgeFile).split(path.sep).join('/');
  const jobs = await getJobs(run.id);

  // Placeholder for future test parsing (JUnit etc.)
  const tests = null;

  const svg = badgeSvg('Run', (run.conclusion || run.status || 'unknown').toUpperCase(), statusColor(run.conclusion));
  const md = runMd(run, jobs, `./${badgeRel}`, tests);

  const archPath = path.join(archDir, `run-${run.id}.md`);
  if (!DRY_RUN) {
    await fsp.writeFile(badgeFile, svg, 'utf8');
    await fsp.writeFile(archPath, md, 'utf8');
  }
  return { archPath, mdPath: archPath, tl: tldr(run, jobs, tests), createdAt: run.created_at };
}

function computeMetrics(runs) {
  const total = runs.length;
  let success = 0; let failure = 0; let cancelled = 0; let timed_out = 0; let other = 0;
  let durations = [];
  for (const r of runs) {
    const conc = r.conclusion || r.status || 'unknown';
    if (conc === 'success') success++; else if (conc === 'failure') failure++; else if (conc === 'cancelled') cancelled++; else if (conc === 'timed_out') timed_out++; else other++;
    const ms = durMs(r.created_at, r.updated_at || r.run_started_at || r.created_at);
    if (Number.isFinite(ms) && ms >= 0) durations.push(ms);
  }
  const avgMs = durations.length ? Math.round(durations.reduce((a,b)=>a+b,0) / durations.length) : 0;
  const passRate = total ? +(success/total*100).toFixed(2) : 0;
  return { total, success, failure, cancelled, timed_out, other, avg_duration_ms: avgMs, pass_rate_pct: passRate };
}

function rsiMd(m) {
  return `# RSI Metrics\n\n- Total runs: ${m.total}\n- Success: ${m.success}\n- Failure: ${m.failure}\n- Cancelled: ${m.cancelled}\n- Timed out: ${m.timed_out}\n- Other: ${m.other}\n- Avg duration: ${fmtDur(m.avg_duration_ms)}\n- Pass rate: ${m.pass_rate_pct}%\n\nTL;DR — ${m.pass_rate_pct}% pass • avg ${fmtDur(m.avg_duration_ms)} over ${m.total} runs\n`;
}

async function rotateLatest(allInfos) {
  const sorted = [...allInfos].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  const keep = sorted.slice(0, MAX_ON_REPO);

  // Clear current latest dir
  const entries = fs.existsSync(OUT_LATEST) ? fs.readdirSync(OUT_LATEST) : [];
  for (const e of entries) {
    fs.rmSync(path.join(OUT_LATEST, e), { recursive: true, force: true });
  }
  // Copy reports into latest
  for (const info of keep) {
    const base = path.basename(info.mdPath);
    const dst = path.join(OUT_LATEST, base);
    if (!DRY_RUN) {
      const content = await fsp.readFile(info.mdPath, 'utf8');
      await fsp.writeFile(dst, content, 'utf8');
    }
  }
  // Write LATEST.md index
  const lines = [
    '# Latest Workflow Run Reports',
    '',
    `Keeping the newest ${MAX_ON_REPO} reports.`,
    ''
  ];
  for (const info of keep) {
    const relArch = path.relative(OUT_ROOT, info.mdPath).split(path.sep).join('/');
    const base = path.basename(info.mdPath);
    lines.push(`- ${base} — [archived](${relArch})`);
  }
  if (!DRY_RUN) {
    await fsp.writeFile(path.join(OUT_ROOT, 'LATEST.md'), lines.join('\n') + '\n', 'utf8');
  }
}

async function appendEvidence(lines) {
  ensureDir(EVID_ROOT);
  const evPath = path.join(EVID_ROOT, 'EVIDENCE.jsonl');
  if (DRY_RUN) return;
  await fsp.appendFile(evPath, lines.map(l => JSON.stringify(l)).join('\n') + '\n', 'utf8');
}

async function appendBossCatLog(message) {
  const logPath = path.join('docs', 'BossCat', 'BOSSCAT_LOG.md');
  const ts = new Date().toISOString();
  const line = `- ${ts} — ${message}`;
  let cur = '';
  try { cur = await fsp.readFile(logPath, 'utf8'); } catch { /* ignore */ }
  const out = cur ? (cur.trimEnd() + '\n' + line + '\n') : ('# BossCat Log\n\n' + line + '\n');
  if (!DRY_RUN) await fsp.writeFile(logPath, out, 'utf8');
}

async function main() {
  console.log(`Archiving runs for ${owner}/${repo} … MAX_ON_REPO=${MAX_ON_REPO} DRY_RUN=${DRY_RUN}`);
  ensureDir(OUT_ARCH); ensureDir(OUT_LATEST); ensureDir(OUT_BADGES); ensureDir(EVID_ROOT);
  const runs = await listRecentRuns(150);
  const infos = [];
  const evid = [];
  for (const run of runs) {
    const info = await writeReport(run);
    infos.push(info);
    evid.push({ type: 'run-report', id: run.id, number: run.run_number, conclusion: run.conclusion, created_at: run.created_at, md: path.relative('.', info.mdPath).replace(/\\/g,'/') });
  }
  await rotateLatest(infos);
  await appendEvidence(evid);
  // RSI metrics
  const metrics = computeMetrics(runs);
  if (!DRY_RUN) {
    await fsp.writeFile(RSI_JSON, JSON.stringify(metrics, null, 2), 'utf8');
    await fsp.writeFile(RSI_MD, rsiMd(metrics), 'utf8');
  }
  await appendBossCatLog(`Run archiver updated ${infos.length} reports; rotated latest to ${Math.min(infos.length, MAX_ON_REPO)}.`);
  console.log('Done.');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
