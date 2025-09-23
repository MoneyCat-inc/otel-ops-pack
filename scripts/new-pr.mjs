#!/usr/bin/env node
import { execSync } from "node:child_process";

function sh(cmd) { return execSync(cmd, { stdio: "pipe" }).toString().trim(); }

const defaultTitle = sh('git rev-parse --abbrev-ref HEAD');
// require gh CLI
try { sh('gh --version'); } catch {
  console.error('❌ GitHub CLI (gh) not found. Install from https://cli.github.com/');
  process.exit(1);
}

// create PR (interactive base/labels allowed via flags if you like)
const cmd = `gh pr create -t "${defaultTitle}" -F scripts/pr-body.md`;
console.log('➡️  ', cmd);
try {
  const out = sh(cmd);
  console.log(out);
  console.log('✅ PR created with ECRR badge + Gate prefilled.');
} catch (e) {
  console.error('❌ Failed to create PR. Details:\n', e?.stdout?.toString() || e?.message);
  process.exit(1);
}
