/**
 * Agent Status Script
 * Shows queue depth, recent runs, and database health
 */

import { AgentDatabase, getQueueConfig } from './db';
import { existsSync } from 'fs';

function formatTimestamp(timestamp: number): string {
  return new Date(timestamp).toISOString();
}

function formatDuration(started: number, finished?: number): string {
  const end = finished || Date.now();
  const duration = end - started;
  
  if (duration < 1000) {
    return `${duration}ms`;
  } else if (duration < 60000) {
    return `${Math.round(duration / 1000)}s`;
  } else {
    return `${Math.round(duration / 60000)}m`;
  }
}

function main() {
  const config = getQueueConfig();
  
  console.log('=== Agent Queue Status ===');
  console.log(`Driver: ${config.driver}`);
  console.log(`WAL: ${config.wal ? 'enabled' : 'disabled'}`);
  console.log(`Shadow: ${config.shadow ? 'enabled' : 'disabled'}`);
  console.log(`Max Jobs: ${config.maxJobs}`);
  console.log(`Max Files: ${config.maxFiles}`);
  console.log(`Max Lines: ${config.maxLines}`);
  console.log('');

  if (config.driver !== 'sqlite') {
    console.log('Queue driver is not SQLite, showing JSON queue info...');
    
    if (existsSync('.agent/agent_queue.json')) {
      const fs = require('fs');
      const jsonContent = fs.readFileSync('.agent/agent_queue.json', 'utf8');
      const jobs = JSON.parse(jsonContent);
      console.log(`JSON Queue Depth: ${jobs.length}`);
      
      if (jobs.length > 0) {
        console.log('\nRecent Jobs:');
        jobs.slice(0, 5).forEach((job: any, index: number) => {
          console.log(`  ${index + 1}. ${job.id} (${job.type}) - Priority: ${job.priority}`);
        });
      }
    } else {
      console.log('JSON queue file not found');
    }
    
    return;
  }

  // SQLite database operations
  if (!existsSync('.agent/queue.db')) {
    console.log('SQLite database not found. Run migration first.');
    return;
  }

  const db = new AgentDatabase('.agent/queue.db', config.wal);
  
  try {
    // Queue depth
    const depth = db.getQueueDepth();
    console.log(`Queue Depth: ${depth}`);

    // Recent runs
    const recentRuns = db.getRecentRuns(5);
    console.log(`\nRecent Runs (${recentRuns.length}):`);
    
    if (recentRuns.length === 0) {
      console.log('  No recent runs');
    } else {
      recentRuns.forEach((run, index) => {
        const status = run.exit_code === null ? 'running' : 
                      run.exit_code === 0 ? 'completed' : 'failed';
        const duration = formatDuration(run.started_at, run.finished_at || undefined);
        
        console.log(`  ${index + 1}. ${run.job_id} - ${status} (${duration})`);
        if (run.exit_code !== null) {
          console.log(`     Exit Code: ${run.exit_code}`);
        }
      });
    }

    // Job status breakdown
    const statuses = ['pending', 'running', 'completed', 'failed'] as const;
    console.log('\nJob Status Breakdown:');
    
    statuses.forEach(status => {
      const jobs = db.getJobsByStatus(status, 100);
      if (jobs.length > 0) {
        console.log(`  ${status}: ${jobs.length}`);
      }
    });

    // Database health
    console.log('\nDatabase Health:');
    const integrity = db.integrityCheck();
    console.log(`  Integrity Check: ${integrity ? 'PASS' : 'FAIL'}`);
    
    if (config.wal) {
      const walSize = db.getWalSize();
      console.log(`  WAL Size: ${walSize} pages`);
    }

    // Cleanup info
    const cleaned = db.cleanupExpiredJobs();
    if (cleaned > 0) {
      console.log(`  Cleaned ${cleaned} expired jobs`);
    }

  } finally {
    db.close();
  }
}

// CLI interface
if (require.main === module) {
  main();
}



