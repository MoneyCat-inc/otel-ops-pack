import { context, trace } from "@opentelemetry/api";
import { BasicTracerProvider, BatchSpanProcessor } from "@opentelemetry/sdk-trace-base";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { Resource } from "@opentelemetry/resources";

const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://127.0.0.1:5321").replace(/\/$/, "");
const url = `${endpoint}/v1/traces`;
const serviceName = process.env.OTEL_SERVICE_NAME || "iona-app";

const exporter = new OTLPTraceExporter({ url });
const provider = new BasicTracerProvider({
  resource: new Resource({ "service.name": serviceName }),
});
provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();

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
