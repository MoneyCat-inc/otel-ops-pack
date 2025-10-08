#!/usr/bin/env node
/**
 * BossCat OEM - Threshold Validator
 * Validates test results against configured thresholds
 */

const fs = require('fs');
const path = require('path');

const RESULTS_DIR = path.join(__dirname, '../../test-results');

// Define thresholds
const THRESHOLDS = {
  minLogs: 50,
  minMetrics: 10,
  maxErrorRate: 5.0 // 5%
};

function validateThresholds() {
  console.log('🎯 Validating performance thresholds...');
  
  // Load results
  const logsFile = path.join(RESULTS_DIR, 'logs.json');
  let logs = [];
  
  if (fs.existsSync(logsFile)) {
    logs = JSON.parse(fs.readFileSync(logsFile, 'utf8'));
  }
  
  const totalLogs = Array.isArray(logs) ? logs.length : 0;
  
  // Validate
  let passed = true;
  
  // Check minimum logs
  if (totalLogs < THRESHOLDS.minLogs) {
    console.log(`❌ FAILED: Total logs (${totalLogs}) below threshold (${THRESHOLDS.minLogs})`);
    passed = false;
  } else {
    console.log(`✅ PASSED: Total logs (${totalLogs}) meets threshold`);
  }
  
  // Calculate error rate
  const errorLogs = logs.filter(log => 
    log.severityText === 'ERROR' || log.level === 'ERROR'
  ).length;
  
  const errorRate = totalLogs > 0 ? ((errorLogs / totalLogs) * 100) : 0;
  
  if (errorRate > THRESHOLDS.maxErrorRate) {
    console.log(`❌ FAILED: Error rate (${errorRate.toFixed(2)}%) exceeds threshold (${THRESHOLDS.maxErrorRate}%)`);
    passed = false;
  } else {
    console.log(`✅ PASSED: Error rate (${errorRate.toFixed(2)}%) within threshold`);
  }
  
  if (!passed) {
    console.log('❌ Threshold validation failed');
    process.exit(1);
  }
  
  console.log('✅ All thresholds passed');
}

if (require.main === module) {
  validateThresholds();
}

module.exports = { validateThresholds };

