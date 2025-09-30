/**
 * Agent Status Command
 * 
 * Prints current queue status and writes .agent/status.json
 */

import { readJsonFile } from './io';
import { SQLiteQueueDB } from './db';
import { getQueueConfig } from '../../lib/config/queue';
import { existsSync } from 'fs';

export interface StatusOutput {
  timestamp: string;
  queueDepth: number;
  runningCount: number;
  lastRuns: Array<{
    id: string;
    kind: string;
    status: string;
    durationMs?: number;
  }>;
  admissionCap: number;
  shadowMode: boolean;
  driver: string;
  lockPresent: boolean;
}

/**
 * Get queue status
 */
export async function getQueueStatus(): Promise<StatusOutput> {
  const config = getQueueConfig();
  const lockPresent = existsSync('.agent/LOCK');
  
  let queueDepth = 0;
  let runningCount = 0;
  let lastRuns: Array<{ id: string; kind: string; status: string; durationMs?: number }> = [];

  if (config.driver === 'sqlite') {
    const dbPath = '.agent/queue.db';
    if (existsSync(dbPath)) {
      const db = new SQLiteQueueDB(dbPath, config);
      const stats = db.getQueueStats();
      queueDepth = stats.pending + stats.running;
      runningCount = stats.running;
      
      // Get recent runs (simplified - in real implementation, you'd query the runs table)
      lastRuns = [];
      db.close();
    }
  } else {
    // JSON driver
    const queueData = await readJsonFile('.agent/agent_queue.json', { jobs: [] });
    const jobs = queueData.jobs || [];
    queueDepth = jobs.filter((job: any) => job.status === 'pending').length;
    runningCount = jobs.filter((job: any) => job.status === 'running').length;
    
    // Get last 5 jobs
    lastRuns = jobs
      .slice(-5)
      .map((job: any) => ({
        id: job.id,
        kind: job.kind,
        status: job.status,
        durationMs: job.durationMs
      }));
  }

  return {
    timestamp: new Date().toISOString(),
    queueDepth,
    runningCount,
    lastRuns,
    admissionCap: parseInt(process.env.QUEUE_ADMISSION_CAP || '200', 10),
    shadowMode: config.shadow,
    driver: config.driver,
    lockPresent
  };
}

/**
 * Print formatted status
 */
export function printStatus(status: StatusOutput): void {
  console.log('📊 Agent Queue Status');
  console.log('═'.repeat(50));
  console.log(`⏰ Timestamp: ${status.timestamp}`);
  console.log(`🔒 Lock Present: ${status.lockPresent ? 'YES' : 'NO'}`);
  console.log(`⚙️  Driver: ${status.driver}`);
  console.log(`👻 Shadow Mode: ${status.shadowMode ? 'ON' : 'OFF'}`);
  console.log(`📋 Queue Depth: ${status.queueDepth}`);
  console.log(`🏃 Running: ${status.runningCount}`);
  console.log(`🚪 Admission Cap: ${status.admissionCap}`);
  
  if (status.lastRuns.length > 0) {
    console.log('\n📝 Last 5 Runs:');
    console.log('─'.repeat(50));
    status.lastRuns.forEach((run, index) => {
      const duration = run.durationMs ? ` (${run.durationMs}ms)` : '';
      const statusIcon = run.status === 'completed' ? '✅' : run.status === 'failed' ? '❌' : '🔄';
      console.log(`${index + 1}. ${statusIcon} ${run.id} [${run.kind}] ${run.status}${duration}`);
    });
  } else {
    console.log('\n📝 No recent runs');
  }

  console.log('\n🔧 Environment:');
  console.log(`   QUEUE_DRIVER=${process.env.QUEUE_DRIVER || 'json'}`);
  console.log(`   QUEUE_SHADOW=${process.env.QUEUE_SHADOW || '1'}`);
  console.log(`   QUEUE_ADMISSION_CAP=${process.env.QUEUE_ADMISSION_CAP || '200'}`);
  console.log(`   QUEUE_METRICS=${process.env.QUEUE_METRICS || '0'}`);
}

/**
 * CLI interface
 */
export async function runStatusCommand(): Promise<void> {
  try {
    const status = await getQueueStatus();
    
    // Print to console
    printStatus(status);
    
    // Write to file
    const fs = require('fs').promises;
    await fs.writeFile('.agent/status.json', JSON.stringify(status, null, 2), 'utf8');
    console.log('\n💾 Status written to .agent/status.json');
    
  } catch (error) {
    console.error('❌ Failed to get status:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (require.main === module) {
  runStatusCommand().catch(error => {
    console.error('Status command failed:', error);
    process.exit(1);
  });
}