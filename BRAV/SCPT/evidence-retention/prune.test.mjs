// Run: node --test BRAV/SCPT/evidence-retention/prune.test.mjs
// Unit: the age rules, git C-quoting, the fold, and the streamed git log pass
// against the per-file `git log -1 --format=%ct -- <path>` reference.
// End to end: the script on scratch evidence repos (dry run, live deletion,
// the merge-commit and shallow-clone refusals, the fallback cap, bad input,
// and an entry path that goes through a junction or symlink).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import {
  ageFromFilename,
  ageFromGitLogSingle,
  buildGitDateMap,
  foldGitLogLines,
  SCOPE_PREFIX,
  unquoteGitPath,
} from './prune.mjs';

const MARK = '\u0001';
const R = SCOPE_PREFIX;
const SCRIPT = fileURLToPath(new URL('./prune.mjs', import.meta.url));
const DAY = 24 * 60 * 60;
const NOW = Math.floor(Date.now() / 1000);

// Hermetic git for this process and every git or node child it starts: no
// system or global config, no repository or identity variables inherited.
for (const key of Object.keys(process.env)) {
  if (key.startsWith('GIT_') && key !== 'GIT_EXEC_PATH') {
    delete process.env[key];
  }
}
const CONFIG_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'prune-test-cfg-'));
process.on('exit', () => fs.rmSync(CONFIG_DIR, { recursive: true, force: true }));
process.env.GIT_CONFIG_GLOBAL = path.join(CONFIG_DIR, 'gitconfig');
fs.writeFileSync(process.env.GIT_CONFIG_GLOBAL, '');
process.env.GIT_CONFIG_NOSYSTEM = '1';

function git(cwd, args, env = {}) {
  return execFileSync('git', args, { cwd, encoding: 'utf8', env: { ...process.env, ...env } }).trim();
}

function at(unixSeconds) {
  const date = `${unixSeconds} +0000`;
  return { GIT_AUTHOR_DATE: date, GIT_COMMITTER_DATE: date };
}

function commitAll(cwd, message, unixSeconds) {
  git(cwd, ['add', '-A']);
  git(cwd, ['commit', '-q', '--allow-empty', '-m', message], at(unixSeconds));
}

function tempDir(t, prefix) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return dir;
}

function scratchRepo(t) {
  const dir = tempDir(t, 'prune-test-');
  git(dir, ['init', '-q', '-b', 'main']);
  git(dir, ['config', 'user.name', 'prune-test']);
  git(dir, ['config', 'user.email', 'prune-test@example.invalid']);
  git(dir, ['config', 'core.autocrlf', 'false']);
  return dir;
}

function put(dir, rel, text) {
  const abs = path.join(dir, ...rel.split('/'));
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, text);
}

function exists(dir, rel) {
  return fs.existsSync(path.join(dir, ...rel.split('/')));
}

function deletedFiles(repo) {
  return git(repo, ['ls-files', '--deleted']).split('\n').filter(Boolean).sort();
}

/** A small evidence repo: an old and a new undated badge, a month-dated archive, two permanent files. */
function evidenceRepo(t) {
  const dir = scratchRepo(t);
  put(dir, `${R}INDEX.jsonl`, '{}\n');
  put(dir, `${R}LATEST.md`, 'latest\n');
  put(dir, `${R}badges/run-old.svg`, 'old\n');
  put(dir, `${R}archived/2020/01/run-1.md`, 'archived\n');
  commitAll(dir, 'old reports', NOW - 200 * DAY);
  put(dir, `${R}badges/run-new.svg`, 'new\n');
  commitAll(dir, 'new report', NOW - 10 * DAY);
  return dir;
}

function addMerge(repo) {
  git(repo, ['checkout', '-q', '-b', 'side']);
  put(repo, `${R}badges/run-side.svg`, 'side\n');
  commitAll(repo, 'side report', NOW - 5 * DAY);
  git(repo, ['checkout', '-q', 'main']);
  git(repo, ['merge', '-q', '--no-ff', '-m', 'merge side', 'side'], {
    ...at(NOW - 4 * DAY),
    GIT_MERGE_AUTOEDIT: 'no',
  });
}

function runPrune(t, repo, env = {}, script = SCRIPT) {
  const manifestPath = path.join(tempDir(t, 'prune-out-'), 'manifest.json');
  const r = spawnSync(process.execPath, [script], {
    encoding: 'utf8',
    env: {
      ...process.env,
      REPO_ROOT: repo,
      RETAIN_DAYS: '90',
      DRY_RUN: 'true',
      MANIFEST_PATH: manifestPath,
      ...env,
    },
  });
  const manifest = fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, 'utf8')) : null;
  return { status: r.status, stdout: r.stdout, stderr: r.stderr, manifest };
}

