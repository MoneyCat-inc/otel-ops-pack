Write-Host "== Verifying Observability Pipeline ==" -ForegroundColor Cyan

$failures = @()

function Test-Port {
    param(
        [int[]]$Ports,
        [string]$Label
    )

    foreach ($port in $Ports) {
        $listening = Test-NetConnection -ComputerName "localhost" -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($listening) {
            Write-Host "  [OK] $Label port $port listening" -ForegroundColor Green
            return
        }
    }

    Write-Host "  [FAIL] $Label not listening on ports $($Ports -join ', ')" -ForegroundColor Red
    $failures += "$Label port unavailable"
}

Write-Host "[1/5] Checking SigNoz UI health..." -ForegroundColor Yellow
try {
    $uiResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
    if ($uiResponse.status -eq "ok") {
        Write-Host "  [OK] SigNoz UI status: ok" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] SigNoz UI status: $($uiResponse.status)" -ForegroundColor Red
        $failures += "SigNoz UI health"
    }
} catch {
    Write-Host "  [FAIL] SigNoz UI unreachable: $($_.Exception.Message)" -ForegroundColor Red
    $failures += "SigNoz UI health"
}

Write-Host "[2/5] Checking collector health endpoint..." -ForegroundColor Yellow
try {
    $collectorResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if (@("Serving", "Server available") -contains $collectorResponse.status) {
        Write-Host "  [OK] Collector health: $($collectorResponse.status)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Collector health: $($collectorResponse.status)" -ForegroundColor Red
        $failures += "Collector health"
    }
} catch {
    Write-Host "  [FAIL] Collector health endpoint unreachable: $($_.Exception.Message)" -ForegroundColor Red
    $failures += "Collector health"
}

Write-Host "[3/5] Checking collector metrics endpoint..." -ForegroundColor Yellow
try {
    $metricsResponse = Invoke-WebRequest -Uri "http://localhost:8888/metrics" -TimeoutSec 5
    if ($metricsResponse.StatusCode -eq 200) {
        $metricLines = $metricsResponse.Content -split "`n" | Where-Object { $_ -match "otelcol_" }
        Write-Host "  [OK] Metrics endpoint responded with $($metricLines.Count) otelcol_* metrics" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Metrics endpoint returned status $($metricsResponse.StatusCode)" -ForegroundColor Red
        $failures += "Collector metrics"
    }
} catch {
    Write-Host "  [FAIL] Collector metrics unreachable: $($_.Exception.Message)" -ForegroundColor Red
    $failures += "Collector metrics"
}

Write-Host "[4/5] Checking OTLP listener ports..." -ForegroundColor Yellow
Test-Port -Ports @(5317, 4317) -Label "OTLP gRPC"
Test-Port -Ports @(5318, 4318) -Label "OTLP HTTP"

Write-Host "[5/5] Checking canary log freshness..." -ForegroundColor Yellow
$logPath = "C:\\logs\\canary-test.log"
if (Test-Path $logPath) {
    $lastWrite = (Get-Item $logPath).LastWriteTime
    $ageMinutes = ((Get-Date) - $lastWrite).TotalMinutes
    Write-Host "  [OK] Canary log exists (age: $([math]::Round($ageMinutes, 2)) minutes)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Canary log file missing at $logPath" -ForegroundColor Red
    $failures += "Canary log missing"
}

if ($failures.Count -eq 0) {
    Write-Host "== Observability pipeline healthy ==" -ForegroundColor Green
    exit 0
} else {
    Write-Host "== Observability pipeline issues detected ==" -ForegroundColor Red
    Write-Host "Failing checks: $($failures -join ', ')" -ForegroundColor Red
    exit 1
}


