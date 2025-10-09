import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";
import { buildTestConfig, createSummary } from "./lib/summary.js";

const config = buildTestConfig({
  baseUrlDefault: "http://localhost:8080",
  vusDefault: 50,
  durationDefault: "2m",
  rampUpDefault: "30s",
  rampDownDefault: "30s"
});

const customErrorRate = new Rate("errors");
const queryDuration = new Trend("query_duration");
const thresholds = {
  p95_ms: 500,
  error_rate: 0.05,
  checks_failed: 0,
  requests_per_s_min: 5
};

export const options = {
  stages: [
    { duration: config.rampUp, target: config.vus },
    { duration: config.duration, target: config.vus },
    { duration: config.rampDown, target: 0 }
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed: ["rate<0.05"],
    errors: ["rate<0.05"],
    query_duration: ["p(90)<1000"],
    checks: ["rate==0"]
  }
};

const queries = [
  'message contains "canary test"',
  'attributes.dataset = "resonai_analytics"',
  'otelcol_*',
  'level = "error"',
  'service.name = "otelcol-contrib"'
];

export default function () {
  const baseUrl = config.baseUrl;
  const query = queries[Math.floor(Math.random() * queries.length)];

  const logsParams = {
    query,
    start: Math.floor(Date.now() / 1000) - 3600,
    end: Math.floor(Date.now() / 1000),
    limit: 100
  };

  const logsResponse = http.get(`${baseUrl}/api/v1/logs`, {
    params: logsParams,
    headers: { "Content-Type": "application/json" }
  });

  const logsCheck = check(logsResponse, {
    "logs query successful": (r) => r.status === 200,
    "logs response time acceptable": (r) => r.timings.duration < 2000,
    "logs response has data": (r) => r.json && r.json("data") !== undefined
  });
  customErrorRate.add(!logsCheck);
  queryDuration.add(logsResponse.timings.duration);

  const metricsParams = {
    query: 'rate(otelcol_processor_batch_batch_send_size_sum[5m])',
    start: Math.floor(Date.now() / 1000) - 3600,
    end: Math.floor(Date.now() / 1000)
  };

  const metricsResponse = http.get(`${baseUrl}/api/v1/metrics`, {
    params: metricsParams,
    headers: { "Content-Type": "application/json" }
  });

  const metricsCheck = check(metricsResponse, {
    "metrics query successful": (r) => r.status === 200,
    "metrics response time acceptable": (r) => r.timings.duration < 1500
  });
  customErrorRate.add(!metricsCheck);
  queryDuration.add(metricsResponse.timings.duration);

  sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
  return createSummary({
    testName: "load",
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
