import { trace } from "@opentelemetry/api";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import * as resources from "@opentelemetry/resources";

const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://127.0.0.1:5318").replace(/\/$/, "");
const url = `${endpoint}/v1/traces`;
const serviceName = process.env.OTEL_SERVICE_NAME || "iona-app";

const sdk = new NodeSDK({
  resource: resources.resourceFromAttributes({ "service.name": serviceName }),
  traceExporter: new OTLPTraceExporter({ url }),
});

(async () => {
  await sdk.start();

  const tracer = trace.getTracer("iona-synthetic");
  const boot = tracer.startSpan("iona.boot");
  const child = tracer.startSpan("iona.synthetic");

  child.end();
  boot.end();

  // flush and exit
  await sdk.shutdown().catch(() => {});
  setTimeout(() => process.exit(0), 50);
})();

