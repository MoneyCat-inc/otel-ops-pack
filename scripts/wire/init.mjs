#!/usr/bin/env node
/**
 * OTel Pipeline Wiring Initialization Script
 * 
 * This script sets up the complete end-to-end wiring for the OTel observability pipeline:
 * - Agent infrastructure with budgets and kill-switch
 * - ECRR report ingestion and task generation
 * - Comprehensive verification and health checks
 * - Background monitoring and automation
 * 
 * Usage: node scripts/wire/init.mjs
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

function ensure(filePath, content) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, content);
    return true;
  }
  return false;
}

function checkPrerequisites() {
  log('Checking prerequisites...');
  
  // Check Node.js version
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
  if (majorVersion < 18) {
    throw new Error(`Node.js 18+ required, found ${nodeVersion}`);
  }
  
  // Check if we're on Windows
  if (process.platform !== 'win32') {
    log('Warning: This script is optimized for Windows. Some features may not work on other platforms.', 'error');
  }
  
  log('Prerequisites check passed', 'success');
}

function setupAgentInfrastructure() {
  log('Setting up agent infrastructure...');
  
  const agentConfig = {
    maxJobs: 2,
    maxFiles: 10,
    maxLines: 200,
    jobTtlMs: 43200000, // 12 hours
    maxAttempts: 3,
    backoffMs: 900000, // 15 minutes
    killSwitch: false,
    lastRun: 0,
    runs: 0
  };
  
  const agentQueue = {
    jobs: [],
    lastProcessed: 0,
    totalProcessed: 0
  };
  
  ensure('.agent/config.json', JSON.stringify(agentConfig, null, 2));
  ensure('.agent/state.json', JSON.stringify(agentConfig, null, 2));
  ensure('.agent/agent_queue.json', JSON.stringify(agentQueue, null, 2));
  
  log('Agent infrastructure created', 'success');
}

function setupECRRInfrastructure() {
  log('Setting up ECRR infrastructure...');
  
  const ecrrIndex = {
    items: [],
    lastUpdated: new Date().toISOString(),
    version: 1
  };
  
  const ecrrTasks = {
    backlog: [],
    completed: [],
    lastUpdated: new Date().toISOString(),
    version: 1
  };
  
  ensure('ecrr/index.json', JSON.stringify(ecrrIndex, null, 2));
  ensure('ecrr/tasks.json', JSON.stringify(ecrrTasks, null, 2));
  ensure('ecrr/reports/.gitkeep', '');
  
  log('ECRR infrastructure created', 'success');
}

function setupWiringScripts() {
  log('Setting up wiring scripts...');
  
  // Create wire verification script
  const verifyScript = `#!/usr/bin/env node
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
  console.log(\`\${prefix} [\${timestamp}] \${message}\`);
}

function animateProgress(message, progress = 0) {
  spinnerIndex = (spinnerIndex + 1) % SPINNER.length;
  const spinner = SPINNER[spinnerIndex];
  process.stdout.write(\`\\r\${spinner} \${message} \${progress}%\`);
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function checkFile(filePath, description) {
  if (!fs.existsSync(filePath)) {
    throw new Error(\`Missing \${description}: \${filePath}\`);
  }
  return true;
}

async function verifyAgentInfrastructure() {
  log('Verifying agent infrastructure...');
  
  checkFile('.agent/config.json', 'agent config');
  checkFile('.agent/state.json', 'agent state');
  checkFile('.agent/agent_queue.json', 'agent queue');
  
  const config = JSON.parse(fs.readFileSync('.agent/config.json', 'utf8'));
  assert(config.maxJobs <= 2, 'Agent maxJobs should be ≤ 2');
  assert(config.maxFiles <= 10, 'Agent maxFiles should be ≤ 10');
  assert(config.maxLines <= 200, 'Agent maxLines should be ≤ 200');
  
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
    'scripts/canary-test.ps1'
  ];
  
  for (const script of requiredScripts) {
    checkFile(script, \`script: \${script}\`);
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
    log(\`Verification failed: \${error.message}\`, 'error');
    process.exit(1);
  }
}

main();
`;
  
  ensure('scripts/wire/verify.mjs', verifyScript);
  
  log('Wiring scripts created', 'success');
}

function setupHealthChecks() {
  log('Setting up health check infrastructure...');
  
  const healthCheckScript = `#!/usr/bin/env node
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
  console.log(\`\${prefix} [\${timestamp}] \${message}\`);
}

function animateProgress(message, progress = 0) {
  spinnerIndex = (spinnerIndex + 1) % SPINNER.length;
  const spinner = SPINNER[spinnerIndex];
  process.stdout.write(\`\\r\${spinner} \${message} \${progress}%\`);
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
        const containers = output.trim().split('\\n').filter(line => line.trim()).map(line => {
          try { return JSON.parse(line); } catch { return null; }
        }).filter(Boolean);
        
        const signozContainers = containers.filter(c => c.Names?.includes('signoz'));
        log(\`Found \${signozContainers.length} SigNoz containers running\`, 'success');
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
    log(\`Health check failed: \${error.message}\`, 'error');
    process.exit(1);
  }
}

main();
`;
  
  ensure('scripts/wire/health-check.mjs', healthCheckScript);
  
  log('Health check infrastructure created', 'success');
}

function updatePackageJson() {
  log('Updating package.json with wiring scripts...');
  
  const packageJsonPath = 'package.json';
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  
  const newScripts = {
    'wire:init': 'node scripts/wire/init.mjs',
    'wire:verify': 'node scripts/wire/verify.mjs',
    'wire:health': 'node scripts/wire/health-check.mjs',
    'agent:start': 'node scripts/agent/watchdog.js',
    'agent:doctor': 'node scripts/agent/doctor.mjs',
    'ecrr:wire': 'node scripts/ecrr/wire.mjs'
  };
  
  packageJson.scripts = { ...packageJson.scripts, ...newScripts };
  
  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
  
  log('Package.json updated with wiring scripts', 'success');
}

async function main() {
  try {
    log('Starting OTel pipeline wiring initialization...');
    
    checkPrerequisites();
    setupAgentInfrastructure();
    setupECRRInfrastructure();
    setupWiringScripts();
    setupHealthChecks();
    updatePackageJson();
    
    log('OTel pipeline wiring initialization complete!', 'success');
    log('Run "pnpm wire:verify" to verify the setup.', 'success');
    log('Run "pnpm wire:health" to check pipeline health.', 'success');
    
  } catch (error) {
    log(`Initialization failed: ${error.message}`, 'error');
    process.exit(1);
  }
}

main();
