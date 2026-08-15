#!/usr/bin/env tsx
/**
 * Synthetic Span Emitter - Bot-Native Telemetry Rail
 * 
 * Purpose: Emit hierarchical OTLP spans for gate/site bot verification
 * 
 * Usage:
 *   pnpm emit                                    # Use defaults or .env
 *   OTEL_SERVICE_NAME=gate-bot pnpm emit         # Override service name
 *   BOSSCAT_LANE=site pnpm emit                  # Override lane
 * 
 * Environment Variables (.env file supported):
 *   OTEL_EXPORTER_OTLP_ENDPOINT  - OTLP endpoint (default: ingest HTTP /v1/traces from otel-ports.json)
 *   OTEL_SERVICE_NAME            - Service identifier (default: gate-synthetic)
 *   BOSSCAT_LANE                 - Bot lane (default: gate)
 *   DEPLOYMENT_ENVIRONMENT       - Environment (default: production)
 * 
 * Create .env from .env.template for persistent configuration.
 * 
 * BossCat Approval: GATE-2025-10-10-REBUILD-001
 * Updated: 2025-10-10 (Phase 1.2 - .env support)
 */

import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes as R } from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { trace, context } from '@opentelemetry/api';
import { ensureCorrelationId, getCorrelationHeaders } from './lib/correlation';
import { getOtelIngestHttpBase } from '../ALFA/LIBS/lib/otel-ports';

// ============================================
// Configuration (env-driven, bot-friendly)
// ============================================
// NOTE: Defaults to HTTP/protobuf (ingest HTTP from otel-ports.json) for reliability.
//       gRPC ingest can cause parse errors; use HTTP for bot operations.
//       Override via OTEL_EXPORTER_OTLP_ENDPOINT environment variable.
const config = {
  endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? `${getOtelIngestHttpBase()}/v1/traces`,
  serviceName: process.env.OTEL_SERVICE_NAME ?? 'gate-synthetic',
  lane: process.env.BOSSCAT_LANE ?? 'gate',
  environment: process.env.DEPLOYMENT_ENVIRONMENT ?? 'production',
  protocol: 'http/protobuf', // Explicit protocol for clarity
};

// ============================================
// Provider Setup
// ============================================
const provider = new NodeTracerProvider({
  resource: resourceFromAttributes({
    [R.SERVICE_NAME]: config.serviceName,
    [R.SERVICE_NAMESPACE]: 'resonai',
    [R.DEPLOYMENT_ENVIRONMENT]: config.environment,
    'bosscat.lane': config.lane,
    'bosscat.synthetic': true,
    'bosscat.version': '1.0.0',
  }),
});

// OTLP HTTP exporter (matches IONA-GATE-002 pattern)
// Explicit timeout (5s) and retry logic for bot reliability
const exporter = new OTLPTraceExporter({
  url: config.endpoint,
  headers: {
    'x-bosscat-lane': config.lane,
    'x-bosscat-synthetic': 'true',
    ...getCorrelationHeaders(),
  },
  timeoutMillis: 5000,  // 5-second timeout (Phase 1.3 - explicit timeout)
});

const spanProcessor = new BatchSpanProcessor(exporter, {
  maxQueueSize: 100,
  scheduledDelayMillis: 500,
  exportTimeoutMillis: 5000,  // 5-second export timeout
  maxExportBatchSize: 50,
});

// Retry configuration note:
// The OTLPTraceExporter handles retries internally with exponential backoff.
// Default: 3 attempts with 1s, 2s, 4s delays (matches Stability Pack pattern)

// Recreate provider to include processor in constructor (node SDK v2 pattern)
const providerWithProc = new NodeTracerProvider({
  resource: resourceFromAttributes({
    [R.SERVICE_NAME]: config.serviceName,
    [R.SERVICE_NAMESPACE]: 'resonai',
    [R.DEPLOYMENT_ENVIRONMENT]: config.environment,
    'bosscat.lane': config.lane,
    'bosscat.synthetic': true,
    'bosscat.version': '1.0.0',
  }),
  spanProcessors: [spanProcessor],
});

providerWithProc.register();

