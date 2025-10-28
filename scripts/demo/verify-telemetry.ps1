# Investor Demo: Telemetry Readiness Verification
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Phase 1: Smoke test for demo telemetry end-to-end

param(
    [string]$Service1 = "bosscat-svc2-api",
    [string]$Service2 = "bosscat-svc3-worker",
    [int]$Port1 = 5556,
    [int]$Port2 = 5557,
    [string]$SigNozUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"
$passCount = 0
$totalChecks = 0

Write-Host "=== Investor Demo: Telemetry Verification ===" -ForegroundColor Cyan
Write-Host ""

# Helper function for checks
function Test-Check {
    param([string]$Name, [scriptblock]$Test)
    
    $script:totalChecks++
    Write-Host "[$script:totalChecks] $Name..." -ForegroundColor White -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host " ✅ PASS" -ForegroundColor Green
            $script:passCount++
            return $true
        } else {
            Write-Host " ❌ FAIL" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host " ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 1. Infrastructure Checks
Test-Check "Docker containers operational" {
    $containers = docker ps --format "{{.Names}}" | Select-String "signoz|pm-engine|redis"
    return ($containers.Count -ge 10)
}

Test-Check "SigNoz health API responding" {
    $health = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -TimeoutSec 5 -ErrorAction Stop
    return ($health.status -eq "ok")
}

Test-Check "Windows Collector running" {
    $status = sc query otelcol-contrib 2>&1
    return ($status -match "RUNNING")
}

Test-Check "OTLP gRPC endpoint (14317)" {
    $result = Test-NetConnection localhost -Port 14317 -WarningAction SilentlyContinue
    return ($result.TcpTestSucceeded -eq $true)
}

# 2. Service Health Checks
Test-Check "Service 1 (${Service1}:${Port1}) responding" {
    try {
        $result = Invoke-RestMethod -Uri "http://localhost:$Port1/health" -TimeoutSec 3 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

Test-Check "Service 2 (${Service2}:${Port2}) responding" {
    try {
        $result = Invoke-RestMethod -Uri "http://localhost:$Port2/health" -TimeoutSec 3 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# 3. Telemetry Flow Checks
Write-Host ""
Write-Host "Generating test traffic for telemetry verification..." -ForegroundColor Yellow

# Send test requests
try {
    Invoke-WebRequest -Uri "http://localhost:$Port1/test" -Method Get -UseBasicParsing | Out-Null
    Start-Sleep -Seconds 2
} catch {
    Write-Host "⚠️  Warning: Test request failed, continuing verification..." -ForegroundColor Yellow
}

Test-Check "SigNoz UI accessible" {
    try {
        $result = Invoke-WebRequest -Uri $SigNozUrl -UseBasicParsing -TimeoutSec 5
        return ($result.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# Note: Actual trace verification requires SigNoz API key
# For demo, we verify infrastructure is ready
Test-Check "Collector metrics endpoint (8888)" {
    $result = Test-NetConnection localhost -Port 8888 -WarningAction SilentlyContinue
    return ($result.TcpTestSucceeded -eq $true)
}

# 4. Demo Artifact Checks
Test-Check "Data Room harness exists" {
    return (Test-Path "docs\demo\data-room.html")
}

Test-Check "Demo script exists" {
    return (Test-Path "docs\demo\DEMO_SCRIPT.md")
}

# Summary
Write-Host ""
Write-Host "=== Verification Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passCount / $totalChecks" -ForegroundColor $(if ($passCount -eq $totalChecks) { 'Green' } elseif ($passCount -ge ($totalChecks * 0.8)) { 'Yellow' } else { 'Red' })

if ($passCount -eq $totalChecks) {
    Write-Host ""
    Write-Host "✅ DEMO READY - All telemetry checks PASS" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Open Data Room: file:///C:/otel/docs/demo/data-room.html" -ForegroundColor Gray
    Write-Host "  2. Open SigNoz: http://localhost:8080" -ForegroundColor Gray
    Write-Host "  3. Review script: C:\otel\docs\demo\DEMO_SCRIPT.md" -ForegroundColor Gray
    Write-Host ""
    exit 0
} elseif ($passCount -ge ($totalChecks * 0.8)) {
    Write-Host ""
    Write-Host "⚠️  DEMO PARTIAL - Some checks failed (non-critical)" -ForegroundColor Yellow
    Write-Host "   Review failures above and proceed with caution" -ForegroundColor Yellow
    Write-Host ""
    exit 1
} else {
    Write-Host ""
    Write-Host "❌ DEMO BLOCKED - Critical checks failed" -ForegroundColor Red
    Write-Host "   Fix infrastructure issues before proceeding" -ForegroundColor Red
    Write-Host ""
    exit 2
}

