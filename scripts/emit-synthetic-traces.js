// Gate #016 Final Certification - Synthetic Trace Emission
// Emit visuals and audio test spans to OTLP collector

const { trace } = require('@opentelemetry/api');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-proto');
const { Resource } = require('@opentelemetry/resources');
const { SEMRESATTRS_SERVICE_NAME, SEMRESATTRS_DEPLOYMENT_ENVIRONMENT } = require('@opentelemetry/semantic-conventions');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

// Configure OTLP exporter
const otlpExporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318',
  headers: {}
});

// Configure SDK
const sdk = new NodeSDK({
  resource: new Resource({
    [SEMRESATTRS_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'viz-engine-projectm',
    [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: process.env.DEPLOYMENT_ENVIRONMENT || 'staging',
    'release.gate': '016'
  }),
  traceExporter: otlpExporter,
  instrumentations: [getNodeAutoInstrumentations()]
});

// Start SDK
sdk.start();

// Wait for initialization
setTimeout(() => {
  const tracer = trace.getTracer('gate-016-synthetic');
  
  // Visuals span
  tracer.startActiveSpan('visuals.test.run', {
    attributes: {
      'lane': 'visual-016',
      'presets': 15,
      'guard': 'L_min:0.07',
      'kind': 'synthetic'
    }
  }, (span) => {
    console.log('[synthetic-trace] Emitted visuals.test.run span');
    span.end();
  });
  
  // Audio span
  tracer.startActiveSpan('audio.test.run', {
    attributes: {
      'case': 'AM_SINE_60S',
      'lane': 'audio-013c',
      'sr': 48000,
      'channels': 2,
      'kind': 'synthetic'
    }
  }, (span) => {
    console.log('[synthetic-trace] Emitted audio.test.run span');
    span.end();
  });
  
  // Wait for spans to flush, then shutdown
  setTimeout(() => {
    sdk.shutdown().then(() => {
      console.log('[synthetic-trace] Traces emitted successfully');
      process.exit(0);
    }).catch((err) => {
      console.error('[synthetic-trace] Shutdown error:', err);
      process.exit(1);
    });
  }, 2000);
}, 1000);

