#!/usr/bin/env node
import { execSync } from 'node:child_process';
import { accessSync } from 'node:fs';

function sh(cmd) {
  return execSync(cmd, { stdio: 'pipe' }).toString().trim();
}

const bodyPath = 'scripts/pr-body.md';

try {
  accessSync(bodyPath);
} catch {
  console.error('? PR template body missing at scripts/pr-body.md');
  process.exit(1);
}

const defaultTitle = sh('git rev-parse --abbrev-ref HEAD');

try {
  sh('gh --version');
} catch {
  console.error('? GitHub CLI (gh) not found. Install from https://cli.github.com/');
  process.exit(1);
}

const cmd = `gh pr create -t "${defaultTitle}" -F ${bodyPath}`;
console.log('??  ', cmd);

try {
  const out = sh(cmd);
  console.log(out);
  console.log('? PR created with ECRR badge + Gate prefilled.');
} catch (e) {
  console.error('? Failed to create PR. Details:\n', e?.stdout?.toString() || e?.message);
  process.exit(1);
}
