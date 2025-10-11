import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";
import { buildTestConfig, createSummary } from "./lib/summary.js";

const config = buildTestConfig({
  baseUrlDefault: "http://localhost:8080",
  vusDefault: 10,
  durationDefault: "30s",
  rampUpDefault: "5s",
  rampDownDefault: "5s"
});

const customErrorRate = new Rate("errors");
const thresholds = {
  p95_ms: 200,
  error_rate: 0.01,
  checks_failed: 0
};

export const options = {
  stages: [
    { duration: config.rampUp, target: config.vus },
    { duration: config.duration, target: config.vus },
    { duration: config.rampDown, target: 0 }
  ],
  thresholds: {
    http_req_duration: ["p(95)<200"],
    http_req_failed: ["rate<0.01"],
    checks: ["rate==0"]
  }
};

export default function () {
  const baseUrl = config.baseUrl;

  const authHeader = __ENV.SIGNOZ_API_KEY ? { 'Authorization': `Api-Key ${__ENV.SIGNOZ_API_KEY}` } : {};
  const baseHeaders = { 'Content-Type': 'application/json', ...authHeader };

  const healthResponse = http.get(`${baseUrl}/api/v1/health`, { headers: baseHeaders });
  const healthCheck = check(healthResponse, {
    "health endpoint status is 200": (r) => r.status === 200,
    "health response time < 100ms": (r) => r.timings.duration < 100
  });
  customErrorRate.add(!healthCheck);

  const logsResponse = http.get(`${baseUrl}/api/v1/logs`, { headers: baseHeaders });
  const logsCheck = check(logsResponse, {
    "logs endpoint status is 200": (r) => r.status === 200,
    "logs response time < 500ms": (r) => r.timings.duration < 500
  });
  customErrorRate.add(!logsCheck);

  const metricsResponse = http.get(`${baseUrl}/api/v1/metrics`, { headers: baseHeaders });
  const metricsCheck = check(metricsResponse, {
    "metrics endpoint status is 200": (r) => r.status === 200,
    "metrics response time < 300ms": (r) => r.timings.duration < 300
  });
  customErrorRate.add(!metricsCheck);

  sleep(1);
}

export function handleSummary(data) {
  return createSummary({
    testName: "baseline",
    data,
    thresholds,
    metadata: {
      base_url: config.baseUrl,
      vus: config.vus,
      duration: config.duration,
      ramp_up: config.rampUp,
      ramp_down: config.rampDown
    }
  });
}
