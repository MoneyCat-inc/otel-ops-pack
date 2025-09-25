#!/usr/bin/env node
/**
 * OTel Pipeline Health Check Script
 * 
 * Comprehensive health check for the OTel observability pipeline.
 * 
 * Usage: node scripts/wire/health-check.mjs
 */

import fs from 'node:fs';
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

async function checkDockerServices() {
  return new Promise((resolve) => {
    const docker = spawn('docker', ['ps', '--format', 'json'], { stdio: 'pipe' });
    let output = '';
    
    docker.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    docker.on('close', (code) => {
      if (code === 0) {
        const containers = output.trim().split('\n').filter(line => line.trim()).map(line => {
          try { return JSON.parse(line); } catch { return null; }
        }).filter(Boolean);
        
        const signozContainers = containers.filter(c => c.Names?.includes('signoz'));
        log(`Found ${signozContainers.length} SigNoz containers running`, 'success');
        resolve(signozContainers.length > 0);
      } else {
        log('Docker not available or no containers running', 'error');
        resolve(false);
      }
    });
  });
}

async function checkWindowsService() {
  return new Promise((resolve) => {
    const sc = spawn('sc', ['query', 'otelcol-contrib'], { stdio: 'pipe' });
    let output = '';
    
    sc.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    sc.on('close', (code) => {
      if (code === 0 && output.includes('RUNNING')) {
        log('Windows OTel Collector service is running', 'success');
        resolve(true);
      } else {
        log('Windows OTel Collector service is not running', 'error');
        resolve(false);
      }
    });
  });
}

async function checkSigNozHealth() {
  return new Promise((resolve) => {
    const curl = spawn('curl', ['-s', 'http://localhost:8080/api/v1/health'], { stdio: 'pipe' });
    let output = '';
    
    curl.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    curl.on('close', (code) => {
      if (code === 0 && output.includes('ok')) {
        log('SigNoz health endpoint responding', 'success');
        resolve(true);
      } else {
        log('SigNoz health endpoint not responding', 'error');
        resolve(false);
      }
    });
  });
}

async function main() {
  try {
    log('Starting comprehensive health check...');
    
    const dockerOk = await checkDockerServices();
    const serviceOk = await checkWindowsService();
    const signozOk = await checkSigNozHealth();
    
    if (dockerOk && serviceOk && signozOk) {
      log('All health checks passed! Pipeline is healthy.', 'success');
    } else {
      log('Some health checks failed. Check the logs above.', 'error');
      process.exit(1);
    }
    
  } catch (error) {
    log(`Health check failed: ${error.message}`, 'error');
    process.exit(1);
  }
}

main();
