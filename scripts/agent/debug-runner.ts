/**
 * Debug Script for Agent Runner
 * 
 * Simple debug to check job retrieval
 */

import { SQLiteQueueDB } from './db';
import { getQueueConfig } from '../../lib/config/queue';

async function debugRunner() {
  console.log('🔍 Debugging Agent Runner...\n');

  // Set test environment
  process.env['QUEUE_DRIVER'] = 'sqlite';
  process.env['QUEUE_SHADOW'] = '1';

  const config = getQueueConfig();
  console.log('Configuration:', config);

  // Initialize database
  const db = new SQLiteQueueDB('.agent/queue.db', config);
  
  console.log('\n📊 Current queue stats:');
  const stats = db.getQueueStats();
  console.log(stats);

  console.log('\n📝 All jobs in database:');
  const allJobs = db.getAllJobs();
  console.log('Total jobs:', allJobs.length);
  allJobs.forEach((job, index) => {
    console.log(`${index + 1}. ${job.id} [${job.kind}] status=${job.status} priority=${job.priority} not_before=${job.not_before} created_at=${job.created_at} ttl_ms=${job.ttl_ms}`);
  });

  console.log('\n🔍 Jobs ready to run:');
  const readyJobs = db.getNextJobs(10);
  console.log('Ready jobs:', readyJobs.length);
  readyJobs.forEach((job, index) => {
    console.log(`${index + 1}. ${job.id} [${job.kind}] status=${job.status}`);
  });

  console.log('\n⏰ Current time:', Date.now());

  db.close();
}

// Run the debug
if (require.main === module) {
  debugRunner().catch(error => {
    console.error('Debug failed:', error);
    process.exit(1);
  });
}
