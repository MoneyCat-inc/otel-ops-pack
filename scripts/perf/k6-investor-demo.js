// Investor Demo: k6 Performance Gate with Hard Thresholds
// Authority: BossCat OEM | Executor: Cursor{Implementer}
// Phase 2: Performance Gates - Auto-fail on SLA breach

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend, Rate } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics for demo visibility
const traceIds = new Counter('demo_trace_ids_generated');
const apiLatency = new Trend('demo_api_p95_latency');
const workerLatency = new Trend('demo_worker_p95_latency');
const errorRate = new Rate('demo_error_rate');

// Demo configuration
const SVC2_URL = __ENV.SVC2_URL || 'http://localhost:5556';
const SVC3_URL = __ENV.SVC3_URL || 'http://localhost:5557';
const DEMO_MODE = __ENV.DEMO_MODE || 'baseline'; // baseline | load | stress

// Workload profiles
export const options = {
  scenarios: {
    // Investor demo baseline (moderate load, clear signals)
    baseline: {
      executor: 'constant-vus',
      vus: 10,
      duration: '1m',
      gracefulStop: '5s',
      startTime: '0s',
      tags: { scenario: 'baseline', demo: 'investor' },
    },
  },

  // HARD THRESHOLDS - Pipeline fails on breach
  thresholds: {
    // P95 latency must be under 300ms (investor demo SLA)
    'http_req_duration{scenario:baseline}': [
      { threshold: 'p(95)<300', abortOnFail: true, delayAbortEval: '10s' },
      'p(50)<150',
    ],

    // Error rate must be under 1%
    'http_req_failed{scenario:baseline}': [
      { threshold: 'rate<0.01', abortOnFail: true, delayAbortEval: '10s' }
    ],

    // Request rate baseline (min 5 RPS sustained)
    'http_reqs{scenario:baseline}': ['rate>=5'],

    // Custom demo metrics
    'demo_api_p95_latency': ['p(95)<300'],
    'demo_worker_p95_latency': ['p(95)<350'],
    'demo_error_rate': ['rate<0.01'],
  },

  // Summary configuration
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(95)', 'p(99)'],
  summaryTimeUnit: 'ms',
};

// Trace context injection (for SigNoz correlation)
function generateTraceContext() {
  const traceId = randomString(32, '0123456789abcdef');
  const spanId = randomString(16, '0123456789abcdef');
  
  traceIds.add(1);
  
  return {
    'traceparent': `00-${traceId}-${spanId}-01`,
    'X-Demo-Trace-Id': traceId,
  };
}

// Test scenarios
export default function () {
  const traceHeaders = generateTraceContext();
  const demoHeaders = {
    ...traceHeaders,
    'X-Demo-Mode': 'investor',
    'X-Demo-Timestamp': new Date().toISOString(),
  };

  // 1. Health check (warm-up, not counted in thresholds)
  if (__ITER === 0) {
    http.get(`${SVC2_URL}/health`, { tags: { name: 'health' } });
    sleep(0.5);
  }

  // 2. API call to svc2 (primary demo path)
  const svc2Res = http.get(`${SVC2_URL}/test`, {
    headers: demoHeaders,
    tags: { name: 'svc2-api-test', service: 'bosscat-svc2-api' },
  });

  check(svc2Res, {
    'svc2 status 200': (r) => r.status === 200,
    'svc2 latency <500ms': (r) => r.timings.duration < 500,
  });

  apiLatency.add(svc2Res.timings.duration, { service: 'svc2-api' });
  errorRate.add(svc2Res.status !== 200);

  // 3. Direct worker call (secondary demo path)
  const svc3Res = http.get(`${SVC3_URL}/test`, {
    headers: generateTraceContext(),
    tags: { name: 'svc3-worker-test', service: 'bosscat-svc3-worker' },
  });

  check(svc3Res, {
    'svc3 status 200': (r) => r.status === 200,
    'svc3 latency <500ms': (r) => r.timings.duration < 500,
  });

  workerLatency.add(svc3Res.timings.duration, { service: 'svc3-worker' });
  errorRate.add(svc3Res.status !== 200);

  // Think time (realistic user behavior)
  sleep(1);
}

// Setup (runs once at start)
export function setup() {
  console.log('🎯 Investor Demo k6 Performance Gate');
  console.log(`   Target: ${SVC2_URL}, ${SVC3_URL}`);
  console.log(`   Mode: ${DEMO_MODE}`);
  console.log(`   Thresholds: p95<300ms, errors<1%`);
  console.log('');

  // Verify services accessible before load
  const svc2Health = http.get(`${SVC2_URL}/health`, { tags: { name: 'preflight' } });
  const svc3Health = http.get(`${SVC3_URL}/health`, { tags: { name: 'preflight' } });

  if (svc2Health.status !== 200 || svc3Health.status !== 200) {
    throw new Error('Services not healthy - aborting test');
  }

  return { startTime: new Date().toISOString() };
}

// Teardown (runs once at end)
export function teardown(data) {
  console.log('');
  console.log('=== Demo Performance Gate Summary ===');
  console.log(`   Start: ${data.startTime}`);
  console.log(`   End: ${new Date().toISOString()}`);
  console.log('   Thresholds enforced via k6 (exit code reflects pass/fail)');
  console.log('');
}

// Handle summary (export results)
export function handleSummary(data) {
  // Extract key metrics for demo
  const durationThresholds = data.metrics['http_req_duration{scenario:baseline}']?.thresholds || {};
  const failureThresholds = data.metrics['http_req_failed{scenario:baseline}']?.thresholds || {};
  const p95Pass = durationThresholds['p(95)<300']?.ok ?? false;
  const errorPass = failureThresholds['rate<0.01']?.ok ?? false;

  const summary = {
    demo: {
      timestamp: new Date().toISOString(),
      mode: DEMO_MODE,
      services: [SVC2_URL, SVC3_URL],
    },
    metrics: {
      requests_total: data.metrics.http_reqs.values.count,
      requests_per_sec: data.metrics.http_reqs.values.rate,
      p50_latency_ms: data.metrics.http_req_duration.values['p(50)'],
      p95_latency_ms: data.metrics.http_req_duration.values['p(95)'],
      p99_latency_ms: data.metrics.http_req_duration.values['p(99)'],
      error_rate: data.metrics.http_req_failed.values.rate,
      trace_ids_generated: data.metrics.demo_trace_ids_generated.values.count,
    },
    thresholds: {
      p95_pass: p95Pass,
      error_pass: errorPass,
      overall_pass: Object.values(data.metrics).every(m => 
        !m.thresholds || Object.values(m.thresholds).every(t => t.ok)
      ),
    },
    verdict: data.metrics.http_req_failed && 
             p95Pass &&
             errorPass
             ? 'GREEN' : 'RED',
  };

  return {
    'stdout': JSON.stringify(summary, null, 2),
    'artifacts/demo/k6-summary.json': JSON.stringify(data, null, 2),
    'artifacts/demo/k6-demo-results.json': JSON.stringify(summary, null, 2),
  };
}

