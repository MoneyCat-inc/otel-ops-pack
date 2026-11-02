#!/usr/bin/env node
/**
 * Evidence-repo raw run-report prune.
 * Age: filename/path stamp (YYYYMMDD or archived/YYYY/MM) → else git %ct.
 * NEVER use filesystem mtime (actions/checkout resets it).
 *
 * Git dating is ONE streamed `git log --name-only` pass over the prune root
 * (newest commit first, so the first time a path is listed is its last touch),
 * not one `git log -1 -- <file>` process per undated file. The per-file walk
 * is quadratic (undated files × history depth) and timed out the first
 * scheduled run (2026-10-01, run 36822679620: 30 min, nothing pruned, nothing
 * logged). A per-file `git log -1` survives only as a bounded fallback for a
 * path the pass did not list; more than GIT_LOG_FALLBACK_MAX of them fails
 * loud before anything is deleted.
 *
 * Env:
 *   REPO_ROOT            — evidence checkout root (required)
 *   RETAIN_DAYS          — default 90
 *   DRY_RUN              — default true
 *   MANIFEST_PATH        — output JSON path (default artifacts/evidence-prune-manifest.json)
 *   GIT_LOG_FALLBACK_MAX — per-file fallbacks tolerated before failing loud (default 100)
 */
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import readline from 'node:readline';
import { spawn, spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const REPO_ROOT = process.env.REPO_ROOT || process.cwd();
const RETAIN_DAYS = parseInt(process.env.RETAIN_DAYS || '90', 10);
const DRY_RUN = (process.env.DRY_RUN || 'true').toLowerCase() !== 'false';
const MANIFEST_PATH =
  process.env.MANIFEST_PATH ||
  path.join(process.env.GITHUB_WORKSPACE || REPO_ROOT, 'artifacts', 'evidence-prune-manifest.json');
const GIT_LOG_FALLBACK_MAX = parseInt(process.env.GIT_LOG_FALLBACK_MAX || '100', 10);

export const SCOPE_PREFIX = 'docs/BossCat/run-reports/';
export const PERMANENT = new Set([
  'docs/BossCat/run-reports/INDEX.jsonl',
  'docs/BossCat/run-reports/LATEST.md',
  'docs/BossCat/run-reports/.gitkeep',
  'docs/BossCat/run-reports/archived/.gitkeep',
]);

/** Marks a commit header line in the streamed log; a path can never start with it. */
const COMMIT_MARK = '\u0001';

export function posixRel(p) {
  return p.split(path.sep).join('/');
}

export function isPermanent(rel) {
  if (PERMANENT.has(rel)) {return true;}
  if (rel.includes('filter-repo/') || /commit-map/i.test(rel)) {return true;}
  return false;
}

/** @returns {{ date: Date, source: 'filename' } | null} */
export function ageFromFilename(rel) {
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

/**
 * Decode a path that git printed C-quoted (`"..."`: a control character,
 * double quote or backslash in the name). With core.quotePath=false, bytes
 * above 0x7f are printed raw, so this only sees ASCII escapes in practice.
 */
export function unquoteGitPath(line) {
  if (line.length < 2 || !line.startsWith('"') || !line.endsWith('"')) {return line;}
  const chars = Array.from(line.slice(1, -1));
  const bytes = [];
  const simple = { a: 7, b: 8, t: 9, n: 10, v: 11, f: 12, r: 13, '\\': 92, '"': 34 };
  for (let i = 0; i < chars.length; i++) {
    const ch = chars[i];
    if (ch !== '\\') {
      bytes.push(...Buffer.from(ch, 'utf8'));
      continue;
    }
    const next = chars[++i];
    if (next === undefined) {break;}
    if (next >= '0' && next <= '7') {
      let oct = next;
      while (oct.length < 3 && i + 1 < chars.length && chars[i + 1] >= '0' && chars[i + 1] <= '7') {
        oct += chars[++i];
      }
      bytes.push(parseInt(oct, 8));
    } else {
      bytes.push(simple[next] ?? next.charCodeAt(0));
    }
  }
  return Buffer.from(bytes).toString('utf8');
}

/**
 * Fold `git log --format=<COMMIT_MARK>%ct --name-only` lines (any sync or
 * async iterable: a readline stream, or an array in the tests) into `map`
 * (path → unix seconds of the newest commit that touched it).
 * @returns {Promise<{ commits: number, lines: number }>}
 */
export async function foldGitLogLines(lines, map) {
  let commits = 0;
  let count = 0;
  let current = null;
  for await (const line of lines) {
    count++;
    if (line.startsWith(COMMIT_MARK)) {
      const ts = parseInt(line.slice(1), 10);
      current = Number.isFinite(ts) && ts > 0 ? ts : null;
      commits++;
      continue;
    }
    if (line === '' || current === null) {continue;}
    const rel = line.startsWith('"') ? unquoteGitPath(line) : line;
    if (!map.has(rel)) {map.set(rel, current);}
  }
  return { commits, lines: count };
}

/**
 * One streamed pass: `git log` newest-first over `pathspec`, first listing of
 * each path wins. Throws (nothing is dated, nothing deleted) when git exits
 * non-zero or lists no commit at all.
 * @returns {Promise<{ map: Map<string, number>, commits: number, lines: number, ms: number }>}
 */
export async function buildGitDateMap({ cwd, pathspec = SCOPE_PREFIX.slice(0, -1) }) {
  const t0 = Date.now();
  const args = [
    '-c',
    'core.quotePath=false',
    'log',
    `--format=${COMMIT_MARK}%ct`,
    '--name-only',
    '--no-renames',
    '--',
    pathspec,
  ];
  const child = spawn('git', args, { cwd, stdio: ['ignore', 'pipe', 'pipe'] });
  const closed = new Promise((resolve, reject) => {
    child.on('error', reject);
    child.on('close', (code, signal) => resolve({ code, signal }));
  });
  let stderr = '';
  child.stderr.setEncoding('utf8');
  child.stderr.on('data', chunk => {
    stderr += chunk;
  });
  child.stdout.setEncoding('utf8');
  const rl = readline.createInterface({ input: child.stdout, crlfDelay: Infinity });
  const map = new Map();
  const { commits, lines } = await foldGitLogLines(rl, map);
  const { code, signal } = await closed;
  if (code !== 0) {
    throw new Error(
      `git log pass failed (exit ${code}${signal ? `, signal ${signal}` : ''}): ${stderr.trim()}`
    );
  }
  if (commits === 0) {
    throw new Error(`git log pass listed no commits under ${pathspec} — refusing to date files from an empty walk`);
  }
  return { map, commits, lines, ms: Date.now() - t0 };
}

/** Per-file fallback, the pre-2026-11 method: newest commit touching `rel`. */
export function ageFromGitLogSingle(rel, cwd = REPO_ROOT) {
  const r = spawnSync('git', ['log', '-1', '--format=%ct', '--', rel], { cwd, encoding: 'utf8' });
  if (r.status !== 0) {return null;}
  const ts = parseInt((r.stdout || '').trim(), 10);
  if (!Number.isFinite(ts) || ts <= 0) {return null;}
  return { date: new Date(ts * 1000), source: 'git-log' };
}

export function walkFiles(dir, acc = []) {
  if (!fs.existsSync(dir)) {return acc;}
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {walkFiles(full, acc);}
    else if (ent.isFile()) {acc.push(full);}
  }
  return acc;
}

function assertScoped(candidates) {
  const bad = candidates.filter(c => !c.path.startsWith(SCOPE_PREFIX));
  if (bad.length) {
    console.error('::error::Scope assertion failed — would-delete outside run-reports/:');
    for (const b of bad.slice(0, 20)) {console.error(`  ${b.path}`);}
    process.exit(2);
  }
}

async function main() {
  const t0 = Date.now();
  const now = Date.now();
  const cutoffMs = RETAIN_DAYS * 24 * 60 * 60 * 1000;
  const reportsAbs = path.join(REPO_ROOT, 'docs', 'BossCat', 'run-reports');

  if (!fs.existsSync(reportsAbs)) {
    console.error(`::error::Missing prune root: ${reportsAbs}`);
    process.exit(1);
  }

  const files = walkFiles(reportsAbs);
  const entries = files.map(abs => ({ abs, rel: posixRel(path.relative(REPO_ROOT, abs)) }));
  const needGit = entries.filter(e => !isPermanent(e.rel) && !ageFromFilename(e.rel)).length;
  console.log(`Scanned ${entries.length} files under ${SCOPE_PREFIX} (${needGit} need git dating)`);

  let gitMap = new Map();
  let gitLogMap = null;
  if (needGit > 0) {
    const pass = await buildGitDateMap({ cwd: REPO_ROOT });
    gitMap = pass.map;
    gitLogMap = { commits: pass.commits, paths: pass.map.size, lines: pass.lines, ms: pass.ms };
    console.log(
      `git log pass: ${pass.commits} commits, ${pass.map.size} paths, ${pass.lines} lines in ${pass.ms} ms`
    );
  }

  let fallbacks = 0;
  const deriveAge = rel => {
    const fromName = ageFromFilename(rel);
    if (fromName) {return fromName;}
    const ts = gitMap.get(rel);
    if (ts !== undefined) {return { date: new Date(ts * 1000), source: 'git-log' };}
    fallbacks++;
    if (fallbacks > GIT_LOG_FALLBACK_MAX) {
      console.error(
        `::error::${fallbacks} files were not listed by the git log pass (limit ${GIT_LOG_FALLBACK_MAX}) — the pass is not covering the tree; stopping before any deletion.`
      );
      process.exit(3);
    }
    console.warn(`::warning::${rel} not listed by the git log pass — per-file git log fallback`);
    return ageFromGitLogSingle(rel);
  };

  const wouldDelete = [];
  const kept = { permanent: 0, young: 0, no_age: 0 };
  const sourceCounts = { filename: 0, 'git-log': 0 };

  for (let i = 0; i < entries.length; i++) {
    if (i > 0 && i % 10000 === 0) {
      console.log(`progress: ${i}/${entries.length} files, ${((Date.now() - t0) / 1000).toFixed(1)} s`);
    }
    const { abs, rel } = entries[i];
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
      filename: wouldDelete.filter(x => x.date_source === 'filename').length,
      'git-log': wouldDelete.filter(x => x.date_source === 'git-log').length,
    },
    scanned_source_counts: sourceCounts,
    kept,
    git_log_pass: gitLogMap,
    git_log_fallbacks: fallbacks,
    elapsed_ms: Date.now() - t0,
    would_delete: wouldDelete,
  };

  await fsp.mkdir(path.dirname(MANIFEST_PATH), { recursive: true });
  await fsp.writeFile(MANIFEST_PATH, JSON.stringify(manifest, null, 2), 'utf8');
  console.log(`Manifest → ${MANIFEST_PATH}`);
  console.log(
    `Would delete: ${wouldDelete.length} files (${bytes} bytes); date_source filename=${manifest.date_source_breakdown.filename} git-log=${manifest.date_source_breakdown['git-log']}`
  );
  console.log(`Kept: permanent=${kept.permanent} young=${kept.young} no_age=${kept.no_age}`);
  console.log(`Elapsed: ${manifest.elapsed_ms} ms (git log fallbacks: ${fallbacks})`);

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

const invokedDirectly =
  process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href;

if (invokedDirectly) {
  main().catch(e => {
    console.error(e);
    process.exit(1);
  });
}
