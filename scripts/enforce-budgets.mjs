/**
 * Budget Enforcement Script for BossCat Gate Verification
 * 
 * Enforces Tetragram governance budgets on PR/commit changes.
 * Budget: ~40 LOC (minimal enforcement)
 * Lane: COMP (compliance)
 * Authority: BossCat OEM Directive 009
 */

import fs from 'fs';

// Parse command line args
const args = process.argv.slice(2);
const configPath = args[args.indexOf('--config') + 1] || 'docs/BOSS/CATX/RESE/SYAR/BOSS-CATX-RESE-SYAR.json';
const metricsPath = args[args.indexOf('--metrics') + 1] || 'gate/loc.json';
const strictness = args[args.indexOf('--strictness') + 1] || 'ci';

// Load configuration
let config = { governance: { budgets: { loc_max: 2000, files_max: 10, sticky_threshold_pct: 80 } } };
try {
  if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  }
} catch (e) {
  console.log(`WARNING: Could not load config from ${configPath}, using defaults`);
}

const budgets = config.governance?.budgets || config.budgets || {};
const maxLOC = strictness === 'prod' ? (budgets.loc_max || 2000) : 200;
const maxFiles = budgets.files_max || 10;
const stickyThreshold = (budgets.sticky_threshold_pct || 80) / 100;

// Load metrics
let metrics = { total: 0, added: 0, deleted: 0 };
try {
  if (fs.existsSync(metricsPath)) {
    metrics = JSON.parse(fs.readFileSync(metricsPath, 'utf8'));
  }
} catch (e) {
  console.log(`WARNING: Could not load metrics from ${metricsPath}`);
}

const loc = metrics.total || metrics.added || 0;

// Enforce budgets
console.log(`\n[Budget Enforcement]`);
console.log(`  Site: ${strictness}`);
console.log(`  LOC: ${loc}/${maxLOC}`);
console.log(`  Sticky threshold: ${(stickyThreshold * 100).toFixed(0)}%\n`);

if (loc > maxLOC) {
  console.error(`::error::LOC budget exceeded: ${loc} > ${maxLOC} (site=${strictness})`);
  process.exit(1);
} else if (loc >= maxLOC * stickyThreshold) {
  console.log(`::warning::Sticky budget warning: ${loc} >= ${(maxLOC * stickyThreshold).toFixed(0)} (${(stickyThreshold * 100).toFixed(0)}% of ${maxLOC})`);
} else {
  console.log(`[OK] Budget check passed: ${loc}/${maxLOC} LOC`);
}

