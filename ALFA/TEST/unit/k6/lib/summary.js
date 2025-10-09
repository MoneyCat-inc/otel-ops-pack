import { parseFloatSafe, parseIntSafe } from './utils.js';

export function buildTestConfig({
  baseUrlDefault,
  vusDefault,
  durationDefault,
  rampUpDefault,
  rampDownDefault,
  extraEnv = {}
}) {
  const env = typeof __ENV === 'undefined' ? {} : __ENV;
  return {
    baseUrl: (env.BASE_URL || baseUrlDefault || 'http://localhost:8080').trim(),
    vus: parseIntSafe(env.VUS, vusDefault ?? 1),
    duration: (env.DURATION || durationDefault || '30s').trim(),
    rampUp: (env.RAMP_UP || rampUpDefault || '0s').trim(),
    rampDown: (env.RAMP_DOWN || rampDownDefault || '0s').trim(),
    extra: Object.entries(extraEnv).reduce((acc, [key, fallback]) => {
      acc[key] = env[key] || fallback;
      return acc;
    }, {})
  };
}

export function gatherHttpMetrics(data) {
  const metrics = (data && data.metrics) || {};
  const duration = metrics.http_req_duration?.values || {};
  const failed = metrics.http_req_failed?.values || {};
  const requests = metrics.http_reqs?.values || {};
  const checks = metrics.checks?.values || {};
  const iterations = metrics.iterations?.values || {};

  const toNumber = (val) => parseFloatSafe(val, 0);

  return {
    p95_ms: toNumber(duration['p(95)']),
    p99_ms: toNumber(duration['p(99)']),
    avg_ms: toNumber(duration.avg),
    med_ms: toNumber(duration.med),
    min_ms: toNumber(duration.min),
    max_ms: toNumber(duration.max),
    error_rate: toNumber(failed.rate),
    error_count: toNumber(failed.count),
    requests: toNumber(requests.count),
    requests_per_s: toNumber(requests.rate),
    checks_failed: toNumber(checks.fails),
    checks_passed: toNumber(checks.passes),
    iterations: toNumber(iterations.count),
    iterations_per_s: toNumber(iterations.rate)
  };
}

export function evaluateThresholds(httpMetrics, thresholds) {
  const failures = [];
  if (thresholds.p95_ms !== undefined && httpMetrics.p95_ms > thresholds.p95_ms) {
    failures.push(`p95 ${httpMetrics.p95_ms.toFixed(2)}ms >= ${thresholds.p95_ms}ms`);
  }
  if (thresholds.p99_ms !== undefined && httpMetrics.p99_ms > thresholds.p99_ms) {
    failures.push(`p99 ${httpMetrics.p99_ms.toFixed(2)}ms >= ${thresholds.p99_ms}ms`);
  }
  if (thresholds.error_rate !== undefined && httpMetrics.error_rate > thresholds.error_rate) {
    failures.push(`error rate ${(httpMetrics.error_rate * 100).toFixed(2)}% > ${(thresholds.error_rate * 100).toFixed(2)}%`);
  }
  if (thresholds.checks_failed !== undefined && httpMetrics.checks_failed > thresholds.checks_failed) {
    failures.push(`checks failed ${httpMetrics.checks_failed} > ${thresholds.checks_failed}`);
  }
  if (thresholds.requests_per_s_min !== undefined && httpMetrics.requests_per_s < thresholds.requests_per_s_min) {
    failures.push(`req/s ${httpMetrics.requests_per_s.toFixed(2)} < ${thresholds.requests_per_s_min}`);
  }
  if (thresholds.requests_min !== undefined && httpMetrics.requests < thresholds.requests_min) {
    failures.push(`requests ${httpMetrics.requests} < ${thresholds.requests_min}`);
  }
  return {
    ok: failures.length === 0,
    failures
  };
}

export function createSummary({ testName, data, thresholds, metadata }) {
  const metrics = gatherHttpMetrics(data);
  const evaluation = evaluateThresholds(metrics, thresholds || {});
  const summary = {
    test_name: testName,
    generated_at: new Date().toISOString(),
    overall_status: evaluation.ok ? 'PASS' : 'FAIL',
    failure_reasons: evaluation.failures,
    metrics,
    thresholds,
    metadata: metadata || {}
  };

  const output = {};
  const basePath = `artifacts/${testName}-test-results.json`;
  output[basePath] = JSON.stringify(summary, null, 2);
  output[`artifacts/${testName}-test-summary.raw.json`] = JSON.stringify(data, null, 2);
  return output;
}
