<#
.SYNOPSIS
  Sends a one-off canary span to the collector. With -Force, skips port checks and sends anyway.

.EXAMPLE
  pwsh -File scripts/iona-trace-canary.ps1 -CollectorHost localhost -OtlpHttpPort 5318 -ZipkinPort 9411 -ServiceName frontend -DurationMs 600 -Force
#>

[CmdletBinding()]
param(
  [string]$CollectorHost = "localhost",
  [int]$OtlpHttpPort = 5318,           # OTLP/HTTP endpoint e.g. http://host:5318/v1/traces
  [int]$ZipkinPort = 9411,             # Zipkin JSON ingest
  [string]$ServiceName = "frontend",
  [int]$DurationMs = 600,
  [string]$SpanName = "iona-canary-span",
  [hashtable]$Attributes = @{ bosscat = "1"; canary = "1"; env = "dev" },
  [switch]$Force
)

Write-Host "🐾 IONA Trace Canary — BossCat Quick Span" -ForegroundColor Cyan
Write-Host ("Service={0} • OTLP/HTTP={1}:{2} • Zipkin={3}:{4}" -f $ServiceName, $CollectorHost, $OtlpHttpPort, $CollectorHost, $ZipkinPort) -ForegroundColor DarkGray

function Test-Port($host, $port) {
  try { return (Test-NetConnection -ComputerName $host -Port $port -WarningAction SilentlyContinue).TcpTestSucceeded }
  catch { return $false }
}

function Send-Zipkin {
  param([string]$targetHost,[int]$port,[string]$svc,[string]$name,[int]$dur,[hashtable]$tags)
  $ts = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
  $span = @(
    @{
      id = "b1"
      traceId = "0123456789abcdef0123456789abcdef"
      name = $name
      timestamp = $ts
      duration  = $dur * 1000
      localEndpoint = @{ serviceName = $svc }
      tags = $tags
    }
  ) | ConvertTo-Json -Depth 6

  $url = "http://$targetHost`:$port/api/v2/spans"
  Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $span -TimeoutSec 10 | Out-Null
  Write-Host "✅ Zipkin POST → $url ($svc/$name)"
  return $true
}

function Send-OtlpCli {
  param([string]$targetHost,[int]$port,[string]$svc,[string]$name,[int]$dur,[hashtable]$tags)
  $ot = Get-Command otel-cli -ErrorAction SilentlyContinue
  if (-not $ot) { Write-Host "ℹ️ otel-cli not found"; return $false }

  $endpoint = "http://$targetHost`:$port/v1/traces"
  $attrs = ($tags.Keys | ForEach-Object { "$_=$($tags[$_])" }) -join ","
  $env:OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = $endpoint
  $env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
  & otel-cli span --name $name --service $svc --attrs $attrs --duration "$($dur)ms" | Out-Null
  Write-Host "✅ OTLP/HTTP (otel-cli) → $endpoint ($svc/$name)"
  return $true
}

# 3) Fallback OTLP/HTTP via dockerized otel-cli (no local install required)
function Send-OtlpCliDocker {
  param([string]$targetHost,[int]$port,[string]$svc,[string]$name,[int]$dur,[hashtable]$tags)
  $endpoint = "http://$targetHost`:$port/v1/traces"
  $attrs = ($tags.Keys | ForEach-Object { "$_=$($tags[$_])" }) -join ","
  $cmd = "docker run --rm -e OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$endpoint -e OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf ghcr.io/equinix-labs/otel-cli:latest span --name $name --service $svc --attrs $attrs --protocol http/protobuf --traces-endpoint $endpoint --insecure --timeout 3s"
  try {
    iex $cmd | Out-Null
    Write-Host "✅ OTLP/HTTP (docker otel-cli) → $endpoint ($svc/$name)"
    return $true
  } catch { Write-Host "OTLP docker send failed: $($_.Exception.Message)"; return $false }
}

# Decide send path
$zipkinReady = $Force -or (Test-Port $CollectorHost $ZipkinPort)
$otlpReady   = $Force -or (Test-Port $CollectorHost $OtlpHttpPort)

$sent = $false

# Prefer Zipkin JSON first (no external tool), then otel-cli
if ($zipkinReady) {
  try { $sent = Send-Zipkin -targetHost $CollectorHost -port $ZipkinPort -svc $ServiceName -name $SpanName -dur $DurationMs -tags $Attributes } catch { Write-Host "Zipkin send failed: $($_.Exception.Message)"; $sent = $false }
}

if (-not $sent -and $otlpReady) {
  try { $sent = Send-OtlpCli -targetHost $CollectorHost -port $OtlpHttpPort -svc $ServiceName -name $SpanName -dur $DurationMs -tags $Attributes } catch { Write-Host "OTLP send failed: $($_.Exception.Message)"; $sent = $false }
}

if (-not $sent -and $otlpReady) {
  try { $sent = Send-OtlpCliDocker -targetHost $CollectorHost -port $OtlpHttpPort -svc $ServiceName -name $SpanName -dur $DurationMs -tags $Attributes } catch { Write-Host "OTLP docker send failed: $($_.Exception.Message)"; $sent = $false }
}

if (-not $sent -and -not $Force) {
  Write-Host "❌ No valid send path (ports closed). Re-run with -Force to bypass checks, or enable receivers/pipeline." -ForegroundColor Red
  exit 2
}

if (-not $sent -and $Force) {
  Write-Host "⚠️ Forced send attempted but failed. Confirm receivers and traces pipeline; then retry." -ForegroundColor Yellow
  exit 3
}

Write-Host "⏳ Waiting for ingestion (5–30s)..."
Start-Sleep -Seconds 7
Write-Host "🎯 Check SigNoz → Traces; filter service=$ServiceName, span=$SpanName"
exit 0

