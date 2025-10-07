import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";
import { buildTestConfig, createSummary } from "./lib/summary.js";

const config = buildTestConfig({
  baseUrlDefault: "http://localhost:8080",
  vusDefault: 20,
  durationDefault: "30m",
  rampUpDefault: "2m",
  rampDownDefault: "2m"
});

const customErrorRate = new Rate("errors");
const soakDuration = new Trend("soak_duration");
const thresholds = {
  p95_ms: 1000,
  error_rate: 0.02,
  checks_failed: 0,
  requests_per_s_min: 1
};

export const options = {
  stages: [
    { duration: config.rampUp, target: config.vus },
    { duration: config.duration, target: config.vus },
    { duration: config.rampDown, target: 0 }
  ],
  thresholds: {
    http_req_duration: ["p(95)<1000"],
    http_req_failed: ["rate<0.02"],
    errors: ["rate<0.02"],
    soak_duration: ["p(90)<2000"],
    checks: ["rate==0"]
  }
};

const realisticQueries = [
  'message contains "canary test"',
  'attributes.dataset = "resonai_analytics"',
  'level = "error"',
  'service.name = "otelcol-contrib"',
  'otelcol_*'
];

export default function () {
  const baseUrl = config.baseUrl;
  const query = realisticQueries[Math.floor(Math.random() * realisticQueries.length)];

  const logsParams = {
    query,
    start: Math.floor(Date.now() / 1000) - 1800,
    end: Math.floor(Date.now() / 1000),
    limit: 100
  };

  const logsResponse = http.get(`${baseUrl}/api/v1/logs`, {
    params: logsParams,
    headers: { "Content-Type": "application/json" }
  });

  const logsCheck = check(logsResponse, {
    "logs soak test successful": (r) => r.status === 200,
    "logs soak response time stable": (r) => r.timings.duration < 2000,
    "logs response consistent": (r) => r.json && r.json("data") !== undefined
  });
  customErrorRate.add(!logsCheck);
  soakDuration.add(logsResponse.timings.duration);

  const metricsParams = {
    query: 'rate(otelcol_processor_batch_batch_send_size_sum[5m])',
    start: Math.floor(Date.now() / 1000) - 1800,
    end: Math.floor(Date.now() / 1000)
  };

  const metricsResponse = http.get(`${baseUrl}/api/v1/metrics`, {
    params: metricsParams,
    headers: { "Content-Type": "application/json" }
  });

  const metricsCheck = check(metricsResponse, {
    "metrics soak test successful": (r) => r.status === 200,
    "metrics soak response time stable": (r) => r.timings.duration < 1500
  });
  customErrorRate.add(!metricsCheck);
  soakDuration.add(metricsResponse.timings.duration);

  sleep(Math.random() * 3 + 2);
}

export function handleSummary(data) {
  return createSummary({
    testName: "soak",
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
