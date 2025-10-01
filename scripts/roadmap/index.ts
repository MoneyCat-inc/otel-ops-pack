#!/usr/bin/env tsx

/**
 * ECRR Roadmap Automation - Master Orchestrator
 * 
 * Runs the full ECRR cycle: Examine → Clean → Report → Role
 * 
 * Usage:
 *   tsx scripts/roadmap/index.ts [options]
 * 
 * Options:
 *   --pr-report <path>       Path to PR test results (default: test-results-pr.json)
 *   --nightly-report <path>  Path to nightly test results (default: test-results-nightly.json)
 *   --skip-examine           Skip examination phase (use existing .artifacts/roadmap-examine.json)
 *   --skip-clean             Skip clean phase (use existing .artifacts/roadmap-clean.json)
 *   --skip-report            Skip report phase (don't generate docs)
 */

import { examine } from './examine.js';
import { clean } from './clean.js';
import { report } from './report.js';

interface OrchestratorOptions {
  skipExamine?: boolean;
  skipClean?: boolean;
  skipReport?: boolean;
}

async function orchestrate(options: OrchestratorOptions = {}) {
  console.log('🚀 ECRR Roadmap Automation - Full Cycle');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log();
  console.log('📋 ECRR Methodology:');
  console.log('   1. 🔍 EXAMINE  → Capture test results');
  console.log('   2. 🧹 CLEAN    → Normalize to roadmap schema');
  console.log('   3. 📝 REPORT   → Generate docs & artifacts');
  console.log('   4. 🎭 ROLE     → Declare ownership & update PRs');
  console.log();
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log();

  const startTime = Date.now();

  try {
    // Phase 1: EXAMINE
    if (!options.skipExamine) {
      console.log('🔍 Phase 1: EXAMINE');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      await examine();
      console.log();
    } else {
      console.log('⏭️  Skipping EXAMINE phase (using existing results)');
      console.log();
    }

    // Phase 2: CLEAN
    if (!options.skipClean) {
      console.log('🧹 Phase 2: CLEAN');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      await clean();
      console.log();
    } else {
      console.log('⏭️  Skipping CLEAN phase (using existing results)');
      console.log();
    }

    // Phase 3: REPORT
    if (!options.skipReport) {
      console.log('📝 Phase 3: REPORT');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      await report();
      console.log();
    } else {
      console.log('⏭️  Skipping REPORT phase');
      console.log();
    }

    // Phase 4: ROLE (documentation only)
    console.log('🎭 Phase 4: ROLE');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ Roadmap automation executed by: ECRR Roadmap Agent');
    console.log('📦 Artifacts generated:');
    console.log('   - .artifacts/roadmap-examine.json');
    console.log('   - .artifacts/roadmap-clean.json');
    console.log('   - docs/ROADMAP.md');
    console.log('   - docs/ROADMAP_KANBAN.md');
    console.log('   - docs/ROADMAP_HEATMAP.md');
    console.log('   - .artifacts/SSOT.md (updated)');
    console.log();
    console.log('🔗 Next steps:');
    console.log('   1. Review generated docs/ROADMAP.md');
    console.log('   2. Commit changes to include in PR');
    console.log('   3. Update PR description with roadmap section');
    console.log();

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ ECRR Roadmap automation complete (${duration}s)`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  } catch (error) {
    console.error();
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('❌ ECRR Roadmap automation failed');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(error);
    throw error;
  }
}

// Parse CLI options
function parseOptions(): OrchestratorOptions {
  const args = process.argv.slice(2);
  const options: OrchestratorOptions = {};

  for (const arg of args) {
    if (arg === '--skip-examine') options.skipExamine = true;
    if (arg === '--skip-clean') options.skipClean = true;
    if (arg === '--skip-report') options.skipReport = true;
  }

  return options;
}

// Run if called directly
if (require.main === module) {
  const options = parseOptions();
  
  orchestrate(options)
    .then(() => process.exit(0))
    .catch(err => {
      console.error(err);
      process.exit(1);
    });
}

export { orchestrate };

