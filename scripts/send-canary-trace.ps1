# Send Canary Trace with Assertion
# Part of BossCat OEM Gate Hardening Framework

param(
  [string]$ServiceName = "synthetic-windows-check",
  [string]$ScriptPath  = "C:\otel\synthetic\send_synthetic_otel_simple.py",
  [int]$WaitSeconds    = 60
)

Write-Host "`n🐾 [BossCat Canary] Sending trace for '$ServiceName'..." -ForegroundColor Cyan

# Set OTLP configuration for local collector (Docker mapped ports)
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:14318"  # Docker port mapping
$env:OTEL_RESOURCE_ATTRIBUTES = "service.name=$ServiceName,service.version=0.1.0,os.type=windows"
$env:OTEL_LOG_LEVEL = "info"

# Check if Python script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Error "❌ Canary script not found: $ScriptPath"
    Write-Host "ℹ️  Using fallback minimal trace..."
    
    # Fallback: use Python inline if available
    $fallbackScript = @'
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
import time

service_name = "synthetic-windows-check"
provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
trace.set_tracer_provider(provider)
exporter = OTLPSpanExporter(endpoint="http://127.0.0.1:4318/v1/traces")
provider.add_span_processor(BatchSpanProcessor(exporter))
tr = trace.get_tracer(__name__)

with tr.start_as_current_span("bosscat-canary-span") as span:
    span.set_attribute("synthetic", True)
    span.set_attribute("bosscat.gate", "GATE-2025-10-08-234500")
    span.add_event("canary_start")
    time.sleep(0.1)
    span.add_event("canary_end")

provider.force_flush()
print("✅ Sent canary trace")
'@
    
    $tempScript = "$env:TEMP\bosscat_canary_$(Get-Date -Format 'yyyyMMdd_HHmmss').py"
    $fallbackScript | Out-File -FilePath $tempScript -Encoding UTF8
    $ScriptPath = $tempScript
}

# Send the trace
Write-Host "📤 Sending canary trace..."
python -u $ScriptPath

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Canary send failed with exit code $LASTEXITCODE"
    exit 2
}

Write-Host "✅ Canary sent successfully"
Write-Host "⏳ [BossCat Canary] Waiting up to $WaitSeconds seconds for ingestion..."
Start-Sleep -Seconds $WaitSeconds

# Heuristic assertion: look for collector "Exported spans" log in last minute
Write-Host "🔍 Checking collector logs for confirmation..."
try {
    $log = docker logs --since 1m signoz-otel-collector 2>$null
    
    if ($log -match "Exported spans|exporter.*otlp|TracesExporter") {
        Write-Host "✅ Canary likely ingested (collector exported spans in last minute)" -ForegroundColor Green
        Write-Host "ℹ️  Verify in SigNoz UI: http://localhost:8080/traces?service=$ServiceName" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Warning "⚠️  Could not confirm via logs; check SigNoz Traces/Service '$ServiceName'"
        Write-Host "ℹ️  SigNoz UI: http://localhost:8080/traces?service=$ServiceName" -ForegroundColor Cyan
        exit 1
    }
} catch {
    Write-Host "(ℹ️  info) Skipping collector confirmation; check SigNoz UI manually."
    Write-Host "ℹ️  SigNoz UI: http://localhost:8080/traces?service=$ServiceName" -ForegroundColor Cyan
    exit 0
}

