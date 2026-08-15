const { NodeTracerProvider } = require("@opentelemetry/sdk-trace-node");
const { BatchSpanProcessor } = require("@opentelemetry/sdk-trace-base");
const { Resource } = require("@opentelemetry/resources");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const api = require("@opentelemetry/api");
const fs = require("fs");
const path = require("path");

function ingestHttpBase() {
  if (process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
    return process.env.OTEL_EXPORTER_OTLP_ENDPOINT.replace(/\/$/, "");
  }
  let dir = __dirname;
  for (;;) {
    const candidate = path.join(dir, "DELT", "CONF", "otel-ports.json");
    if (fs.existsSync(candidate)) {
      const j = JSON.parse(fs.readFileSync(candidate, "utf8"));
      return `http://127.0.0.1:${j.windows_collector_ingest.http}`;
    }
    const parent = path.dirname(dir);
    if (parent === dir) throw new Error("otel-ports.json not found");
    dir = parent;
  }
}

const endpoint = ingestHttpBase();
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