test('ageFromFilename: YYYYMMDD basename, archived/YYYY/MM path, else null', () => {
  assert.deepEqual(ageFromFilename(`${R}run-20260815-x.md`), {
    date: new Date(Date.UTC(2026, 7, 15)),
    source: 'filename',
  });
  assert.deepEqual(ageFromFilename(`${R}archived/2026/06/run-27413707649.md`), {
    date: new Date(Date.UTC(2026, 5, 1)),
    source: 'filename',
  });
  assert.equal(ageFromFilename(`${R}badges/run-17813577604.svg`), null);
  assert.equal(ageFromFilename(`${R}x-20261399.md`), null);
});

test('unquoteGitPath decodes C-quoted names and passes others through', () => {
  assert.equal(unquoteGitPath('plain/path.svg'), 'plain/path.svg');
  assert.equal(unquoteGitPath('"a\\"b.md"'), 'a"b.md');
  assert.equal(unquoteGitPath('"tab\\there"'), 'tab\there');
  assert.equal(unquoteGitPath('"\\303\\251.svg"'), 'é.svg');
  assert.equal(unquoteGitPath('"back\\\\slash"'), 'back\\slash');
});

test('foldGitLogLines keeps the first (newest) listing of each path', async () => {
  const map = new Map();
  const lines = [
    `${MARK}300`,
    '',
    'a.md',
    'b.md',
    '',
    `${MARK}200`,
    '',
    'b.md',
    '"q\\"uote.md"',
    `${MARK}100`,
    '',
    'a.md',
    'c.md',
  ];
  const stats = await foldGitLogLines(lines, map);
  assert.deepEqual(stats, { commits: 3, lines: lines.length });
  assert.deepEqual(
    [...map.entries()],
    [
      ['a.md', 300],
      ['b.md', 300],
      ['q"uote.md', 200],
      ['c.md', 100],
    ]
  );
});

test('foldGitLogLines leaves a path undated when its newest commit has no usable timestamp', async () => {
  const map = new Map();
  await foldGitLogLines([`${MARK}0`, '', 'x.md', `${MARK}100`, '', 'x.md', 'y.md'], map);
  assert.equal(map.get('x.md'), null, 'not dated by the older commit');
  assert.equal(map.get('y.md'), 100);
});

test('buildGitDateMap matches the per-file reference on a linear history', async t => {
  const dir = scratchRepo(t);
  put(dir, `${R}badges/run-1.svg`, 'one');
  put(dir, `${R}badges/run-2.svg`, 'two');
  put(dir, 'elsewhere/outside.md', 'not in scope');
  commitAll(dir, 'add two badges and an outside file', 1_700_000_000);
  put(dir, `${R}badges/run-2.svg`, 'two, edited');
  put(dir, `${R}LATEST.md`, 'latest');
  commitAll(dir, 'edit run-2, add LATEST', 1_700_100_000);
  git(dir, ['mv', `${R}badges/run-1.svg`, `${R}badges/run-1-renamed.svg`]);
  commitAll(dir, 'rename run-1', 1_700_200_000);
  put(dir, `${R}badges/run-1-renamed.svg`, 'renamed and edited');
  // A double quote makes git C-quote the path (Windows cannot create one).
  // In a non-literal pathspec the brackets are a glob that matches the twin
  // ('[2]' -> '2'), committed later: the odd name must not take its date.
  const oddName = process.platform === 'win32' ? 'run sp [2].svg' : 'run sp "q" [2].svg';
  const twinName = oddName.replace('[2]', '2');
  put(dir, `${R}badges/${oddName}`, 'odd name');
  commitAll(dir, 'edit renamed, add odd name', 1_700_300_000);
  put(dir, `${R}badges/${twinName}`, 'glob twin');
  commitAll(dir, 'add the glob twin', 1_700_400_000);

  const pass = await buildGitDateMap({ cwd: dir });
  assert.equal(pass.commits, 5);
  const inScope = git(dir, ['ls-files', '-z'])
    .split('\0')
    .filter(p => p.startsWith(R));
  assert.equal(inScope.length, 5);
  for (const rel of inScope) {
    const ref = ageFromGitLogSingle(rel, dir);
    assert.ok(ref, `reference date for ${rel}`);
    assert.equal(pass.map.get(rel), ref.date.getTime() / 1000, `newest touch of ${rel}`);
  }
  assert.equal(pass.map.get(`${R}badges/run-1-renamed.svg`), 1_700_300_000);
  assert.equal(pass.map.get(`${R}badges/run-2.svg`), 1_700_100_000);
  assert.equal(pass.map.get(`${R}badges/${oddName}`), 1_700_300_000);
  assert.equal(pass.map.get(`${R}badges/${twinName}`), 1_700_400_000);
  assert.equal(
    ageFromGitLogSingle(`${R}badges/${oddName}`, dir).date.getTime() / 1000,
    1_700_300_000,
    'the fallback reads the odd name literally, not as a glob that also matches the twin'
  );
  assert.equal(pass.map.has('elsewhere/outside.md'), false, 'the pathspec limits the pass');
});

