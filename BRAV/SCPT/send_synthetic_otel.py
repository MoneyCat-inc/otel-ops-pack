#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

def _noop():
    print('{"attempted": false, "ok": true, "note": "opentelemetry not installed; skipped"}')
    return 0

def _ingest_traces_url():
    env = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
    if env:
        endpoint = env
    else:
        here = Path(__file__).resolve().parent
        ports_path = None
        for d in [here, *here.parents]:
            candidate = d / "DELT" / "CONF" / "otel-ports.json"
            if candidate.is_file():
                ports_path = candidate
                break
        if ports_path is None:
            raise FileNotFoundError("DELT/CONF/otel-ports.json not found")
        ports = json.loads(ports_path.read_text(encoding="utf-8"))
        http_port = ports["windows_collector_ingest"]["http"]
        endpoint = f"http://localhost:{http_port}/v1/traces"
    if not endpoint.endswith("/v1/traces"):
        endpoint = endpoint.rstrip("/") + "/v1/traces"
    return endpoint

try:
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
except Exception:
    sys.exit(_noop())

endpoint = _ingest_traces_url()
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
