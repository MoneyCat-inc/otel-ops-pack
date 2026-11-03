#!/usr/bin/env node
/**
 * Evidence-repo raw run-report prune.
 * Age: filename/path stamp (YYYYMMDD or archived/YYYY/MM), else the newest
 * commit that touched the path (git %ct). NEVER filesystem mtime
 * (actions/checkout resets it).
 *
 * Git dating is ONE streamed `git log --name-only` pass over the prune root
 * (newest commit first, so the first time a path is listed is its last
 * touch), not one `git log -1 -- <file>` process per undated file. The
 * per-file walk costs undated files x history depth and timed out the first
 * scheduled run (2026-10-01, run 36822679620: 30 min, nothing pruned,
 * nothing logged).
 *
 * The pass equals the per-file `git log -1 -- <path>` exactly on a complete,
 * linear history. A merge commit can make the two disagree in either
 * direction (git log lists no files for a merge by default, and history
 * simplification depends on the pathspec), and a shallow clone dates
 * everything at its boundary, so the script refuses both before anything is
 * dated or deleted. A path the pass did not list falls back to the per-file
 * call; more than GIT_LOG_FALLBACK_MAX fallbacks stop the run before any
 * deletion.
 *
 * Env:
 *   REPO_ROOT            evidence checkout root (default: cwd)
 *   RETAIN_DAYS          integer >= 1 (default 90); a live run needs >= 90,
 *                        the policy value (BRIEFING_EVIDENCE_RETENTION.md)
 *   DRY_RUN              anything but "false" is a dry run (default true)
 *   MANIFEST_PATH        output JSON (default artifacts/evidence-prune-manifest.json)
 *   GIT_LOG_FALLBACK_MAX integer >= 0 (default 100)
 *
 * Exit: 0 done; 1 bad input, missing prune root, or a git/history refusal;
 * 2 scope assertion; 3 more per-file fallbacks than GIT_LOG_FALLBACK_MAX.
 */
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import readline from 'node:readline';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export const SCOPE_PREFIX = 'docs/BossCat/run-reports/';
export const PERMANENT = new Set([
  'docs/BossCat/run-reports/INDEX.jsonl',
  'docs/BossCat/run-reports/LATEST.md',
  'docs/BossCat/run-reports/.gitkeep',
  'docs/BossCat/run-reports/archived/.gitkeep',
]);

/** Starts each commit header in the streamed log (git prints it for %x01). */
const COMMIT_MARK = '\u0001';
const DAY_MS = 24 * 60 * 60 * 1000;
/** Raw run reports are kept 90 days (BRIEFING_EVIDENCE_RETENTION.md); a live run never keeps fewer. */
const POLICY_RETAIN_DAYS = 90;

/** Bad input or a refusal: reported as one ::error:: line, exit 1. */
export class PruneError extends Error {}

export function posixRel(p) {
  return p.split(path.sep).join('/');
}

