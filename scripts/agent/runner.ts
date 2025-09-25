#!/usr/bin/env node
/**
 * Autopilot Agent Runner
 * Entry point for the background autopilot system
 * Part of the push-button automation system
 */

import { AutopilotWatchdog } from './watchdog';
import * as fs from 'fs/promises';
import * as path from 'path';

interface RunnerConfig {
  configPath: string;
  daemon: boolean;
  logFile?: string;
}

class AutopilotRunner {
  private watchdog: AutopilotWatchdog;
  private config: RunnerConfig;

  constructor(config: RunnerConfig) {
    this.config = config;
    this.watchdog = new AutopilotWatchdog(config.configPath);
  }

  private async setupLogging(): Promise<void> {
    if (this.config.logFile) {
      // Redirect stdout/stderr to log file in daemon mode
      const logStream = await fs.open(this.config.logFile, 'a');
      process.stdout.write = logStream.write.bind(logStream);
      process.stderr.write = logStream.write.bind(logStream);
    }
  }

  private async createPidFile(): Promise<void> {
    const pidFile = '.agent/watchdog.pid';
    await fs.writeFile(pidFile, process.pid.toString());
  }

  private async removePidFile(): Promise<void> {
    const pidFile = '.agent/watchdog.pid';
    try {
      await fs.unlink(pidFile);
    } catch (error) {
      // Ignore if file doesn't exist
    }
  }

  private async handleSignals(): Promise<void> {
    const gracefulShutdown = async (signal: string) => {
      console.log(`Received ${signal}, shutting down gracefully...`);
      await this.watchdog.stop();
      await this.removePidFile();
      process.exit(0);
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    process.on('SIGHUP', () => gracefulShutdown('SIGHUP'));
  }

  public async start(): Promise<void> {
    try {
      console.log('Starting autopilot agent runner...');
      
      if (this.config.daemon) {
        await this.setupLogging();
        await this.createPidFile();
      }
      
      await this.handleSignals();
      await this.watchdog.start();
      
      console.log('Autopilot agent runner started successfully');
      
      if (!this.config.daemon) {
        // Keep the process alive in non-daemon mode
        process.stdin.resume();
      }
      
    } catch (error) {
      console.error('Failed to start autopilot agent runner:', error);
      await this.removePidFile();
      process.exit(1);
    }
  }

  public async stop(): Promise<void> {
    try {
      console.log('Stopping autopilot agent runner...');
      await this.watchdog.stop();
      await this.removePidFile();
      console.log('Autopilot agent runner stopped');
    } catch (error) {
      console.error('Error stopping autopilot agent runner:', error);
      process.exit(1);
    }
  }

  public async status(): Promise<void> {
    const status = this.watchdog.getStatus();
    console.log('Autopilot Agent Status:');
    console.log(JSON.stringify(status, null, 2));
  }
}

// CLI interface
async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'start';
  
  const config: RunnerConfig = {
    configPath: '.agent/config.json',
    daemon: args.includes('--daemon'),
    logFile: args.includes('--log-file') ? '.agent/runner.log' : undefined
  };
  
  const runner = new AutopilotRunner(config);
  
  try {
    switch (command) {
      case 'start':
        await runner.start();
        break;
      case 'stop':
        await runner.stop();
        break;
      case 'status':
        await runner.status();
        break;
      default:
        console.log('Usage: node runner.ts [start|stop|status] [--daemon] [--log-file]');
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

export { AutopilotRunner };




