// Gate #026 Track B: k6 Performance Thresholds
// Authority: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Fail CI on performance regression

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up
    { duration: '60s', target: 10 },  // Steady state
    { duration: '10s', target: 0 },   // Ramp down
  ],
  
  // Gate #026: Blocking thresholds
  thresholds: {
    // Error rate must be <1%
    http_req_failed: ['rate<0.01'],
    
    // Latency targets (aligned with Gate #025 optimized baseline)
    http_req_duration: [
      'p(50)<900',   // p50 ≤900ms (buffer vs 850ms aspirational)
      'p(95)<1200',  // p95 ≤1200ms (Gate #025 target)
      'p(99)<1500'   // p99 ≤1500ms
    ],
    
    // Throughput minimum
    http_reqs: ['rate>5'], // ≥5 req/s
  },
};

export default function () {
  // Gate #026 Track B: Test the dotnet-test-gate026 service (port 5555), NOT SigNoz UI
  const baseUrl = __ENV.BASE_URL || 'http://localhost:5555';
  
  // Test health endpoint
  const res = http.get(`${baseUrl}/health`);
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time OK': (r) => r.timings.duration < 1000,
  });
  
  sleep(1);
}

export function handleSummary(data) {
  // Gate #026: Write summary using k6's native file handling
  // Path relative to CWD (workspace root) where k6 runs
  return {
    'artifacts/k6-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, opts = {}) {
  const indent = opts.indent || '';
  
  let summary = `\nGate #026 Track B: Performance Gate Results\n`;
  summary += `===============================================\n\n`;
  
  const metrics = data.metrics;
  
  // Latency metrics
  if (metrics.http_req_duration && metrics.http_req_duration.values) {
    const p50 = metrics.http_req_duration.values['p(50)'];
    const p95 = metrics.http_req_duration.values['p(95)'];
    const p99 = metrics.http_req_duration.values['p(99)'];
    
    summary += `Latency:\n`;
    if (p50 !== undefined) {
      summary += `  p50: ${p50.toFixed(2)}ms (threshold: <900ms) ${p50 < 900 ? '✓ PASS' : '✗ FAIL'}\n`;
    }
    if (p95 !== undefined) {
      summary += `  p95: ${p95.toFixed(2)}ms (threshold: <1200ms) ${p95 < 1200 ? '✓ PASS' : '✗ FAIL'}\n`;
    }
    if (p99 !== undefined) {
      summary += `  p99: ${p99.toFixed(2)}ms (threshold: <1500ms) ${p99 < 1500 ? '✓ PASS' : '✗ FAIL'}\n`;
    }
    summary += `\n`;
  }
  
  // Error rate
  if (metrics.http_req_failed && metrics.http_req_failed.values) {
    const errorRate = metrics.http_req_failed.values.rate;
    if (errorRate !== undefined) {
      summary += `Error Rate: ${(errorRate * 100).toFixed(2)}% (threshold: <1%) ${errorRate < 0.01 ? '✓ PASS' : '✗ FAIL'}\n\n`;
    }
  }
  
  // Throughput
  if (metrics.http_reqs && metrics.http_reqs.values) {
    const reqRate = metrics.http_reqs.values.rate;
    if (reqRate !== undefined) {
      summary += `Throughput: ${reqRate.toFixed(2)} req/s (threshold: ≥5) ${reqRate >= 5 ? '✓ PASS' : '✗ FAIL'}\n\n`;
    }
  }
  
  // Overall verdict based on thresholds
  const thresholdsPassed = data.metrics.http_req_duration?.thresholds['p(50)<900']?.ok &&
                            data.metrics.http_req_duration?.thresholds['p(95)<1200']?.ok &&
                            data.metrics.http_req_failed?.thresholds['rate<0.01']?.ok &&
                            data.metrics.http_reqs?.thresholds['rate>5']?.ok;
  
  summary += `Overall: ${thresholdsPassed ? '✓ ALL THRESHOLDS PASSED' : '✗ SOME THRESHOLDS FAILED'}\n`;
  
  return summary;
}

