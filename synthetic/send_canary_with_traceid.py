#!/usr/bin/env python3
"""
BossCat OEM - Forensic-Grade Canary Trace Generator

Sends a synthetic OpenTelemetry trace and emits machine-readable verification data:
- TRACE_ID: 32-character hex trace identifier for pinpoint verification
- CANARY_ID: Unique canary run identifier (timestamp-based)
- SEND_TS_NS: Nanosecond timestamp of trace send (for latency calculation)

Usage:
    python send_canary_with_traceid.py

Environment Variables:
    SERVICE_NAME: Service name for trace (default: synthetic-windows-check)
    OTEL_EXPORTER_OTLP_ENDPOINT: OTLP endpoint (default: http://127.0.0.1:4318/v1/traces)

Output Format (machine-readable):
    TRACE_ID=<32-char-hex>
    CANARY_ID=<timestamp-ms>
    SEND_TS_NS=<nanosecond-timestamp>

References:
    - OTLP/HTTP endpoint: Avoids gRPC native dependency issues on Windows
    - SigNoz verification: Uses trace ID for pinpoint API queries
"""

from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
import time
import os
import sys

# Configuration from environment
service_name = os.getenv("SERVICE_NAME", "synthetic-windows-check")

# Accept base or full path; normalize to full /v1/traces
raw = os.getenv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT") or os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT") or "http://127.0.0.1:14318"
if not raw.endswith("/v1/traces"):
    endpoint = raw.rstrip("/") + "/v1/traces"
else:
    endpoint = raw

# Initialize OpenTelemetry tracer
provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
trace.set_tracer_provider(provider)
exporter = OTLPSpanExporter(endpoint=endpoint)
provider.add_span_processor(BatchSpanProcessor(exporter))
tracer = trace.get_tracer("boss-cat.canary")

# Generate unique canary ID (millisecond timestamp)
canary_id = str(int(time.time() * 1000))
send_ts_ns = time.time_ns()

# Create canary span with forensic attributes
with tracer.start_as_current_span("canary-span") as span:
    span.set_attribute("canary.id", canary_id)
    span.set_attribute("boss.cat", True)
    span.set_attribute("canary.type", "forensic-verification")
    span.add_event("canary_start")
    time.sleep(0.05)  # Minimal span duration
    span.add_event("canary_end")
    
    # Extract trace ID from span context
    span_context = span.get_span_context()
    trace_id_hex = format(span_context.trace_id, "032x")

# Force flush to ensure span is sent
provider.force_flush()

# Emit machine-readable output for verification script
print(f"TRACE_ID={trace_id_hex}")
print(f"CANARY_ID={canary_id}")
print(f"SEND_TS_NS={send_ts_ns}")
sys.stdout.flush()

# Success
sys.exit(0)

