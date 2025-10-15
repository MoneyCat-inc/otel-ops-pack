#!/usr/bin/env node
// BRAV/SCPT/rsi-bench/score.mjs — Compare baseline vs candidate metrics and decide pass/fail
import { createReadStream } from 'node:fs';
import { dirname, resolve } from 'node:path';
import readline from 'node:readline';

const args = process.argv.slice(2);
let compare = null; // [baselineTag, candidateTag]
let kind = 'both'; // 'index' | 'arch' | 'both'
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--compare') { compare = [args[i+1], args[i+2]]; i+=2; }
  else if (args[i] === '--kind') { kind = args[i+1]; i++; }
}
if (!compare) {
  console.error('Usage: node BRAV/SCPT/rsi-bench/score.mjs --compare <baselineTag> <candidateTag> [--kind index|arch|both]');
  process.exit(2);
}

const ROOT = resolve(process.cwd());
const files = {
  index: resolve(ROOT, 'CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl'),
  arch: resolve(ROOT, 'CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl')
};

async function readMetrics(file) {
  const out = [];
  try {
    const rl = readline.createInterface({ input: createReadStream(file, 'utf8'), crlfDelay: Infinity });
    for await (const line of rl) {
      if (!line.trim()) continue;
      try { out.push(JSON.parse(line)); } catch {}
    }
  } catch { /* missing is ok */ }
  return out;
}

function pickByTag(rows, tag) {
  return rows.filter(r => r.tag === tag).slice(-1)[0] || null;
}

function cmpIndex(base, cand) {
  const filesSecBase = base?.primary?.files_per_sec ?? 0;
  const filesSecCand = cand?.primary?.files_per_sec ?? 0;
  const errorsCand = cand?.guards?.errors ?? 0;
  const p95 = cand?.guards?.batch_p95_ms ?? null; // optional
  const delta = filesSecBase === 0 ? (filesSecCand > 0 ? 1 : 0) : (filesSecCand - filesSecBase) / filesSecBase;
  const pass = (filesSecCand > filesSecBase) && (errorsCand === 0);
  return { score: Number(delta.toFixed(4)), pass, primary: { files_per_sec: filesSecCand }, guards: { errors: errorsCand, batch_p95_ms: p95 } };
}

function cmpArch(base, cand) {
  const qpsBase = base?.primary?.arch_qps_effective ?? 0;
  const qpsCand = cand?.primary?.arch_qps_effective ?? 0;
  const errRate = cand?.guards?.error_rate ?? 0;
  const backoff = cand?.guards?.rate_backoff_ms ?? 0;
  const delta = qpsBase === 0 ? (qpsCand > 0 ? 1 : 0) : (qpsCand - qpsBase) / qpsBase;
  const pass = (qpsCand > qpsBase) && (errRate === 0);
  return { score: Number(delta.toFixed(4)), pass, primary: { arch_qps_effective: qpsCand }, guards: { error_rate: errRate, rate_backoff_ms: backoff } };
}

(async () => {
  const out = {};
  if (kind === 'index' || kind === 'both') {
    const rows = await readMetrics(files.index);
    const base = pickByTag(rows, compare[0]);
    const cand = pickByTag(rows, compare[1]);
    out.index = cmpIndex(base, cand);
  }
  if (kind === 'arch' || kind === 'both') {
    const rows = await readMetrics(files.arch);
    const base = pickByTag(rows, compare[0]);
    const cand = pickByTag(rows, compare[1]);
    out.arch = cmpArch(base, cand);
  }
  // Summary score: average of available kinds
  const parts = Object.values(out);
  const score = parts.length ? Number((parts.reduce((a,b)=>a + (b.score||0),0) / parts.length).toFixed(4)) : 0;
  const pass = parts.every(p => p.pass !== false);
  const result = { score, pass, ...out };
  process.stdout.write(JSON.stringify(result));
})();

