// Frontend OpenTelemetry Tracing Setup
// This file initializes tracing for the browser/client-side

import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-web';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { DocumentLoadInstrumentation } from '@opentelemetry/instrumentation-document-load';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
import { UserInteractionInstrumentation } from '@opentelemetry/instrumentation-user-interaction';
import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';
import { getOtelIngestHttpBase } from './otel-ports';

// Only initialize tracing in browser environment
if (typeof globalThis !== 'undefined' && (globalThis as any).window) {
  // Create OTLP exporter for SigNoz
  const otlpExporter = new OTLPTraceExporter({
    url: process.env['NEXT_PUBLIC_OTEL_EXPORTER_OTLP_ENDPOINT'] || `${getOtelIngestHttpBase('localhost')}/v1/traces`,
    headers: {
      'signoz-access-token': process.env['NEXT_PUBLIC_SIGNOZ_ACCESS_TOKEN'] || 'local-signoz-jwt-secret-rotate',
    },
  });

  // Create resource with service information
  const resource = resourceFromAttributes({
    [SemanticResourceAttributes.SERVICE_NAME]: 'resonai-frontend',
        [SemanticResourceAttributes.SERVICE_VERSION]: process.env['NEXT_PUBLIC_APP_VERSION'] || '1.0.0',
        [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env['NEXT_PUBLIC_ENVIRONMENT'] || 'development',
        'browser.name': (globalThis as any).navigator?.userAgent || '',
        'browser.version': (globalThis as any).navigator?.userAgent || '',
  });

  // Create tracer provider
  const tracerProvider = new WebTracerProvider({
    resource,
  });

  // Add span processor
  (tracerProvider as any).addSpanProcessor(
    new BatchSpanProcessor(otlpExporter, {
      maxExportBatchSize: 100,
      exportTimeoutMillis: 30000,
      scheduledDelayMillis: 5000,
    })
  );

  // Register instrumentations
  registerInstrumentations({
    instrumentations: [
      new DocumentLoadInstrumentation(),
      new FetchInstrumentation({
        requestHook: (span, request) => {
          span.setAttributes({
            'http.request.method': request.method,
            'http.request.url': (request as any).url || '',
          });
        },
      }),
      new UserInteractionInstrumentation({
        enabled: true,
        eventNames: ['click', 'submit', 'keydown'],
      }),
      new XMLHttpRequestInstrumentation(),
    ],
  });

  // Register the tracer provider
  tracerProvider.register();

  console.log('OpenTelemetry frontend tracing initialized');
}