export function isPermanent(rel) {
  if (PERMANENT.has(rel)) {
    return true;
  }
  return rel.includes('filter-repo/') || /commit-map/i.test(rel);
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
  if (line.length < 2 || !line.startsWith('"') || !line.endsWith('"')) {
    return line;
  }
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
    if (next === undefined) {
      break;
    }
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

/** Run git and return its trimmed stdout; PruneError when it cannot run or fails. */
function gitText(cwd, args) {
  const r = spawnSync('git', args, { cwd, encoding: 'utf8' });
  if (r.error || r.status !== 0) {
    const why = r.error ? r.error.message : (r.stderr || '').trim() || `exit ${r.status}`;
    throw new PruneError(`git ${args.join(' ')} failed: ${why}`);
  }
  return r.stdout.trim();
}

/**
 * Refuse a history on which the single pass is not exactly the per-file
 * `git log -1 -- <path>`: a shallow clone, or any merge commit (counted over
 * the whole history, because a pathspec-limited walk can skip a merge).
 * @returns {{ merge_commits: 0, shallow: false }}
 */
export function assertLinearCompleteHistory(cwd) {
  const shallow = gitText(cwd, ['rev-parse', '--is-shallow-repository']);
  if (shallow !== 'false') {
    throw new PruneError(
      `refusing to date from a shallow clone (git rev-parse --is-shallow-repository: ${shallow}); check out with fetch-depth: 0`
    );
  }
  const merges = Number(gitText(cwd, ['rev-list', '--merges', '--count', 'HEAD']));
  if (merges !== 0) {
    throw new PruneError(
      `refusing to date: the history has ${merges} merge commit(s), and the single git log pass equals the per-file git log -1 only on linear history`
    );
  }
  return { merge_commits: 0, shallow: false };
}

/**
 * Fold `git log --format=%x01%ct --name-only` lines (any sync or async
 * iterable: a readline stream, or an array in the tests) into `map`: path ->
 * unix seconds of the newest commit that listed it, or null when that
 * commit's timestamp is unusable (the path then stays undated and is kept,
 * as the per-file method kept it, instead of taking an older commit's date).
 * @returns {Promise<{ commits: number, lines: number }>}
 */
export async function foldGitLogLines(lines, map) {
  let commits = 0;
  let count = 0;
  let current;
  for await (const line of lines) {
    count++;
    if (line.startsWith(COMMIT_MARK)) {
      const ts = Number(line.slice(1));
      current = Number.isInteger(ts) && ts > 0 ? ts : null;
      commits++;
      continue;
    }
    if (line === '' || current === undefined) {
      continue;
    }
    const rel = line.startsWith('"') ? unquoteGitPath(line) : line;
    if (!map.has(rel)) {
      map.set(rel, current);
    }
  }
  return { commits, lines: count };
}

/**
 * One streamed pass: `git log` newest-first over `pathspec`, the first listing
 * of each path wins. Refuses a shallow or non-linear history first, and throws
 * when git cannot start, exits non-zero, or lists no commit, all before any
 * file is dated. Streamed, not spawnSync: the output is several MiB, past
 * spawnSync's default 1 MiB maxBuffer.
 * @returns {Promise<{ map: Map<string, number | null>, commits: number, lines: number, ms: number, merge_commits: 0, shallow: false }>}
 */
export async function buildGitDateMap({ cwd, pathspec = SCOPE_PREFIX.slice(0, -1) }) {
  const t0 = Date.now();
  const history = assertLinearCompleteHistory(cwd);
  const args = [
    '-c',
    'core.quotePath=false',
    '--literal-pathspecs',
    'log',
    '--format=%x01%ct',
    '--name-only',
    '--no-renames',
    '--',
    pathspec,
  ];
  const child = spawn('git', args, { cwd, stdio: ['ignore', 'pipe', 'pipe'] });
  // Resolve, never reject: a spawn error must not surface as an unhandled
  // rejection while the output is still being read.
  const closed = new Promise(resolve => {
    child.once('error', error => resolve({ error }));
    child.once('close', (code, signal) => resolve({ code, signal }));
  });
  let stderr = '';
  child.stderr.setEncoding('utf8');
  child.stderr.on('data', chunk => {
    stderr += chunk;
  });
  child.stdout.setEncoding('utf8');
  const rl = readline.createInterface({ input: child.stdout, crlfDelay: Infinity });
  const map = new Map();
  let stats;
  try {
    stats = await foldGitLogLines(rl, map);
  } catch (e) {
    child.kill();
    throw e;
  } finally {
    rl.close();
  }
  const { error, code, signal } = await closed;
  if (error) {
    throw new PruneError(`git log pass could not start: ${error.message}`);
  }
  if (code !== 0) {
    throw new PruneError(
      `git log pass failed (exit ${code}${signal ? `, signal ${signal}` : ''}): ${stderr.trim()}`
    );
  }
  if (stats.commits === 0) {
    throw new PruneError(
      `git log pass listed no commits under ${pathspec}; refusing to date files from an empty walk`
    );
  }
  return { map, commits: stats.commits, lines: stats.lines, ms: Date.now() - t0, ...history };
}

/** Per-file fallback (the pre-2026-11 method, literal pathspec): newest commit touching `rel`. */
export function ageFromGitLogSingle(rel, cwd) {
  const r = spawnSync('git', ['--literal-pathspecs', 'log', '-1', '--format=%ct', '--', rel], {
    cwd,
    encoding: 'utf8',
  });
  if (r.error || r.status !== 0) {
    return null;
  }
  const ts = Number((r.stdout || '').trim());
  if (!Number.isInteger(ts) || ts <= 0) {
    return null;
  }
  return { date: new Date(ts * 1000), source: 'git-log' };
}

export function walkFiles(dir, acc = []) {
  if (!fs.existsSync(dir)) {
    return acc;
  }
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      walkFiles(full, acc);
    } else if (ent.isFile()) {
      acc.push(full);
    }
  }
  return acc;
}

