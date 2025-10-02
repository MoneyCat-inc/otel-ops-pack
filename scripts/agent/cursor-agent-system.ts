#!/usr/bin/env node

/**
 * Cursor Agent System - Main Entry Point
 * 
 * This is the main entry point for the comprehensive agent system
 * that implements ECRR methodology across all agents.
 */

import { AgentOrchestrator } from './orchestrator';
import { SQLiteQueueManager } from './sqlite-queue';
import { ECRRComplianceEngine } from './ecrr-compliance';
import { promises as fs } from 'fs';
import path from 'path';

interface SystemConfig {
  orchestrator: {
    enabled: boolean;
    interval: number;
  };
  queue: {
    dbPath: string;
    walMode: boolean;
    maxConcurrentJobs: number;
  };
  compliance: {
    enabled: boolean;
    reportInterval: number;
  };
  agents: {
    'cursor-local': boolean;
    'codex-cloud': boolean;
    'otel-steward': boolean;
    'qa-scribe': boolean;
    'bosscat': boolean;
  };
}

class CursorAgentSystem {
  private orchestrator: AgentOrchestrator;
  private queue: SQLiteQueueManager;
  private compliance: ECRRComplianceEngine;
  private config: SystemConfig;
  private isRunning: boolean = false;

  constructor(configPath: string = '.agent/system-config.json') {
    this.loadConfig(configPath);
    this.orchestrator = new AgentOrchestrator();
    this.queue = new SQLiteQueueManager(this.config.queue);
    this.compliance = new ECRRComplianceEngine();
  }

  private async loadConfig(configPath: string): Promise<void> {
    try {
      const configData = await fs.readFile(configPath, 'utf-8');
      this.config = JSON.parse(configData);
    } catch (error) {
      // Use default config if file doesn't exist
      this.config = {
        orchestrator: {
          enabled: true,
          interval: 30000
        },
        queue: {
          dbPath: '.agent/queue.db',
          walMode: true,
          maxConcurrentJobs: 5
        },
        compliance: {
          enabled: true,
          reportInterval: 300000 // 5 minutes
        },
        agents: {
          'cursor-local': true,
          'codex-cloud': true,
          'otel-steward': true,
          'qa-scribe': true,
          'bosscat': true
        }
      };
      
      // Save default config
      await this.saveConfig(configPath);
    }
  }

  private async saveConfig(configPath: string): Promise<void> {
    await fs.mkdir(path.dirname(configPath), { recursive: true });
    await fs.writeFile(configPath, JSON.stringify(this.config, null, 2));
  }

  async start(): Promise<void> {
    if (this.isRunning) {
      console.log('🚀 Agent system already running');
      return;
    }

    console.log('🚀 Starting Cursor Agent System...');

    // Check kill switch
    if (await this.isLocked()) {
      console.log('🔒 System paused due to lock file');
      await this.updateSystemStatus('paused:lock', 'Lock file present');
      return;
    }

    this.isRunning = true;

    try {
      // Start orchestrator
      if (this.config.orchestrator.enabled) {
        console.log('🎯 Starting Agent Orchestrator...');
        await this.orchestrator.start();
      }

      // Start compliance reporting
      if (this.config.compliance.enabled) {
        console.log('📊 Starting ECRR Compliance Engine...');
        this.startComplianceReporting();
      }

      // Start system monitoring
      this.startSystemMonitoring();

      console.log('✅ Cursor Agent System started successfully');

    } catch (error) {
      console.error('❌ Failed to start agent system:', error);
      this.isRunning = false;
      throw error;
    }
  }

  async stop(): Promise<void> {
    if (!this.isRunning) {
      console.log('🛑 Agent system not running');
      return;
    }

    console.log('🛑 Stopping Cursor Agent System...');

    try {
      await this.orchestrator.stop();
      await this.queue.close();
      
      this.isRunning = false;
      await this.updateSystemStatus('stopped', 'System stopped gracefully');
      
      console.log('✅ Cursor Agent System stopped successfully');

    } catch (error) {
      console.error('❌ Error stopping agent system:', error);
      throw error;
    }
  }

  async status(): Promise<any> {
    const queueStats = await this.queue.getQueueStats();
    const complianceStats = await this.compliance.getComplianceStats();
    const systemStatus = await this.getSystemStatus();

    return {
      system: {
        running: this.isRunning,
        status: systemStatus.status,
        message: systemStatus.message,
        timestamp: systemStatus.timestamp
      },
      queue: queueStats,
      compliance: complianceStats,
      agents: this.config.agents,
      config: this.config
    };
  }

