# C:\otel\health-check.ps1
# Unified health check for OTel collector
# ASCII only, PowerShell 5.1 compatible

param(
  [ValidateSet("quick", "full", "regression")]
  [string]$Mode = "quick",
  [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

function Write-Status($message, $status) {
  $color = switch ($status) {
    "OK" { "Green" }
    "WARN" { "Yellow" }
    "ERROR" { "Red" }
    default { "White" }
  }
  Write-Host $message -ForegroundColor $color
}

function Test-Service {
  try {
    $svc = Get-Service otelcol-contrib -ErrorAction Stop
    if ($svc.Status -eq 'Running') {
      Write-Status "Service: $($svc.Status)" "OK"
      return $true
    } else {
      Write-Status "Service: $($svc.Status)" "ERROR"
      return $false
    }
  } catch {
    Write-Status "Service: NOT FOUND" "ERROR"
    return $false
  }
}

function Test-HealthEndpoint {
  try {
    $health = Invoke-WebRequest -Uri 'http://127.0.0.1:13134' -TimeoutSec 5 | ConvertFrom-Json
    if ($health.status -eq "Server available") {
      Write-Status "Health: $($health.status) (uptime $($health.uptime))" "OK"
      return $true
    } else {
      Write-Status "Health: $($health.status)" "ERROR"
      return $false
    }
  } catch {
    Write-Status "Health: DOWN" "ERROR"
    return $false
  }
}

function Test-MetricsEndpoint {
  try {
    $metrics = Invoke-WebRequest -Uri 'http://127.0.0.1:8889/metrics' -TimeoutSec 5
    if ($metrics.StatusCode -eq 200) {
      $lines = ($metrics.Content -split "`n" | Where-Object { $_ -like "otelcol_receiver_accepted_log_records*" }).Count
      Write-Status "Metrics: $($metrics.StatusCode) ($lines lines for accepted_log_records)" "OK"
      return $true
    } else {
      Write-Status "Metrics: $($metrics.StatusCode)" "ERROR"
      return $false
    }
  } catch {
    Write-Status "Metrics: DOWN" "ERROR"
    return $false
  }
}

function Test-Canary {
  try {
    $result = & C:\otel\canary-check-min.ps1
    if ($LASTEXITCODE -eq 0) {
      Write-Status "Canary: PASS (delta +1)" "OK"
      return $true
    } else {
      Write-Status "Canary: FAIL (exit code $LASTEXITCODE)" "ERROR"
      return $false
    }
  } catch {
    Write-Status "Canary: ERROR" "ERROR"
    return $false
  }
}

function Test-Kafka {
  try {
    $result = & C:\otel\kafka-smoke.ps1
    if ($LASTEXITCODE -eq 0) {
      Write-Status "Kafka: REACHABLE" "OK"
      return $true
    } else {
      Write-Status "Kafka: UNREACHABLE (optional)" "WARN"
      return $false
    }
  } catch {
    Write-Status "Kafka: ERROR (optional)" "WARN"
    return $false
  }
}

function Test-ConfigValidation {
  try {
    $result = & C:\otel\config-schema.ps1 -ConfigPath C:\otel\config-hardened-plus.yaml -CheckSecurity -CheckPerformance
    if ($LASTEXITCODE -eq 0) {
      Write-Status "Config: VALID" "OK"
      return $true
    } else {
      Write-Status "Config: INVALID (exit code $LASTEXITCODE)" "ERROR"
      return $false
    }
  } catch {
    Write-Status "Config: ERROR" "ERROR"
    return $false
  }
}

# Main execution
Write-Host "== OTel Health Check ==" -ForegroundColor Cyan

$results = @{
  Service = Test-Service
  Health = Test-HealthEndpoint
  Metrics = Test-MetricsEndpoint
}

if ($Mode -eq "full" -or $Mode -eq "regression") {
  $results.Canary = Test-Canary
  $results.Kafka = Test-Kafka
  $results.Config = Test-ConfigValidation
}

# Summary
$passed = ($results.Values | Where-Object { $_ -eq $true }).Count
$total = $results.Count

Write-Host "`nSummary: $passed/$total checks passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

# Count only non-optional checks for pass/fail determination
$requiredChecks = @($results.Service, $results.Health, $results.Metrics)
$requiredPassed = ($requiredChecks | Where-Object { $_ -eq $true }).Count
$requiredTotal = $requiredChecks.Count

if ($requiredPassed -eq $requiredTotal) {
  Write-Host "All required systems operational" -ForegroundColor Green
  exit 0
} else {
  Write-Host "Some required issues detected" -ForegroundColor Yellow
  exit 1
}