function intSetting(env, name, fallback, min) {
  const raw = env[name];
  const text = raw === undefined || raw.trim() === '' ? String(fallback) : raw.trim();
  if (!/^\d+$/.test(text) || Number(text) < min) {
    throw new PruneError(`${name} must be an integer >= ${min}, got ${JSON.stringify(raw)}`);
  }
  return Number(text);
}

function readConfig(env) {
  const repoRoot = env.REPO_ROOT || process.cwd();
  const cfg = {
    repoRoot,
    retainDays: intSetting(env, 'RETAIN_DAYS', 90, 1),
    fallbackMax: intSetting(env, 'GIT_LOG_FALLBACK_MAX', 100, 0),
    dryRun: (env.DRY_RUN || 'true').toLowerCase() !== 'false',
    manifestPath:
      env.MANIFEST_PATH ||
      path.join(env.GITHUB_WORKSPACE || repoRoot, 'artifacts', 'evidence-prune-manifest.json'),
  };
  if (!cfg.dryRun && cfg.retainDays < POLICY_RETAIN_DAYS) {
    throw new PruneError(
      `a live prune keeps at least ${POLICY_RETAIN_DAYS} days of reports (retention policy); RETAIN_DAYS=${cfg.retainDays} is allowed only with DRY_RUN=true`
    );
  }
  return cfg;
}

function assertScoped(candidates) {
  const bad = candidates.filter(c => !c.path.startsWith(SCOPE_PREFIX));
  if (bad.length) {
    console.error('::error::Scope assertion failed — would-delete outside run-reports/:');
    for (const b of bad.slice(0, 20)) {
      console.error(`  ${b.path}`);
    }
    process.exit(2);
  }
}

