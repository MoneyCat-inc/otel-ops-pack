import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { diag, DiagConsoleLogger, DiagLogLevel, trace } from '@opentelemetry/api';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

diag.setLogger(new DiagConsoleLogger(), DiagLogLevel.ERROR);

const endpoint = process.env.OTLP_HTTP || 'http://localhost:4318/v1/traces';
const serviceName = process.env.OTEL_SERVICE_NAME || 'gate-synth';

const exporter = new OTLPTraceExporter({ url: endpoint });
const resource = new Resource({
  [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
});
const sdk = new NodeSDK({
  traceExporter: exporter,
  resource,
});

async function main() {
  await sdk.start();
  const tracer = trace.getTracer(serviceName);
  // simple retry: emit up to 3 spans with short delays
  for (let i = 0; i < 3; i++) {
    const span = tracer.startSpan('gate-synthetic-span', {
      attributes: { 'gate.synthetic': true },
    });
    await new Promise((r) => setTimeout(r, 50));
    span.end();
    await new Promise((r) => setTimeout(r, 150));
  }
  // allow exporter to flush
  await new Promise((r) => setTimeout(r, 500));
  await sdk.shutdown();
}

main().catch((e) => {
  console.error('synth-trace failed', e);
  process.exit(1);
});