// ============================================
// Synthetic Trace Emission (hierarchical)
// ============================================
const tracer = providerWithProc.getTracer('gate-emitter', '1.0.0');

async function emitSyntheticTrace() {
  const startTime = Date.now();
  const correlationId = ensureCorrelationId();
  
  // Root span: gate.boot
  const rootSpan = tracer.startSpan('gate.boot', {
    attributes: {
      'bosscat.synthetic': true,
      'bosscat.lane': config.lane,
      'bosscat.phase': 'boot',
      'gate.timestamp': new Date().toISOString(),
      'correlation_id': correlationId,
    },
  });

  try {
    // Simulate initialization work
    await new Promise(resolve => setTimeout(resolve, 50));
    
    // Child span 1: gate.verify
    const verifySpan = tracer.startSpan('gate.verify', {
      attributes: {
        'bosscat.phase': 'verify',
        'gate.check': 'pipeline_health',
        'correlation_id': correlationId,
      },
    }, trace.setSpan(context.active(), rootSpan));
    
    await new Promise(resolve => setTimeout(resolve, 30));
    verifySpan.setStatus({ code: 1 }); // OK
    verifySpan.end();
    
    // Child span 2: gate.synthetic
    const synthSpan = tracer.startSpan('gate.synthetic', {
      attributes: {
        'bosscat.phase': 'synthetic',
        'gate.check': 'otlp_ingestion',
        'correlation_id': correlationId,
      },
    }, trace.setSpan(context.active(), rootSpan));
    
    await new Promise(resolve => setTimeout(resolve, 20));
    synthSpan.setStatus({ code: 1 }); // OK
    synthSpan.end();
    
    rootSpan.setStatus({ code: 1 }); // OK
    rootSpan.setAttribute('gate.duration_ms', Date.now() - startTime);
    rootSpan.end();
    
    console.log('✅ Synthetic trace emitted successfully');
    console.log(`   Service: ${config.serviceName}`);
    console.log(`   Endpoint: ${config.endpoint}`);
    console.log(`   Lane: ${config.lane}`);
    console.log(`   Trace ID: ${rootSpan.spanContext().traceId}`);
    console.log(`   Correlation ID: ${correlationId}`);
    console.log(`   Duration: ${Date.now() - startTime}ms`);
    
  } catch (error) {
    rootSpan.setStatus({ code: 2, message: String(error) }); // ERROR
    rootSpan.end();
    console.error('❌ Failed to emit synthetic trace:', error);
    throw error;
  }
}

// ============================================
// Execution & Graceful Shutdown
// ============================================
(async () => {
  try {
    await emitSyntheticTrace();
    
    // Flush and shutdown (critical for CI/bot environments)
    await new Promise(resolve => setTimeout(resolve, 250));
    await providerWithProc.shutdown();
    
    console.log('✅ Provider shutdown complete');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Synthetic trace emission failed:', error);
    await providerWithProc.shutdown();
    process.exit(1);
  }
})();

// ============================================
// Error Handling (Stability Pack pattern)
// ============================================
process.on('SIGTERM', async () => {
  console.log('⚠️  SIGTERM received, shutting down gracefully...');
  await provider.shutdown();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('⚠️  SIGINT received, shutting down gracefully...');
  await provider.shutdown();
  process.exit(0);
});

// ============================================
// Bot-Native Design Notes
// ============================================
//
// 1. Env-Driven: All config via env vars (no hardcoded secrets)
// 2. Fast Exit: Completes in <500ms (bot-friendly)
// 3. Hierarchical: Root + 2 children (easy to verify in UI)
// 4. Graceful Shutdown: Flushes before exit (no data loss)
// 5. Exit Codes: 0 = success, 1 = failure (CI integration)
// 6. Evidence: Logs trace ID for ECRR audit trail
//
// Usage Examples:
//   pnpm emit                                    # Default (gate-synthetic)
//   OTEL_SERVICE_NAME=site-bot pnpm emit         # Site bot
//   BOSSCAT_LANE=site pnpm emit                  # Site lane
//   OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:<ingestHttp>/v1/traces pnpm emit
//
// ============================================