async function main() {
  const t0 = Date.now();
  const cfg = readConfig(process.env);
  const now = Date.now();
  const reportsAbs = path.join(cfg.repoRoot, 'docs', 'BossCat', 'run-reports');
  if (!fs.existsSync(reportsAbs)) {
    throw new PruneError(`Missing prune root: ${reportsAbs}`);
  }

  const entries = walkFiles(reportsAbs).map(abs => ({
    abs,
    rel: posixRel(path.relative(cfg.repoRoot, abs)),
  }));
  const needGit = entries.filter(e => !isPermanent(e.rel) && !ageFromFilename(e.rel)).length;
  console.log(`Scanned ${entries.length} files under ${SCOPE_PREFIX} (${needGit} need git dating)`);

  let gitMap = new Map();
  let gitLogPass = null;
  if (needGit > 0) {
    const pass = await buildGitDateMap({ cwd: cfg.repoRoot });
    gitMap = pass.map;
    gitLogPass = {
      commits: pass.commits,
      paths: pass.map.size,
      lines: pass.lines,
      ms: pass.ms,
      merge_commits: pass.merge_commits,
      shallow: pass.shallow,
    };
    console.log(
      `git log pass: ${pass.commits} commits, ${pass.map.size} paths, ${pass.lines} lines in ${pass.ms} ms; history linear, not shallow`
    );
  }

  let fallbacks = 0;
  const deriveAge = rel => {
    const fromName = ageFromFilename(rel);
    if (fromName) {
      return fromName;
    }
    const ts = gitMap.get(rel);
    if (ts === null) {
      return null;
    }
    if (ts !== undefined) {
      return { date: new Date(ts * 1000), source: 'git-log' };
    }
    fallbacks++;
    if (fallbacks > cfg.fallbackMax) {
      console.error(
        `::error::${fallbacks} files were not listed by the git log pass (limit GIT_LOG_FALLBACK_MAX=${cfg.fallbackMax}); the pass is not covering the tree, stopping before any deletion.`
      );
      process.exit(3);
    }
    console.warn(`::warning::${rel} not listed by the git log pass; per-file git log fallback`);
    const single = ageFromGitLogSingle(rel, cfg.repoRoot);
    return single && { ...single, fallback: true };
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
    const ageDays = (now - age.date.getTime()) / DAY_MS;
    if (ageDays > cfg.retainDays) {
      wouldDelete.push({
        path: rel,
        derived_date: age.date.toISOString().slice(0, 10),
        date_source: age.source,
        ...(age.fallback ? { git_log_fallback: true } : {}),
        age_days: Math.floor(ageDays),
        bytes: fs.statSync(abs).size,
      });
    } else {
      kept.young++;
    }
  }

  assertScoped(wouldDelete);

  const bytes = wouldDelete.reduce((s, x) => s + x.bytes, 0);
  const manifest = {
    timestamp: new Date().toISOString(),
    repo_root: cfg.repoRoot,
    retain_days: cfg.retainDays,
    dry_run: cfg.dryRun,
    cutoff_ms_ago: cfg.retainDays * DAY_MS,
    would_delete_count: wouldDelete.length,
    would_delete_bytes: bytes,
    date_source_breakdown: {
      filename: wouldDelete.filter(x => x.date_source === 'filename').length,
      'git-log': wouldDelete.filter(x => x.date_source === 'git-log').length,
    },
    scanned_source_counts: sourceCounts,
    kept,
    git_log_pass: gitLogPass,
    git_log_fallbacks: fallbacks,
    elapsed_ms: Date.now() - t0,
    would_delete: wouldDelete,
  };

  await fsp.mkdir(path.dirname(cfg.manifestPath), { recursive: true });
  await fsp.writeFile(cfg.manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
  console.log(`Manifest → ${cfg.manifestPath}`);
  console.log(
    `Would delete: ${wouldDelete.length} files (${bytes} bytes); date_source filename=${manifest.date_source_breakdown.filename} git-log=${manifest.date_source_breakdown['git-log']}`
  );
  console.log(`Kept: permanent=${kept.permanent} young=${kept.young} no_age=${kept.no_age}`);
  console.log(`Elapsed: ${manifest.elapsed_ms} ms (git log fallbacks: ${fallbacks})`);

  if (cfg.dryRun) {
    console.log('DRY_RUN=true — no deletions.');
    return;
  }

  let deleted = 0;
  let deletedBytes = 0;
  for (const row of wouldDelete) {
    await fsp.unlink(path.join(cfg.repoRoot, ...row.path.split('/')));
    deleted++;
    deletedBytes += row.bytes;
  }
  console.log(`Deleted: ${deleted} files (${deletedBytes} bytes)`);
  manifest.deleted_count = deleted;
  manifest.deleted_bytes = deletedBytes;
  await fsp.writeFile(cfg.manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
}

const SELF = fileURLToPath(import.meta.url);

/** True when Node runs this file as its entry script, also through a junction or symlink. */
function invokedAsScript() {
  const entry = process.argv[1];
  if (!entry) {
    return false;
  }
  const canonical = p => {
    const real = fs.realpathSync.native(p);
    return process.platform === 'win32' ? real.toLowerCase() : real;
  };
  try {
    return canonical(entry) === canonical(SELF);
  } catch {
    return path.resolve(entry) === SELF;
  }
}

if (invokedAsScript()) {
  main().catch(e => {
    console.error(e instanceof PruneError ? `::error::${e.message}` : e);
    process.exit(1);
  });
}
