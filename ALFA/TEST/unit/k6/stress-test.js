import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";
import { buildTestConfig, createSummary } from "./lib/summary.js";

const config = buildTestConfig({
  baseUrlDefault: "http://localhost:8080",
  vusDefault: 100,
  durationDefault: "5m",
  rampUpDefault: "1m",
  rampDownDefault: "1m"
});

const customErrorRate = new Rate("errors");
const stressDuration = new Trend("stress_duration");
const thresholds = {
  p95_ms: 2000,
  error_rate: 0.1,
  checks_failed: 0,
  requests_per_s_min: 10
};

export const options = {
  stages: [
    { duration: config.rampUp, target: config.vus },
    { duration: config.duration, target: config.vus },
    { duration: config.rampDown, target: 0 }
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"],
    http_req_failed: ["rate<0.1"],
    errors: ["rate<0.1"],
    stress_duration: ["p(90)<3000"],
    checks: ["rate==0"]
  }
};

const complexQueries = [
  'message contains "canary test" AND level = "info" AND attributes.dataset = "resonai_analytics"',
  'otelcol_processor_batch_batch_send_size_sum > 1000 AND otelcol_processor_batch_batch_send_size_count > 10',
  'service.name = "otelcol-contrib" AND resource.attributes.host.name contains "windows"',
  'trace_id != "" AND span_id != "" AND parent_span_id = ""',
  'attributes.http.method = "POST" AND attributes.http.status_code >= 400'
];

export default function () {
  const baseUrl = config.baseUrl;
  const query = complexQueries[Math.floor(Math.random() * complexQueries.length)];

  const logsParams = {
    query,
    start: Math.floor(Date.now() / 1000) - 7200,
    end: Math.floor(Date.now() / 1000),
    limit: 1000
  };

  const logsResponse = http.get(`${baseUrl}/api/v1/logs`, {
    params: logsParams,
    headers: { "Content-Type": "application/json" },
    timeout: "10s"
  });

  const logsCheck = check(logsResponse, {
    "logs stress test successful": (r) => r.status === 200,
    "logs stress response time acceptable": (r) => r.timings.duration < 5000
  });
  customErrorRate.add(!logsCheck);
  stressDuration.add(logsResponse.timings.duration);

  const metricsParams = {
    query: 'rate(otelcol_processor_batch_batch_send_size_sum[1m]) / rate(otelcol_processor_batch_batch_send_size_count[1m])',
    start: Math.floor(Date.now() / 1000) - 7200,
    end: Math.floor(Date.now() / 1000)
  };

  const metricsResponse = http.get(`${baseUrl}/api/v1/metrics`, {
    params: metricsParams,
    headers: { "Content-Type": "application/json" },
    timeout: "10s"
  });

  const metricsCheck = check(metricsResponse, {
    "metrics stress test successful": (r) => r.status === 200,
    "metrics stress response time acceptable": (r) => r.timings.duration < 3000
  });
  customErrorRate.add(!metricsCheck);
  stressDuration.add(metricsResponse.timings.duration);

  sleep(0.1);
}

export function handleSummary(data) {
  return createSummary({
    testName: "stress",
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
