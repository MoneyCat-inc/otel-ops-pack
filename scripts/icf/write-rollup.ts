#!/usr/bin/env -S node --enable-source-maps
/**
 * ICF Rollup Writer (CSP-safe feeder)
 * Produces a tiny 24h rolling metric JSON consumed by the status panel.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

type GateLoc = { added: number; deleted: number; total: number };

function readJson<T>(path: string): T | null {
  try {
    return JSON.parse(readFileSync(path, 'utf8')) as T;
  } catch {
    return null;
  }
}

function main() {
  // Inputs (best-effort): gate/loc.json and DELT/ARTF/gate-verification-results.json
  const loc = readJson<GateLoc>('gate/loc.json');
  const gate = readJson<any>('DELT/ARTF/gate-verification-results.json');

  const totalChanges = loc?.total ?? 0;
  const totalTests = gate?.tests?.total ?? 0;
  const failedTests = gate?.tests?.failed ?? 0;

  const errorRate = totalTests > 0 ? failedTests / totalTests : 0;
  const chaosEvents = 0; // placeholder; real chaos events can be wired later

  const out = {
    timestamp: new Date().toISOString(),
    horizon: '24h',
    throughput: totalChanges, // proxy per run
    errorRate,
    chaosEvents
  };

  const outDir = join('artifacts', 'icf');
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });
  writeFileSync(join(outDir, 'rollup.json'), JSON.stringify(out, null, 2), 'utf8');
  // Mirror under DELT/ARTF for CI artifact collection if desired
  const altDir = join('DELT', 'ARTF', 'icf');
  try {
    if (!existsSync(altDir)) mkdirSync(altDir, { recursive: true });
    writeFileSync(join(altDir, 'rollup.json'), JSON.stringify(out, null, 2), 'utf8');
  } catch {}
  console.log('[ICF] rollup written:', out);
}

main();

