import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import fs from "node:fs";
import path from "node:path";
const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const { BatchSpanProcessor, TracerProvider } = require("@opentelemetry/sdk-trace");
const { AsyncLocalStorageContextManager } = require("@opentelemetry/context-async-hooks");
const { CompositePropagator, W3CBaggagePropagator, W3CTraceContextPropagator } = require("@opentelemetry/core");
const { resourceFromAttributes } = require("@opentelemetry/resources");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const api = require("@opentelemetry/api");

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

const provider = new TracerProvider({
  resource: resourceFromAttributes({ "service.name": "iona-app" }),
  spanProcessors: [new BatchSpanProcessor({ exporter })],
});
// @opentelemetry/sdk-trace 3.0 has no register(): install what NodeTracerProvider.register() used to.
api.context.setGlobalContextManager(new AsyncLocalStorageContextManager().enable());
api.propagation.setGlobalPropagator(
  new CompositePropagator({ propagators: [new W3CTraceContextPropagator(), new W3CBaggagePropagator()] })
);
api.trace.setGlobalTracerProvider(provider);

const tracer = api.trace.getTracer("iona-synthetic");
const span = tracer.startSpan("iona.boot", undefined, api.context.active());

setTimeout(() => {
  span.end();
  // give the BatchSpanProcessor a moment to flush
  setTimeout(() => process.exit(0), 300);
}, 50);
