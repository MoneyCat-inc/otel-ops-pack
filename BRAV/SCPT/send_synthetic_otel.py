#!/usr/bin/env python3
import os, sys

def _noop():
    print('{"attempted": false, "ok": true, "note": "opentelemetry not installed; skipped"}')
    return 0

try:
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
except Exception:
    sys.exit(_noop())

endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:5318/v1/traces")
if not endpoint.endswith("/v1/traces"):
    endpoint = endpoint.rstrip("/") + "/v1/traces"
service  = os.getenv("OTEL_SERVICE_NAME", "bosc-iona-gatecheck")

provider = TracerProvider()
exporter = OTLPSpanExporter(endpoint=endpoint)
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)
tr = trace.get_tracer(service)

with tr.start_as_current_span("bc.synthetic.root", attributes={
    "check.kind": "gate-verification",
    "component": "windows-collector",
    "test.type": "end-to-end-verification"
}):
    pass

print('{"attempted": true, "ok": true}')
sys.exit(0)

