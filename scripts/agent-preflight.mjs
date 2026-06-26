#!/usr/bin/env node
// BossCat ECRR preflight: kill-switch + workspace prep
import { existsSync, mkdirSync, readFileSync } from 'fs';
import { exit } from 'process';

const log = (msg) => console.log(`[preflight] ${msg}`);
const fail = (msg) => {
  console.error(`[preflight] FAIL: ${msg}`);
  exit(1);
};

try {
  // Kill-switch: .agent/LOCK (optional JSON with reason)
  if (existsSync('.agent/LOCK')) {
    let reason = '';
    try { reason = String(readFileSync('.agent/LOCK')).trim(); } catch {}
    fail(`Kill-switch engaged (.agent/LOCK). ${reason}`);
  }

  // Prepare required dirs (idempotent)
  ['artifacts', 'docs', 'docs/ecrr', 'CHAR/ECRR/ECRR_REPORTS', 'docs/observability', 'docs/observability/snapshots', '.agent', '.agent/tmp']
    .forEach((d) => { try { mkdirSync(d, { recursive: true }); } catch {} });

  // CI scope note (hook for future lane validations)
  const site = process.env.SITE || 'ci';
  const gate = process.env.GATE || 'IONA';
  log(`Scope: site=${site} gate=${gate}`);

  log('OK');
  exit(0);
} catch (err) {
  fail(err?.message || String(err));
}


