import { NodeSDK } from '@opentelemetry/sdk-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes as S } from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    [S.SERVICE_NAME]: 'codex-local',
    [S.SERVICE_VERSION]: '0.1.0',
    'resonai.agent.role': 'local-workflow-custodian'
  }),
  traceExporter: new OTLPTraceExporter(), // honors OTEL_EXPORTER_OTLP_ENDPOINT
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter(),
    exportIntervalMillis: 60000
  })
});

try {
  sdk.start();
} catch (err) {
  console.error('OTel SDK start failed', err);
}
process.on('SIGTERM', () => sdk.shutdown());
