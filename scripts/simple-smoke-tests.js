#!/usr/bin/env node
// Resonai Backend - Simple Smoke Test Suite
// Basic connectivity and endpoint testing

const http = require('http');
const https = require('https');
const { URL } = require('url');

// Configuration
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';
const TEST_TIMEOUT = 10000; // 10 seconds

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

  printSummary() {
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
function makeRequest(endpoint, options = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${BASE_URL}${endpoint}`);
    const isHttps = url.protocol === 'https:';
    const client = isHttps ? https : http;
    
    const requestOptions = {
      hostname: url.hostname,
      port: url.port || (isHttps ? 443 : 80),
      path: url.pathname + url.search,
      method: options.method || 'GET',
      headers: {
        'User-Agent': 'Resonai-Smoke-Test/1.0',
        ...options.headers,
      },
      timeout: options.timeout || 10000,
    };

    const req = client.request(requestOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          data: data,
          ok: res.statusCode >= 200 && res.statusCode < 300,
        });
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('Request timeout')));
    
    if (options.body) {
      req.write(options.body);
    }
    
    req.end();
  });
}

function makeRequestWithBody(endpoint, body, options = {}) {
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

// Initialize test runner
const runner = new TestRunner();

// =============================================================================
// BASIC CONNECTIVITY TESTS
// =============================================================================

runner.addTest('Health Check Endpoint', async () => {
  const response = await makeRequest('/api/health');
  
  if (!response.ok) {
    throw new Error(`Health check failed: ${response.status} ${response.data}`);
  }
  
  try {
    const data = JSON.parse(response.data);
    if (data.status !== 'ok') {
      throw new Error(`Health check status not ok: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    throw new Error(`Invalid JSON response: ${response.data}`);
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
  
  const corsHeader = response.headers['access-control-allow-origin'];
  if (!corsHeader) {
    throw new Error('CORS headers not present');
  }
});

runner.addTest('Security Headers', async () => {
  const response = await makeRequest('/api/health');
  
  const requiredHeaders = [
    'x-frame-options',
    'x-content-type-options',
    'referrer-policy',
  ];
  
  for (const header of requiredHeaders) {
    if (!response.headers[header]) {
      throw new Error(`Missing security header: ${header}`);
    }
  }
});

// =============================================================================
// API ENDPOINT TESTS
// =============================================================================

runner.addTest('Events Batch Endpoint', async () => {
  const testEvent = {
    id: `test_${Date.now()}_${Math.random().toString(36).substring(7)}`,
    ts: Date.now(),
    userId: `test_user_${Math.random().toString(36).substring(7)}`,
    kind: 'session_start',
    props: {
      duration: 60000,
      sessionId: `session_${Math.random().toString(36).substring(7)}`,
    },
    schema: 'v1',
  };
  
  const response = await makeRequestWithBody('/api/events/batch', {
    events: [testEvent],
  });
  
  if (!response.ok) {
    throw new Error(`Events batch endpoint failed: ${response.status} ${response.data}`);
  }
  
  try {
    const data = JSON.parse(response.data);
    if (!data.ok) {
      throw new Error(`Events batch response not ok: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    throw new Error(`Invalid JSON response: ${response.data}`);
  }
});

runner.addTest('Story Chapters Endpoint', async () => {
  const response = await makeRequest('/api/story/chapters');
  
  if (!response.ok) {
    throw new Error(`Story chapters endpoint failed: ${response.status} ${response.data}`);
  }
  
  try {
    const data = JSON.parse(response.data);
    if (!data.success || !Array.isArray(data.data.chapters)) {
      throw new Error(`Invalid story chapters response: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    throw new Error(`Invalid JSON response: ${response.data}`);
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
    throw new Error(`Feedback endpoint failed: ${response.status} ${response.data}`);
  }
  
  try {
    const data = JSON.parse(response.data);
    if (!data.success || !data.data.feedbackId) {
      throw new Error(`Invalid feedback response: ${JSON.stringify(data)}`);
    }
  } catch (error) {
    throw new Error(`Invalid JSON response: ${response.data}`);
  }
});

// =============================================================================
// PRIVACY COMPLIANCE TESTS
// =============================================================================

runner.addTest('PII Prevention', async () => {
  // Test that PII is not accepted in event properties
  const testEvent = {
    id: `test_${Date.now()}_${Math.random().toString(36).substring(7)}`,
    ts: Date.now(),
    userId: `test_user_${Math.random().toString(36).substring(7)}`,
    kind: 'session_start',
    props: {
      email: 'test@example.com', // This should be rejected
      duration: 60000,
    },
    schema: 'v1',
  };
  
  try {
    const response = await makeRequestWithBody('/api/events/batch', {
      events: [testEvent],
    });
    
    if (response.ok) {
      throw new Error('PII should have been rejected');
    }
  } catch (error) {
    // Expected to fail
    if (!error.message.includes('4')) {
      throw new Error('Expected validation error for PII');
    }
  }
});

runner.addTest('Data Minimization', async () => {
  // Test that too many properties are rejected
  const testEvent = {
    id: `test_${Date.now()}_${Math.random().toString(36).substring(7)}`,
    ts: Date.now(),
    userId: `test_user_${Math.random().toString(36).substring(7)}`,
    kind: 'session_start',
    props: {},
    schema: 'v1',
  };
  
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
    if (!error.message.includes('4')) {
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
// PERFORMANCE TESTS
// =============================================================================

runner.addTest('Response Time Performance', async () => {
  const startTime = Date.now();
  
  const response = await makeRequest('/api/health');
  
  const duration = Date.now() - startTime;
  
  if (duration > 2000) {
    throw new Error(`Response time too slow: ${duration}ms`);
  }
  
  if (!response.ok) {
    throw new Error('Health check failed');
  }
});

runner.addTest('Concurrent Request Handling', async () => {
  const promises = [];
  for (let i = 0; i < 5; i++) {
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
    const response = await makeRequest('/api/events/batch', {
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
    if (!error.message.includes('4')) {
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
    if (!error.message.includes('4')) {
      throw new Error('Expected validation error for missing fields');
    }
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
