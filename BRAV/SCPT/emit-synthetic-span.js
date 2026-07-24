#!/usr/bin/env node
// HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
/**
 * IONA Synthetic Span Emitter (CommonJS)
 * Uses NodeSDK for proper span processor registration
 * Part of: IONA-GATE-002
 */

const { trace, context, SpanKind } = require("@opentelemetry/api");
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");

const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://127.0.0.1:5318").replace(/\/$/, "");
const url = `${endpoint}/v1/traces`;
const serviceName = process.env.OTEL_SERVICE_NAME || "iona-app";

const sdk = new NodeSDK({
  resource: resourceFromAttributes({ "service.name": serviceName }),
  traceExporter: new OTLPTraceExporter({ url }),
});

sdk.start();

// Give SDK time to initialize
setTimeout(() => {
  const tracer = trace.getTracer("iona-synthetic");
  
  // Boot span with child
  const boot = tracer.startSpan("iona.boot", { kind: SpanKind.INTERNAL });
  const ctx = trace.setSpan(context.active(), boot);
  
  setTimeout(() => {
    const child = tracer.startSpan("iona.synthetic", { kind: SpanKind.INTERNAL }, ctx);
    setTimeout(() => {
      child.end();
      boot.end();
      
      sdk.shutdown().then(
        () => {
          console.log("[IONA] Spans emitted");
          process.exit(0);
        },
        (err) => {
          console.error("[IONA] Error:", err.message);
          process.exit(1);
        }
      );
    }, 50);
  }, 50);
}, 100);
