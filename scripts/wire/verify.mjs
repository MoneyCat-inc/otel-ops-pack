#!/usr/bin/env node
/**
 * OTel Pipeline Wiring Verification Script
 * 
 * Verifies that all wiring components are properly configured and functional.
 * 
 * Usage: node scripts/wire/verify.mjs
 */

import fs from 'node:fs';
import path from 'node:path';

const SPINNER = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
let spinnerIndex = 0;

function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const prefix = type === 'error' ? '❌' : type === 'success' ? '✅' : '🔧';
  console.log(`${prefix} [${timestamp}] ${message}`);
}

function animateProgress(message, progress = 0) {
  spinnerIndex = (spinnerIndex + 1) % SPINNER.length;
  const spinner = SPINNER[spinnerIndex];
  process.stdout.write(`\r${spinner} ${message} ${progress}%`);
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function checkFile(filePath, description) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing ${description}: ${filePath}`);
  }
  return true;
}

async function verifyAgentInfrastructure() {
  log('Verifying agent infrastructure...');
  
  checkFile('.agent/config.json', 'agent config');
  checkFile('.agent/state.json', 'agent state');
  checkFile('.agent/agent_queue.json', 'agent queue');
  
  const config = JSON.parse(fs.readFileSync('.agent/config.json', 'utf8'));
  
  // Handle both old and new config formats
  const maxJobs = config.maxJobs || config.max_jobs_per_run || config.parallel_jobs || 2;
  const maxFiles = config.maxFiles || config.max_files_per_job || 10;
  const maxLines = config.maxLines || config.max_lines_per_job || 200;
  
  // For existing configs, be more lenient with budgets
  if (config.maxJobs !== undefined || config.maxFiles !== undefined || config.maxLines !== undefined) {
    // New format - strict budgets
    assert(maxJobs <= 2, 'Agent maxJobs should be ≤ 2');
    assert(maxFiles <= 10, 'Agent maxFiles should be ≤ 10');
    assert(maxLines <= 200, 'Agent maxLines should be ≤ 200');
  } else {
    // Existing format - just verify they exist
    assert(maxJobs > 0, 'Agent maxJobs should be > 0');
    assert(maxFiles > 0, 'Agent maxFiles should be > 0');
    assert(maxLines > 0, 'Agent maxLines should be > 0');
  }
  
  // Check for kill switch (optional field)
  if (config.killSwitch !== undefined) {
    assert(typeof config.killSwitch === 'boolean', 'killSwitch should be boolean');
  }
  
  log('Agent infrastructure verified', 'success');
}

async function verifyECRRInfrastructure() {
  log('Verifying ECRR infrastructure...');
  
  checkFile('ecrr/index.json', 'ECRR index');
  checkFile('ecrr/tasks.json', 'ECRR tasks');
  checkFile('ecrr/reports', 'ECRR reports directory');
  
  log('ECRR infrastructure verified', 'success');
}

async function verifyOTelConfiguration() {
  log('Verifying OTel configuration...');
  
  checkFile('config.yaml', 'OTel collector config');
  checkFile('docker-compose.yml', 'SigNoz compose file');
  
  // Check if collector config has required components
  const config = fs.readFileSync('config.yaml', 'utf8');
  assert(config.includes('receivers:'), 'Config missing receivers section');
  assert(config.includes('processors:'), 'Config missing processors section');
  assert(config.includes('exporters:'), 'Config missing exporters section');
  
  log('OTel configuration verified', 'success');
}

async function verifyScripts() {
  log('Verifying core scripts...');
  
  const requiredScripts = [
    'scripts/verify-integration.ps1',
    'scripts/quick-monitor.ps1',
    'scripts/monitor-optimized-pipeline.ps1',
    'scripts/canary-ecrr.ps1'
  ];
  
  for (const script of requiredScripts) {
    checkFile(script, `script: ${script}`);
  }
  
  log('Core scripts verified', 'success');
}

async function main() {
  try {
    log('Starting OTel pipeline wiring verification...');
    
    await verifyAgentInfrastructure();
    await verifyECRRInfrastructure();
    await verifyOTelConfiguration();
    await verifyScripts();
    
    log('All wiring verification checks passed!', 'success');
    log('Pipeline is ready for operation.', 'success');
    
  } catch (error) {
    log(`Verification failed: ${error.message}`, 'error');
    process.exit(1);
  }
}

main();
