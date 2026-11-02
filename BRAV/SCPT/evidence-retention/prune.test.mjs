// Run: node --test BRAV/SCPT/evidence-retention/prune.test.mjs
// Covers the age rules, git's C-quoting, and the streamed git-log pass against
// the per-file `git log -1 --format=%ct -- <path>` reference on a scratch repo.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import {
  ageFromFilename,
  buildGitDateMap,
  foldGitLogLines,
  unquoteGitPath,
  ageFromGitLogSingle,
  SCOPE_PREFIX,
} from './prune.mjs';

const MARK = '\u0001';

test('ageFromFilename: YYYYMMDD basename, archived/YYYY/MM path, else null', () => {
  assert.deepEqual(ageFromFilename('docs/BossCat/run-reports/run-20260815-x.md'), {
    date: new Date(Date.UTC(2026, 7, 15)),
    source: 'filename',
  });
  assert.deepEqual(ageFromFilename('docs/BossCat/run-reports/archived/2026/06/run-27413707649.md'), {
    date: new Date(Date.UTC(2026, 5, 1)),
    source: 'filename',
  });
  assert.equal(ageFromFilename('docs/BossCat/run-reports/badges/run-17813577604.svg'), null);
  assert.equal(ageFromFilename('docs/BossCat/run-reports/x-20261399.md'), null);
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

function git(cwd, args, env = {}) {
  return execFileSync('git', args, { cwd, encoding: 'utf8', env: { ...process.env, ...env } }).trim();
}

function commitAll(cwd, message, unixSeconds) {
  const date = `${unixSeconds} +0000`;
  git(cwd, ['add', '-A']);
  git(cwd, ['commit', '-q', '--allow-empty', '-m', message], {
    GIT_AUTHOR_DATE: date,
    GIT_COMMITTER_DATE: date,
  });
}

function scratchRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'prune-test-'));
  git(dir, ['init', '-q']);
  git(dir, ['config', 'user.name', 'prune-test']);
  git(dir, ['config', 'user.email', 'prune-test@example.invalid']);
  git(dir, ['config', 'core.autocrlf', 'false']);
  return dir;
}

test('buildGitDateMap matches the per-file reference on a scratch history', async () => {
  const dir = scratchRepo();
  const scope = path.join(dir, ...SCOPE_PREFIX.slice(0, -1).split('/'));
  fs.mkdirSync(path.join(scope, 'badges'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'elsewhere'), { recursive: true });

  fs.writeFileSync(path.join(scope, 'badges', 'run-1.svg'), 'one');
  fs.writeFileSync(path.join(scope, 'badges', 'run-2.svg'), 'two');
  fs.writeFileSync(path.join(dir, 'elsewhere', 'outside.md'), 'not in scope');
  commitAll(dir, 'add two badges and an outside file', 1_700_000_000);

  fs.writeFileSync(path.join(scope, 'badges', 'run-2.svg'), 'two, edited');
  fs.writeFileSync(path.join(scope, 'LATEST.md'), 'latest');
  commitAll(dir, 'edit run-2, add LATEST', 1_700_100_000);

  git(dir, ['mv', path.join('docs', 'BossCat', 'run-reports', 'badges', 'run-1.svg'), path.join('docs', 'BossCat', 'run-reports', 'badges', 'run-1-renamed.svg')]);
  commitAll(dir, 'rename run-1', 1_700_200_000);

  fs.writeFileSync(path.join(scope, 'badges', 'run-1-renamed.svg'), 'renamed and edited');
  // A double quote makes git C-quote the path; Windows cannot create such a name.
  const oddName = process.platform === 'win32' ? 'sp ace.svg' : 'sp ace "q".svg';
  fs.writeFileSync(path.join(scope, 'badges', oddName), 'odd name');
  commitAll(dir, 'edit renamed, add odd name', 1_700_300_000);

  const { map, commits } = await buildGitDateMap({ cwd: dir });
  assert.equal(commits, 4);
  const tracked = git(dir, ['ls-files']).split('\n').filter(Boolean);
  const inScope = tracked.filter(p => p.startsWith(SCOPE_PREFIX));
  assert.ok(inScope.length >= 4);
  for (const rel of inScope) {
    const ref = ageFromGitLogSingle(rel, dir);
    assert.ok(ref, `reference date for ${rel}`);
    assert.equal(map.get(rel), ref.date.getTime() / 1000, `newest touch of ${rel}`);
  }
  assert.equal(map.get('docs/BossCat/run-reports/badges/run-1-renamed.svg'), 1_700_300_000);
  assert.equal(map.get('docs/BossCat/run-reports/badges/run-2.svg'), 1_700_100_000);
  assert.equal(map.get(`docs/BossCat/run-reports/badges/${oddName}`), 1_700_300_000);
  assert.equal(map.has('elsewhere/outside.md'), false, 'pathspec limits the pass');
  fs.rmSync(dir, { recursive: true, force: true });
});

test('buildGitDateMap fails loud on an unborn history', async () => {
  const dir = scratchRepo();
  await assert.rejects(buildGitDateMap({ cwd: dir }), /git log pass failed|listed no commits/);
  fs.rmSync(dir, { recursive: true, force: true });
});
