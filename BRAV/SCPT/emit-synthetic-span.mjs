import { trace } from "@opentelemetry/api";
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import * as resources from "@opentelemetry/resources";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

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
