#!/usr/bin/env node

/**
 * Agent Orchestrator - Central coordination and ECRR enforcement
 * 
 * This module coordinates all agents and enforces ECRR methodology
 * across the entire system.
 */

import { Database } from 'sqlite3';
import { promises as fs } from 'fs';
import path from 'path';

interface AgentConfig {
  id: string;
  name: string;
  type: 'cursor-local' | 'codex-cloud' | 'otel-steward' | 'qa-scribe' | 'bosscat';
  enabled: boolean;
  budget: {
    maxJobsPerPass: number;
    maxFilesPerJob: number;
    maxLinesPerJob: number;
  };
  schedule: {
    interval: number; // minutes
    maxRetries: number;
  };
}

interface Task {
  id: string;
  agentId: string;
  type: 'maintenance' | 'remediation' | 'monitoring' | 'cleanup';
  priority: 'critical' | 'high' | 'medium' | 'low';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  payload: any;
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  attempts: number;
  maxAttempts: number;
  ecrrReport?: ECRRReport;
}

interface ECRRReport {
  examine: {
    timestamp: string;
    environment: any;
    state: any;
    evidence: string[];
  };
  clean: {
    actions: string[];
    changes: any[];
    rollback: any[];
  };
  report: {
    artifacts: string[];
    metrics: any;
    compliance: boolean;
  };
  role: {
    actor: string;
    responsibility: string;
    signature: string;
  };
}

class AgentOrchestrator {
  private db: Database;
  private agents: Map<string, AgentConfig> = new Map();
  private isRunning = false;
  private lockFile = '.agent/LOCK';
  private statusFile = '.agent/status.json';

  constructor() {
    this.db = new Database('.agent/queue.db');
    this.initializeDatabase();
    this.loadAgentConfigs();
  }

