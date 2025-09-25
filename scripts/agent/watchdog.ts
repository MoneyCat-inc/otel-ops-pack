#!/usr/bin/env node
/**
 * Background Autopilot Watchdog Agent
 * Keeps the project healthy between commits with budgets and kill-switch
 * Part of the push-button automation system
 */

import { spawn, ChildProcess } from 'child_process';
import * as fs from 'fs/promises';
import * as path from 'path';
import { EventEmitter } from 'events';

interface AgentConfig {
  maxJobs: number;
  maxFiles: number;
  maxLines: number;
  backoffMinutes: number;
  ttlHours: number;
  logLevel: 'debug' | 'info' | 'warn' | 'error';
}

interface AgentState {
  status: 'running' | 'paused' | 'stopped';
  lastRun: string;
  jobsCompleted: number;
  errors: string[];
  lockFile?: string;
}

interface Job {
  id: string;
  type: 'ssot-refresh' | 'flake-quarantine' | 'csp-lint' | 'a11y-check' | 'cleanup';
  priority: number;
  createdAt: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  result?: any;
  error?: string;
}

class AutopilotWatchdog extends EventEmitter {
  private config: AgentConfig;
  private state: AgentState;
  private jobs: Job[] = [];
  private runningJobs: Set<string> = new Set();
  private intervalId?: NodeJS.Timeout;
  private lockFilePath: string;

  constructor(configPath: string = '.agent/config.json') {
    super();
    this.lockFilePath = '.agent/LOCK';
    this.config = this.getDefaultConfig();
    this.state = this.getDefaultState();
    this.loadConfig(configPath);
  }

  private getDefaultConfig(): AgentConfig {
    return {
      maxJobs: 2,
      maxFiles: 10,
      maxLines: 200,
      backoffMinutes: 15,
      ttlHours: 12,
      logLevel: 'info'
    };
  }

  private getDefaultState(): AgentState {
    return {
      status: 'stopped',
      lastRun: new Date().toISOString(),
      jobsCompleted: 0,
      errors: []
    };
  }

  private async loadConfig(configPath: string): Promise<void> {
    try {
      const configData = await fs.readFile(configPath, 'utf-8');
      this.config = { ...this.config, ...JSON.parse(configData) };
      this.log('info', `Configuration loaded from ${configPath}`);
    } catch (error) {
      this.log('warn', `Could not load config from ${configPath}, using defaults`);
    }
  }

  private async saveState(): Promise<void> {
    try {
      await fs.mkdir('.agent', { recursive: true });
      await fs.writeFile('.agent/state.json', JSON.stringify(this.state, null, 2));
    } catch (error) {
      this.log('error', `Failed to save state: ${error}`);
    }
  }

  private async loadState(): Promise<void> {
    try {
      const stateData = await fs.readFile('.agent/state.json', 'utf-8');
      this.state = { ...this.state, ...JSON.parse(stateData) };
    } catch (error) {
      this.log('warn', 'Could not load state, using defaults');
    }
  }

  private log(level: string, message: string): void {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] [${level.toUpperCase()}] ${message}`;
    
    if (this.config.logLevel === 'debug' || level === 'error') {
      console.log(logMessage);
    }
    
    // Also write to log file
    this.writeToLogFile(logMessage);
  }

  private async writeToLogFile(message: string): Promise<void> {
    try {
      await fs.mkdir('.agent/logs', { recursive: true });
      const logFile = `.agent/logs/watchdog-${new Date().toISOString().split('T')[0]}.log`;
      await fs.appendFile(logFile, message + '\n');
      
      // Rotate logs if they get too large (>10MB)
      const stats = await fs.stat(logFile).catch(() => null);
      if (stats && stats.size > 10 * 1024 * 1024) {
        const rotatedFile = logFile.replace('.log', `-${Date.now()}.log`);
        await fs.rename(logFile, rotatedFile);
      }
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  private async checkLockFile(): Promise<boolean> {
    try {
      await fs.access(this.lockFilePath);
      return true;
    } catch {
      return false;
    }
  }

  private async createLockFile(): Promise<void> {
    try {
      await fs.writeFile(this.lockFilePath, `Locked by autopilot watchdog at ${new Date().toISOString()}`);
    } catch (error) {
      this.log('error', `Failed to create lock file: ${error}`);
    }
  }

  private async removeLockFile(): Promise<void> {
    try {
      await fs.unlink(this.lockFilePath);
    } catch (error) {
      this.log('warn', `Failed to remove lock file: ${error}`);
    }
  }

  private async queueJob(job: Omit<Job, 'id' | 'createdAt' | 'status'>): Promise<string> {
    const jobId = `job-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const newJob: Job = {
      id: jobId,
      ...job,
      createdAt: new Date().toISOString(),
      status: 'pending'
    };
    
