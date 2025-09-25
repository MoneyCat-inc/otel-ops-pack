#!/usr/bin/env node
/**
 * OTel Agent Watchdog
 * 
 * Background agent that maintains the OTel observability pipeline health.
 * Respects budgets, kill-switch, and runs safe micro-jobs.
 * 
 * Usage: node scripts/agent/watchdog.js
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';

const SPINNER = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
let spinnerIndex = 0;
let isRunning = false;

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

function isLocked() {
  return fs.existsSync('.agent/LOCK');
}

function loadConfig() {
  try {
    const configPath = '.agent/config.json';
    if (!fs.existsSync(configPath)) {
      throw new Error('Agent config not found. Run "pnpm wire:init" first.');
    }
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (error) {
    log(`Failed to load config: ${error.message}`, 'error');
    return null;
  }
}

function loadState() {
  try {
    const statePath = '.agent/state.json';
    if (!fs.existsSync(statePath)) {
      return { lastRun: 0, killSwitch: false, runs: 0 };
    }
    return JSON.parse(fs.readFileSync(statePath, 'utf8'));
  } catch (error) {
    log(`Failed to load state: ${error.message}`, 'error');
    return { lastRun: 0, killSwitch: false, runs: 0 };
  }
}

function saveState(state) {
  try {
    fs.writeFileSync('.agent/state.json', JSON.stringify(state, null, 2));
  } catch (error) {
    log(`Failed to save state: ${error.message}`, 'error');
  }
}

function loadQueue() {
  try {
    const queuePath = '.agent/agent_queue.json';
    if (!fs.existsSync(queuePath)) {
      return { jobs: [], lastProcessed: 0, totalProcessed: 0 };
    }
    return JSON.parse(fs.readFileSync(queuePath, 'utf8'));
  } catch (error) {
    log(`Failed to load queue: ${error.message}`, 'error');
    return { jobs: [], lastProcessed: 0, totalProcessed: 0 };
  }
}

function saveQueue(queue) {
  try {
    fs.writeFileSync('.agent/agent_queue.json', JSON.stringify(queue, null, 2));
  } catch (error) {
    log(`Failed to save queue: ${error.message}`, 'error');
  }
}

function createJob(type, payload) {
  return {
    id: `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    type,
    payload,
    createdAt: Date.now(),
    attempts: 0,
    status: 'pending'
  };
}

function shouldRunJob(job, config) {
  const now = Date.now();
  const age = now - job.createdAt;
  
  // Check if job has expired
  if (age > config.jobTtlMs) {
    return false;
  }
  
  // Check if job has exceeded max attempts
  if (job.attempts >= config.maxAttempts) {
    return false;
  }
  
  return true;
}

async function runHealthCheck() {
  return new Promise((resolve) => {
    const healthCheck = spawn('node', ['scripts/wire/health-check.mjs'], { stdio: 'pipe' });
    let output = '';
    
    healthCheck.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    healthCheck.stderr.on('data', (data) => {
      output += data.toString();
    });
    
    healthCheck.on('close', (code) => {
      resolve({ success: code === 0, output });
    });
  });
}

async function runCanaryTest() {
  return new Promise((resolve) => {
    const canaryTest = spawn('pwsh', ['-File', 'scripts/canary-test.ps1'], { stdio: 'pipe' });
    let output = '';
    
    canaryTest.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    canaryTest.stderr.on('data', (data) => {
      output += data.toString();
    });
    
    canaryTest.on('close', (code) => {
      resolve({ success: code === 0, output });
    });
  });
}

async function runECRRReport() {
  return new Promise((resolve) => {
    const ecrrReport = spawn('pwsh', ['-File', 'scripts/ecrr-doctor.ps1'], { stdio: 'pipe' });
    let output = '';
    
    ecrrReport.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    ecrrReport.stderr.on('data', (data) => {
      output += data.toString();
    });
    
    ecrrReport.on('close', (code) => {
      resolve({ success: code === 0, output });
    });
  });
}

async function processJob(job, config) {
  log(`Processing job: ${job.type} (attempt ${job.attempts + 1})`);
  
  let result;
  switch (job.type) {
    case 'health_check':
      result = await runHealthCheck();
      break;
    case 'canary_test':
      result = await runCanaryTest();
      break;
    case 'ecrr_report':
      result = await runECRRReport();
      break;
    default:
      log(`Unknown job type: ${job.type}`, 'error');
      return { success: false, output: 'Unknown job type' };
  }
  
  job.attempts++;
  job.lastAttempt = Date.now();
  
  if (result.success) {
    job.status = 'completed';
    log(`Job ${job.type} completed successfully`, 'success');
  } else {
    job.status = 'failed';
    log(`Job ${job.type} failed: ${result.output}`, 'error');
  }
  
  return result;
}

async function processQueue(config, queue, state) {
  const now = Date.now();
  const jobsToProcess = queue.jobs.filter(job => 
    job.status === 'pending' && shouldRunJob(job, config)
  ).slice(0, config.maxJobs);
  
  if (jobsToProcess.length === 0) {
    return;
  }
  
  log(`Processing ${jobsToProcess.length} jobs from queue`);
  
  for (const job of jobsToProcess) {
    if (isLocked()) {
      log('Kill switch activated, stopping job processing', 'error');
      break;
    }
    
    const result = await processJob(job, config);
    
    // Update job in queue
    const jobIndex = queue.jobs.findIndex(j => j.id === job.id);
    if (jobIndex !== -1) {
      queue.jobs[jobIndex] = job;
    }
    
    queue.totalProcessed++;
  }
  
  // Clean up old jobs
  queue.jobs = queue.jobs.filter(job => 
    job.status === 'pending' || 
    (now - job.createdAt) < config.jobTtlMs
  );
  
  queue.lastProcessed = now;
  saveQueue(queue);
}

function scheduleJobs(queue, config) {
  const now = Date.now();
  const lastHealthCheck = queue.jobs.find(j => j.type === 'health_check' && j.status === 'completed');
  const lastCanaryTest = queue.jobs.find(j => j.type === 'canary_test' && j.status === 'completed');
  const lastECRRReport = queue.jobs.find(j => j.type === 'ecrr_report' && j.status === 'completed');
  
  // Schedule health check every 5 minutes
  if (!lastHealthCheck || (now - lastHealthCheck.lastAttempt) > 300000) {
    const healthJob = createJob('health_check', {});
    queue.jobs.push(healthJob);
  }
  
  // Schedule canary test every 15 minutes
  if (!lastCanaryTest || (now - lastCanaryTest.lastAttempt) > 900000) {
    const canaryJob = createJob('canary_test', {});
    queue.jobs.push(canaryJob);
  }
  
  // Schedule ECRR report every hour
  if (!lastECRRReport || (now - lastECRRReport.lastAttempt) > 3600000) {
    const ecrrJob = createJob('ecrr_report', {});
    queue.jobs.push(ecrrJob);
  }
}

async function runCycle() {
  if (isLocked()) {
    log('Kill switch active, skipping cycle', 'error');
    return;
  }
  
  const config = loadConfig();
  if (!config) {
    log('Failed to load config, stopping watchdog', 'error');
    return;
  }
  
  const state = loadState();
  const queue = loadQueue();
  
  // Update state
  state.lastRun = Date.now();
  state.runs++;
  saveState(state);
  
  log(`Watchdog cycle ${state.runs} starting...`);
  
  // Schedule new jobs
  scheduleJobs(queue, config);
  
  // Process queue
  await processQueue(config, queue, state);
  
  log(`Watchdog cycle ${state.runs} completed`);
}

function startWatchdog() {
  if (isRunning) {
    log('Watchdog already running', 'error');
    return;
  }
  
  isRunning = true;
  log('Starting OTel Agent Watchdog...');
  
  // Initial cycle
  runCycle().catch(error => {
    log(`Initial cycle failed: ${error.message}`, 'error');
  });
  
  // Schedule regular cycles every 2 minutes
  const interval = setInterval(async () => {
    if (isLocked()) {
      log('Kill switch activated, stopping watchdog', 'error');
      clearInterval(interval);
      isRunning = false;
      return;
    }
    
    try {
      await runCycle();
    } catch (error) {
      log(`Cycle failed: ${error.message}`, 'error');
    }
  }, 120000); // 2 minutes
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    log('Received SIGINT, shutting down watchdog...', 'error');
    clearInterval(interval);
    isRunning = false;
    process.exit(0);
  });
  
  process.on('SIGTERM', () => {
    log('Received SIGTERM, shutting down watchdog...', 'error');
    clearInterval(interval);
    isRunning = false;
    process.exit(0);
  });
}

// Main execution
if (import.meta.url === `file://${process.argv[1]}`) {
  startWatchdog();
}
