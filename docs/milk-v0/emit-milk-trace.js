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

// Async function to properly await SDK initialization
async function emitTrace() {
  // Start SDK and wait for initialization
  await sdk.start();
  console.log('[trace] SDK started');

  // Wait a moment for provider registration
  await new Promise(resolve => setTimeout(resolve, 100));

  // Emit test span
  const tracer = trace.getTracer('milk-viewer');
  const span = tracer.startSpan('milk.viewer.test');
  span.setAttribute('test.duration', 30);
  span.setAttribute('test.frames', 20);
  span.setAttribute('test.status', 'PASS');
  span.end();

  console.log('[trace] Emitted milk.viewer.test span');
  console.log('[trace] Endpoint:', process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces');

  // Wait for span export before shutdown
  await new Promise(resolve => setTimeout(resolve, 500));

  await sdk.shutdown();
  console.log('[trace] Shutdown complete');
}

// Run async function
emitTrace()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('[trace] Error:', err);
    process.exit(1);
  });