    this.jobs.push(newJob);
    this.log('info', `Queued job ${jobId}: ${job.type}`);
    return jobId;
  }

  private async executeJob(job: Job): Promise<void> {
    this.runningJobs.add(job.id);
    job.status = 'running';
    
    try {
      this.log('info', `Executing job ${job.id}: ${job.type}`);
      
      switch (job.type) {
        case 'ssot-refresh':
          await this.executeSSOTRefresh(job);
          break;
        case 'flake-quarantine':
          await this.executeFlakeQuarantine(job);
          break;
        case 'csp-lint':
          await this.executeCSPLint(job);
          break;
        case 'a11y-check':
          await this.executeA11yCheck(job);
          break;
        case 'cleanup':
          await this.executeCleanup(job);
          break;
        default:
          throw new Error(`Unknown job type: ${job.type}`);
      }
      
      job.status = 'completed';
      this.state.jobsCompleted++;
      this.log('info', `Job ${job.id} completed successfully`);
      
    } catch (error) {
      job.status = 'failed';
      job.error = error instanceof Error ? error.message : String(error);
      this.state.errors.push(`Job ${job.id} failed: ${job.error}`);
      this.log('error', `Job ${job.id} failed: ${job.error}`);
    } finally {
      this.runningJobs.delete(job.id);
    }
  }

  private async executeSSOTRefresh(job: Job): Promise<void> {
    // Run SSOT generation script
    const result = await this.runScript('scripts/generate-ssot.mjs');
    job.result = { script: 'generate-ssot.mjs', output: result };
  }

  private async executeFlakeQuarantine(job: Job): Promise<void> {
    // Run flake detection and quarantine
    const result = await this.runScript('scripts/quarantine-flakes.ps1');
    job.result = { script: 'quarantine-flakes.ps1', output: result };
  }

  private async executeCSPLint(job: Job): Promise<void> {
    // Run CSP linting
    const result = await this.runScript('scripts/lint-csp.ps1');
    job.result = { script: 'lint-csp.ps1', output: result };
  }

  private async executeA11yCheck(job: Job): Promise<void> {
    // Run accessibility checks
    const result = await this.runScript('scripts/check-a11y.ps1');
    job.result = { script: 'check-a11y.ps1', output: result };
  }

  private async executeCleanup(job: Job): Promise<void> {
    // Run cleanup tasks
    const result = await this.runScript('scripts/quick-tidy.ps1');
    job.result = { script: 'quick-tidy.ps1', output: result };
  }

  private async runScript(scriptPath: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const isPowerShell = scriptPath.endsWith('.ps1');
      const command = isPowerShell ? 'pwsh' : 'node';
      const args = isPowerShell ? ['-File', scriptPath] : [scriptPath];
      
      const child = spawn(command, args, {
        stdio: ['pipe', 'pipe', 'pipe'],
        shell: true
      });
      
      let output = '';
      let error = '';
      
      child.stdout?.on('data', (data) => {
        output += data.toString();
      });
      
      child.stderr?.on('data', (data) => {
        error += data.toString();
      });
      
      child.on('close', (code) => {
        if (code === 0) {
          resolve(output);
        } else {
          reject(new Error(`Script ${scriptPath} failed with code ${code}: ${error}`));
        }
      });
      
      child.on('error', (error) => {
        reject(new Error(`Failed to run script ${scriptPath}: ${error.message}`));
      });
    });
  }

  private async scheduleJobs(): Promise<void> {
    const now = new Date();
    const lastRun = new Date(this.state.lastRun);
    const minutesSinceLastRun = (now.getTime() - lastRun.getTime()) / (1000 * 60);
    
    // Only schedule jobs if enough time has passed
    if (minutesSinceLastRun < this.config.backoffMinutes) {
      return;
    }
    
    // Check if we're at job limit
    if (this.runningJobs.size >= this.config.maxJobs) {
      return;
    }
    
    // Schedule high-priority jobs
    await this.queueJob({
      type: 'ssot-refresh',
      priority: 1
    });
    
    // Schedule medium-priority jobs
    await this.queueJob({
      type: 'flake-quarantine',
      priority: 2
    });
    
    // Schedule low-priority jobs
    await this.queueJob({
      type: 'cleanup',
      priority: 3
    });
  }

  private async processJobs(): Promise<void> {
    // Sort jobs by priority
    const pendingJobs = this.jobs
      .filter(job => job.status === 'pending')
      .sort((a, b) => a.priority - b.priority);
    
    // Process jobs up to the limit
    const jobsToProcess = pendingJobs.slice(0, this.config.maxJobs - this.runningJobs.size);
    
    for (const job of jobsToProcess) {
      this.executeJob(job).catch(error => {
        this.log('error', `Job ${job.id} execution error: ${error.message}`);
      });
    }
  }

  private async cleanupOldJobs(): Promise<void> {
    const cutoffTime = new Date(Date.now() - this.config.ttlHours * 60 * 60 * 1000);
    
    this.jobs = this.jobs.filter(job => {
      const jobTime = new Date(job.createdAt);
      return jobTime > cutoffTime;
    });
  }

  private async runCycle(): Promise<void> {
    try {
      // Check for lock file
      if (await this.checkLockFile()) {
        this.state.status = 'paused';
        this.log('info', 'Lock file detected, pausing operations');
        return;
      }
      
      this.state.status = 'running';
      this.state.lastRun = new Date().toISOString();
      
      // Schedule new jobs
      await this.scheduleJobs();
      
      // Process pending jobs
      await this.processJobs();
      
      // Cleanup old jobs
      await this.cleanupOldJobs();
      
      // Save state
      await this.saveState();
      
    } catch (error) {
      this.log('error', `Run cycle error: ${error}`);
      this.state.errors.push(`Run cycle error: ${error}`);
    }
  }

  public async start(): Promise<void> {
    this.log('info', 'Starting autopilot watchdog');
    
    await this.loadState();
    await this.createLockFile();
    
    // Run initial cycle
    await this.runCycle();
    
    // Schedule regular cycles
    this.intervalId = setInterval(() => {
      this.runCycle().catch(error => {
        this.log('error', `Scheduled cycle error: ${error}`);
      });
    }, this.config.backoffMinutes * 60 * 1000);
    
    this.log('info', `Autopilot watchdog started, running every ${this.config.backoffMinutes} minutes`);
  }

  public async stop(): Promise<void> {
    this.log('info', 'Stopping autopilot watchdog');
    
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
    
    this.state.status = 'stopped';
    await this.saveState();
    await this.removeLockFile();
    
    this.log('info', 'Autopilot watchdog stopped');
  }

  public async pause(): Promise<void> {
    this.log('info', 'Pausing autopilot watchdog');
    this.state.status = 'paused';
    await this.saveState();
  }

  public async resume(): Promise<void> {
    this.log('info', 'Resuming autopilot watchdog');
    this.state.status = 'running';
    await this.saveState();
  }

  public getStatus(): { config: AgentConfig; state: AgentState; jobs: Job[] } {
    return {
      config: this.config,
      state: this.state,
      jobs: this.jobs
    };
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'start';
  
  const watchdog = new AutopilotWatchdog();
  
  try {
    switch (command) {
      case 'start':
        await watchdog.start();
        break;
      case 'stop':
        await watchdog.stop();
        break;
      case 'pause':
        await watchdog.pause();
        break;
      case 'resume':
        await watchdog.resume();
        break;
      case 'status':
        const status = watchdog.getStatus();
        console.log(JSON.stringify(status, null, 2));
        break;
      default:
        console.log('Usage: node watchdog.ts [start|stop|pause|resume|status]');
        process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { AutopilotWatchdog };




