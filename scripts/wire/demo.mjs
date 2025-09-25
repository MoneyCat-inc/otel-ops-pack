#!/usr/bin/env node
/**
 * OTel Pipeline Wiring Demo
 * 
 * Demonstrates the complete wiring system functionality.
 * 
 * Usage: node scripts/wire/demo.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';

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

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function runCommand(command, args = [], description = '') {
  return new Promise((resolve) => {
    log(`Running: ${command} ${args.join(' ')} ${description ? `(${description})` : ''}`);
    
    const child = spawn(command, args, { stdio: 'pipe' });
    let output = '';
    let error = '';
    
    child.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    child.stderr.on('data', (data) => {
      error += data.toString();
    });
    
    child.on('close', (code) => {
      resolve({
        success: code === 0,
        output: output.trim(),
        error: error.trim(),
        code
      });
    });
  });
}

async function demonstrateWiringInit() {
  log('=== Demonstrating Wire Initialization ===');
  
  const result = await runCommand('node', ['scripts/wire/init.mjs'], 'Initialize wiring system');
  
  if (result.success) {
    log('Wire initialization completed successfully', 'success');
  } else {
    log(`Wire initialization failed: ${result.error}`, 'error');
  }
  
  return result.success;
}

async function demonstrateWiringVerify() {
  log('=== Demonstrating Wire Verification ===');
  
  const result = await runCommand('node', ['scripts/wire/verify.mjs'], 'Verify wiring system');
  
  if (result.success) {
    log('Wire verification completed successfully', 'success');
  } else {
    log(`Wire verification failed: ${result.error}`, 'error');
  }
  
  return result.success;
}

async function demonstrateAgentDoctor() {
  log('=== Demonstrating Agent Doctor ===');
  
  const result = await runCommand('node', ['scripts/agent/doctor.mjs'], 'Agent health diagnostics');
  
  if (result.success) {
    log('Agent doctor completed successfully', 'success');
  } else {
    log(`Agent doctor failed: ${result.error}`, 'error');
  }
  
  return result.success;
}

async function demonstrateECRRWire() {
  log('=== Demonstrating ECRR Wiring ===');
  
  // Create a sample ECRR report for demonstration
  const sampleReport = `# ECRR Report: Demo Report

## Executive Summary
This is a demonstration ECRR report for testing the wiring system.

## Critical Gaps
- Missing automated health checks
- Inadequate error handling in collector
- No alerting for service failures

## Recommendations
- Implement automated health checks
- Add comprehensive error handling
- Set up alerting thresholds

## Action Items
- [ ] Deploy health check script
- [ ] Update collector configuration
- [ ] Configure SigNoz alerts
`;

  // Ensure ECRR reports directory exists
  if (!fs.existsSync('ecrr/reports')) {
    fs.mkdirSync('ecrr/reports', { recursive: true });
  }
  
  // Write sample report
  fs.writeFileSync('ecrr/reports/demo-report.md', sampleReport);
  log('Created sample ECRR report', 'success');
  
  // Run ECRR wiring
  const result = await runCommand('node', ['scripts/ecrr/wire.mjs'], 'Process ECRR reports');
  
  if (result.success) {
    log('ECRR wiring completed successfully', 'success');
  } else {
    log(`ECRR wiring failed: ${result.error}`, 'error');
  }
  
  return result.success;
}

async function demonstrateHealthCheck() {
  log('=== Demonstrating Health Check ===');
  
  const result = await runCommand('node', ['scripts/wire/health-check.mjs'], 'Pipeline health check');
  
  if (result.success) {
    log('Health check completed successfully', 'success');
  } else {
    log(`Health check failed: ${result.error}`, 'error');
  }
  
  return result.success;
}

async function showGeneratedArtifacts() {
  log('=== Generated Artifacts ===');
  
  const artifacts = [
    '.agent/config.json',
    '.agent/state.json',
    '.agent/agent_queue.json',
    'ecrr/index.json',
    'ecrr/tasks.json',
    'artifacts/agent-health-report.json',
    'artifacts/ecrr-wiring-report.json'
  ];
  
  for (const artifact of artifacts) {
    if (fs.existsSync(artifact)) {
      const stats = fs.statSync(artifact);
      log(`✅ ${artifact} (${stats.size} bytes, ${new Date(stats.mtime).toISOString()})`, 'success');
    } else {
      log(`❌ ${artifact} (not found)`, 'error');
    }
  }
}

async function showAgentStatus() {
  log('=== Agent Status ===');
  
  if (fs.existsSync('.agent/LOCK')) {
    log('🔒 Kill switch is ACTIVE - agent operations are paused', 'error');
  } else {
    log('🔓 Kill switch is inactive - agent operations are enabled', 'success');
  }
  
  if (fs.existsSync('.agent/state.json')) {
    const state = JSON.parse(fs.readFileSync('.agent/state.json', 'utf8'));
    
    // Handle both old and new state formats
    if (state.lastRun !== undefined && state.runs !== undefined) {
      log(`Agent runs: ${state.runs}`);
      log(`Last run: ${new Date(state.lastRun).toISOString()}`);
    } else {
      log(`Agent runs: legacy format`);
      log(`Available fields: ${Object.keys(state).join(', ')}`);
    }
  }
  
  if (fs.existsSync('.agent/agent_queue.json')) {
    const queue = JSON.parse(fs.readFileSync('.agent/agent_queue.json', 'utf8'));
    log(`Total jobs processed: ${queue.totalProcessed}`);
    log(`Pending jobs: ${queue.jobs.filter(j => j.status === 'pending').length}`);
  }
}

async function showECRRStatus() {
  log('=== ECRR Status ===');
  
  if (fs.existsSync('ecrr/index.json')) {
    const index = JSON.parse(fs.readFileSync('ecrr/index.json', 'utf8'));
    log(`Total reports: ${index.items.length}`);
    log(`Open reports: ${index.items.filter(item => item.status === 'open').length}`);
  }
  
  if (fs.existsSync('ecrr/tasks.json')) {
    const tasks = JSON.parse(fs.readFileSync('ecrr/tasks.json', 'utf8'));
    log(`Total tasks: ${tasks.backlog.length + tasks.completed.length}`);
    log(`Backlog: ${tasks.backlog.length}`);
    log(`Completed: ${tasks.completed.length}`);
  }
}

async function main() {
  try {
    log('🚀 Starting OTel Pipeline Wiring Demo...');
    log('This demo will show you how the complete wiring system works.');
    
    // Step 1: Initialize wiring
    const initSuccess = await demonstrateWiringInit();
    if (!initSuccess) {
      log('Demo failed at initialization step', 'error');
      return;
    }
    
    await sleep(1000);
    
    // Step 2: Verify wiring
    const verifySuccess = await demonstrateWiringVerify();
    if (!verifySuccess) {
      log('Demo failed at verification step', 'error');
      return;
    }
    
    await sleep(1000);
    
    // Step 3: Agent doctor
    const doctorSuccess = await demonstrateAgentDoctor();
    if (!doctorSuccess) {
      log('Demo failed at agent doctor step', 'error');
      return;
    }
    
    await sleep(1000);
    
    // Step 4: ECRR wiring
    const ecrrSuccess = await demonstrateECRRWire();
    if (!ecrrSuccess) {
      log('Demo failed at ECRR wiring step', 'error');
      return;
    }
    
    await sleep(1000);
    
    // Step 5: Health check
    const healthSuccess = await demonstrateHealthCheck();
    if (!healthSuccess) {
      log('Demo failed at health check step', 'error');
      return;
    }
    
    await sleep(1000);
    
    // Show results
    await showGeneratedArtifacts();
    await showAgentStatus();
    await showECRRStatus();
    
    log('🎉 Demo completed successfully!', 'success');
    log('The OTel pipeline wiring system is now fully operational.', 'success');
    log('');
    log('Next steps:');
    log('1. Run "pnpm agent:start" to start the background agent');
    log('2. Run "pnpm wire:health" to check pipeline health');
    log('3. Run "pnpm agent:doctor" to check agent status');
    log('4. Add ECRR reports to ecrr/reports/ and run "pnpm ecrr:wire"');
    log('');
    log('For more information, see:');
    log('- docs/WIRING_GUIDE.md');
    log('- WIRING_README.md');
    
  } catch (error) {
    log(`Demo failed: ${error.message}`, 'error');
    process.exit(1);
  }
}

main();
