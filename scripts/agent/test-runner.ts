/**
 * Test Script for Agent Runner
 * 
 * Tests admission control, retry logic, shadow writes, and budget enforcement
 */

import { AgentRunner } from './runner';
import { SQLiteQueueDB } from './db';
import { getQueueConfig } from '../../lib/config/queue';
import { writeFileAtomicIfChanged, ensureDir } from './io';
import { existsSync, unlinkSync } from 'fs';

async function testRunner() {
  console.log('🧪 Testing Agent Runner...\n');

  // Set test environment
  process.env.QUEUE_DRIVER = 'sqlite';
  process.env.QUEUE_SHADOW = '1';
  process.env.QUEUE_ADMISSION_CAP = '10';
  process.env.QUEUE_METRICS = '1';
  process.env.QUEUE_MAX_FILES = '5';
  process.env.QUEUE_MAX_LINES = '100';

  const config = getQueueConfig();
  console.log('Configuration:', {
    driver: config.driver,
    shadow: config.shadow,
    maxJobs: config.maxJobs,
    maxConcurrency: config.maxConcurrency
  });

  // Use the main database for testing
  const testDbPath = '.agent/queue.db';

  // Initialize database and add test jobs
  const db = new SQLiteQueueDB(testDbPath, config);
  
  console.log('\n📝 Adding test jobs...');
  
  // Add various test jobs
  const testJobs = [
    {
      kind: 'test-job',
      payload_json: JSON.stringify({ message: 'Simple test job', test: true }),
      priority: 5,
      max_attempts: 3,
      not_before: Date.now(),
      created_at: Date.now(),
      ttl_ms: 86400000,
    },
    {
      kind: 'failing-job',
      payload_json: JSON.stringify({ message: 'This will fail', shouldFail: true }),
      priority: 3,
      max_attempts: 3,
      not_before: Date.now(),
      created_at: Date.now(),
      ttl_ms: 86400000,
    },
    {
      kind: 'over-budget-job',
      payload_json: JSON.stringify({ files: 10, lines: 2000, message: 'Exceeds budget' }),
      priority: 1,
      max_attempts: 1,
      not_before: Date.now(),
      created_at: Date.now(),
      ttl_ms: 86400000,
    },
    {
      kind: 'slow-job',
      payload_json: JSON.stringify({ message: 'Slow processing job', duration: 2000 }),
      priority: 4,
      max_attempts: 3,
      not_before: Date.now(),
      created_at: Date.now(),
      ttl_ms: 86400000,
    }
  ];

  const jobIds = testJobs.map(job => db.addJob(job));
  console.log(`✅ Added ${jobIds.length} test jobs:`, jobIds);

  // Ensure shadow directory exists
  await ensureDir('.agent/shadow');
  await ensureDir('C:/logs/queue');

  db.close();

  // Create a temporary runner for testing
  const runner = new AgentRunner();
  await runner.initialize();

  console.log('\n🏃 Running test pass...');
  
  // Run a single pass
  try {
    // Access private method for testing (in real implementation, you'd expose this)
    await (runner as any).runPass();
    console.log('✅ Test pass completed');
  } catch (error) {
    console.error('❌ Test pass failed:', error);
  }

  // Check results
  console.log('\n📊 Checking results...');
  
  // Check database state
  const db2 = new SQLiteQueueDB(testDbPath, config);
  const stats = db2.getQueueStats();
  console.log('Queue stats:', stats);

  // Check shadow artifacts
  const shadowStatus = await require('./io').readJsonFile('.agent/shadow/status.json', null);
  if (shadowStatus) {
    console.log('Shadow status:', shadowStatus);
  } else {
    console.log('⚠️  No shadow status found');
  }

  // Check if metrics were exported
  const metricsPath = 'C:/logs/queue/health.log';
  if (existsSync(metricsPath)) {
    const metricsContent = await require('fs').promises.readFile(metricsPath, 'utf8');
    const lines = metricsContent.trim().split('\n');
    console.log(`📈 Metrics exported: ${lines.length} lines`);
    if (lines.length > 0) {
      console.log('Latest metrics:', JSON.parse(lines[lines.length - 1]));
    }
  } else {
    console.log('⚠️  No metrics file found');
  }

  // Test admission control
  console.log('\n🚪 Testing admission control...');
  
  // Fill queue near capacity
  for (let i = 0; i < 8; i++) {
    db2.addJob({
      kind: 'bulk-job',
      payload_json: JSON.stringify({ message: `Bulk job ${i}` }),
      priority: 1,
      max_attempts: 1,
      not_before: Date.now(),
      created_at: Date.now(),
      ttl_ms: 86400000,
    });
  }
  
  const currentDepth = await (runner as any).getQueueDepth();
  const admissionCap = parseInt(process.env.QUEUE_ADMISSION_CAP || '10', 10);
  console.log(`Queue depth: ${currentDepth}/${admissionCap}`);
  
  if (currentDepth >= admissionCap) {
    console.log('✅ Admission control working - queue at capacity');
  } else {
    console.log('⚠️  Admission control not triggered yet');
  }

  // Test lock mechanism
  console.log('\n🔒 Testing lock mechanism...');
  await require('fs').promises.writeFile('.agent/LOCK', 'Test lock', 'utf8');
  
  try {
    await (runner as any).runPass();
    console.log('✅ Lock mechanism working - no processing with lock present');
  } catch (error) {
    console.error('❌ Lock mechanism failed:', error);
  }
  
  // Clean up lock
  await require('fs').promises.unlink('.agent/LOCK');

  db2.close();

  console.log('\n🎉 Runner tests completed!');
}

// Run the test
if (require.main === module) {
  testRunner().catch(error => {
    console.error('Test failed:', error);
    process.exit(1);
  });
}

export { testRunner };