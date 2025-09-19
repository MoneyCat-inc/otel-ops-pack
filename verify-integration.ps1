# Observability integration verification script

Write-Host "== Verifying Windows OTel Collector -> SigNoz ==" -ForegroundColor Cyan

$failures = @()

function Test-PortGroup {
    param(
        [int[]]$Ports,
        [string]$Label
    )

    foreach ($port in $Ports) {
        $ok = Test-NetConnection -ComputerName "localhost" -Port $port -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($ok) {
            Write-Host "  [OK] $Label port $port listening" -ForegroundColor Green
            return $true
        }
    }

    Write-Host "  [FAIL] $Label not listening on ports $($Ports -join ', ')" -ForegroundColor Red
    $script:failures += "$Label port"
    return $false
}

# 1. Check service status
Write-Host "[1/6] Checking otelcol-contrib service..." -ForegroundColor Yellow
$service = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq 'Running') {
    Write-Host "  [OK] Service running (Status: $($service.Status))" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Service not running" -ForegroundColor Red
    $failures += "otelcol-contrib service"
}

# 2. Check critical ports
Write-Host "[2/6] Checking OTLP and SigNoz ports..." -ForegroundColor Yellow
Test-PortGroup -Ports @(5317, 4317) -Label "OTLP gRPC"
Test-PortGroup -Ports @(5318, 4318) -Label "OTLP HTTP"
Test-PortGroup -Ports @(4317) -Label "SigNoz gRPC"
Test-PortGroup -Ports @(4318) -Label "SigNoz HTTP"
Test-PortGroup -Ports @(8888) -Label "Collector metrics"
Test-PortGroup -Ports @(13134) -Label "Collector health"

# 3. Collector health endpoint
Write-Host "[3/6] Checking collector health endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if (@("Serving", "Server available") -contains $health.status) {
        Write-Host "  [OK] Health endpoint reports $($health.status)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Health endpoint returned: $($health.status)" -ForegroundColor Red
        $failures += "health endpoint"
    }
} catch {
    Write-Host "  [FAIL] Failed to reach health endpoint: $($_.Exception.Message)" -ForegroundColor Red
    $failures += "health endpoint"
}

# 4. Collector self-metrics endpoint
Write-Host "[4/6] Checking collector metrics endpoint..." -ForegroundColor Yellow
try {
    $metricsResponse = Invoke-WebRequest -Uri "http://localhost:8888/metrics" -TimeoutSec 5
    if ($metricsResponse.StatusCode -eq 200) {
        Write-Host "  [OK] Metrics endpoint responded (200 OK)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Metrics endpoint returned $($metricsResponse.StatusCode)" -ForegroundColor Red
        $failures += "metrics endpoint"
    }
} catch {
    Write-Host "  [FAIL] Metrics endpoint unreachable: $($_.Exception.Message)" -ForegroundColor Red
    $failures += "metrics endpoint"
}

# 5. Fire OTLP log canary
Write-Host "[5/6] Emitting OTLP log canary..." -ForegroundColor Yellow
$timestamp = (Get-Date).ToString("o")
$canaryMessage = "windows-canary-$timestamp"

$logRecord = [pscustomobject]@{
    timeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
    severityNumber = 9
    severityText = "INFO"
    body = [pscustomobject]@{ stringValue = $canaryMessage }
    attributes = @(
        [pscustomobject]@{
            key = "canary"
            value = [pscustomobject]@{ stringValue = "true" }
        },
        [pscustomobject]@{
            key = "source"
            value = [pscustomobject]@{ stringValue = "verify-integration.ps1" }
        }
    )
}

$resourceLog = [pscustomobject]@{
    resource = [pscustomobject]@{
        attributes = @(
            [pscustomobject]@{
                key = "service.name"
                value = [pscustomobject]@{ stringValue = "windows-collector" }
            }
        )
    }
    scopeLogs = @(
        [pscustomobject]@{
            logRecords = @($logRecord)
        }
    )
}

$logPayload = [pscustomobject]@{
    resourceLogs = @($resourceLog)
} | ConvertTo-Json -Depth 10

$otlpEndpoints = @("http://localhost:5318/v1/logs", "http://localhost:4318/v1/logs")
$sent = $false
foreach ($endpoint in $otlpEndpoints) {
    try {
        $response = Invoke-WebRequest -Method Post -Uri $endpoint -ContentType "application/json" -Body $logPayload -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "  [OK] Canary log sent to collector ($endpoint)" -ForegroundColor Green
            $sent = $true
            break
        } else {
            Write-Host "  [WARN] Collector returned status $($response.StatusCode) at $endpoint" -ForegroundColor Yellow
        }
    } catch {
        $lastError = $_
    }
}
if (-not $sent) {
    Write-Host "  [FAIL] Failed to send canary log: $($lastError.Exception.Message)" -ForegroundColor Red
    $failures += "otlp log canary"
}

# 6. SigNoz UI reachability
Write-Host "[6/6] Checking SigNoz UI..." -ForegroundColor Yellow
try {
    $uiResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
    if ($uiResponse.StatusCode -eq 200) {
        Write-Host "  [OK] SigNoz UI reachable" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] SigNoz UI returned $($uiResponse.StatusCode)" -ForegroundColor Red
        $failures += "signoz ui"
    }
} catch {
    Write-Host "  [FAIL] Cannot reach SigNoz UI: $($_.Exception.Message)" -ForegroundColor Red
    $failures += "signoz ui"
}

if ($failures.Count -eq 0) {
    Write-Host "== Verification complete: all checks passed ==" -ForegroundColor Green
    exit 0
} else {
    Write-Host "== Verification completed with failures ==" -ForegroundColor Red
    Write-Host "Failing components: $($failures -join ', ')" -ForegroundColor Red
    exit 1
}

