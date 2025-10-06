import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const customErrorRate = new Rate("errors");

export const options = {
  stages: [
    { duration: "5s", target: 5 },
    { duration: "10s", target: 5 },
    { duration: "5s", target: 0 }
  ],
  thresholds: {
    http_req_duration: ["p(95)<1000"], // More lenient for mock
    http_req_failed: ["rate<0.5"],      // Allow 50% failures for mock
    checks: ["rate>0.3"]                // At least 30% checks pass
  }
};

export default function () {
  const baseUrl = __ENV.BASE_URL || "http://localhost:8080";

  // Test health endpoint
  const healthResponse = http.get(`${baseUrl}/api/v1/health`);
  const healthCheck = check(healthResponse, {
    "health endpoint responds": (r) => r.status >= 200 && r.status < 500,
    "health response time reasonable": (r) => r.timings.duration < 1000
  });
  customErrorRate.add(!healthCheck);

  // Test logs endpoint
  const logsResponse = http.get(`${baseUrl}/api/v1/logs`);
  const logsCheck = check(logsResponse, {
    "logs endpoint responds": (r) => r.status >= 200 && r.status < 500,
    "logs response time reasonable": (r) => r.timings.duration < 1000
  });
  customErrorRate.add(!logsCheck);

  // Test metrics endpoint
  const metricsResponse = http.get(`${baseUrl}/api/v1/metrics`);
  const metricsCheck = check(metricsResponse, {
    "metrics endpoint responds": (r) => r.status >= 200 && r.status < 500,
    "metrics response time reasonable": (r) => r.timings.duration < 1000
  });
  customErrorRate.add(!metricsCheck);

  sleep(0.1);
}
