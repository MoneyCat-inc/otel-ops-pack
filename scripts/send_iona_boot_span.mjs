import { context, trace } from "@opentelemetry/api";
import { BasicTracerProvider, BatchSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://127.0.0.1:14318";
const exporter = new OTLPTraceExporter({ url: `${endpoint}/v1/traces` });

const provider = new BasicTracerProvider({
  resource: { attributes: { "service.name": "iona-app" } },
});
provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();

const tracer = trace.getTracer("iona-synthetic");
const span = tracer.startSpan("iona.boot", undefined, context.active());

setTimeout(() => {
  span.end();
  // give the BatchSpanProcessor a moment to flush
  setTimeout(() => process.exit(0), 300);
}, 50);
