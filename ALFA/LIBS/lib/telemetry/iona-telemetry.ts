/**
 * IONA Telemetry Module
 * 
 * Provides OpenTelemetry instrumentation for the IONA (Resonai) app
 * Emits iona.boot span on app startup and integrates with local OTLP collector
 * 
 * Part of: IONA Gate Integration
 * Service: iona-app
 * Gate: BossCat Gate Verify
 */

import { trace, context, SpanStatusCode } from '@opentelemetry/api';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

// Configuration
const OTEL_ENABLED = process.env.NEXT_PUBLIC_OTEL_ENABLED === 'true' || process.env.NODE_ENV === 'development';
const OTEL_ENDPOINT =
  process.env.NEXT_PUBLIC_OTEL_ENDPOINT || 'http://127.0.0.1:14318/v1/traces';
const SERVICE_NAME = 'iona-app';
const SERVICE_VERSION = '1.0.0';

let provider: WebTracerProvider | null = null;
let isInitialized = false;

/**
 * Initialize OpenTelemetry for IONA app
 */
export function initializeTelemetry(): void {
  if (!OTEL_ENABLED) {
    console.log('[iona-telemetry] Telemetry disabled (set NEXT_PUBLIC_OTEL_ENABLED=true to enable)');
    return;
  }

  if (isInitialized) {
    console.warn('[iona-telemetry] Already initialized');
    return;
  }

  try {
    console.log('[iona-telemetry] Initializing OpenTelemetry...');

    // Create resource with service information
    const resource = resourceFromAttributes({
      [SemanticResourceAttributes.SERVICE_NAME]: SERVICE_NAME,
      [SemanticResourceAttributes.SERVICE_VERSION]: SERVICE_VERSION,
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]:
        process.env.NODE_ENV || 'development',
      'telemetry.sdk.name': 'opentelemetry',
      'telemetry.sdk.language': 'javascript',
      'app.component': 'frontend',
    });

    // Create tracer provider
    provider = new WebTracerProvider({
      resource,
    });

    // Configure OTLP exporter
    const exporter = new OTLPTraceExporter({
      url: OTEL_ENDPOINT,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add batch span processor
    const spanProcessor = new BatchSpanProcessor(exporter, {
      maxQueueSize: 100,
      maxExportBatchSize: 10,
      scheduledDelayMillis: 500,
      exportTimeoutMillis: 30000,
    });

    if (typeof provider.addSpanProcessor === 'function') {
      provider.addSpanProcessor(spanProcessor);
    } else if ((provider as unknown as { _activeSpanProcessor?: { addSpanProcessor?: (processor: BatchSpanProcessor) => void } })._activeSpanProcessor?.addSpanProcessor) {
      (provider as unknown as { _activeSpanProcessor: { addSpanProcessor: (processor: BatchSpanProcessor) => void } })._activeSpanProcessor.addSpanProcessor(spanProcessor);
    } else {
      console.warn('[iona-telemetry] Unable to attach span processor; telemetry will be disabled');
      isInitialized = false;
      return;
    }

    // Register provider
    provider.register();

    isInitialized = true;
    console.log('[iona-telemetry] OpenTelemetry initialized');
    console.log(`[iona-telemetry] Service: ${SERVICE_NAME}`);
    console.log(`[iona-telemetry] Endpoint: ${OTEL_ENDPOINT}`);
  } catch (error) {
    console.error('[iona-telemetry] Failed to initialize:', error);
  }
}

/**
 * Emit iona.boot span
 */
export function emitBootSpan(): void {
  if (!OTEL_ENABLED || !isInitialized) {
    return;
  }

  try {
    const tracer = trace.getTracer(SERVICE_NAME, SERVICE_VERSION);
    const span = tracer.startSpan('iona.boot', {
      startTime: performance.timing.navigationStart,
    });

    // Set attributes
    span.setAttributes({
      'app.name': SERVICE_NAME,
      'app.component': 'frontend',
      'boot.phase': 'initialization',
      'boot.timestamp': Date.now(),
      'gate.test': 'bosscat-verify',
      'browser.userAgent': navigator.userAgent,
      'browser.language': navigator.language,
      'screen.width': window.screen.width,
      'screen.height': window.screen.height,
      'url.full': window.location.href,
      'url.pathname': window.location.pathname,
    });

    // Add boot timing events
    if (performance.timing) {
      const timing = performance.timing;
      span.addEvent('dom.loading', {
        timestamp: timing.domLoading,
      });
      span.addEvent('dom.interactive', {
        timestamp: timing.domInteractive,
      });
      span.addEvent('dom.contentLoaded', {
        timestamp: timing.domContentLoadedEventEnd,
      });
      span.addEvent('load.complete', {
        timestamp: timing.loadEventEnd,
      });

      // Calculate durations
      const ttfb = timing.responseStart - timing.navigationStart;
      const domReady = timing.domContentLoadedEventEnd - timing.navigationStart;
      const loadComplete = timing.loadEventEnd - timing.navigationStart;

      span.setAttributes({
        'performance.ttfb': ttfb,
        'performance.domReady': domReady,
        'performance.loadComplete': loadComplete,
      });
    }

    // Mark as successful
    span.setStatus({ code: SpanStatusCode.OK });
    span.addEvent('iona.boot.complete', {
      status: 'success',
      duration_ms: performance.now(),
    });

    // End span
    span.end();

    console.log('[iona-telemetry] Boot span emitted');
  } catch (error) {
    console.error('[iona-telemetry] Failed to emit boot span:', error);
  }
}

/**
 * Shutdown telemetry gracefully
 */
export async function shutdownTelemetry(): Promise<void> {
  if (!provider) {
    return;
  }

  try {
    console.log('[iona-telemetry] Shutting down...');
    await provider.shutdown();
    isInitialized = false;
    console.log('[iona-telemetry] Shutdown complete');
  } catch (error) {
    console.error('[iona-telemetry] Shutdown error:', error);
  }
}

/**
 * Get tracer for custom instrumentation
 */
export function getTracer() {
  if (!OTEL_ENABLED || !isInitialized) {
    return null;
  }
  return trace.getTracer(SERVICE_NAME, SERVICE_VERSION);
}

/**
 * Check if telemetry is enabled and initialized
 */
export function isTelemetryReady(): boolean {
  return OTEL_ENABLED && isInitialized;
}

