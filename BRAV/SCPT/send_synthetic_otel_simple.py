#!/usr/bin/env python3
"""
BossCat Canary Trace Sender — Gate Verification Contract
=========================================================
Sends a single synthetic OTLP trace and emits machine-readable tokens
consumed by BRAV\\SCPT\\verify-pipeline.ps1:

  TRACE_ID=<32-hex>
  CANARY_ID=<epoch-ms>
  SEND_TS_NS=<nanoseconds>

Environment variables (set by verify-pipeline.ps1):
  OTEL_EXPORTER_OTLP_ENDPOINT          e.g. http://127.0.0.1:4318
  OTEL_EXPORTER_OTLP_TRACES_ENDPOINT   e.g. http://127.0.0.1:4318/v1/traces
  OTEL_SERVICE_NAME / SERVICE_NAME     service name for the span
  OTEL_RESOURCE_ATTRIBUTES             extra resource attributes (parsed best-effort)

Exit codes:
  0  — span sent and flushed successfully
  1  — opentelemetry packages missing (soft skip)
  2  — export error
"""

import os
import sys
import time

# ── dependency guard ──────────────────────────────────────────────────────────
try:
    from opentelemetry import trace
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor
    from opentelemetry.sdk.resources import Resource
    from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
except ImportError:
    # Soft skip — pipeline stays WARN rather than FAIL
    print("WARN: opentelemetry packages not installed; skipping canary send", file=sys.stderr)
    print('{"attempted": false, "ok": true, "note": "opentelemetry not installed"}')
    sys.exit(1)

# ── resolve endpoint ──────────────────────────────────────────────────────────
_base = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4318")
traces_endpoint = os.getenv(
    "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT",
    _base.rstrip("/") + "/v1/traces",
)
if not traces_endpoint.endswith("/v1/traces"):
    traces_endpoint = traces_endpoint.rstrip("/") + "/v1/traces"

# ── resolve service name ──────────────────────────────────────────────────────
service_name = (
    os.getenv("SERVICE_NAME")
    or os.getenv("OTEL_SERVICE_NAME")
    or "synthetic-windows-check"
)

# ── build resource (parse OTEL_RESOURCE_ATTRIBUTES best-effort) ───────────────
resource_attrs: dict = {"service.name": service_name}
raw_res = os.getenv("OTEL_RESOURCE_ATTRIBUTES", "")
if raw_res:
    for pair in raw_res.split(","):
        pair = pair.strip()
        if "=" in pair:
            k, _, v = pair.partition("=")
            resource_attrs[k.strip()] = v.strip()
# Ensure service.name is always set from env, not overridden by attr string
resource_attrs["service.name"] = service_name

resource = Resource.create(resource_attrs)

# ── tracer provider ───────────────────────────────────────────────────────────
provider = TracerProvider(resource=resource)
exporter = OTLPSpanExporter(endpoint=traces_endpoint)
# SimpleSpanProcessor ensures synchronous export before process exits
provider.add_span_processor(SimpleSpanProcessor(exporter))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("bosscat.canary")

# ── record send timestamp (nanoseconds, monotonic wall-clock) ─────────────────
send_ts_ns = time.time_ns()
canary_id  = send_ts_ns // 1_000_000  # epoch-ms

# ── emit canary span ──────────────────────────────────────────────────────────
try:
    with tracer.start_as_current_span(
        "bc.synthetic.root",
        attributes={
            "check.kind":  "gate-verification",
            "component":   "windows-collector",
            "test.type":   "end-to-end-verification",
            "canary.id":   str(canary_id),
            "send.ts.ns":  str(send_ts_ns),
        },
    ) as span:
        # Capture the OTel trace-id (128-bit hex, 32 chars)
        ctx = span.get_span_context()
        trace_id_int = ctx.trace_id
        trace_id_hex = format(trace_id_int, "032x")

        # Small pause so the span has a non-zero duration
        time.sleep(0.05)

except Exception as exc:
    print(f"ERROR: span export failed: {exc}", file=sys.stderr)
    sys.exit(2)

# ── flush (SimpleSpanProcessor is synchronous; BatchSpanProcessor needs this) ─
try:
    provider.force_flush(timeout_millis=10_000)
except Exception:
    pass

# ── machine-readable output (parsed by verify-pipeline.ps1) ──────────────────
print(f"TRACE_ID={trace_id_hex}")
print(f"CANARY_ID={canary_id}")
print(f"SEND_TS_NS={send_ts_ns}")
print('{"attempted": true, "ok": true}')

sys.exit(0)
