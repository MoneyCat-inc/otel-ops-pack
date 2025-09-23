#!/usr/bin/env node
/* Validates ECRR reports in docs/ECRR_REPORTS.
 * Requirements:
 *  - Front matter block at file top: --- ... ---
 *  - Required fields: ecrr_key, timestamp_utc, branch, commit, scope, outcome
 *  - ecrr_key: ECRR-YYYYMMDD-HHMMSS(-SLUG)?
 *  - timestamp_utc: ISO 8601 ending with Z
 *  - commit: 7-40 hex
 *  - outcome: success|partial|fail
 *  - filename starts with ecrr_key
 *  - no duplicate keys across files
 */
const fs = require('fs');
const path = require('path');

const DIR = path.join(process.cwd(), 'docs', 'ECRR_REPORTS');
const REQ = ['ecrr_key','timestamp_utc','branch','commit','scope','outcome'];
const KEY_RE = /^ECRR-\d{8}-\d{6}(?:-[A-Z0-9-]+)?$/;
const FILE_RE = /^ECRR-\d{8}-\d{6}(?:-[A-Z0-9-]+)?\.md$/;
const SHA_RE = /^[0-9a-f]{7,40}$/i;
const OUTCOME = new Set(['success','partial','fail']);

function readFrontMatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!m) return null;
  const fm = {};
  for (const line of m[1].split(/\r?\n/)) {
    const mm = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!mm) continue;
    const k = mm[1].trim();
    // naive scalar parse (quotes stripped); nested values optional & ignored
    const v = mm[2].trim().replace(/^"(.*)"$/,'$1').replace(/^'(.*)'$/,'$1');
    fm[k] = v;
  }
  return fm;
}
function isIsoZ(s){ return /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(s); }

const errors = [];
const keys = new Map();

if (!fs.existsSync(DIR)) {
  console.error(`Missing directory: ${DIR}`);
  process.exit(1);
}
const files = fs.readdirSync(DIR).filter(f => FILE_RE.test(f));
for (const f of files) {
  const p = path.join(DIR, f);
  const raw = fs.readFileSync(p, 'utf8');
  const fm = readFrontMatter(raw);
  if (!fm) { errors.push(`❌ ${f}: Missing YAML front matter (--- ... --- at top)`); continue; }

  // required fields present
  for (const k of REQ) {
    if (!(k in fm) || !String(fm[k]).trim()) {
      errors.push(`❌ ${f}: Missing required field '${k}' in front matter`);
    }
  }
  const k = fm.ecrr_key;
  if (k && !KEY_RE.test(k)) {
    errors.push(`❌ ${f}: ecrr_key '${k}' must match ${KEY_RE}`);
  }
  if (fm.timestamp_utc && !isIsoZ(fm.timestamp_utc)) {
    errors.push(`❌ ${f}: timestamp_utc '${fm.timestamp_utc}' must be ISO 8601 and end with 'Z'`);
  }
  if (fm.commit && !SHA_RE.test(fm.commit)) {
    errors.push(`❌ ${f}: commit '${fm.commit}' must be a 7–40 char hex SHA`);
  }
  if (fm.outcome && !OUTCOME.has(String(fm.outcome))) {
    errors.push(`❌ ${f}: outcome '${fm.outcome}' must be one of ${[...OUTCOME].join(', ')}`);
  }
  if (k && !f.startsWith(k)) {
    errors.push(`❌ ${f}: filename must start with ecrr_key ('${k}')`);
  }
  if (k) {
    if (keys.has(k)) {
      errors.push(`❌ Duplicate ecrr_key '${k}' in: ${keys.get(k)} and ${f}`);
    } else {
      keys.set(k, f);
    }
  }
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
} else {
  console.info(`✅ ECRR validation passed for ${files.length} report(s).`);
}
