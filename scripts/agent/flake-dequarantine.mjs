#!/usr/bin/env node
// De-quarantine Script - Safe Untag After N Green Nights
// ECRR Compliance: Examine → Clean → Report → Role

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const LEDGER = '.agent/unflakeLedger.json';      // { "<test_id>": { greenStreak: n, firstSeen: ISO } }
const REPORT = '.artifacts/flake-report.json';   // nightly report listing current flakes
const ROOT   = 'playwright/tests';

/**
 * Load JSON file with fallback
 */
async function loadJSON(p, fallback) {
  try {
    const content = await fs.readFile(p, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.log(`[dequarantine] Could not load ${p}, using fallback`);
    return fallback;
  }
}

/**
 * Save JSON file
 */
async function saveJSON(p, data) {
  try {
    await fs.writeFile(p, JSON.stringify(data, null, 2), 'utf8');
  } catch (error) {
    console.error(`[dequarantine] Failed to save ${p}:`, error);
    throw error;
  }
}

/**
 * Generate test ID from file and title
 */
function testId(file, title) {
  return `${file}::${title || '*'}`;
}

/**
 * Parse test ID back to file and title
 */
function parseTestId(id) {
  const [file, ...titleParts] = id.split('::');
  const title = titleParts.join('::') || '*';
  return { file, title };
}

/**
 * Find all test titles in a spec file
 */
function* iterSpecTitles(src) {
  // Match test declarations with various modifiers
  const re = /^\s*(test(?:\.(?:only|skip|fixme))?\s*\(\s*)(['"`])(.*?)\2/gm;
  let m;
  while ((m = re.exec(src))) {
    yield { 
      idx: m.index, 
      head: m[1], 
      q: m[2], 
      title: m[3] 
    };
  }
}

/**
 * Remove @flaky prefix from test title
 */
function removeFlakyPrefix(src, title, head, q) {
  const escapedHead = head.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const escapedTitle = title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(`(${escapedHead})@flaky\\s+${q}${escapedTitle}${q}`);
  return src.replace(pattern, `$1${q}${title}${q}`);
}

/**
 * Main de-quarantine function
 */
async function main(N = 3) {
  console.log(`[dequarantine] Starting de-quarantine process (N=${N} green nights)`);
  
  const ledger = await loadJSON(LEDGER, {});
  const flakeReport = await loadJSON(REPORT, { specs: [] });
  
  console.log(`[dequarantine] Loaded ledger with ${Object.keys(ledger).length} entries`);
  console.log(`[dequarantine] Loaded flake report with ${flakeReport.specs?.length || 0} specs`);
  
  // 1) Update green streaks: decrement/reset for tests still flaky
  const stillFlaky = new Set(
    (flakeReport.specs || []).map(s => testId(s.file, s.title || '*'))
  );
  
  console.log(`[dequarantine] Found ${stillFlaky.size} tests still flaky`);
  
  for (const k of Object.keys(ledger)) {
    if (stillFlaky.has(k)) {
      ledger[k].greenStreak = 0;
      ledger[k].lastFlaky = new Date().toISOString();
    } else {
      ledger[k].greenStreak = (ledger[k].greenStreak || 0) + 1;
      if (!ledger[k].firstSeen) {
        ledger[k].firstSeen = new Date().toISOString();
      }
    }
  }
  
  // 2) Find candidates for de-quarantine
  const candidates = Object.entries(ledger).filter(([_, v]) => (v.greenStreak || 0) >= N);
  console.log(`[dequarantine] Found ${candidates.length} candidates for de-quarantine`);
  
  if (candidates.length === 0) {
    console.log('[dequarantine] No tests ready for de-quarantine');
    await saveJSON(LEDGER, ledger);
    return;
  }
  
  // 3) Group candidates by file
  const byFile = new Map();
  for (const [id] of candidates) {
    const { file, title } = parseTestId(id);
    const arr = byFile.get(file) || [];
    arr.push(title);
    byFile.set(file, arr);
  }
  
  console.log(`[dequarantine] Processing ${byFile.size} files`);
  
  // 4) Process each file
  const changed = [];
  const dequarantined = [];
  
  for (const [file, titles] of byFile.entries()) {
    const filePath = path.resolve(file);
    
    try {
      let src = await fs.readFile(filePath, 'utf8');
      const before = src;
      
      if (titles.includes('*')) {
        // De-tag all tests in file
        src = src.replace(/(\btest(?:\.(?:only|skip|fixme))?\s*\(\s*['"`])@flaky\s+/g, '$1');
        console.log(`[dequarantine] Removed @flaky from all tests in ${file}`);
      } else {
        // De-tag specific tests
        for (const { idx, head, q, title } of iterSpecTitles(src)) {
          if (titles.includes(title)) {
            src = removeFlakyPrefix(src, title, head, q);
            console.log(`[dequarantine] Removed @flaky from test: ${title}`);
          }
        }
      }
      
      if (src !== before) {
        await fs.writeFile(filePath, src, 'utf8');
        changed.push(file);
        
        // Record de-quarantine
        for (const title of titles) {
          const testId = testId(file, title === '*' ? '' : title);
          dequarantined.push({
            testId,
            file,
            title: title === '*' ? 'all tests' : title,
            greenStreak: ledger[testId]?.greenStreak || 0,
            firstSeen: ledger[testId]?.firstSeen,
            dequarantinedAt: new Date().toISOString()
          });
          
          // Remove from ledger after de-quarantine
          delete ledger[testId];
        }
      }
    } catch (error) {
      console.error(`[dequarantine] Failed to process ${file}:`, error);
    }
  }
  
  // 5) Save updated ledger
  await saveJSON(LEDGER, ledger);
  
  // 6) Generate de-quarantine report
  const report = {
    timestamp: new Date().toISOString(),
    threshold: N,
    filesChanged: changed.length,
    testsDequarantined: dequarantined.length,
    dequarantined,
    summary: {
      totalCandidates: candidates.length,
      filesProcessed: byFile.size,
      filesChanged,
      testsDequarantined
    }
  };
  
  const reportPath = `.artifacts/dequarantine-report-${new Date().toISOString().split('T')[0]}.json`;
  await saveJSON(reportPath, report);
  
  console.log(`[dequarantine] De-quarantine complete:`);
  console.log(`  - Files changed: ${changed.length}`);
  console.log(`  - Tests de-quarantined: ${dequarantined.length}`);
  console.log(`  - Report saved: ${reportPath}`);
  
  // 7) Emit telemetry (if available)
  if (dequarantined.length > 0) {
    console.log(`[dequarantine] Emitting telemetry for ${dequarantined.length} de-quarantined tests`);
    // In a real implementation, this would emit metrics to your observability system
    // emitMetric('flake_rehabilitated_total', dequarantined.length, { source: 'dequarantine' });
  }
  
  return report;
}

/**
 * CLI interface
 */
async function cli() {
  const args = process.argv.slice(2);
  const N = parseInt(args[0]) || 3;
  
  try {
    const report = await main(N);
    
    if (report && report.testsDequarantined > 0) {
      console.log('\n[dequarantine] De-quarantine successful!');
      console.log('Next steps:');
      console.log('1. Review the changes in your git diff');
      console.log('2. Open a PR with the de-quarantine changes');
      console.log('3. Monitor test stability after merge');
      process.exit(0);
    } else {
      console.log('\n[dequarantine] No tests ready for de-quarantine');
      process.exit(0);
    }
  } catch (error) {
    console.error('[dequarantine] Error:', error);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  cli();
}

export { main, testId, parseTestId, iterSpecTitles };
