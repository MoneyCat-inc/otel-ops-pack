#!/usr/bin/env python3
"""
Minimal OTLP trace canary sender.
- Posts a single span to OTLP HTTP endpoint (JSON body) for collector ingestion
- Prints machine-readable markers for downstream verification:
  TRACE_ID=..., CANARY_ID=..., SEND_TS_NS=...

Defaults:
- Endpoint from OTEL_EXPORTER_OTLP_TRACES_ENDPOINT or http://127.0.0.1:4318/v1/traces
"""
import json
import os
import sys
import time
import uuid
from datetime import datetime, timezone
from urllib import request, error


def _hex(nbytes: int) -> str:
    return uuid.uuid4().hex[: nbytes * 2]


def build_trace_payload(trace_id: str, span_id: str, start_ns: int, end_ns: int):
    # JSON OTLP payload compatible with collector (mirrors working PowerShell script)
    return {
        "resourceSpans": [
            {
                "resource": {
                    "attributes": [
                        {"key": "service.name", "value": {"stringValue": "canary-test"}},
                        {"key": "canary", "value": {"stringValue": "true"}},
                    ]
                },
                "scopeSpans": [
                    {
                        "spans": [
                            {
                                "traceId": trace_id,
                                "spanId": span_id,
                                "name": "canary-test-span",
                                "kind": 1,
                                "startTimeUnixNano": start_ns,
                                "endTimeUnixNano": end_ns,
                                "attributes": [
                                    {"key": "canary", "value": {"stringValue": "true"}},
                                    {
                                        "key": "test.type",
                                        "value": {"stringValue": "pipeline-verification"},
                                    },
                                ],
                            }
                        ]
                    }
                ],
            }
        ]
    }


def post_json(endpoint: str, body: bytes, timeout: int = 5) -> int:
    req = request.Request(endpoint, data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode() or 0
    except error.HTTPError as e:
        return e.code
    except Exception:
        return -1


def main() -> int:
    # Prefer env var set by verify script; fallback to the SigNoz OTLP HTTP endpoint.
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT", "http://127.0.0.1:4318/v1/traces")
    # Prepare IDs and timing
    trace_id = uuid.uuid4().hex  # 32 hex chars
    span_id = uuid.uuid4().hex[:16]  # 16 hex chars
    send_ts_ns = int(time.time_ns())
    start_ns = send_ts_ns
    end_ns = start_ns + 100_000_000  # +100ms

    payload = build_trace_payload(trace_id, span_id, start_ns, end_ns)
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")

    # Try primary endpoint, then common fallbacks.
    endpoints = [endpoint, "http://localhost:5318/v1/traces", "http://localhost:4318/v1/traces"]
    status = None
    for ep in endpoints:
        status = post_json(ep, body)
        if status == 200:
            # Success
            print(f"TRACE_ID={trace_id}")
            print(f"CANARY_ID={int(datetime.now(tz=timezone.utc).timestamp())}")
            print(f"SEND_TS_NS={send_ts_ns}")
            return 0

    # If we got here, all attempts failed; emit markers for debugging
    print(f"TRACE_ID={trace_id}")
    print(f"CANARY_ID={int(datetime.now(tz=timezone.utc).timestamp())}")
    print(f"SEND_TS_NS={send_ts_ns}")
    print(f"ERROR=failed_to_post status={status}")
    return 2


if __name__ == "__main__":
    sys.exit(main())


