# SigNoz Canary Monitoring Script
# Generates test logs and provides verification commands

param(
    [switch]$GenerateCanary,
    [switch]$CheckRecent,
    [switch]$VerifySigNoz,
    [switch]$Help
)

if ($Help) {
    Write-Host "SigNoz Canary Monitoring Script" -ForegroundColor Green
    Write-Host "Usage: .\signoz-canary-monitor.ps1 [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -GenerateCanary    Create a new canary log entry" -ForegroundColor White
    Write-Host "  -CheckRecent       Show recent log entries" -ForegroundColor White
    Write-Host "  -VerifySigNoz      Check SigNoz connectivity" -ForegroundColor White
    Write-Host "  -Help              Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\signoz-canary-monitor.ps1 -GenerateCanary" -ForegroundColor White
    Write-Host "  .\signoz-canary-monitor.ps1 -CheckRecent" -ForegroundColor White
    Write-Host "  .\signoz-canary-monitor.ps1 -VerifySigNoz" -ForegroundColor White
    exit 0
}

# Ensure log directory exists
if (-not (Test-Path 'C:\logs')) {
    New-Item -Path 'C:\logs' -ItemType Directory -Force | Out-Null
    Write-Host "Created C:\logs directory" -ForegroundColor Green
}

if ($GenerateCanary) {
    Write-Host "`n=== Generating SigNoz Canary Log Entry ===" -ForegroundColor Green
    
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $payload = [ordered]@{
        timestamp = $timestamp
        level     = 'INFO'
        message   = 'SigNoz test from hardened collector'
        service   = 'windows-host'
        test_id   = [System.Guid]::NewGuid().ToString('N').Substring(0,8)
    }
    
    $json = $payload | ConvertTo-Json -Compress
    Add-Content -Path 'C:\logs\test.log' -Value $json
    
    Write-Host "✓ Canary log entry created" -ForegroundColor Green
    Write-Host "  Timestamp: $timestamp" -ForegroundColor Gray
    Write-Host "  Test ID: $($payload.test_id)" -ForegroundColor Gray
    Write-Host "  File: C:\logs\test.log" -ForegroundColor Gray
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Go to Logs → Logs Explorer" -ForegroundColor White
    Write-Host "3. Apply filter: service.name = `"windows-host`"" -ForegroundColor White
    Write-Host "4. Look for message: `"SigNoz test from hardened collector`"" -ForegroundColor White
}

if ($CheckRecent) {
    Write-Host "`n=== Recent Log Entries ===" -ForegroundColor Green
    
    if (Test-Path 'C:\logs\test.log') {
        $recentLogs = Get-Content -Path 'C:\logs\test.log' -Tail 5
        Write-Host "Last 5 entries from C:\logs\test.log:" -ForegroundColor Yellow
        
        foreach ($log in $recentLogs) {
            try {
                $logObj = $log | ConvertFrom-Json
                Write-Host "  [$($logObj.timestamp)] $($logObj.level): $($logObj.message)" -ForegroundColor White
                if ($logObj.test_id) {
                    Write-Host "    Test ID: $($logObj.test_id)" -ForegroundColor Gray
                }
            } catch {
                Write-Host "  Raw: $log" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "No log file found at C:\logs\test.log" -ForegroundColor Red
    }
}

if ($VerifySigNoz) {
    Write-Host "`n=== SigNoz Connectivity Check ===" -ForegroundColor Green
    
    # Check SigNoz UI port
    try {
        $uiTest = Test-NetConnection -ComputerName localhost -Port 8080 -WarningAction SilentlyContinue
        if ($uiTest.TcpTestSucceeded) {
            Write-Host "✓ SigNoz UI (8080): OPEN" -ForegroundColor Green
        } else {
            Write-Host "✗ SigNoz UI (8080): CLOSED" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ SigNoz UI (8080): ERROR" -ForegroundColor Red
    }
    
    # Check SigNoz OTLP ports
    try {
        $grpcTest = Test-NetConnection -ComputerName localhost -Port 4317 -WarningAction SilentlyContinue
        if ($grpcTest.TcpTestSucceeded) {
            Write-Host "✓ SigNoz OTLP gRPC (4317): OPEN" -ForegroundColor Green
        } else {
            Write-Host "✗ SigNoz OTLP gRPC (4317): CLOSED" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ SigNoz OTLP gRPC (4317): ERROR" -ForegroundColor Red
    }
    
    try {
        $httpTest = Test-NetConnection -ComputerName localhost -Port 4318 -WarningAction SilentlyContinue
        if ($httpTest.TcpTestSucceeded) {
            Write-Host "✓ SigNoz OTLP HTTP (4318): OPEN" -ForegroundColor Green
        } else {
            Write-Host "✗ SigNoz OTLP HTTP (4318): CLOSED" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ SigNoz OTLP HTTP (4318): ERROR" -ForegroundColor Red
    }
    
    # Check SigNoz health endpoint
    try {
        $healthResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health' -TimeoutSec 5
        Write-Host "✓ SigNoz Health: $($healthResponse.status)" -ForegroundColor Green
    } catch {
        Write-Host "✗ SigNoz Health: UNAVAILABLE" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# If no parameters provided, show help
if (-not ($GenerateCanary -or $CheckRecent -or $VerifySigNoz)) {
    Write-Host "SigNoz Canary Monitoring Script" -ForegroundColor Green
    Write-Host "Use -Help for usage information" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick commands:" -ForegroundColor Cyan
    Write-Host "  .\signoz-canary-monitor.ps1 -GenerateCanary" -ForegroundColor White
    Write-Host "  .\signoz-canary-monitor.ps1 -CheckRecent" -ForegroundColor White
    Write-Host "  .\signoz-canary-monitor.ps1 -VerifySigNoz" -ForegroundColor White
}
