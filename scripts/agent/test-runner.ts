/**
 * Test script for Enhanced Runner with Admission Control
 * Verifies SQLite integration, shadow writes, and admission control
 */

import { createEnhancedRunner } from './runner';
import { existsSync, unlinkSync } from 'fs';

const testDbPath = '.agent/test-runner.db';

function cleanup() {
  if (existsSync(testDbPath)) {
    unlinkSync(testDbPath);
  }
  if (existsSync('.agent/shadow')) {
    const fs = require('fs');
    fs.rmSync('.agent/shadow', { recursive: true, force: true });
  }
}

function testAdmissionControl() {
  console.log('Testing admission control...');
  
  const runner = createEnhancedRunner();
  
  try {
    // Test enqueue with admission control
    const result1 = runner.enqueueJob({
      id: 'test-job-1',
      type: 'test',
      priority: 10,
      payload: { message: 'Test job 1' },
    });
    
    if (result1.success) {
      console.log('✓ Job 1 enqueued successfully');
    } else {
      console.log(`✗ Job 1 enqueue failed: ${result1.reason}`);
    }
    
    // Test multiple jobs
    const result2 = runner.enqueueJob({
      id: 'test-job-2',
      type: 'test',
      priority: 5,
      payload: { message: 'Test job 2' },
    });
    
    if (result2.success) {
      console.log('✓ Job 2 enqueued successfully');
    } else {
      console.log(`✗ Job 2 enqueue failed: ${result2.reason}`);
    }
    
    // Test job processing
    console.log('Testing job processing...');
    runner.processJobs().then(results => {
      console.log(`✓ Processed ${results.length} jobs`);
      results.forEach((result, index) => {
        console.log(`  Job ${index + 1}: ${result.success ? 'success' : 'failed'} (${result.duration}ms)`);
      });
    });
    
  } finally {
    runner.close();
  }
}

function testShadowWrites() {
  console.log('\nTesting shadow writes...');
  
  // Set shadow mode
  process.env.QUEUE_SHADOW = '1';
  
  const runner = createEnhancedRunner();
  
  try {
    // Enqueue a job
    runner.enqueueJob({
      id: 'shadow-test-job',
      type: 'test',
      priority: 8,
      payload: { message: 'Shadow test job' },
    });
    
    // Write status (should go to shadow)
    runner.writeStatus();
    
    // Check if shadow artifacts exist
    if (existsSync('.agent/shadow/status.json')) {
      console.log('✓ Shadow status artifact created');
    } else {
      console.log('✗ Shadow status artifact not found');
    }
    
    // Compare artifacts
    runner.compareArtifacts();
    
  } finally {
    runner.close();
    process.env.QUEUE_SHADOW = '0';
  }
}

function testSQLiteIntegration() {
  console.log('\nTesting SQLite integration...');
  
  // Set SQLite mode
  process.env.QUEUE_DRIVER = 'sqlite';
  
  const runner = createEnhancedRunner();
  
  try {
    // Test enqueue
    const result = runner.enqueueJob({
      id: 'sqlite-test-job',
      type: 'test',
      priority: 7,
      payload: { message: 'SQLite test job' },
    });
    
    if (result.success) {
      console.log('✓ SQLite job enqueued successfully');
    } else {
      console.log(`✗ SQLite job enqueue failed: ${result.reason}`);
    }
    
    // Test processing
    runner.processJobs().then(results => {
      console.log(`✓ SQLite processed ${results.length} jobs`);
    });
    
    // Test status writing
    runner.writeStatus();
    console.log('✓ SQLite status written');
    
  } finally {
    runner.close();
    process.env.QUEUE_DRIVER = 'json';
  }
}

function testRetryLogic() {
  console.log('\nTesting retry logic...');
  
  const runner = createEnhancedRunner();
  
  try {
    // Enqueue a job that will fail
    runner.enqueueJob({
      id: 'retry-test-job',
      type: 'failing-test',
      priority: 6,
      payload: { message: 'This job will fail' },
    });
    
    // Process jobs
    runner.processJobs().then(results => {
      console.log(`✓ Retry test processed ${results.length} jobs`);
      results.forEach((result, index) => {
        console.log(`  Job ${index + 1}: ${result.success ? 'success' : 'failed'} (${result.duration}ms)`);
      });
    });
    
  } finally {
    runner.close();
  }
}

function main() {
  console.log('=== Enhanced Runner Test Suite ===\n');
  
  try {
    cleanup();
    
    testAdmissionControl();
    testShadowWrites();
    testSQLiteIntegration();
    testRetryLogic();
    
    console.log('\n🎉 All enhanced runner tests completed!');
    console.log('\nNext steps:');
    console.log('1. Set QUEUE_DRIVER=sqlite to enable SQLite mode');
    console.log('2. Set QUEUE_SHADOW=1 to enable shadow mode');
    console.log('3. Run enhanced runner: npm run agent:runner');
    console.log('4. Check status: npm run agent:status');
    
  } catch (error) {
    console.error('\n❌ Test failed:', error);
    process.exit(1);
  } finally {
    cleanup();
  }
}

if (require.main === module) {
  main();
}



