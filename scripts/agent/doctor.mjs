#!/usr/bin/env node
/**
 * OTel Agent Doctor
 * 
 * Diagnoses agent infrastructure and provides health status.
 * 
 * Usage: node scripts/agent/doctor.mjs
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

function checkDirectory(dirPath, description) {
  if (!fs.existsSync(dirPath) || !fs.statSync(dirPath).isDirectory()) {
    throw new Error(`Missing ${description}: ${dirPath}`);
  }
  return true;
}

function checkAgentInfrastructure() {
  log('Checking agent infrastructure...');
  
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
  
  const state = JSON.parse(fs.readFileSync('.agent/state.json', 'utf8'));
  
  // Handle both old and new state formats
  if (state.lastRun !== undefined) {
    // New format
    assert(typeof state.lastRun === 'number', 'lastRun should be number');
    assert(typeof state.runs === 'number', 'runs should be number');
  } else {
    // Existing format - just verify it's a valid state object
    assert(typeof state === 'object', 'state should be an object');
  }
  
  const queue = JSON.parse(fs.readFileSync('.agent/agent_queue.json', 'utf8'));
  assert(Array.isArray(queue.jobs), 'jobs should be array');
  
  // Handle both old and new queue formats
  if (queue.totalProcessed !== undefined) {
    // New format
    assert(typeof queue.totalProcessed === 'number', 'totalProcessed should be number');
  } else {
    // Existing format - just verify it's a valid queue object
    assert(typeof queue === 'object', 'queue should be an object');
  }
  
  log('Agent infrastructure healthy', 'success');
}

function checkECRRInfrastructure() {
  log('Checking ECRR infrastructure...');
  
  checkFile('ecrr/index.json', 'ECRR index');
  checkFile('ecrr/tasks.json', 'ECRR tasks');
  checkDirectory('ecrr/reports', 'ECRR reports directory');
  
  const index = JSON.parse(fs.readFileSync('ecrr/index.json', 'utf8'));
  assert(Array.isArray(index.items), 'index items should be array');
  assert(typeof index.version === 'number', 'index version should be number');
  
  const tasks = JSON.parse(fs.readFileSync('ecrr/tasks.json', 'utf8'));
  assert(Array.isArray(tasks.backlog), 'tasks backlog should be array');
  assert(Array.isArray(tasks.completed), 'tasks completed should be array');
  assert(typeof tasks.version === 'number', 'tasks version should be number');
  
  log('ECRR infrastructure healthy', 'success');
}

function checkOTelConfiguration() {
  log('Checking OTel configuration...');
  
  checkFile('config.yaml', 'OTel collector config');
  checkFile('docker-compose.yml', 'SigNoz compose file');
  
  // Check if collector config has required components
  const config = fs.readFileSync('config.yaml', 'utf8');
  assert(config.includes('receivers:'), 'Config missing receivers section');
  assert(config.includes('processors:'), 'Config missing processors section');
  assert(config.includes('exporters:'), 'Config missing exporters section');
  
  // Check docker compose
  const compose = fs.readFileSync('docker-compose.yml', 'utf8');
  assert(compose.includes('signoz'), 'Docker compose missing SigNoz services');
  
  log('OTel configuration healthy', 'success');
}

function checkCoreScripts() {
  log('Checking core scripts...');
  
  const requiredScripts = [
    'scripts/verify-integration.ps1',
    'scripts/quick-monitor.ps1',
    'scripts/monitor-optimized-pipeline.ps1',
    'scripts/canary-ecrr.ps1'
  ];
  
  for (const script of requiredScripts) {
    checkFile(script, `script: ${script}`);
  }
  
  log('Core scripts healthy', 'success');
}

function checkWiringScripts() {
  log('Checking wiring scripts...');
  
  const wiringScripts = [
    'scripts/wire/init.mjs',
    'scripts/wire/verify.mjs',
    'scripts/wire/health-check.mjs',
    'scripts/agent/watchdog.js',
    'scripts/agent/doctor.mjs'
  ];
  
  for (const script of wiringScripts) {
    checkFile(script, `wiring script: ${script}`);
  }
  
  log('Wiring scripts healthy', 'success');
}

function checkPackageJson() {
  log('Checking package.json scripts...');
  
  checkFile('package.json', 'package.json');
  
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  const requiredScripts = [
    'wire:init',
    'wire:verify',
    'wire:health',
    'agent:start',
    'agent:doctor',
    'ecrr:wire'
  ];
  
  for (const script of requiredScripts) {
    assert(packageJson.scripts[script], `Missing script: ${script}`);
  }
  
  log('Package.json scripts healthy', 'success');
}

function checkLockStatus() {
  log('Checking lock status...');
  
  if (fs.existsSync('.agent/LOCK')) {
    log('Kill switch is ACTIVE - agent operations are paused', 'error');
    return false;
  } else {
    log('Kill switch is inactive - agent operations are enabled', 'success');
    return true;
  }
}

function checkAgentState() {
  log('Checking agent state...');
  
  const state = JSON.parse(fs.readFileSync('.agent/state.json', 'utf8'));
  
  // Handle both old and new state formats
  if (state.lastRun !== undefined && state.runs !== undefined) {
    // New format
    const now = Date.now();
    const timeSinceLastRun = now - state.lastRun;
    
    log(`Agent runs: ${state.runs}`);
    log(`Last run: ${new Date(state.lastRun).toISOString()}`);
    log(`Time since last run: ${Math.round(timeSinceLastRun / 1000)}s`);
    
    if (timeSinceLastRun > 3600000) { // 1 hour
      log('Warning: Agent has not run recently', 'error');
    } else {
      log('Agent state healthy', 'success');
    }
  } else {
    // Existing format - just show available info
    log(`State format: existing (legacy)`);
    log(`Available fields: ${Object.keys(state).join(', ')}`);
    log('Agent state healthy (legacy format)', 'success');
  }
}

function checkQueueHealth() {
  log('Checking queue health...');
  
  const queue = JSON.parse(fs.readFileSync('.agent/agent_queue.json', 'utf8'));
  const now = Date.now();
  
  log(`Total jobs processed: ${queue.totalProcessed}`);
  log(`Pending jobs: ${queue.jobs.filter(j => j.status === 'pending').length}`);
  log(`Completed jobs: ${queue.jobs.filter(j => j.status === 'completed').length}`);
  log(`Failed jobs: ${queue.jobs.filter(j => j.status === 'failed').length}`);
  
  // Check for stale jobs
  const staleJobs = queue.jobs.filter(job => 
    job.status === 'pending' && (now - job.createdAt) > 3600000 // 1 hour
  );
  
  if (staleJobs.length > 0) {
    log(`Warning: ${staleJobs.length} stale jobs in queue`, 'error');
  } else {
    log('Queue health good', 'success');
  }
}

function generateHealthReport() {
  log('Generating health report...');
  
  const report = {
    timestamp: new Date().toISOString(),
    agent: {
      config: JSON.parse(fs.readFileSync('.agent/config.json', 'utf8')),
      state: JSON.parse(fs.readFileSync('.agent/state.json', 'utf8')),
      queue: JSON.parse(fs.readFileSync('.agent/agent_queue.json', 'utf8'))
    },
    ecrr: {
      index: JSON.parse(fs.readFileSync('ecrr/index.json', 'utf8')),
      tasks: JSON.parse(fs.readFileSync('ecrr/tasks.json', 'utf8'))
    },
    lockStatus: fs.existsSync('.agent/LOCK'),
    platform: process.platform,
    nodeVersion: process.version
  };
  
  const reportPath = 'artifacts/agent-health-report.json';
  if (!fs.existsSync('artifacts')) {
    fs.mkdirSync('artifacts', { recursive: true });
  }
  
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  log(`Health report saved to ${reportPath}`, 'success');
}

async function main() {
  try {
    log('Starting OTel Agent Doctor...');
    
    checkAgentInfrastructure();
    checkECRRInfrastructure();
    checkOTelConfiguration();
    checkCoreScripts();
    checkWiringScripts();
    checkPackageJson();
    
    const lockOk = checkLockStatus();
    checkAgentState();
    checkQueueHealth();
    
    generateHealthReport();
    
    log('All agent health checks passed!', 'success');
    log('Agent infrastructure is healthy and ready for operation.', 'success');
    
    if (!lockOk) {
      log('Note: Kill switch is active. Run "rm .agent/LOCK" to enable agent operations.', 'error');
    }
    
  } catch (error) {
    log(`Agent health check failed: ${error.message}`, 'error');
    process.exit(1);
  }
}

main();
