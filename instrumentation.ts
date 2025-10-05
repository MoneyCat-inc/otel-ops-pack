// Next.js instrumentation entrypoint
// Starts a single NodeSDK with auto-instrumentations and OTLP trace exporter

import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

let sdk: NodeSDK | undefined;

export async function register() {
  if (sdk) return; // ensure singleton

  const serviceName = process.env.OTEL_SERVICE_NAME || 'resonai-backend';
  const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:14318';

  const traceExporter = new OTLPTraceExporter({
    url: `${otlpEndpoint.replace(/\/$/, '')}/v1/traces`,
    headers: {},
  });

  sdk = new NodeSDK({
    resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
      [SemanticResourceAttributes.SERVICE_VERSION]: process.env.OTEL_SERVICE_VERSION || '1.0.0',
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.OTEL_ENVIRONMENT || 'development',
    }),
    traceExporter,
    instrumentations: [],
  });

  await sdk.start();

  const shutdown = async () => {
    try {
      await sdk?.shutdown();
      // eslint-disable-next-line no-console
      console.log('OpenTelemetry SDK shut down');
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error('Error shutting down OpenTelemetry SDK', err);
    }
  };

  process.on('beforeExit', shutdown);
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}


