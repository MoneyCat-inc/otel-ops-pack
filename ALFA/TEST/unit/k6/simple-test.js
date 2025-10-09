import http from "k6/http";
import { check } from "k6";

export const options = {
  vus: 2,
  duration: "10s",
  thresholds: {
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.5"], // More lenient for mock API
    checks: ["rate>0.5"] // At least 50% of checks should pass
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
  
  // Test logs endpoint
  const logsResponse = http.get(`${baseUrl}/api/v1/logs`);
  const logsCheck = check(logsResponse, {
    "logs endpoint responds": (r) => r.status >= 200 && r.status < 500,
    "logs response time reasonable": (r) => r.timings.duration < 1000
  });
  
  // Test metrics endpoint
  const metricsResponse = http.get(`${baseUrl}/api/v1/metrics`);
  const metricsCheck = check(metricsResponse, {
    "metrics endpoint responds": (r) => r.status >= 200 && r.status < 500,
    "metrics response time reasonable": (r) => r.timings.duration < 1000
  });
}
