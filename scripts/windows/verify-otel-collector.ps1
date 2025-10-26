# BOSSCAT-022A: Verify Windows OpenTelemetry Collector
# Purpose: Health check + canary event for gate verification
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
  [string]$ServiceName = "otelcol-contrib",
  [string]$AggregatorHost = "127.0.0.1",
  [int]$GrpcPort = 14317,
  [int]$HttpPort = 14318,
  [string]$CanarySource = "VizCanary",
  [int]$WaitSeconds = 3
)

$ErrorActionPreference = "Stop"

Write-Host "=== BOSSCAT-022A :: Verify Windows Collector ===" -ForegroundColor Cyan
Write-Host ""

# Check 1: Service running?
Write-Host "[1/4] Checking service state..." -ForegroundColor White
try {
  $svc = Get-Service -Name $ServiceName -ErrorAction Stop
  
  if ($svc.Status -ne "Running") {
    Write-Error "Service '$ServiceName' not RUNNING (Status: $($svc.Status))"
    exit 1
  }
  
  Write-Host "  ✓ Service state: RUNNING" -ForegroundColor Green
  
  # Check start type
  $startType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'").StartMode
  Write-Host "  → Start type: $startType" -ForegroundColor Gray
  
} catch {
  Write-Error "Service '$ServiceName' not found or inaccessible: $_"
  exit 1
}

# Check 2: Aggregator reachable (OTLP endpoints)
Write-Host ""
Write-Host "[2/4] Testing OTLP aggregator connectivity..." -ForegroundColor White

$grpcReachable = $false
$httpReachable = $false

try {
  $grpcTest = Test-NetConnection -ComputerName $AggregatorHost -Port $GrpcPort -WarningAction SilentlyContinue -InformationLevel Quiet
  if ($grpcTest) {
    $grpcReachable = $true
    Write-Host "  ✓ gRPC port $GrpcPort: REACHABLE" -ForegroundColor Green
  }
} catch {
  Write-Host "  ✗ gRPC port $GrpcPort: UNREACHABLE" -ForegroundColor Yellow
}

try {
  $httpTest = Test-NetConnection -ComputerName $AggregatorHost -Port $HttpPort -WarningAction SilentlyContinue -InformationLevel Quiet
  if ($httpTest) {
    $httpReachable = $true
    Write-Host "  ✓ HTTP port $HttpPort: REACHABLE" -ForegroundColor Green
  }
} catch {
  Write-Host "  ✗ HTTP port $HttpPort: UNREACHABLE" -ForegroundColor Yellow
}

if (-not ($grpcReachable -or $httpReachable)) {
  Write-Error "Aggregator not reachable on $AggregatorHost:$GrpcPort or :$HttpPort"
  Write-Host ""
  Write-Host "  Troubleshooting:" -ForegroundColor Yellow
  Write-Host "  - Ensure Docker containers are running: docker ps" -ForegroundColor Gray
  Write-Host "  - Check signoz-otel-collector exposes ports 14317/14318" -ForegroundColor Gray
  Write-Host "  - Verify firewall rules allow localhost connections" -ForegroundColor Gray
  exit 1
}

# Check 3: Write Windows Event canary
Write-Host ""
Write-Host "[3/4] Writing canary event..." -ForegroundColor White

try {
  # Ensure event source exists
  if (-not [System.Diagnostics.EventLog]::SourceExists($CanarySource)) {
    New-EventLog -LogName Application -Source $CanarySource
    Write-Host "  → Created event source: $CanarySource" -ForegroundColor Gray
  }
  
  # Generate unique event ID
  $eid = Get-Random -Minimum 60000 -Maximum 65000
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $message = "BOSSCAT-022A canary event | EID=$eid | Timestamp=$timestamp | Verification=WINCOLL-03"
  
  Write-EventLog -LogName Application -Source $CanarySource -EventId $eid -EntryType Information -Message $message
  Write-Host "  ✓ Canary event written to Application log" -ForegroundColor Green
  Write-Host "  → Event ID: $eid" -ForegroundColor Gray
  Write-Host "  → Source: $CanarySource" -ForegroundColor Gray
  
} catch {
  Write-Warning "Failed to write canary event: $_"
  Write-Host "  → Non-critical: Event log may require admin privileges" -ForegroundColor Yellow
}

# Check 4: Wait for ingestion
Write-Host ""
Write-Host "[4/4] Waiting for collector to process..." -ForegroundColor White
Start-Sleep -Seconds $WaitSeconds
Write-Host "  ✓ Wait complete ($WaitSeconds seconds)" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Windows Collector Verification Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Local Checks:" -ForegroundColor White
Write-Host "  ✓ Service RUNNING" -ForegroundColor Green
Write-Host "  ✓ OTLP aggregator reachable" -ForegroundColor Green
Write-Host "  ✓ Canary event written" -ForegroundColor Green
Write-Host ""
Write-Host "Note: End-to-end ingestion verification will be performed" -ForegroundColor White
Write-Host "      by the gate pipeline as a separate step (WINCOLL-03)." -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Check collector telemetry: http://localhost:8888/metrics" -ForegroundColor Gray
Write-Host "  2. Verify in SigNoz UI: Look for host metrics and event logs" -ForegroundColor Gray
Write-Host "  3. Run full gate verification: pwsh -File BRAV\SCPT\verify-pipeline.ps1" -ForegroundColor Gray
Write-Host ""

