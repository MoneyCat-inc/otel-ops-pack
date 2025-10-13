// BRAV/SCPT/icf/rsi-metrics-extractor.ts
// RSI Metrics Extractor v0.1: Analyzes run evidence and emits actionable metrics
// Reads EVIDENCE.jsonl, outputs RSI_METRICS.json + RSI_METRICS.md
import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'fs';
import { dirname } from 'path';

const src = 'CHAR/EVID/artifacts/ecrr/arch/EVIDENCE.jsonl';
const outJson = 'CHAR/EVID/artifacts/ecrr/arch/RSI_METRICS.json';
const outMd = 'docs/BossCat/RSI_METRICS.md';

function parseJSONL(p: string) {
  if (!existsSync(p)) return [];
  const t = readFileSync(p, 'utf8').trim();
  if (!t) return [];
  return t.split('\n').map(l => { try { return JSON.parse(l) } catch { return null } }).filter(Boolean);
}

const rows: any[] = parseJSONL(src);
const runs = rows.filter(r => r.type === 'run-report' || r.type === 'run' || r.type === 'workflow_run' || r.run_id || r.id).map(r => ({
  id: r.run_id || r.id,
  workflow: r.workflow || r.name || 'unknown',
  status: (r.conclusion || r.status || '').toLowerCase(),
  durationMs: +(r.durationMs || r.duration_ms || r.duration || 0),
  endedAt: r.concluded_at || r.updated_at || r.created_at || r.t
}));

const total = runs.length;
const succ = runs.filter(r => ['success', 'completed', 'passed'].includes(r.status)).length;
const fail = runs.filter(r => ['failure', 'failed', 'cancelled'].includes(r.status)).length;
const durs = runs.filter(r => r.durationMs > 0).map(r => r.durationMs);
const avgMs = durs.length ? Math.round(durs.reduce((a, b) => a + b, 0) / durs.length) : 0;

const wf: Record<string, { fails: number, total: number }> = {};
runs.forEach(r => {
  wf[r.workflow] ??= { fails: 0, total: 0 };
  wf[r.workflow].total++;
  if (['failure', 'failed'].includes(r.status)) wf[r.workflow].fails++;
});

const top = Object.entries(wf).sort((a, b) => (b[1].fails - a[1].fails) || (b[1].total - a[1].total)).slice(0, 5)
  .map(([name, v]) => ({ workflow: name, failures: v.fails, total: v.total }));

const metrics = {
  generatedAt: new Date().toISOString(),
  totals: { totalRuns: total, successes: succ, failures: fail, passRate: total ? +((succ / total) * 100).toFixed(2) : 0 },
  durations: { avgMs },
  topFailingWorkflows: top
};

[outJson, outMd].forEach(p => mkdirSync(dirname(p), { recursive: true }));
writeFileSync(outJson, JSON.stringify(metrics, null, 2));
writeFileSync(outMd,
  `# RSI Metrics (auto-generated)\n\n` +
  `- **Generated:** ${metrics.generatedAt}\n` +
  `- **Total Runs:** ${total}\n` +
  `- **Pass Rate:** ${metrics.totals.passRate}%\n` +
  `- **Avg Duration:** ${avgMs} ms\n\n` +
  `## Top Failing Workflows\n\n` +
  `| Workflow | Failures | Total |\n` +
  `|---|---:|---:|\n` +
  `${top.map(t => `| ${t.workflow} | ${t.failures} | ${t.total} |`).join('\n')}\n`
);

console.log(JSON.stringify({ type: 'rsi-metrics', totals: metrics.totals, avgMs, wrote: [outJson, outMd] }));

