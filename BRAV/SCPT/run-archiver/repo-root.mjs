// Shared repo-root resolution + nested BossCat guard for run-archiver tools.
// Faulty expression this replaces: path.resolve(process.cwd(), '..', '..', '..')
// which only works when CWD is BRAV/SCPT/run-archiver and silently writes into the
// wrong tree (or, via fix-paths.ps1 Move-Item into an existing docs/BossCat,
// creates docs/BossCat/BossCat/).

import { execSync } from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs';

const NESTED_RE = /[/\\]BossCat[/\\]BossCat([/\\]|$)/i;

export function resolveRepoRoot() {
  const fromEnv = process.env.REPO_ROOT || process.env.GITHUB_WORKSPACE;
  if (fromEnv) {
    return path.resolve(fromEnv);
  }
  try {
    const top = execSync('git rev-parse --show-toplevel', {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    if (top) return path.resolve(top);
  } catch {
    /* fall through */
  }
  // Last resort: three levels up from BRAV/SCPT/run-archiver
  return path.resolve(process.cwd(), '..', '..', '..');
}

/** Throw if a resolved path would write under a nested BossCat/BossCat directory. */
export function assertNotNestedBossCat(targetPath, label = 'path') {
  const norm = path.resolve(targetPath);
  if (NESTED_RE.test(norm)) {
    throw new Error(
      `Refusing nested BossCat output (${label}): ${norm}\n` +
        'Output must be <repo>/docs/BossCat/... resolved from REPO_ROOT/GITHUB_WORKSPACE/git toplevel — not CWD-relative.',
    );
  }
  return norm;
}

export function rootJoin(repoRoot, ...parts) {
  const joined = path.join(repoRoot, ...parts);
  return assertNotNestedBossCat(joined, parts.join('/'));
}

export function ensureDirSafe(dirPath) {
  assertNotNestedBossCat(dirPath, 'mkdir');
  fs.mkdirSync(dirPath, { recursive: true });
}
