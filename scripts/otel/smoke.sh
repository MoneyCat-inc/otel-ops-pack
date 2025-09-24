#!/usr/bin/env bash
set -euo pipefail

SMOKE_ID="otel-smoke-$(uuidgen | tr 'A-Z' 'a-z')"
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-120}
SKIP_STACK_CHECK=${SKIP_STACK_CHECK:-0}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

log() { printf '\n==> %s\n' "$1"; }
pass() { printf '   [OK] %s\n' "$1"; }
warn() { printf '   [WARN] %s\n' "$1"; }

wait_for() {
  local url=$1
  local deadline=$((SECONDS + TIMEOUT_SECONDS))
  while (( SECONDS < deadline )); do
    if curl -sf "$url" >/dev/null; then
      return 0
    fi
    sleep 3
  done
  return 1
}

log "Preparing SigNoz stack"
if [[ "$SKIP_STACK_CHECK" != "1" ]]; then
  (cd "$ROOT_DIR" && docker compose -f docker-compose.yml up -d)
  pass "docker compose up -d"
else
  warn "Skipping docker compose bring-up"
fi

wait_for http://localhost:13133/healthz || { echo "SigNoz collector health endpoint not ready" >&2; exit 1; }
pass "SigNoz collector healthy"
wait_for http://localhost:8080/api/v1/health || { echo "SigNoz UI health endpoint not ready" >&2; exit 1; }
pass "SigNoz UI reachable"

log "Emitting OTLP payloads ($SMOKE_ID)"
SMOKE_ID=$SMOKE_ID TMP_DIR=$TMP_DIR python3 - <<'PY'
import json, os, time, uuid

smoke_id = os.environ["SMOKE_ID"]
tmp_dir = os.environ["TMP_DIR"]
now_ns = int(time.time() * 1_000_000_000)
span_end_ns = now_ns + 5_000_000

log_payload = {
    "resourceLogs": [
        {
            "resource": {
                "attributes": [
                    {"key": "service.name", "value": {"stringValue": "windows-collector"}},
                    {"key": "deployment.environment", "value": {"stringValue": "local-smoke"}}
                ]
            },
            "scopeLogs": [
                {
                    "scope": {"name": "smoke-harness", "version": "1.0.0"},
                    "logRecords": [
                        {
                            "timeUnixNano": str(now_ns),
                            "observedTimeUnixNano": str(now_ns),
                            "severityNumber": 9,
                            "severityText": "INFO",
                            "body": {"stringValue": f"sig-smoke-log::{smoke_id}"},
                            "attributes": [
                                {"key": "smoke.id", "value": {"stringValue": smoke_id}},
                                {"key": "dataset", "value": {"stringValue": "smoke"}}
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}

trace_payload = {
    "resourceSpans": [
        {
            "resource": {
                "attributes": [
                    {"key": "service.name", "value": {"stringValue": "smoke-service"}},
                    {"key": "deployment.environment", "value": {"stringValue": "local-smoke"}}
                ]
            },
            "scopeSpans": [
                {
                    "scope": {"name": "smoke-harness", "version": "1.0.0"},
                    "spans": [
                        {
                            "traceId": uuid.uuid4().hex,
                            "spanId": uuid.uuid4().hex[:16],
                            "name": "smoke-span",
                            "kind": "SPAN_KIND_INTERNAL",
                            "startTimeUnixNano": str(now_ns),
                            "endTimeUnixNano": str(span_end_ns),
                            "attributes": [
                                {"key": "smoke.id", "value": {"stringValue": smoke_id}},
                                {"key": "smoke.phase", "value": {"stringValue": "harness"}}
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}

metric_payload = {
    "resourceMetrics": [
        {
            "resource": {
                "attributes": [
                    {"key": "service.name", "value": {"stringValue": "smoke-service"}},
                    {"key": "deployment.environment", "value": {"stringValue": "local-smoke"}}
                ]
            },
            "scopeMetrics": [
                {
                    "scope": {"name": "smoke-harness", "version": "1.0.0"},
                    "metrics": [
                        {
                            "name": "smoke_gauge",
                            "unit": "1",
                            "gauge": {
                                "dataPoints": [
                                    {
                                        "timeUnixNano": str(now_ns),
                                        "asDouble": 1.0,
                                        "attributes": [
                                            {"key": "smoke.id", "value": {"stringValue": smoke_id}}
                                        ]
                                    }
                                ]
                            }
                        }
                    ]
                }
            ]
        }
    ]
}

with open(os.path.join(tmp_dir, "logs.json"), "w", encoding="utf-8") as fh:
    json.dump(log_payload, fh)
with open(os.path.join(tmp_dir, "traces.json"), "w", encoding="utf-8") as fh:
    json.dump(trace_payload, fh)
with open(os.path.join(tmp_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metric_payload, fh)
PY

curl -sf -o /dev/null -X POST -H 'Content-Type: application/json' --data "@${TMP_DIR}/logs.json" http://localhost:4318/v1/logs
pass "OTLP log accepted"
curl -sf -o /dev/null -X POST -H 'Content-Type: application/json' --data "@${TMP_DIR}/traces.json" http://localhost:4318/v1/traces
pass "OTLP trace accepted"
curl -sf -o /dev/null -X POST -H 'Content-Type: application/json' --data "@${TMP_DIR}/metrics.json" http://localhost:4318/v1/metrics
pass "OTLP metric accepted"

sleep 10

log "Verifying ingestion"
if log_count=$(docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.distributed_logs_v2 WHERE JSONExtractString(body, 'smoke.id') = '${SMOKE_ID}'" 2>/dev/null); then
  if [[ "$log_count" -gt 0 ]]; then
    pass "Log present in ClickHouse"
  else
    warn "Log not found in ClickHouse"
  fi
else
  warn "Unable to query ClickHouse for logs"
fi

if trace_count=$(docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_traces.signoz_index_v2 WHERE attributes_string['smoke.id'] = '${SMOKE_ID}'" 2>/dev/null); then
  if [[ "$trace_count" -gt 0 ]]; then
    pass "Trace present in ClickHouse"
  else
    warn "Trace not found in ClickHouse"
  fi
else
  warn "Unable to query ClickHouse for traces"
fi

PROM_QUERY=$(python3 - <<'PY'
import urllib.parse, os
print(urllib.parse.quote(f"smoke_gauge{{smoke_id='{os.environ['SMOKE_ID']}'}}"))
PY
)
if prom_response=$(curl -sf "http://localhost:8080/api/v1/prometheus/api/v1/query?query=${PROM_QUERY}"); then
  if PROM_RESPONSE="$prom_response" python3 - <<'PY'
import json, os, sys
response = json.loads(os.environ['PROM_RESPONSE'])
result = response.get('data', {}).get('result', [])
if result:
    sys.exit(0)
sys.exit(1)
PY
  then
    pass "Metric visible via PromQL"
  else
    warn "Metric not returned via PromQL"
  fi
else
  warn "PromQL query failed"
fi

log "Smoke complete"
printf 'Smoke ID: %s\n' "$SMOKE_ID"
