#!/usr/bin/env tsx
/**
 * AUTO-BOTS Preflight Check
 * Abort-fast checks: kill-switch, pristine git state, lane validation
 * 
 * Exit Codes:
 * - 0: All checks passed
 * - 50: Kill-switch active (.agent/LOCK exists)
 * - 51: Git state blocked (uncommitted changes, merge/rebase, locks)
 */

import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

const EXIT_PAUSED_LOCK = 50;
const EXIT_BLOCKED_GIT = 51;

interface Config {
  lanes: Record<string, { allow: string[] }>;
}

function checkKillSwitch(): void {
  const lockPath = path.join(process.cwd(), '.agent', 'LOCK');
  if (fs.existsSync(lockPath)) {
    console.error('❌ ABORT: Kill-switch active');
    console.error('paused:lock');
    process.exit(EXIT_PAUSED_LOCK);
  }
  console.log('✅ Kill-switch: Clear');
}

function checkGitState(): void {
  try {
    // Check for index lock (file system conflict)
    const indexLock = path.join(process.cwd(), '.git', 'index.lock');
    if (fs.existsSync(indexLock)) {
      console.error('❌ ABORT: Git index locked');
      console.error('blocked:git-state');
      process.exit(EXIT_BLOCKED_GIT);
    }

    // Check for merge in progress (actual conflict state)
    const mergeHead = path.join(process.cwd(), '.git', 'MERGE_HEAD');
    if (fs.existsSync(mergeHead)) {
      console.error('❌ ABORT: Merge in progress');
      console.error('blocked:git-state');
      process.exit(EXIT_BLOCKED_GIT);
    }

    // Check for rebase in progress (actual conflict state)
    const rebaseMerge = path.join(process.cwd(), '.git', 'rebase-merge');
    const rebaseApply = path.join(process.cwd(), '.git', 'rebase-apply');
    if (fs.existsSync(rebaseMerge) || fs.existsSync(rebaseApply)) {
      console.error('❌ ABORT: Rebase in progress');
      console.error('blocked:git-state');
      process.exit(EXIT_BLOCKED_GIT);
    }

    // Note: We allow dirty working tree - only blocking on actual conflicts
    console.log('✅ Git state: No conflicts (dirty working tree allowed)');
  } catch (error) {
    console.error('❌ ABORT: Failed to check git state');
    console.error('blocked:git-state');
    console.error(error);
    process.exit(EXIT_BLOCKED_GIT);
  }
}

function validateLaneConfig(lane?: string): void {
  const configPath = path.join(process.cwd(), '.agent', 'config.json');
  
  if (!fs.existsSync(configPath)) {
    console.error('❌ ABORT: Config file not found');
    process.exit(1);
  }

  const config: Config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

  if (lane && !config.lanes[lane]) {
    console.error(`❌ ABORT: Unknown lane "${lane}"`);
    console.error(`Available lanes: ${Object.keys(config.lanes).join(', ')}`);
    process.exit(1);
  }

  console.log('✅ Lane configuration: Valid');
}

async function main() {
  const lane = process.argv.find(arg => arg.startsWith('--lane='))?.split('=')[1];

  console.log('🔍 AUTO-BOTS Preflight Check');
  console.log('─'.repeat(50));

  // Check 1: Kill-switch
  checkKillSwitch();

  // Check 2: Git state (with one retry for transient races)
  try {
    checkGitState();
  } catch (error) {
    console.log('⏳ Retrying git check in 60-90s (transient race mitigation)...');
    const jitter = 60000 + Math.random() * 30000;
    await new Promise(resolve => setTimeout(resolve, jitter));
    checkGitState(); // Second check - fail if still blocked
  }

  // Check 3: Lane validation (if specified)
  if (lane) {
    validateLaneConfig(lane);
  }

  console.log('─'.repeat(50));
  console.log('✅ All preflight checks passed');
  process.exit(0);
}

main().catch(error => {
  console.error('❌ Preflight check failed:', error);
  process.exit(1);
});