  private async initializeDatabase(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.serialize(() => {
        // Tasks table
        this.db.run(`
          CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            agent_id TEXT NOT NULL,
            type TEXT NOT NULL,
            priority TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            started_at TEXT,
            completed_at TEXT,
            attempts INTEGER DEFAULT 0,
            max_attempts INTEGER DEFAULT 3,
            ecrr_report TEXT,
            FOREIGN KEY (agent_id) REFERENCES agents (id)
          )
        `);

        // Agents table
        this.db.run(`
          CREATE TABLE IF NOT EXISTS agents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            enabled BOOLEAN DEFAULT 1,
            budget_config TEXT NOT NULL,
            schedule_config TEXT NOT NULL,
            last_run TEXT,
            status TEXT DEFAULT 'idle'
          )
        `);

        // ECRR reports table
        this.db.run(`
          CREATE TABLE IF NOT EXISTS ecrr_reports (
            id TEXT PRIMARY KEY,
            task_id TEXT NOT NULL,
            examine TEXT NOT NULL,
            clean TEXT NOT NULL,
            report TEXT NOT NULL,
            role TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (task_id) REFERENCES tasks (id)
          )
        `);

        resolve();
      });
    });
  }

  private async loadAgentConfigs(): Promise<void> {
    const configs: AgentConfig[] = [
      {
        id: 'cursor-local',
        name: 'Cursor-Local',
        type: 'cursor-local',
        enabled: true,
        budget: { maxJobsPerPass: 2, maxFilesPerJob: 10, maxLinesPerJob: 200 },
        schedule: { interval: 5, maxRetries: 3 }
      },
      {
        id: 'codex-cloud',
        name: 'Codex-Cloud',
        type: 'codex-cloud',
        enabled: true,
        budget: { maxJobsPerPass: 1, maxFilesPerJob: 5, maxLinesPerJob: 100 },
        schedule: { interval: 10, maxRetries: 2 }
      },
      {
        id: 'otel-steward',
        name: 'OTel-Steward',
        type: 'otel-steward',
        enabled: true,
        budget: { maxJobsPerPass: 2, maxFilesPerJob: 8, maxLinesPerJob: 150 },
        schedule: { interval: 3, maxRetries: 3 }
      },
      {
        id: 'qa-scribe',
        name: 'QA-Scribe',
        type: 'qa-scribe',
        enabled: true,
        budget: { maxJobsPerPass: 1, maxFilesPerJob: 3, maxLinesPerJob: 50 },
        schedule: { interval: 15, maxRetries: 2 }
      },
      {
        id: 'bosscat',
        name: 'BossCat',
        type: 'bosscat',
        enabled: true,
        budget: { maxJobsPerPass: 3, maxFilesPerJob: 15, maxLinesPerJob: 300 },
        schedule: { interval: 30, maxRetries: 1 }
      }
    ];

    for (const config of configs) {
      this.agents.set(config.id, config);
      await this.upsertAgent(config);
    }
  }

  private async upsertAgent(config: AgentConfig): Promise<void> {
    return new Promise((resolve, reject) => {
      const stmt = this.db.prepare(`
        INSERT OR REPLACE INTO agents (id, name, type, enabled, budget_config, schedule_config)
        VALUES (?, ?, ?, ?, ?, ?)
      `);
      
      stmt.run(
        config.id,
        config.name,
        config.type,
        config.enabled ? 1 : 0,
        JSON.stringify(config.budget),
        JSON.stringify(config.schedule),
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  async start(): Promise<void> {
    if (this.isRunning) {
      console.log('Orchestrator already running');
      return;
    }

    // Check kill switch
    if (await this.isLocked()) {
      console.log('🔒 Orchestrator paused due to lock file');
      await this.updateStatus('paused:lock', 'Lock file present');
      return;
    }

    this.isRunning = true;
    console.log('🚀 Agent Orchestrator starting...');

    // Start main loop
    this.mainLoop();
  }

  private async mainLoop(): Promise<void> {
    while (this.isRunning) {
      try {
        // Check kill switch
        if (await this.isLocked()) {
          console.log('🔒 Orchestrator paused due to lock file');
          this.isRunning = false;
          break;
        }

        // Process tasks for each agent
        for (const [agentId, config] of this.agents) {
          if (!config.enabled) continue;
          
          await this.processAgentTasks(agentId, config);
        }

        // Update system status
        await this.updateSystemStatus();

        // Wait before next iteration
        await this.sleep(30000); // 30 seconds

      } catch (error) {
        console.error('Orchestrator error:', error);
        await this.sleep(60000); // Wait longer on error
      }
    }
  }

  private async processAgentTasks(agentId: string, config: AgentConfig): Promise<void> {
    const tasks = await this.getPendingTasks(agentId, config.budget.maxJobsPerPass);
    
    for (const task of tasks) {
      try {
        await this.executeTask(task, config);
      } catch (error) {
        console.error(`Task ${task.id} failed:`, error);
        await this.markTaskFailed(task.id, error.message);
      }
    }
  }

  private async executeTask(task: Task, config: AgentConfig): Promise<void> {
    console.log(`🔄 Executing task ${task.id} for agent ${task.agentId}`);

    // Start ECRR process
    const ecrrReport: ECRRReport = {
      examine: {
        timestamp: new Date().toISOString(),
        environment: await this.captureEnvironment(),
        state: await this.captureState(),
        evidence: []
      },
      clean: {
        actions: [],
        changes: [],
        rollback: []
      },
      report: {
        artifacts: [],
        metrics: {},
        compliance: false
      },
      role: {
        actor: config.name,
        responsibility: `Execute ${task.type} task`,
        signature: `agent-${config.id}-${Date.now()}`
      }
    };

    // Mark task as processing
    await this.updateTaskStatus(task.id, 'processing');

    try {
      // Execute task based on type
      const result = await this.executeTaskByType(task, config);

      // Complete ECRR report
      ecrrReport.clean.actions = result.actions;
      ecrrReport.clean.changes = result.changes;
      ecrrReport.clean.rollback = result.rollback;
      ecrrReport.report.artifacts = result.artifacts;
      ecrrReport.report.metrics = result.metrics;
      ecrrReport.report.compliance = true;

      // Save ECRR report
      await this.saveECRRReport(task.id, ecrrReport);

      // Mark task as completed
      await this.updateTaskStatus(task.id, 'completed');
      await this.updateTaskECRR(task.id, ecrrReport);

      console.log(`✅ Task ${task.id} completed successfully`);

    } catch (error) {
      // Mark task as failed
      await this.updateTaskStatus(task.id, 'failed');
      ecrrReport.report.compliance = false;
      ecrrReport.report.metrics.error = error.message;
      
      await this.saveECRRReport(task.id, ecrrReport);
      await this.updateTaskECRR(task.id, ecrrReport);

      throw error;
    }
  }

  private async executeTaskByType(task: Task, config: AgentConfig): Promise<any> {
    switch (task.type) {
      case 'maintenance':
        return await this.executeMaintenanceTask(task, config);
      case 'remediation':
        return await this.executeRemediationTask(task, config);
      case 'monitoring':
        return await this.executeMonitoringTask(task, config);
      case 'cleanup':
        return await this.executeCleanupTask(task, config);
      default:
        throw new Error(`Unknown task type: ${task.type}`);
    }
  }

  private async executeMaintenanceTask(task: Task, config: AgentConfig): Promise<any> {
    // Implementation for maintenance tasks
    return {
      actions: ['Maintenance task executed'],
      changes: [],
      rollback: [],
      artifacts: [`maintenance-${task.id}.log`],
      metrics: { duration: 1000, success: true }
    };
  }

  private async executeRemediationTask(task: Task, config: AgentConfig): Promise<any> {
    // Implementation for remediation tasks
    return {
      actions: ['Remediation task executed'],
      changes: [],
      rollback: [],
      artifacts: [`remediation-${task.id}.log`],
      metrics: { duration: 2000, success: true }
    };
  }

  private async executeMonitoringTask(task: Task, config: AgentConfig): Promise<any> {
    // Implementation for monitoring tasks
    return {
      actions: ['Monitoring task executed'],
      changes: [],
      rollback: [],
      artifacts: [`monitoring-${task.id}.log`],
      metrics: { duration: 500, success: true }
    };
  }

  private async executeCleanupTask(task: Task, config: AgentConfig): Promise<any> {
    // Implementation for cleanup tasks
    return {
      actions: ['Cleanup task executed'],
      changes: [],
      rollback: [],
      artifacts: [`cleanup-${task.id}.log`],
      metrics: { duration: 1500, success: true }
    };
  }

  private async getPendingTasks(agentId: string, limit: number): Promise<Task[]> {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT * FROM tasks WHERE agent_id = ? AND status = ? ORDER BY priority DESC, created_at ASC LIMIT ?',
        [agentId, 'pending', limit],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows.map(this.mapRowToTask));
        }
      );
    });
  }

  private mapRowToTask(row: any): Task {
    return {
      id: row.id,
      agentId: row.agent_id,
      type: row.type,
      priority: row.priority,
      status: row.status,
      payload: JSON.parse(row.payload),
      createdAt: row.created_at,
      startedAt: row.started_at,
      completedAt: row.completed_at,
      attempts: row.attempts,
      maxAttempts: row.max_attempts,
      ecrrReport: row.ecrr_report ? JSON.parse(row.ecrr_report) : undefined
    };
  }

  private async updateTaskStatus(taskId: string, status: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const now = new Date().toISOString();
      const updates: any = { status };
      
      if (status === 'processing') {
        updates.started_at = now;
      } else if (status === 'completed' || status === 'failed') {
        updates.completed_at = now;
      }

      const setClause = Object.keys(updates).map(key => `${key} = ?`).join(', ');
      const values = Object.values(updates);
      values.push(taskId);

      this.db.run(
        `UPDATE tasks SET ${setClause} WHERE id = ?`,
        values,
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  private async updateTaskECRR(taskId: string, ecrrReport: ECRRReport): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.run(
        'UPDATE tasks SET ecrr_report = ? WHERE id = ?',
        [JSON.stringify(ecrrReport), taskId],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  private async saveECRRReport(taskId: string, ecrrReport: ECRRReport): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.run(
        'INSERT INTO ecrr_reports (id, task_id, examine, clean, report, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          `ecrr-${taskId}-${Date.now()}`,
          taskId,
          JSON.stringify(ecrrReport.examine),
          JSON.stringify(ecrrReport.clean),
          JSON.stringify(ecrrReport.report),
          JSON.stringify(ecrrReport.role),
          new Date().toISOString()
        ],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  private async captureEnvironment(): Promise<any> {
    return {
      nodeVersion: process.version,
      platform: process.platform,
      arch: process.arch,
      timestamp: new Date().toISOString()
    };
  }

  private async captureState(): Promise<any> {
    return {
      agents: Array.from(this.agents.keys()),
      isRunning: this.isRunning,
      timestamp: new Date().toISOString()
    };
  }

  private async isLocked(): Promise<boolean> {
    try {
      await fs.access(this.lockFile);
      return true;
    } catch {
      return false;
    }
  }

  private async updateStatus(status: string, message: string): Promise<void> {
    const statusData = {
      status,
      message,
      timestamp: new Date().toISOString(),
      orchestrator: 'running'
    };

    await fs.writeFile(this.statusFile, JSON.stringify(statusData, null, 2));
  }

  private async updateSystemStatus(): Promise<void> {
    const taskCounts = await this.getTaskCounts();
    const agentStatuses = await this.getAgentStatuses();

    const statusData = {
      status: 'active',
      message: 'Orchestrator running normally',
      timestamp: new Date().toISOString(),
      orchestrator: 'running',
      tasks: taskCounts,
      agents: agentStatuses
    };

    await fs.writeFile(this.statusFile, JSON.stringify(statusData, null, 2));
  }

  private async getTaskCounts(): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT status, COUNT(*) as count FROM tasks GROUP BY status',
        (err, rows) => {
          if (err) reject(err);
          else {
            const counts: any = {};
            rows.forEach((row: any) => {
              counts[row.status] = row.count;
            });
            resolve(counts);
          }
        }
      );
    });
  }

  private async getAgentStatuses(): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT id, name, status, last_run FROM agents',
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });
  }

  private async markTaskFailed(taskId: string, error: string): Promise<void> {
    await this.updateTaskStatus(taskId, 'failed');
    console.error(`❌ Task ${taskId} failed: ${error}`);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async stop(): Promise<void> {
    this.isRunning = false;
    console.log('🛑 Agent Orchestrator stopped');
  }
}

// Main execution
if (require.main === module) {
  const orchestrator = new AgentOrchestrator();
  
  orchestrator.start().catch(console.error);
  
  // Graceful shutdown
  process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down orchestrator...');
    await orchestrator.stop();
    process.exit(0);
  });
}

export { AgentOrchestrator, Task, ECRRReport };
