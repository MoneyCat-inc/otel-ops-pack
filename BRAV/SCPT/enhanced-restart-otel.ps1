# Enhanced OTel Collector Restart Script
# Handles elevated restart with preflight port checks

param(
    [switch]$Force,
    [int]$MaxWaitSeconds = 30,
    [string]$SigNozPort = "14318"
)

Write-Host "🔍 OTel Collector Enhanced Restart" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ This script requires elevated privileges (Run as Administrator)" -ForegroundColor Red
    Write-Host "💡 Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with elevated privileges" -ForegroundColor Green

# Preflight check: Ensure SigNoz OTLP HTTP endpoint is ready
Write-Host "`n🔍 Preflight Check: SigNoz OTLP HTTP Endpoint" -ForegroundColor Cyan
Write-Host "Testing connection to localhost:$SigNozPort..."

$portReady = $false
$attempts = 0
$maxAttempts = 10

while (-not $portReady -and $attempts -lt $maxAttempts) {
    $attempts++
    Write-Host "  Attempt $attempts/$maxAttempts..." -ForegroundColor Yellow
    
    try {
        $connection = Test-NetConnection -ComputerName "127.0.0.1" -Port $SigNozPort -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "  ✅ Port $SigNozPort is reachable" -ForegroundColor Green
            
            # Additional HTTP check
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$SigNozPort/" -Method Head -TimeoutSec 5 -ErrorAction Stop
                Write-Host "  ✅ HTTP endpoint responding (Status: $($response.StatusCode))" -ForegroundColor Green
                $portReady = $true
            }
            catch {
                Write-Host "  ⚠️  Port open but HTTP not ready: $($_.Exception.Message)" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
        else {
            Write-Host "  ❌ Port $SigNozPort not reachable" -ForegroundColor Red
            Start-Sleep -Seconds 3
        }
    }
    catch {
        Write-Host "  ❌ Connection test failed: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 3
    }
}

if (-not $portReady) {
    Write-Host "`n❌ SigNoz OTLP HTTP endpoint not ready after $maxAttempts attempts" -ForegroundColor Red
    if (-not $Force) {
        Write-Host "💡 Use -Force to proceed anyway, or ensure SigNoz is running" -ForegroundColor Yellow
        Write-Host "   Check SigNoz with: docker ps | findstr signoz" -ForegroundColor Yellow
        exit 1
    }
    else {
        Write-Host "⚠️  Proceeding with restart despite endpoint not ready (Force mode)" -ForegroundColor Yellow
    }
}

# Get current service status
Write-Host "`n📊 Current Service Status" -ForegroundColor Cyan
$serviceStatus = sc.exe query otelcol-contrib
Write-Host $serviceStatus

# Stop the service
Write-Host "`n🛑 Stopping otelcol-contrib service..." -ForegroundColor Yellow
$stopResult = sc.exe stop otelcol-contrib
Write-Host $stopResult

# Wait for service to stop
Write-Host "⏳ Waiting for service to stop..." -ForegroundColor Yellow
$stopped = $false
$waitTime = 0
while (-not $stopped -and $waitTime -lt $MaxWaitSeconds) {
    Start-Sleep -Seconds 1
    $waitTime++
    $status = sc.exe query otelcol-contrib
    if ($status -match "STOPPED") {
        $stopped = $true
        Write-Host "✅ Service stopped successfully" -ForegroundColor Green
    }
    else {
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }
}

if (-not $stopped) {
    Write-Host "`n❌ Service did not stop within $MaxWaitSeconds seconds" -ForegroundColor Red
    Write-Host "💡 You may need to stop it manually or check for dependencies" -ForegroundColor Yellow
    exit 1
}

# Start the service
Write-Host "`n🚀 Starting otelcol-contrib service..." -ForegroundColor Yellow
$startResult = sc.exe start otelcol-contrib
Write-Host $startResult

# Wait for service to start
Write-Host "⏳ Waiting for service to start..." -ForegroundColor Yellow
$started = $false
$waitTime = 0
while (-not $started -and $waitTime -lt $MaxWaitSeconds) {
    Start-Sleep -Seconds 1
    $waitTime++
    $status = sc.exe query otelcol-contrib
    if ($status -match "RUNNING") {
        $started = $true
        Write-Host "✅ Service started successfully" -ForegroundColor Green
    }
    else {
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }
}

if (-not $started) {
    Write-Host "`n❌ Service did not start within $MaxWaitSeconds seconds" -ForegroundColor Red
    Write-Host "💡 Check Windows Event Logs for startup errors" -ForegroundColor Yellow
    exit 1
}

# Final verification
Write-Host "`n✅ Final Verification" -ForegroundColor Cyan
$finalStatus = sc.exe query otelcol-contrib
Write-Host $finalStatus

# Test canary log emission
Write-Host "`n🧪 Testing Log Forwarding" -ForegroundColor Cyan
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists('SigNozTest')) { 
        New-EventLog -LogName Application -Source 'SigNozTest' 
    }
    $msg = "SigNoz restart test at $(Get-Date -Format s)"
    Write-EventLog -LogName Application -Source 'SigNozTest' -EventId 1002 -EntryType Information -Message $msg
    Write-Host "✅ Canary log emitted: $msg" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to emit canary log: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Enhanced Restart Complete!" -ForegroundColor Green
Write-Host "💡 Monitor logs in SigNoz UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "🔍 Check ClickHouse: docker exec signoz-clickhouse clickhouse-client --query \"SELECT timestamp, body FROM signoz_logs.logs_v2 WHERE body LIKE '%SigNoz restart test%' ORDER BY timestamp DESC LIMIT 3\"" -ForegroundColor Cyan

