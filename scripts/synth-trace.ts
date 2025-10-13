import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { diag, DiagConsoleLogger, DiagLogLevel, trace } from '@opentelemetry/api';

diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.ERROR);

const endpoint = process.env.OTLP_HTTP || 'http://localhost:14318/v1/traces';
const serviceName = process.env.OTEL_SERVICE_NAME || 'gate-synth';

const exporter = new OTLPTraceExporter({ url: endpoint });
const sdk = new NodeSDK({
  traceExporter: exporter,
  resource: undefined,
});

async function main() {
  await sdk.start();
  const tracer = trace.getTracer(serviceName);
  const span = tracer.startSpan('gate-synthetic-span', {
    attributes: { 'gate.synthetic': true, 'service.name': serviceName },
  });
  await new Promise((r) => setTimeout(r, 50));
  span.end();
  // give exporter a moment
  await new Promise((r) => setTimeout(r, 250));
  await sdk.shutdown();
}

main().catch((e) => {
  console.error('synth-trace failed', e);
  process.exit(1);
});

