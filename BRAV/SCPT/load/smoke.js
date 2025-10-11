import http from 'k6/http';
import { sleep, check } from 'k6';

const SITE = __ENV.SITE || 'ci';
const DEFAULT_BASE = 'https://httpbin.org';
const BASE_URL = __ENV.BASE_URL || DEFAULT_BASE;
const TARGET = __ENV.TARGET_URL || `${BASE_URL}/get`;

const targets = {
  ci:    { p95: 600, err: 0.015 },
  local: { p95: 500, err: 0.010 },
  prod:  { p95: 400, err: 0.005 },
};

export const options = {
  vus: Number(__ENV.VUS || 20),
  duration: __ENV.DURATION || '60s',
  thresholds: {
    http_req_failed: [ `rate<=${targets[SITE]?.err ?? 0.015}` ],
    http_req_duration: [ `p(95)<=${targets[SITE]?.p95 ?? 600}` ],
  },
};

export default function () {
  const res = http.get(TARGET);
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}

