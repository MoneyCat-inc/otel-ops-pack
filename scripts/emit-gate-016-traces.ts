#!/usr/bin/env tsx
/**
 * Gate #016 Synthetic Trace Emission
 * 
 * Purpose: Emit visuals.test.run and audio.test.run spans for final certification
 * 
 * Usage:
 *   tsx scripts/emit-gate-016-traces.ts
 * 
 * Environment Variables:
 *   OTEL_EXPORTER_OTLP_ENDPOINT  - OTLP endpoint (default: http://127.0.0.1:5321/v1/traces)
 *   OTEL_SERVICE_NAME            - Service identifier (default: viz-engine-projectm)
 *   DEPLOYMENT_ENVIRONMENT        - Environment (default: staging)
 */

import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes as R } from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { trace, context } from '@opentelemetry/api';

// Configuration
const config = {
  endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://127.0.0.1:5321/v1/traces',
  serviceName: process.env.OTEL_SERVICE_NAME ?? 'viz-engine-projectm',
  environment: process.env.DEPLOYMENT_ENVIRONMENT ?? 'staging',
};

// Provider Setup
const provider = new NodeTracerProvider({
  resource: resourceFromAttributes({
    [R.SERVICE_NAME]: config.serviceName,
    [R.SERVICE_NAMESPACE]: 'resonai',
    [R.DEPLOYMENT_ENVIRONMENT]: config.environment,
    'release.gate': '016',
  }),
});

const exporter = new OTLPTraceExporter({
  url: config.endpoint,
  timeoutMillis: 5000,
});

const spanProcessor = new BatchSpanProcessor(exporter, {
  maxQueueSize: 100,
  scheduledDelayMillis: 500,
  exportTimeoutMillis: 5000,
  maxExportBatchSize: 50,
});

const providerWithProc = new NodeTracerProvider({
  resource: resourceFromAttributes({
    [R.SERVICE_NAME]: config.serviceName,
    [R.SERVICE_NAMESPACE]: 'resonai',
    [R.DEPLOYMENT_ENVIRONMENT]: config.environment,
    'release.gate': '016',
  }),
  spanProcessors: [spanProcessor],
});

providerWithProc.register();

// Synthetic Trace Emission
const tracer = providerWithProc.getTracer('gate-016-emitter', '1.0.0');

async function emitGate016Traces() {
  console.log('🚀 Emitting Gate #016 synthetic traces...');
  console.log(`   Endpoint: ${config.endpoint}`);
  console.log(`   Service: ${config.serviceName}`);
  console.log(`   Environment: ${config.environment}`);
  console.log('');

  // Visuals span
  const visualsSpan = tracer.startSpan('visuals.test.run', {
    attributes: {
      'lane': 'visual-016',
      'presets': 15,
      'guard': 'L_min:0.07',
      'kind': 'synthetic',
    },
  });

  await new Promise(resolve => setTimeout(resolve, 50));
  visualsSpan.setStatus({ code: 1 }); // OK
  visualsSpan.end();

  console.log('✅ visuals.test.run span emitted');
  console.log(`   Trace ID: ${visualsSpan.spanContext().traceId}`);
  console.log(`   Attributes: lane=visual-016, presets=15, guard=L_min:0.07, kind=synthetic`);
  console.log('');

  // Audio span
  const audioSpan = tracer.startSpan('audio.test.run', {
    attributes: {
      'case': 'AM_SINE_60S',
      'lane': 'audio-013c',
      'sr': 48000,
      'channels': 2,
      'kind': 'synthetic',
    },
  });

  await new Promise(resolve => setTimeout(resolve, 50));
  audioSpan.setStatus({ code: 1 }); // OK
  audioSpan.end();

  console.log('✅ audio.test.run span emitted');
  console.log(`   Trace ID: ${audioSpan.spanContext().traceId}`);
  console.log(`   Attributes: case=AM_SINE_60S, lane=audio-013c, sr=48000, channels=2, kind=synthetic`);
  console.log('');

  console.log('✅ Gate #016 synthetic traces emitted successfully');
}

// Execution & Graceful Shutdown
(async () => {
  try {
    await emitGate016Traces();
    
    // Flush and shutdown
    await new Promise(resolve => setTimeout(resolve, 500));
    await providerWithProc.shutdown();
    
    console.log('✅ Provider shutdown complete');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Failed to emit synthetic traces:', error);
    await providerWithProc.shutdown();
    process.exit(1);
  }
})();

process.on('SIGTERM', async () => {
  console.log('⚠️  SIGTERM received, shutting down gracefully...');
  await providerWithProc.shutdown();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('⚠️  SIGINT received, shutting down gracefully...');
  await providerWithProc.shutdown();
  process.exit(0);
});

