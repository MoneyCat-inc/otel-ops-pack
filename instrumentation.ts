// Next.js instrumentation entrypoint
// Sets up a lightweight Node tracer provider with the OTLP HTTP exporter
// Skips the full @opentelemetry/sdk-node bundle to avoid optional gRPC deps.

import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

let tracerProvider: NodeTracerProvider | undefined;
let shuttingDown = false;

export async function register() {
  // Avoid referencing `window` (not in default TS lib); skip only in browser runtimes.
  if (typeof globalThis !== 'undefined' && 'window' in globalThis) {
    return;
  }

  if (tracerProvider || shuttingDown) return; // ensure singleton

  const serviceName = process.env['OTEL_SERVICE_NAME'] || 'resonai-backend';
  const otlpEndpoint =
    process.env['OTEL_EXPORTER_OTLP_ENDPOINT'] || 'http://127.0.0.1:4318';

  const traceExporter = new OTLPTraceExporter({
    url: `${otlpEndpoint.replace(/\/$/, '')}/v1/traces`,
    headers: {},
  });

  const spanProcessor = new BatchSpanProcessor(traceExporter);

  tracerProvider = new NodeTracerProvider({
    resource: resourceFromAttributes({
      [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
      [SemanticResourceAttributes.SERVICE_VERSION]: process.env['OTEL_SERVICE_VERSION'] || '1.0.0',
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]:
        process.env['OTEL_ENVIRONMENT'] || 'development',
    }),
    spanProcessors: [spanProcessor],
  });

  tracerProvider.register();

  const shutdown = async () => {
    if (shuttingDown) return;
    shuttingDown = true;
    try {
      await tracerProvider?.shutdown();
      // eslint-disable-next-line no-console
      console.log('OpenTelemetry tracer provider shut down');
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Error shutting down OpenTelemetry SDK', err);
    }
    tracerProvider = undefined;
    shuttingDown = false;
  };

  process.once('beforeExit', shutdown);
  process.once('SIGTERM', shutdown);
  process.once('SIGINT', shutdown);
}
