const { NodeTracerProvider } = require("@opentelemetry/sdk-trace-node");
const { BatchSpanProcessor } = require("@opentelemetry/sdk-trace-base");
const { Resource } = require("@opentelemetry/resources");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const api = require("@opentelemetry/api");

const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://127.0.0.1:5318").replace(/\/$/, "");
const exporter = new OTLPTraceExporter({ url: `${endpoint}/v1/traces` });

const provider = new NodeTracerProvider({
  resource: new Resource({ "service.name": "iona-app" }),
});
provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();

const tracer = api.trace.getTracer("iona-synthetic");
const span = tracer.startSpan("iona.boot", undefined, api.context.active());

setTimeout(() => {
  span.end();
  // give the BatchSpanProcessor a moment to flush
  setTimeout(() => process.exit(0), 300);
}, 50);
