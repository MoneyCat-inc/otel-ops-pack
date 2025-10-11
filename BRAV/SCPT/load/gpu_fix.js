// GPU_FIX k6 smoke with site-aware SLO gating
import http from 'k6/http';
import { check, sleep } from 'k6';

const TARGET_BASE = __ENV.TARGET_URL || 'https://httpbin.org';
const SLO_P95_MS = Number(__ENV.SLO_P95_MS || '500');
const SLO_ERR_RATE = Number(__ENV.SLO_ERR_RATE || '0.01');
const VUS = Number(__ENV.VUS || '20');
const DURATION = __ENV.DURATION || '60s';

export const options = {
  scenarios: {
    gpu_fix_smoke: {
      executor: 'constant-vus',
      vus: VUS,
      duration: DURATION,
      gracefulStop: '5s',
    },
  },
  thresholds: {
    http_req_failed: [`rate<${SLO_ERR_RATE}`],
    http_req_duration: [`p(95)<${SLO_P95_MS}`],
  },
  summaryTrendStats: ['avg', 'p(90)', 'p(95)', 'p(99)', 'min', 'max', 'count'],
};

export default function () {
  const res = http.get(`${TARGET_BASE}/get?gpu_fix=true`);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'latency < 3xSLO_P95': (r) => r.timings.duration < SLO_P95_MS * 3,
  });
  sleep(1);
}

