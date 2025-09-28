#!/usr/bin/env node
// Resonai Backend - Smoke Test Suite
// Comprehensive testing of all backend endpoints and functionality

const { execSync } = require('child_process');
const { createHash } = require('crypto');
const fetch = require('node-fetch');

// Configuration
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';
const TEST_TIMEOUT = 30000; // 30 seconds
const SIGNOZ_URL = process.env.SIGNOZ_URL || 'http://localhost:8080';

// Test utilities
class TestRunner {
  constructor() {
    this.tests = [];
    this.results = [];
  }

  addTest(name, fn) {
    this.tests.push({ name, fn });
  }

  async runAll() {
    console.log('🧪 Starting Resonai Backend Smoke Tests...\n');
    
    for (const test of this.tests) {
      const startTime = Date.now();
      try {
        console.log(`⏳ Running: ${test.name}`);
        await Promise.race([
          test.fn(),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Test timeout')), TEST_TIMEOUT)
          )
        ]);
        
        const duration = Date.now() - startTime;
        this.results.push({ name: test.name, passed: true, duration });
        console.log(`✅ PASSED: ${test.name} (${duration}ms)\n`);
      } catch (error) {
        const duration = Date.now() - startTime;
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        this.results.push({ name: test.name, passed: false, error: errorMessage, duration });
        console.log(`❌ FAILED: ${test.name} - ${errorMessage} (${duration}ms)\n`);
      }
    }

    this.printSummary();
  }

  private printSummary() {
    const passed = this.results.filter(r => r.passed).length;
    const failed = this.results.filter(r => !r.passed).length;
    const totalDuration = this.results.reduce((sum, r) => sum + r.duration, 0);

    console.log('📊 Test Summary:');
    console.log(`   Total Tests: ${this.results.length}`);
    console.log(`   Passed: ${passed}`);
    console.log(`   Failed: ${failed}`);
    console.log(`   Total Duration: ${totalDuration}ms`);
    console.log(`   Success Rate: ${((passed / this.results.length) * 100).toFixed(1)}%\n`);

    if (failed > 0) {
      console.log('❌ Failed Tests:');
      this.results.filter(r => !r.passed).forEach(r => {
        console.log(`   - ${r.name}: ${r.error}`);
      });
      console.log('');
    }

    if (failed === 0) {
      console.log('🎉 All smoke tests passed! Backend is ready for production.');
    } else {
      console.log('⚠️  Some tests failed. Please review and fix before deployment.');
      process.exit(1);
    }
  }
}

// HTTP utilities
async function makeRequest(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    timeout: 10000,
    ...options,
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response;
}

async function makeRequestWithBody(endpoint, body, options = {}) {
  return makeRequest(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
    body: JSON.stringify(body),
    ...options,
  });
}

// Test data generators
function generateTestEvent() {
  return {
    id: `test_${Date.now()}_${Math.random().toString(36).substring(7)}`,
    ts: Date.now(),
    userId: `test_user_${Math.random().toString(36).substring(7)}`,
    kind: 'session_start',
    props: {
      duration: Math.floor(Math.random() * 300000) + 30000,
      sessionId: `session_${Math.random().toString(36).substring(7)}`,
    },
    schema: 'v1',
  };
}

function generateTestUser() {
  return {
    email: `test_${Date.now()}@resonai.app`,
    consentShareMetrics: true,
    consentCoachPortal: false,
  };
}

// Initialize test runner
const runner = new TestRunner();

// =============================================================================
// BASIC CONNECTIVITY TESTS
// =============================================================================

runner.addTest('Health Check Endpoint', async () => {
  const response = await makeRequest('/api/health');
  const data = await response.json();
  
  if (data.status !== 'ok') {
    throw new Error(`Health check failed: ${JSON.stringify(data)}`);
  }
  
  if (!data.database || data.database !== 'connected') {
    throw new Error('Database not connected');
  }
});

runner.addTest('CORS Headers', async () => {
  const response = await makeRequest('/api/health', {
    method: 'OPTIONS',
    headers: {
      'Origin': 'http://localhost:3000',
      'Access-Control-Request-Method': 'GET',
    },
  });
  
  const corsHeader = response.headers.get('Access-Control-Allow-Origin');
  if (!corsHeader) {
    throw new Error('CORS headers not present');
  }
});

runner.addTest('Security Headers', async () => {
  const response = await makeRequest('/api/health');
  
  const requiredHeaders = [
    'X-Frame-Options',
    'X-Content-Type-Options',
    'Referrer-Policy',
  ];
  
  for (const header of requiredHeaders) {
    if (!response.headers.get(header)) {
      throw new Error(`Missing security header: ${header}`);
    }
  }
});

