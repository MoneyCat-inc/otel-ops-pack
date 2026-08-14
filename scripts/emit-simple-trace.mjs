#!/usr/bin/env node
// ESM synthetic emitter honoring USE_MOCK. Dependency-light for PRs.
// - USE_MOCK=true: POST to httpbin and exit 0
// - USE_MOCK=false: emit real OTLP span via HTTP/protobuf to /v1/traces

import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

const env = (k, d) => (process.env[k] ?? d);
const USE_MOCK = String(env('USE_MOCK', 'true')).toLowerCase() === 'true';
const SERVICE_NAME = env('OTEL_SERVICE_NAME', 'iona-app');
const SITE = env('SITE', env('GATE_SITE', 'ci'));
const RUN_ID = env('GITHUB_RUN_ID', 'local');
const GIT_SHA = String(env('GITHUB_SHA', '')).slice(0, 12);
let OTLP_ENDPOINT = env('OTEL_EXPORTER_OTLP_ENDPOINT', 'http://127.0.0.1:5321/v1/traces');
if (!OTLP_ENDPOINT.endsWith('/v1/traces')) {
  // Normalize to /v1/traces if user only provided host:port
  OTLP_ENDPOINT = OTLP_ENDPOINT.replace(/\/$/, '') + '/v1/traces';
}

const nowIso = () => new Date().toISOString();
const log = (lvl, msg, extra = {}) => console.log(JSON.stringify({ t: nowIso(), lvl, msg, ...extra }));

(async function main() {
  try {
    if (USE_MOCK) {
      const res = await fetch('https://httpbin.org/post', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          event: 'iona.synthetic',
          mode: 'mock',
          site: SITE,
          git: GIT_SHA,
          run: RUN_ID,
          service: SERVICE_NAME,
          ts: nowIso()
        })
      });
      log('info', 'Mock emit complete', { status: res.status });
      process.exit(0);
    }

    const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
    const { BatchSpanProcessor } = require('@opentelemetry/sdk-trace-base');
    const { Resource } = require('@opentelemetry/resources');
    const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
    const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
    const api = require('@opentelemetry/api');

    const resource = new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: SERVICE_NAME,
      'boss.gate': 'IONA',
      'boss.site': SITE,
      'github.run_id': RUN_ID,
      'github.sha': GIT_SHA || 'unknown'
    });

    const provider = new NodeTracerProvider({ resource });
    const exporter = new OTLPTraceExporter({ url: OTLP_ENDPOINT });
    provider.addSpanProcessor(new BatchSpanProcessor(exporter));
    provider.register();

    const tracer = api.trace.getTracer('boss/iona-gate');
    const parent = tracer.startSpan('iona.boot', { attributes: { 'gate.phase': 'boot' } });
    await new Promise((r) => setTimeout(r, 25));
    const ctx = api.trace.setSpan(api.context.active(), parent);
    const child = tracer.startSpan(
      'iona.synthetic',
      { attributes: { 'gate.check': 'synthetic-trace', 'otlp.endpoint': OTLP_ENDPOINT, 'boss.site': SITE } },
      ctx
    );
    child.end();
    parent.end();

    await provider.forceFlush();
    await provider.shutdown();
    log('info', 'OTLP emit complete', { endpoint: OTLP_ENDPOINT, service: SERVICE_NAME });
    process.exit(0);
  } catch (err) {
    const msg = (err && err.message) || String(err);
    const code = USE_MOCK ? 0 : 2;
    log('error', 'Emitter error', { msg, endpoint: OTLP_ENDPOINT, code });
    process.exit(code);
  }
})();
