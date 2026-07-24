# Wait for Docker Kafka, then start the Windows otelcol-contrib service.
# Use from boot scripts or bring-up when Kafka is not a Windows service dependency.
# KafkaWaitSec: allow Docker Desktop + Kafka cold-start (90s+ on slow hardware).

param(
  [int]$KafkaWaitSec = 180,
  [int]$HealthWaitSec = 15,
  [int]$KafkaSettleSec = 3
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$startTime = Get-Date

Write-Host "Starting Windows OTel collector (with Kafka readiness wait)..." -ForegroundColor Cyan

$kafkaScript = Join-Path $repoRoot 'kafka-smoke.ps1'
$kafkaExit = 0
if (Test-Path $kafkaScript) {
  & $kafkaScript -Broker 'localhost:9092' -WaitTimeoutSec $KafkaWaitSec -SettleSec $KafkaSettleSec
  $kafkaExit = $LASTEXITCODE
  $kafkaReadyAt = (Get-Date) - $startTime
  $kafkaSec = [int]$kafkaReadyAt.TotalSeconds
  $marginSec = $KafkaWaitSec - $kafkaSec
  if ($kafkaExit -eq 0) {
    Write-Host "Kafka ready after ${kafkaSec}s (margin: ${marginSec}s of ${KafkaWaitSec}s window)" -ForegroundColor Cyan
  } else {
    Write-Host "Kafka not ready after ${kafkaSec}s (exceeded ${KafkaWaitSec}s window or broker down)" -ForegroundColor Yellow
  }
  $logDir = Join-Path $repoRoot 'artifacts'
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
  $logLine = "$(Get-Date -Format 'o') kafka_ready_sec=$kafkaSec margin_sec=$marginSec timeout_sec=$KafkaWaitSec kafka_exit=$kafkaExit"
  Add-Content -Path (Join-Path $logDir 'collector-kafka-ready.log') -Value $logLine -Encoding utf8
  if ($kafkaExit -ne 0) {
    Write-Host "Collector may fail until broker is up; SCM retry will cover delayed Docker starts" -ForegroundColor Yellow
  }
}

$service = Get-Service -Name 'otelcol-contrib' -ErrorAction SilentlyContinue
if (-not $service) {
  Write-Error 'otelcol-contrib service not installed'
  exit 1
}

if ($service.Status -ne 'Running') {
  Start-Service -Name 'otelcol-contrib'
  Start-Sleep -Seconds 3
  $service = Get-Service -Name 'otelcol-contrib'
}

if ($service.Status -ne 'Running') {
  Write-Error "otelcol-contrib failed to start (status: $($service.Status))"
  exit 1
}

Write-Host "Collector service running; waiting for health endpoint..." -ForegroundColor Cyan
$deadline = (Get-Date).AddSeconds($HealthWaitSec)
do {
  try {
    $health = Invoke-WebRequest -Uri 'http://127.0.0.1:13134/healthz' -TimeoutSec 3 -UseBasicParsing | ConvertFrom-Json
    if ($health.status -eq 'Server available') {
      $totalSec = [int]((Get-Date) - $startTime).TotalSeconds
      Write-Host "Collector healthy after ${totalSec}s (uptime $($health.uptime))" -ForegroundColor Green
      exit 0
    }
  } catch {
    # still starting
  }
  Start-Sleep -Seconds 1
} while ((Get-Date) -lt $deadline)

Write-Host "Collector running but health endpoint not ready yet" -ForegroundColor Yellow
exit 0
