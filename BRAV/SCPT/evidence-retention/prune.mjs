#!/usr/bin/env node
/**
 * Evidence-repo raw run-report prune.
 * Age: filename/path stamp (YYYYMMDD or archived/YYYY/MM) → else git %ct.
 * NEVER use filesystem mtime (actions/checkout resets it).
 *
 * Env:
 *   REPO_ROOT     — evidence checkout root (required)
 *   RETAIN_DAYS   — default 90
 *   DRY_RUN       — default true
 *   MANIFEST_PATH — output JSON path (default artifacts/evidence-prune-manifest.json)
 */
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const REPO_ROOT = process.env.REPO_ROOT || process.cwd();
const RETAIN_DAYS = parseInt(process.env.RETAIN_DAYS || '90', 10);
const DRY_RUN = (process.env.DRY_RUN || 'true').toLowerCase() !== 'false';
const MANIFEST_PATH =
  process.env.MANIFEST_PATH ||
  path.join(process.env.GITHUB_WORKSPACE || REPO_ROOT, 'artifacts', 'evidence-prune-manifest.json');

const SCOPE_PREFIX = 'docs/BossCat/run-reports/';
const PERMANENT = new Set([
  'docs/BossCat/run-reports/INDEX.jsonl',
  'docs/BossCat/run-reports/LATEST.md',
  'docs/BossCat/run-reports/.gitkeep',
  'docs/BossCat/run-reports/archived/.gitkeep',
]);

function posixRel(p) {
  return p.split(path.sep).join('/');
}

function isPermanent(rel) {
  if (PERMANENT.has(rel)) return true;
  if (rel.includes('filter-repo/') || /commit-map/i.test(rel)) return true;
  return false;
}

/** @returns {{ date: Date, source: 'filename' } | null} */
function ageFromFilename(rel) {
  const base = path.posix.basename(rel);
  const m8 = base.match(/(?<!\d)(\d{8})(?!\d)/);
  if (m8) {
    const s = m8[1];
    const y = +s.slice(0, 4);
    const mo = +s.slice(4, 6);
    const d = +s.slice(6, 8);
    if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
      return { date: new Date(Date.UTC(y, mo - 1, d)), source: 'filename' };
    }
  }
  const mPath = rel.match(/archived\/(\d{4})\/(\d{2})\//);
  if (mPath) {
    const y = +mPath[1];
    const mo = +mPath[2];
    if (mo >= 1 && mo <= 12) {
      return { date: new Date(Date.UTC(y, mo - 1, 1)), source: 'filename' };
    }
  }
  return null;
}

/** @returns {{ date: Date, source: 'git-log' } | null} */
function ageFromGitLog(rel) {
  const r = spawnSync(
    'git',
    ['log', '-1', '--format=%ct', '--', rel],
    { cwd: REPO_ROOT, encoding: 'utf8' }
  );
  if (r.status !== 0) return null;
  const ts = parseInt((r.stdout || '').trim(), 10);
  if (!Number.isFinite(ts) || ts <= 0) return null;
  return { date: new Date(ts * 1000), source: 'git-log' };
}

function deriveAge(rel) {
  return ageFromFilename(rel) || ageFromGitLog(rel);
}

function walkFiles(dir, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) walkFiles(full, acc);
    else if (ent.isFile()) acc.push(full);
  }
  return acc;
}

function assertScoped(candidates) {
  const bad = candidates.filter((c) => !c.path.startsWith(SCOPE_PREFIX));
  if (bad.length) {
    console.error('::error::Scope assertion failed — would-delete outside run-reports/:');
    for (const b of bad.slice(0, 20)) console.error(`  ${b.path}`);
    process.exit(2);
  }
}

async function main() {
  const now = Date.now();
  const cutoffMs = RETAIN_DAYS * 24 * 60 * 60 * 1000;
  const reportsAbs = path.join(REPO_ROOT, 'docs', 'BossCat', 'run-reports');

  if (!fs.existsSync(reportsAbs)) {
    console.error(`::error::Missing prune root: ${reportsAbs}`);
    process.exit(1);
  }

  const files = walkFiles(reportsAbs);
  const wouldDelete = [];
  const kept = { permanent: 0, young: 0, no_age: 0 };
  const sourceCounts = { filename: 0, 'git-log': 0 };

  for (const abs of files) {
    const rel = posixRel(path.relative(REPO_ROOT, abs));
    if (isPermanent(rel)) {
      kept.permanent++;
      continue;
    }
    const age = deriveAge(rel);
    if (!age) {
      kept.no_age++;
      console.warn(`::warning::No age for ${rel} — keeping`);
      continue;
    }
    sourceCounts[age.source]++;
    const ageDays = (now - age.date.getTime()) / (24 * 60 * 60 * 1000);
    if (ageDays > RETAIN_DAYS) {
      const st = fs.statSync(abs);
      wouldDelete.push({
        path: rel,
        derived_date: age.date.toISOString().slice(0, 10),
        date_source: age.source,
        age_days: Math.floor(ageDays),
        bytes: st.size,
      });
    } else {
      kept.young++;
    }
  }

  assertScoped(wouldDelete);

  const bytes = wouldDelete.reduce((s, x) => s + x.bytes, 0);
  const manifest = {
    timestamp: new Date().toISOString(),
    repo_root: REPO_ROOT,
    retain_days: RETAIN_DAYS,
    dry_run: DRY_RUN,
    cutoff_ms_ago: cutoffMs,
    would_delete_count: wouldDelete.length,
    would_delete_bytes: bytes,
    date_source_breakdown: {
      filename: wouldDelete.filter((x) => x.date_source === 'filename').length,
      'git-log': wouldDelete.filter((x) => x.date_source === 'git-log').length,
    },
    scanned_source_counts: sourceCounts,
    kept,
    would_delete: wouldDelete,
  };

  await fsp.mkdir(path.dirname(MANIFEST_PATH), { recursive: true });
  await fsp.writeFile(MANIFEST_PATH, JSON.stringify(manifest, null, 2), 'utf8');
  console.log(`Manifest → ${MANIFEST_PATH}`);
  console.log(
    `Would delete: ${wouldDelete.length} files (${bytes} bytes); date_source filename=${manifest.date_source_breakdown.filename} git-log=${manifest.date_source_breakdown['git-log']}`
  );
  console.log(`Kept: permanent=${kept.permanent} young=${kept.young} no_age=${kept.no_age}`);

  if (DRY_RUN) {
    console.log('DRY_RUN=true — no deletions.');
    return;
  }

  let deleted = 0;
  let deletedBytes = 0;
  for (const row of wouldDelete) {
    const abs = path.join(REPO_ROOT, ...row.path.split('/'));
    await fsp.unlink(abs);
    deleted++;
    deletedBytes += row.bytes;
  }
  console.log(`Deleted: ${deleted} files (${deletedBytes} bytes)`);
  manifest.deleted_count = deleted;
  manifest.deleted_bytes = deletedBytes;
  await fsp.writeFile(MANIFEST_PATH, JSON.stringify(manifest, null, 2), 'utf8');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
