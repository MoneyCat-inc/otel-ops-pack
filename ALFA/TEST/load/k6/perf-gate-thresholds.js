// Performance Gate - k6 Thresholds
// Lane: SSOT | Owner: AUTO-BOTS-SSOT-ALFA
// Authority: BossCat OEM P1-D
// DoD: CI fails on threshold breach

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 5 },  // Ramp up
    { duration: '20s', target: 10 }, // Sustain
    { duration: '10s', target: 0 },  // Ramp down
  ],
  thresholds: {
    // BossCat Performance SLOs (sub-200ms headline)
    http_req_duration: ['p(95)<200'],        // p95 < 200ms ✅
    http_req_failed: ['rate<0.01'],          // error rate < 1% ✅
    checks: ['rate>=0.99'],                  // pass rate ≥ 99% ✅
    
    // Additional monitoring (non-gating)
    http_req_duration: ['p(50)<100'],        // p50 < 100ms (monitor)
    http_req_duration: ['max<500'],          // max < 500ms (monitor)
  },
};

export default function () {
  // Target: SigNoz health endpoint (lightweight)
  const res = http.get('http://localhost:8080/api/v1/health');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time <200ms': (r) => r.timings.duration < 200,
  });
  
  sleep(0.1); // 100ms think time
}

