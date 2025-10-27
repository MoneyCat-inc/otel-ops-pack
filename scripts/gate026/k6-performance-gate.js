// Gate #026 Track B: k6 Performance Gate with Thresholds
// Authority: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Load test with blocking thresholds (p50<=900ms, p95<=1200ms, error<1%)

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  // Thresholds: FAIL the test if these are violated
  thresholds: {
    // HTTP failures must be < 1%
    'http_req_failed': ['rate<0.01'],
    
    // P50 (median) must be <= 900ms
    'http_req_duration': ['p(50)<900', 'p(95)<1200'],
    
    // Custom error rate must be < 1%
    'errors': ['rate<0.01'],
  },

  // Load profile: 10 VUs for 30 seconds
  vus: 10,
  duration: '30s',

  // Don't abort on threshold failure (let it complete for full data)
  // But exit code will be non-zero
  noThresholds: false,
};

// Target endpoint (configurable via environment)
const BASE_URL = __ENV.TARGET_URL || 'http://localhost:5555';

export default function () {
  // Test 1: Root endpoint
  const rootRes = http.get(`${BASE_URL}/`);
  
  const rootCheck = check(rootRes, {
    'root status is 200': (r) => r.status === 200,
    'root response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!rootCheck);

  sleep(0.5);

  // Test 2: Health endpoint
  const healthRes = http.get(`${BASE_URL}/health`);
  
  const healthCheck = check(healthRes, {
    'health status is 200': (r) => r.status === 200,
    'health has service field': (r) => JSON.parse(r.body).service !== undefined,
  });
  
  errorRate.add(!healthCheck);

  sleep(0.5);

  // Test 3: Test endpoint (with outbound call)
  const testRes = http.get(`${BASE_URL}/test`);
  
  const testCheck = check(testRes, {
    'test status is 200': (r) => r.status === 200,
    'test response time < 2000ms': (r) => r.timings.duration < 2000, // Higher threshold for outbound call
  });
  
  errorRate.add(!testCheck);

  sleep(1);
}

// Summary handler
export function handleSummary(data) {
  // Return results for file output (configured in CI)
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, opts) {
  const indent = opts.indent || '';
  const enableColors = opts.enableColors !== undefined ? opts.enableColors : false;
  
  const green = enableColors ? '\x1b[32m' : '';
  const red = enableColors ? '\x1b[31m' : '';
  const yellow = enableColors ? '\x1b[33m' : '';
  const reset = enableColors ? '\x1b[0m' : '';

  let summary = '\n';
  summary += `${indent}=== Gate #026 k6 Performance Gate Results ===\n\n`;

  // Test summary
  const httpReqs = data.metrics.http_reqs;
  const httpReqFailed = data.metrics.http_req_failed;
  const httpReqDuration = data.metrics.http_req_duration;
  const errors = data.metrics.errors;

  summary += `${indent}📊 Request Stats:\n`;
  summary += `${indent}   Total Requests: ${httpReqs ? httpReqs.values.count : 0}\n`;
  summary += `${indent}   Failed: ${httpReqFailed ? (httpReqFailed.values.rate * 100).toFixed(2) : 0}%\n`;
  summary += `${indent}   Error Rate: ${errors ? (errors.values.rate * 100).toFixed(2) : 0}%\n`;

  summary += `\n${indent}⏱️  Response Times:\n`;
  if (httpReqDuration) {
    const p50 = httpReqDuration.values['p(50)'];
    const p95 = httpReqDuration.values['p(95)'];
    const avg = httpReqDuration.values.avg;

    const p50Status = p50 < 900 ? `${green}✅${reset}` : `${red}❌${reset}`;
    const p95Status = p95 < 1200 ? `${green}✅${reset}` : `${red}❌${reset}`;

    summary += `${indent}   Avg: ${avg.toFixed(2)}ms\n`;
    summary += `${indent}   P50: ${p50.toFixed(2)}ms ${p50Status} (threshold: <=900ms)\n`;
    summary += `${indent}   P95: ${p95.toFixed(2)}ms ${p95Status} (threshold: <=1200ms)\n`;
    summary += `${indent}   Max: ${httpReqDuration.values.max.toFixed(2)}ms\n`;
  }

  // Threshold results
  summary += `\n${indent}🚦 Threshold Results:\n`;
  const thresholdsPass = data.root_group.checks.passes === data.root_group.checks.value;
  
  for (const [name, threshold] of Object.entries(data.thresholds || {})) {
    const status = threshold.ok ? `${green}✅ PASS${reset}` : `${red}❌ FAIL${reset}`;
    summary += `${indent}   ${name}: ${status}\n`;
  }

  summary += `\n${indent}========================================\n`;
  if (Object.values(data.thresholds || {}).every(t => t.ok)) {
    summary += `${green}${indent}✅ Performance Gate: PASS${reset}\n`;
  } else {
    summary += `${red}${indent}❌ Performance Gate: FAIL (thresholds violated)${reset}\n`;
  }
  summary += `${indent}========================================\n\n`;

  return summary;
}