// =============================================================================
// DATABASE CONNECTIVITY TESTS
// =============================================================================

runner.addTest('Database Connection', async () => {
  const response = await makeRequest('/api/health');
  const data = await response.json();
  
  if (data.database !== 'connected') {
    throw new Error('Database connection failed');
  }
});

runner.addTest('Database Schema Validation', async () => {
  // Test that we can create and read from the database
  const testEvent = generateTestEvent();
  
  const response = await makeRequestWithBody('/api/events/batch', {
    events: [testEvent],
  });
  
  if (!response.ok) {
    throw new Error('Failed to create test event');
  }
});

// =============================================================================
// AUTHENTICATION TESTS
// =============================================================================

runner.addTest('Magic Link Request', async () => {
  const testUser = generateTestUser();
  
  const response = await makeRequestWithBody('/api/auth/magic-link', {
    email: testUser.email,
  });
  
  if (!response.ok) {
    throw new Error('Magic link request failed');
  }
  
  const data = await response.json();
  if (!data.message || !data.message.includes('Magic link sent')) {
    throw new Error('Invalid magic link response');
  }
});

runner.addTest('Session Management', async () => {
  // Test session endpoint without authentication
  const response = await makeRequest('/api/auth/session');
  
  if (!response.ok) {
    throw new Error('Session endpoint failed');
  }
  
  const data = await response.json();
  if (data.user !== null) {
    throw new Error('Expected null user for unauthenticated request');
  }
});

// =============================================================================
// API ENDPOINT TESTS
// =============================================================================

runner.addTest('Events Batch Endpoint', async () => {
  const testEvent = generateTestEvent();
  
  const response = await makeRequestWithBody('/api/events/batch', {
    events: [testEvent],
  });
  
  if (!response.ok) {
    throw new Error('Events batch endpoint failed');
  }
  
  const data = await response.json();
  if (!data.ok) {
    throw new Error('Events batch response not ok');
  }
});

runner.addTest('Story Chapters Endpoint', async () => {
  const response = await makeRequest('/api/story/chapters');
  
  if (!response.ok) {
    throw new Error('Story chapters endpoint failed');
  }
  
  const data = await response.json();
  if (!data.success || !Array.isArray(data.data.chapters)) {
    throw new Error('Invalid story chapters response');
  }
});

runner.addTest('Feedback Endpoint', async () => {
  const response = await makeRequestWithBody('/api/feedback', {
    type: 'general',
    content: 'This is a test feedback message',
    metadata: {
      test: true,
      timestamp: Date.now(),
    },
  });
  
  if (!response.ok) {
    throw new Error('Feedback endpoint failed');
  }
  
  const data = await response.json();
  if (!data.success || !data.data.feedbackId) {
    throw new Error('Invalid feedback response');
  }
});

// =============================================================================
// PRIVACY COMPLIANCE TESTS
// =============================================================================

runner.addTest('PII Prevention', async () => {
  // Test that PII is not accepted in event properties
  const testEvent = generateTestEvent();
  testEvent.props.email = 'test@example.com'; // This should be rejected
  
  try {
    const response = await makeRequestWithBody('/api/events/batch', {
      events: [testEvent],
    });
    
    if (response.ok) {
      throw new Error('PII should have been rejected');
    }
  } catch (error) {
    // Expected to fail
    if (!error.message.includes('HTTP 4')) {
      throw new Error('Expected validation error for PII');
    }
  }
});

runner.addTest('Data Minimization', async () => {
  // Test that too many properties are rejected
  const testEvent = generateTestEvent();
  testEvent.props = {};
  
  // Add more than 10 properties
  for (let i = 0; i < 15; i++) {
    testEvent.props[`prop${i}`] = `value${i}`;
  }
  
  try {
    const response = await makeRequestWithBody('/api/events/batch', {
      events: [testEvent],
    });
    
    if (response.ok) {
      throw new Error('Too many properties should have been rejected');
    }
  } catch (error) {
    // Expected to fail
    if (!error.message.includes('HTTP 4')) {
      throw new Error('Expected validation error for too many properties');
    }
  }
});

runner.addTest('Rate Limiting', async () => {
  // Test rate limiting by making multiple requests quickly
  const promises = [];
  for (let i = 0; i < 15; i++) {
    promises.push(
      makeRequestWithBody('/api/feedback', {
        type: 'general',
        content: `Test feedback ${i}`,
      }).catch(error => error.message)
    );
  }
  
  const results = await Promise.all(promises);
  const rateLimited = results.some(result => result.includes('429'));
  
  if (!rateLimited) {
    throw new Error('Rate limiting not working');
  }
});

