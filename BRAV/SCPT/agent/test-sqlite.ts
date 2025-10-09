/**
 * Simple test script for SQLite DAL
 * Run with: npx tsx scripts/agent/test-sqlite.ts
 */

import { SQLiteQueueDB } from './db';
import { getQueueConfig, describeQueueConfig } from '../../lib/config/queue';
import { unlinkSync } from 'fs';

async function testSQLiteDAL() {
  console.log('🧪 Testing SQLite Queue DAL...\n');

  const config = getQueueConfig();
  console.log('Configuration:', describeQueueConfig(config));

  const dbPath = '.agent/test-queue.db';
  
  // Clean up any existing test database
  try {
    unlinkSync(dbPath);
  } catch (error) {
    // File doesn't exist, that's fine
  }

  const db = new SQLiteQueueDB(dbPath, config);

  try {
    // Test 1: Add a job
    console.log('\n📝 Test 1: Adding a job...');
    const jobId = db.addJob({
      kind: 'test-job',
      payload_json: JSON.stringify({ message: 'Hello from SQLite!', timestamp: Date.now() }),
      priority: 5,
      max_attempts: 3,
      not_before: Date.now(),
      created_at: Date.now(),
      ttl_ms: 86400000, // 24 hours
    });
    console.log(`✅ Job added with ID: ${jobId}`);

    // Test 2: Retrieve the job
    console.log('\n🔍 Test 2: Retrieving the job...');
    const job = db.getJob(jobId);
    if (job) {
      console.log(`✅ Job retrieved:`, {
        id: job.id,
        kind: job.kind,
        priority: job.priority,
        status: job.status,
        attempts: job.attempts,
      });
    } else {
      console.log('❌ Job not found');
      return;
    }

    // Test 3: Get next jobs
    console.log('\n📋 Test 3: Getting next jobs...');
    const nextJobs = db.getNextJobs(10);
    console.log(`✅ Found ${nextJobs.length} jobs ready to run`);
    nextJobs.forEach((job, index) => {
      console.log(`  ${index + 1}. ${job.kind} (priority: ${job.priority})`);
    });

    // Test 4: Mark job as running
    console.log('\n🏃 Test 4: Marking job as running...');
    const runningSuccess = db.markJobRunning(jobId);
    console.log(`✅ Job marked as running: ${runningSuccess}`);

    const runningJob = db.getJob(jobId);
    console.log(`   Status: ${runningJob?.status}, Attempts: ${runningJob?.attempts}`);

    // Test 5: Add a run record
    console.log('\n📊 Test 5: Adding run record...');
    const runId = db.addRun({
      job_id: jobId,
      started_at: Date.now(),
      finished_at: Date.now() + 1000,
      exit_code: 0,
      stdout: 'Test completed successfully',
      stderr: '',
      metrics_json: JSON.stringify({
        duration_ms: 1000,
        memory_mb: 128,
        cpu_percent: 5.2,
      }),
    });
    console.log(`✅ Run record added with ID: ${runId}`);

    // Test 6: Mark job as completed
    console.log('\n✅ Test 6: Marking job as completed...');
    const completedSuccess = db.markJobCompleted(jobId);
    console.log(`✅ Job marked as completed: ${completedSuccess}`);

    const completedJob = db.getJob(jobId);
    console.log(`   Final status: ${completedJob?.status}`);

    // Test 7: Get queue statistics
    console.log('\n📈 Test 7: Queue statistics...');
    const stats = db.getQueueStats();
    console.log(`✅ Queue stats:`, stats);

    // Test 8: Get job runs
    console.log('\n📋 Test 8: Job runs...');
    const runs = db.getJobRuns(jobId);
    console.log(`✅ Found ${runs.length} runs for job ${jobId}`);
    runs.forEach((run, index) => {
      console.log(`  ${index + 1}. Run ${run.id}: exit_code=${run.exit_code}, duration=${(run.finished_at || 0) - run.started_at}ms`);
    });

    // Test 9: Integrity check
    console.log('\n🔍 Test 9: Database integrity check...');
    const integrity = db.integrityCheck();
    console.log(`✅ Integrity check: ${integrity.status}`);
    if (integrity.details) {
      console.log(`   Details: ${integrity.details}`);
    }

    console.log('\n🎉 All tests completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error);
    throw error;
  } finally {
    db.close();
    
    // Clean up test database
    try {
      unlinkSync(dbPath);
      console.log('\n🧹 Cleaned up test database');
    } catch (error) {
      console.log('\n⚠️  Could not clean up test database:', error);
    }
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  testSQLiteDAL().catch(error => {
    console.error('Test suite failed:', error);
    process.exit(1);
  });
}

export { testSQLiteDAL };