# OTLP Host Wiring Cheat Sheet

This note shows how to send OpenTelemetry data from *host* processes (Cursor agents, Node scripts, Playwright, Python, etc.) directly into the SigNoz collector that runs inside Docker. The goal is a single ingestion point on the host so every tool shares the same OTLP endpoint.

## Topology

```
[ Host process ] -> http://127.0.0.1:<host-OTLP-http-port> -> signoz-otel-collector (Docker) -> ClickHouse -> SigNoz UI
```

- Collector container name: `signoz-otel-collector`
- Default container ports: 4318/tcp (HTTP), 4317/tcp (gRPC)
- Host sees the mapped ports reported by `docker inspect`

## Quick Commands

```powershell
# 1) Discover mapped OTLP ports
$collectorName = "signoz-otel-collector"
$httpPort = docker inspect -f "{{(index (index .NetworkSettings.Ports \"4318/tcp\") 0).HostPort}}" $collectorName
$grpcPort = docker inspect -f "{{(index (index .NetworkSettings.Ports \"4317/tcp\") 0).HostPort}}" $collectorName
"`nCollector host ports -> HTTP:$httpPort  gRPC:$grpcPort"

# 2) Export OTLP settings for this session
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:$httpPort"
$env:OTEL_SERVICE_NAME = "smoke"
$env:OTEL_RESOURCE_ATTRIBUTES = "env=dev,host=windows"

# 3) Listener health
Test-NetConnection 127.0.0.1 -Port $httpPort
Test-NetConnection 127.0.0.1 -Port $grpcPort

# 4) Optional: confirm a Windows collector forwards only
Select-String -Path "C:\\otel\\config.yaml" -Pattern "otlphttp" -Context 2,5

# 5) Emit a smoke span (Python)
py - <<'PY'
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
import os, time
trace.set_tracer_provider(TracerProvider(resource=Resource.create({"service.name": os.environ.get("OTEL_SERVICE_NAME", "smoke")})))
tracer_provider = trace.get_tracer_provider()
tracer_provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"])))
tracer = trace.get_tracer("smoke")
with tracer.start_as_current_span("otel-smoke-span"):
    time.sleep(0.05)
print("sent span")
PY

# Helper: show the active OTLP env
Get-ChildItem Env:OTEL_EXPORTER_OTLP_ENDPOINT,OTEL_EXPORTER_OTLP_PROTOCOL,OTEL_SERVICE_NAME,OTEL_RESOURCE_ATTRIBUTES
```

## Verification Flow

1. `docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"` — collector should be running and expose the mapped ports.
2. `docker inspect -f "HTTP={{(index (index .NetworkSettings.Ports \"4318/tcp\") 0).HostPort}}; GRPC={{(index (index .NetworkSettings.Ports \"4317/tcp\") 0).HostPort}}" signoz-otel-collector` — confirm host ports.
3. SigNoz UI → Traces → Search → Filter `resource.service.name = 'smoke'` — expect span `otel-smoke-span` after running the Python snippet.

## Environment Persistence

Add these lines to your PowerShell profile (or to launch scripts) so every run points at the same collector:

```powershell
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:<host-OTLP-http-port>"
$env:OTEL_SERVICE_NAME = "my-service"
$env:OTEL_RESOURCE_ATTRIBUTES = "env=dev,host=windows"
```

For containers that must send data to the host collector use `http://host.docker.internal:<host-OTLP-http-port>` instead of `127.0.0.1`.

## Troubleshooting Checklist

- **Collector missing in `docker ps`:** Start the SigNoz stack (for example `docker compose up -d` in the SigNoz directory).
- **Wrong port:** Always use the host port from `docker inspect`, not the container port 4318/4317.
- **Protocol mismatch:** Keep `http/protobuf` with the HTTP port and `grpc` with the gRPC port. Mixing the two gives `EOF` or `UNAVAILABLE` errors.
- **Multiple collectors ingesting separately:** If a Windows `otelcol-contrib` is installed, configure it to forward to `http://127.0.0.1:<host-OTLP-http-port>` so SigNoz remains the single ingestion point.

## Related Scripts

- `scripts/test-otlp-wiring.ps1` — automated smoke test with connectivity checks and span emission.
- `scripts/verify-wiring.ps1` — broader pipeline verification that should incorporate the same OTLP endpoint.

Keep this document alongside `docs/WIRING_GUIDE.md`; update both whenever the ports, container names, or verification workflow change.