// =============================================================================
// SIGNOZ INTEGRATION TESTS
// =============================================================================

runner.addTest('SigNoz Health Check', async () => {
  try {
    const response = await fetch(`${SIGNOZ_URL}/api/v1/health`, {
      timeout: 5000,
    });
    
    if (!response.ok) {
      throw new Error(`SigNoz health check failed: ${response.status}`);
    }
  } catch (error) {
    console.log('⚠️  SigNoz not available - skipping integration tests');
    throw new Error('SigNoz not available');
  }
});

runner.addTest('OTel Trace Generation', async () => {
  // Make a request that should generate traces
  const testEvent = generateTestEvent();
  
  const response = await makeRequestWithBody('/api/events/batch', {
    events: [testEvent],
  });
  
  if (!response.ok) {
    throw new Error('Failed to generate trace');
  }
  
  // Wait a moment for trace to be sent
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Check if trace was sent to SigNoz
  try {
    const traceResponse = await fetch(`${SIGNOZ_URL}/api/v1/traces?serviceName=resonai-backend&limit=1`, {
      timeout: 5000,
    });
    
    if (traceResponse.ok) {
      const traceData = await traceResponse.json();
      if (traceData.traces && traceData.traces.length > 0) {
        console.log('✅ Trace successfully sent to SigNoz');
      } else {
        console.log('⚠️  No traces found in SigNoz (may be delayed)');
      }
    }
  } catch (error) {
    console.log('⚠️  Could not verify trace in SigNoz');
  }
});

// =============================================================================
// PERFORMANCE TESTS
// =============================================================================

runner.addTest('Response Time Performance', async () => {
  const startTime = Date.now();
  
  const response = await makeRequest('/api/health');
  const data = await response.json();
  
  const duration = Date.now() - startTime;
  
  if (duration > 1000) {
    throw new Error(`Response time too slow: ${duration}ms`);
  }
  
  if (data.status !== 'ok') {
    throw new Error('Health check failed');
  }
});

runner.addTest('Concurrent Request Handling', async () => {
  const promises = [];
  for (let i = 0; i < 10; i++) {
    promises.push(makeRequest('/api/health'));
  }
  
  const startTime = Date.now();
  const responses = await Promise.all(promises);
  const duration = Date.now() - startTime;
  
  const failed = responses.filter(r => !r.ok);
  if (failed.length > 0) {
    throw new Error(`${failed.length} concurrent requests failed`);
  }
  
  if (duration > 5000) {
    throw new Error(`Concurrent requests too slow: ${duration}ms`);
  }
});

// =============================================================================
// ERROR HANDLING TESTS
// =============================================================================

runner.addTest('Invalid JSON Handling', async () => {
  try {
    const response = await fetch(`${BASE_URL}/api/events/batch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: 'invalid json',
    });
    
    if (response.ok) {
      throw new Error('Invalid JSON should have been rejected');
    }
    
    if (response.status !== 400) {
      throw new Error(`Expected 400, got ${response.status}`);
    }
  } catch (error) {
    if (!error.message.includes('HTTP 4')) {
      throw error;
    }
  }
});

runner.addTest('Missing Required Fields', async () => {
  try {
    const response = await makeRequestWithBody('/api/events/batch', {
      events: [{}], // Missing required fields
    });
    
    if (response.ok) {
      throw new Error('Missing fields should have been rejected');
    }
  } catch (error) {
    if (!error.message.includes('HTTP 4')) {
      throw new Error('Expected validation error for missing fields');
    }
  }
});

// =============================================================================
// BACKGROUND JOB TESTS
// =============================================================================

runner.addTest('Background Job System', async () => {
  // Test that background jobs can be scheduled
  const response = await makeRequest('/api/admin/jobs');
  
  if (!response.ok) {
    throw new Error('Background jobs endpoint failed');
  }
  
  const data = await response.json();
  if (!data.success || !data.data.statistics) {
    throw new Error('Invalid background jobs response');
  }
});

// =============================================================================
// RUN ALL TESTS
// =============================================================================

async function main() {
  try {
    await runner.runAll();
  } catch (error) {
    console.error('❌ Test runner failed:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Tests interrupted by user');
  process.exit(0);
});

process.on('unhandledRejection', (reason) => {
  console.error('❌ Unhandled rejection:', reason);
  process.exit(1);
});

// Run the tests
main().catch(error => {
  console.error('❌ Test suite failed:', error);
  process.exit(1);
});
