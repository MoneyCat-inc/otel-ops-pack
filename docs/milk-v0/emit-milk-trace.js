// docs/milk-v0/emit-milk-trace.js
// Gate #011 Job M2 - Synthetic OTLP trace for Milk v0 viewer
const { trace, context } = require('@opentelemetry/api');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// Initialize OTLP exporter
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'milk-viewer',
    'deployment.environment': 'staging',
    'release.gate': '011',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
  }),
});

sdk.start();

// Emit test span
const tracer = trace.getTracer('milk-viewer');
const span = tracer.startSpan('milk.viewer.test');
span.setAttribute('test.duration', 30);
span.setAttribute('test.frames', 20);
span.setAttribute('test.status', 'PASS');
span.end();

console.log('[trace] Emitted milk.viewer.test span');
console.log('[trace] Endpoint:', process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces');

sdk.shutdown().then(() => {
  console.log('[trace] Shutdown complete');
  process.exit(0);
});

