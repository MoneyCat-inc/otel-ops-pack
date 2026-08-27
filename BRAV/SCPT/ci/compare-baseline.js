#!/usr/bin/env node
/**
 * BossCat OEM - Performance Baseline Comparator
 * Compares current test results against historical baselines
 */

const fs = require('fs');
const path = require('path');

const RESULTS_DIR = path.join(__dirname, '../../test-results');
const BASELINE_FILE = path.join(__dirname, '../../test-results/baseline.json');

function compareBaseline() {
  console.log('📊 Comparing against performance baseline...');
  
  // Load current results
  const logsFile = path.join(RESULTS_DIR, 'logs.json');
  let currentLogs = 0;
  
  if (fs.existsSync(logsFile)) {
    const logs = JSON.parse(fs.readFileSync(logsFile, 'utf8'));
    currentLogs = Array.isArray(logs) ? logs.length : 0;
  }
  
  // Load or create baseline
  let baseline = { logs: 0, metrics: 0, timestamp: new Date().toISOString() };
  
  try {
    baseline = JSON.parse(fs.readFileSync(BASELINE_FILE, 'utf8'));
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
    // First run - create baseline
    baseline.logs = currentLogs;
    fs.writeFileSync(BASELINE_FILE, JSON.stringify(baseline, null, 2), 'utf8');
    console.log('✅ Baseline created');
    return;
  }
  
  // Compare
  const logDiff = currentLogs - baseline.logs;
  const logPercentChange = baseline.logs > 0 ? ((logDiff / baseline.logs) * 100).toFixed(2) : 0;
  
  console.log(`📊 Current logs: ${currentLogs}`);
  console.log(`📊 Baseline logs: ${baseline.logs}`);
  console.log(`📊 Difference: ${logDiff} (${logPercentChange}%)`);
  
  // Check for regression
  const REGRESSION_THRESHOLD = -10; // 10% drop is a regression
  
  if (logPercentChange < REGRESSION_THRESHOLD) {
    console.log('⚠️  Performance regression detected!');
    process.exit(1);
  }
  
  console.log('✅ Performance within acceptable range');
  
  // Update baseline if improved
  if (currentLogs > baseline.logs) {
    baseline.logs = currentLogs;
    baseline.timestamp = new Date().toISOString();
    fs.writeFileSync(BASELINE_FILE, JSON.stringify(baseline, null, 2), 'utf8');
    console.log('✅ Baseline updated');
  }
}

if (require.main === module) {
  compareBaseline();
}

module.exports = { compareBaseline };