test('buildGitDateMap lists root-commit files even when the repo sets log.showRoot=false', async t => {
  const dir = scratchRepo(t);
  put(dir, `${R}badges/run-root.svg`, 'root');
  commitAll(dir, 'root', 1_700_000_000);
  put(dir, `${R}badges/run-next.svg`, 'next');
  commitAll(dir, 'next', 1_700_100_000);
  git(dir, ['config', 'log.showRoot', 'false']);
  const pass = await buildGitDateMap({ cwd: dir });
  assert.equal(pass.map.get(`${R}badges/run-root.svg`), 1_700_000_000);
});

test('buildGitDateMap refuses a history with a merge commit', async t => {
  const repo = evidenceRepo(t);
  addMerge(repo);
  await assert.rejects(buildGitDateMap({ cwd: repo }), /history has 1 merge commit/);
});

test('buildGitDateMap fails on an unborn history and when nothing touched the prune root', async t => {
  const unborn = scratchRepo(t);
  await assert.rejects(buildGitDateMap({ cwd: unborn }), /git rev-list --merges --count HEAD failed/);
  const elsewhere = scratchRepo(t);
  put(elsewhere, 'elsewhere/outside.md', 'not in scope');
  commitAll(elsewhere, 'outside only', 1_700_000_000);
  await assert.rejects(buildGitDateMap({ cwd: elsewhere }), /listed no commits/);
});

test('script: a dry run dates undated files from git and deletes nothing', t => {
  const repo = evidenceRepo(t);
  const r = runPrune(t, repo);
  assert.equal(r.status, 0, r.stderr);
  const m = r.manifest;
  assert.ok(m, 'manifest written');
  assert.equal(m.dry_run, true);
  assert.deepEqual(
    m.would_delete.map(x => `${x.date_source} ${x.path}`).sort(),
    [`filename ${R}archived/2020/01/run-1.md`, `git-log ${R}badges/run-old.svg`]
  );
  assert.deepEqual(m.kept, { permanent: 2, young: 1, no_age: 0 });
  assert.deepEqual(m.date_source_breakdown, { filename: 1, 'git-log': 1 });
  assert.equal(m.git_log_pass.commits, 2);
  assert.ok('merge_commits' in m.git_log_pass && 'shallow' in m.git_log_pass, 'the history checks are recorded');
  assert.equal(m.git_log_fallbacks, 0);
  assert.deepEqual(deletedFiles(repo), []);
});

test('script: a live run deletes exactly the would-delete rows', t => {
  const repo = evidenceRepo(t);
  const r = runPrune(t, repo, { DRY_RUN: 'false' });
  assert.equal(r.status, 0, r.stderr);
  assert.equal(r.manifest.deleted_count, 2);
  assert.deepEqual(deletedFiles(repo), [`${R}archived/2020/01/run-1.md`, `${R}badges/run-old.svg`]);
  assert.ok(exists(repo, `${R}badges/run-new.svg`));
});

test('script: keeps a file whose newest commit has no usable timestamp, as the per-file method did', t => {
  const repo = evidenceRepo(t);
  put(repo, `${R}badges/run-zero.svg`, 'zero\n');
  git(repo, ['add', '-A']);
  const tree = git(repo, ['write-tree']);
  const parent = git(repo, ['rev-parse', 'HEAD']);
  const body = `tree ${tree}\nparent ${parent}\nauthor z <z@example.invalid> 0 +0000\ncommitter z <z@example.invalid> 0 +0000\n\nzero timestamp\n`;
  const commit = execFileSync('git', ['hash-object', '-t', 'commit', '-w', '--stdin'], {
    cwd: repo,
    input: body,
    encoding: 'utf8',
  }).trim();
  git(repo, ['update-ref', 'refs/heads/main', commit]);
  assert.equal(ageFromGitLogSingle(`${R}badges/run-zero.svg`, repo), null, 'the per-file method has no date either');
  const r = runPrune(t, repo);
  assert.equal(r.status, 0, r.stderr);
  assert.equal(r.manifest.kept.no_age, 1);
  assert.equal(r.manifest.git_log_fallbacks, 0, 'listed by the pass, so no fallback');
  assert.equal(r.manifest.would_delete.some(x => x.path.endsWith('run-zero.svg')), false);
});

