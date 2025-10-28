#!/usr/bin/env node
/**
 * Investor Demo: Synthetic Trace Emitter
 * Authority: BossCat OEM | Executor: Cursor{Implementer}
 * Phase 2: Pre-load synthetic trace for demo visibility
 * 
 * Emits a rich demo trace with multiple spans showing:
 * - Service interaction (demo-prober → svc2-api → svc3-worker)
 * - Database and cache operations
 * - Clear attributes for investor storytelling
 */

const { trace, context, SpanKind, SpanStatusCode } = require("@opentelemetry/api");
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");

// Configuration
const endpoint = (process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://127.0.0.1:14318").replace(/\/$/, "");
const url = `${endpoint}/v1/traces`;

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    "service.name": "demo-prober",
    "service.version": "1.0.0-demo",
    "deployment.environment": "investor-demo",
    "team": "bosscat",
    "demo.phase": "phase2",
    "demo.type": "synthetic",
  }),
  traceExporter: new OTLPTraceExporter({ url }),
});

sdk.start();

// Generate demo trace
setTimeout(() => {
  const tracer = trace.getTracer("demo-prober");
  
  // Root span: Investor demo request
  const rootSpan = tracer.startSpan("investor.demo.request", {
    kind: SpanKind.CLIENT,
    attributes: {
      "http.method": "GET",
      "http.url": "http://localhost:5556/test",
      "http.target": "/test",
      "demo.scenario": "baseline",
      "demo.timestamp": new Date().toISOString(),
    }
  });
  
  const rootCtx = trace.setSpan(context.active(), rootSpan);
  
  // Span 1: API processing
  setTimeout(() => {
    const apiSpan = tracer.startSpan("svc2.api.process", {
      kind: SpanKind.SERVER,
      attributes: {
        "http.method": "GET",
        "http.route": "/test",
        "http.status_code": 200,
        "service.name": "bosscat-svc2-api",
      }
    }, rootCtx);
    
    const apiCtx = trace.setSpan(rootCtx, apiSpan);
    
    // Span 2: Database query (child of API)
    setTimeout(() => {
      const dbSpan = tracer.startSpan("db.query.users", {
        kind: SpanKind.CLIENT,
        attributes: {
          "db.system": "postgresql",
          "db.statement": "SELECT * FROM users WHERE id = @p1",
          "db.name": "demo_db",
          "db.operation": "SELECT",
        }
      }, apiCtx);
      
      setTimeout(() => dbSpan.end(), 15);
    }, 10);
    
    // Span 3: Cache lookup (child of API)
    setTimeout(() => {
      const cacheSpan = tracer.startSpan("cache.get.session", {
        kind: SpanKind.CLIENT,
        attributes: {
          "db.system": "redis",
          "db.operation": "GET",
          "cache.key": "session:demo-user-123",
          "cache.hit": true,
        }
      }, apiCtx);
      
      setTimeout(() => cacheSpan.end(), 8);
    }, 25);
    
    // Span 4: Worker call (child of API)
    setTimeout(() => {
      const workerSpan = tracer.startSpan("svc3.worker.process", {
        kind: SpanKind.CLIENT,
        attributes: {
          "http.method": "POST",
          "http.url": "http://localhost:5557/process",
          "service.name": "bosscat-svc3-worker",
          "worker.job_type": "data_transform",
        }
      }, apiCtx);
      
      setTimeout(() => {
        workerSpan.setStatus({ code: SpanStatusCode.OK });
        workerSpan.end();
      }, 40);
    }, 35);
    
    setTimeout(() => {
      apiSpan.setStatus({ code: SpanStatusCode.OK });
      apiSpan.end();
    }, 90);
  }, 20);
  
  // End root span
  setTimeout(() => {
    rootSpan.setStatus({ code: SpanStatusCode.OK });
    rootSpan.setAttribute("http.status_code", 200);
    rootSpan.end();
    
    // Shutdown SDK
    setTimeout(() => {
      sdk.shutdown().then(
        () => {
          console.log("[DEMO] Synthetic trace emitted successfully");
          console.log("  Service: demo-prober");
          console.log("  Spans: 5 (request → api → db/cache/worker)");
          console.log("  Endpoint: " + url);
          console.log("  Verify in SigNoz: service.name = 'demo-prober'");
          process.exit(0);
        },
        (err) => {
          console.error("[DEMO] Error:", err.message);
          process.exit(1);
        }
      );
    }, 200);
  }, 120);
}, 100);

