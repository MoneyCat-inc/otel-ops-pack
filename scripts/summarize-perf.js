// Summarize k6 performance results into a compact GPU_FIX summary
// Reads DELT/ARTF/k6-summary.json and writes DELT/ARTF/gpu_fix_summary.json
const fs = require('fs');
const path = require('path');

try {
  const site = process.env.SITE || 'ci';
  const useMock = (process.env.USE_MOCK || 'true').toLowerCase() === 'true';
  const ardir = process.env.ARTIFACT_DIR || 'DELT/ARTF';
  const gfdir = path.join(ardir, 'gpu_fix');
  const input = path.join(gfdir, 'k6-summary.json');
  const output = path.join(gfdir, 'gpu_fix_summary.json');

  if (!fs.existsSync(input)) {
    console.error(`Missing k6 summary: ${input}`);
    process.exit(0);
  }

  const raw = JSON.parse(fs.readFileSync(input, 'utf8'));
  const dur = raw.metrics && raw.metrics.http_req_duration;
  const fail = raw.metrics && raw.metrics.http_req_failed;
  const p95 = dur && dur.values ? dur.values['p(95)'] : undefined;
  const err = fail && fail.values ? fail.values.rate : undefined;

  const strict = site === 'prod' && !useMock;
  const sloP95 = Number(process.env.SLO_P95_MS || (strict ? 200 : 500));
  const sloErr = Number(process.env.SLO_ERR_RATE || (strict ? 0.005 : 0.01));

  const payload = {
    gate: 'GPU_FIX',
    site,
    useMock,
    slo: { p95_ms: sloP95, err_rate: sloErr },
    result: { p95_ms_observed: p95, error_rate_observed: err },
    verdict: typeof p95 === 'number' && typeof err === 'number' ? 'evaluated' : 'unknown',
    source: 'k6',
    artifacts: ['k6-summary.json'],
    ts: new Date().toISOString(),
  };

  if (!fs.existsSync(gfdir)) {
    fs.mkdirSync(gfdir, { recursive: true });
  }
  fs.writeFileSync(output, JSON.stringify(payload, null, 2));
  console.log(`Wrote ${output}`);
} catch (e) {
  console.error(`summarize-perf error: ${e.message}`);
  process.exit(0);
}