test('script: refuses a history with a merge commit and deletes nothing', t => {
  const repo = evidenceRepo(t);
  addMerge(repo);
  const r = runPrune(t, repo, { DRY_RUN: 'false' });
  assert.equal(r.status, 1, r.stderr);
  assert.match(r.stderr, /::error::refusing to date: the history has 1 merge commit/);
  assert.equal(r.manifest, null);
  assert.deepEqual(deletedFiles(repo), []);
});

test('script: refuses a shallow clone and deletes nothing', t => {
  const repo = evidenceRepo(t);
  const clone = path.join(tempDir(t, 'prune-shallow-'), 'clone');
  git(os.tmpdir(), ['clone', '-q', '--depth', '1', pathToFileURL(repo).href, clone]);
  assert.equal(git(clone, ['rev-parse', '--is-shallow-repository']), 'true');
  const r = runPrune(t, clone, { DRY_RUN: 'false' });
  assert.equal(r.status, 1, r.stderr);
  assert.match(r.stderr, /::error::refusing to date from a shallow clone/);
  assert.equal(r.manifest, null);
  assert.deepEqual(deletedFiles(clone), []);
});

test('script: exit 3 when the pass misses more files than GIT_LOG_FALLBACK_MAX', t => {
  const repo = evidenceRepo(t);
  put(repo, `${R}badges/run-untracked.svg`, 'never committed\n');
  const capped = runPrune(t, repo, { GIT_LOG_FALLBACK_MAX: '0', DRY_RUN: 'false' });
  assert.equal(capped.status, 3, capped.stderr);
  assert.match(capped.stderr, /not listed by the git log pass/);
  assert.equal(capped.manifest, null);
  assert.deepEqual(deletedFiles(repo), []);

  const allowed = runPrune(t, repo);
  assert.equal(allowed.status, 0, allowed.stderr);
  assert.equal(allowed.manifest.git_log_fallbacks, 1);
  assert.equal(allowed.manifest.kept.no_age, 1);
});

test('script: rejects a non-integer RETAIN_DAYS or GIT_LOG_FALLBACK_MAX before anything else', t => {
  const repo = evidenceRepo(t);
  for (const env of [
    { RETAIN_DAYS: 'ninety' },
    { RETAIN_DAYS: '0' },
    { RETAIN_DAYS: '90.5' },
    { RETAIN_DAYS: '9'.repeat(400) },
    { RETAIN_DAYS: '9007199254740993' },
    { RETAIN_DAYS: '3651' },
    { GIT_LOG_FALLBACK_MAX: 'lots' },
    { GIT_LOG_FALLBACK_MAX: '-1' },
    { GIT_LOG_FALLBACK_MAX: '100001' },
  ]) {
    const r = runPrune(t, repo, { ...env, DRY_RUN: 'false' });
    assert.equal(r.status, 1, JSON.stringify(env));
    assert.match(r.stderr, /must be an integer/);
    assert.equal(r.manifest, null);
  }
  assert.deepEqual(deletedFiles(repo), []);
});

test('script: a live run never keeps fewer than the policy 90 days; a dry run may', t => {
  const repo = evidenceRepo(t);
  const live = runPrune(t, repo, { RETAIN_DAYS: '89', DRY_RUN: 'false' });
  assert.equal(live.status, 1, live.stderr);
  assert.match(live.stderr, /a live prune keeps at least 90 days/);
  assert.equal(live.manifest, null);
  assert.deepEqual(deletedFiles(repo), []);

  const dry = runPrune(t, repo, { RETAIN_DAYS: '5' });
  assert.equal(dry.status, 0, dry.stderr);
  assert.equal(dry.manifest.retain_days, 5);
  assert.equal(dry.manifest.would_delete_count, 3, 'the 10-day-old badge too, at 5 days');

  const at90 = runPrune(t, repo, { RETAIN_DAYS: ' 90 ', DRY_RUN: 'False' });
  assert.equal(at90.status, 0, at90.stderr);
  assert.equal(at90.manifest.retain_days, 90, 'surrounding whitespace is trimmed');
  assert.equal(at90.manifest.dry_run, false, 'DRY_RUN compares without case');
  assert.equal(at90.manifest.deleted_count, 2);
});

test('script: runs when its path goes through a junction or symlink (no silent no-op)', t => {
  const repo = evidenceRepo(t);
  const holder = fs.mkdtempSync(path.join(os.tmpdir(), 'prune-link-'));
  const link = path.join(holder, 'linked');
  fs.symlinkSync(path.dirname(SCRIPT), link, 'junction');
  t.after(() => {
    fs.unlinkSync(link); // the link only, never its target
    fs.rmSync(holder, { recursive: true, force: true });
  });
  const r = runPrune(t, repo, {}, path.join(link, path.basename(SCRIPT)));
  assert.equal(r.status, 0, r.stderr);
  assert.ok(r.manifest, 'the script ran and wrote its manifest');
  assert.equal(r.manifest.would_delete_count, 2);
});