  async healthCheck(): Promise<{ healthy: boolean; issues: string[] }> {
    const issues: string[] = [];

    try {
      // Check kill switch
      if (await this.isLocked()) {
        issues.push('System locked by .agent/LOCK file');
      }

      // Check queue health
      const queueStats = await this.queue.getQueueStats();
      if (queueStats.failed && queueStats.failed.count > 10) {
        issues.push(`High failure rate: ${queueStats.failed.count} failed jobs`);
      }

      // Check compliance
      const complianceStats = await this.compliance.getComplianceStats();
      if (complianceStats.complianceRate < 90) {
        issues.push(`Low compliance rate: ${complianceStats.complianceRate}%`);
      }

      // Check disk space
      const stats = await fs.stat('.agent');
      if (stats.size > 100 * 1024 * 1024) { // 100MB
        issues.push('High disk usage in .agent directory');
      }

      return {
        healthy: issues.length === 0,
        issues
      };

    } catch (error) {
      return {
        healthy: false,
        issues: [`Health check failed: ${error.message}`]
      };
    }
  }

  async generateReport(): Promise<string> {
    const status = await this.status();
    const health = await this.healthCheck();
    const complianceReport = await this.compliance.generateComplianceReport();

    const report = `# Cursor Agent System Report

**Generated**: ${new Date().toISOString()}  
**System Status**: ${status.system.status}  
**Health**: ${health.healthy ? '✅ Healthy' : '❌ Issues Detected'}  

## 📊 System Overview

- **Running**: ${status.system.running ? 'Yes' : 'No'}
- **Queue Status**: ${Object.entries(status.queue).map(([k, v]) => `${k}: ${v.count}`).join(', ')}
- **Compliance Rate**: ${status.compliance.complianceRate}%

## 🚨 Health Issues

${health.issues.length > 0 ? health.issues.map(issue => `- ${issue}`).join('\n') : '- No issues detected'}

## 📋 Agent Status

${Object.entries(status.agents).map(([agent, enabled]) => 
  `- **${agent}**: ${enabled ? '✅ Enabled' : '❌ Disabled'}`
).join('\n')}

## 📊 Compliance Report

${complianceReport}

---

*Generated by Cursor Agent System*
`;

    return report;
  }

  private async isLocked(): Promise<boolean> {
    try {
      await fs.access('.agent/LOCK');
      return true;
    } catch {
      return false;
    }
  }

  private async updateSystemStatus(status: string, message: string): Promise<void> {
    const statusData = {
      status,
      message,
      timestamp: new Date().toISOString(),
      system: 'cursor-agent-system'
    };

    await fs.writeFile('.agent/system-status.json', JSON.stringify(statusData, null, 2));
  }

  private async getSystemStatus(): Promise<any> {
    try {
      const data = await fs.readFile('.agent/system-status.json', 'utf-8');
      return JSON.parse(data);
    } catch {
      return {
        status: 'unknown',
        message: 'Status file not found',
        timestamp: new Date().toISOString()
      };
    }
  }

  private startComplianceReporting(): void {
    setInterval(async () => {
      try {
        const report = await this.compliance.generateComplianceReport();
        const reportPath = `docs/ECRR_REPORTS/compliance-${Date.now()}.md`;
        
        await fs.mkdir(path.dirname(reportPath), { recursive: true });
        await fs.writeFile(reportPath, report);
        
        console.log(`📊 Compliance report generated: ${reportPath}`);
      } catch (error) {
        console.error('Failed to generate compliance report:', error);
      }
    }, this.config.compliance.reportInterval);
  }

  private startSystemMonitoring(): void {
    setInterval(async () => {
      try {
        const health = await this.healthCheck();
        if (!health.healthy) {
          console.warn('⚠️ System health issues detected:', health.issues);
        }
      } catch (error) {
        console.error('Health check failed:', error);
      }
    }, 60000); // Every minute
  }
}

// CLI interface
async function main() {
  const command = process.argv[2];
  const system = new CursorAgentSystem();

  try {
    switch (command) {
      case 'start':
        await system.start();
        break;
      case 'stop':
        await system.stop();
        break;
      case 'status':
        const status = await system.status();
        console.log(JSON.stringify(status, null, 2));
        break;
      case 'health':
        const health = await system.healthCheck();
        console.log(JSON.stringify(health, null, 2));
        break;
      case 'report':
        const report = await system.generateReport();
        console.log(report);
        break;
      default:
        console.log(`
Cursor Agent System

Usage: node cursor-agent-system.js <command>

Commands:
  start   - Start the agent system
  stop    - Stop the agent system
  status  - Show system status
  health  - Run health check
  report  - Generate system report
        `);
    }
  } catch (error) {
    console.error('Command failed:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down agent system...');
  try {
    const system = new CursorAgentSystem();
    await system.stop();
  } catch (error) {
    console.error('Error during shutdown:', error);
  }
  process.exit(0);
});

if (require.main === module) {
  main();
}

export { CursorAgentSystem };
