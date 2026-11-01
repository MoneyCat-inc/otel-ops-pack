import { context, propagation, trace } from "@opentelemetry/api";
import { BatchSpanProcessor, TracerProvider } from "@opentelemetry/sdk-trace";
import { AsyncLocalStorageContextManager } from "@opentelemetry/context-async-hooks";
import { CompositePropagator, W3CBaggagePropagator, W3CTraceContextPropagator } from "@opentelemetry/core";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { resourceFromAttributes } from "@opentelemetry/resources";
import { getOtelIngestHttpBase } from "../../ALFA/LIBS/lib/otel-ports";

const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || getOtelIngestHttpBase()).replace(/\/$/, "");
const url = `${endpoint}/v1/traces`;
const serviceName = process.env.OTEL_SERVICE_NAME || "iona-app";

const exporter = new OTLPTraceExporter({ url });
const provider = new TracerProvider({
  resource: resourceFromAttributes({ "service.name": serviceName }),
  spanProcessors: [new BatchSpanProcessor({ exporter })],
});
// @opentelemetry/sdk-trace 3.0 has no register(): install what the old register() used to.
context.setGlobalContextManager(new AsyncLocalStorageContextManager().enable());
propagation.setGlobalPropagator(
  new CompositePropagator({ propagators: [new W3CTraceContextPropagator(), new W3CBaggagePropagator()] })
);
trace.setGlobalTracerProvider(provider);

const tracer = trace.getTracer("iona-synthetic");

// optional parent boot span for nicer grouping
const boot = tracer.startSpan("iona.boot", undefined, context.active());
setTimeout(() => {
  const child = tracer.startSpan("iona.synthetic", undefined, context.active());
  setTimeout(() => {
    child.end();
    boot.end();
    setTimeout(() => process.exit(0), 300); // flush BatchSpanProcessor
  }, 50);
}, 50);
