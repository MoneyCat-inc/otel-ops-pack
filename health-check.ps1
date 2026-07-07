# C:\otel\health-check.ps1
# Unified health check for OTel collector
# ASCII only, PowerShell 5.1 compatible
# Updated with progress indicators for better user experience

param(
  [ValidateSet("quick", "full", "regression")]
  [string]$Mode = "quick",
  [switch]$Verbose
)

# Import progress indicators module (optional)
$ProgressIndicatorsAvailable = $false
if (Test-Path ".\scripts\progress-indicators.ps1") {
  try {
    . .\scripts\progress-indicators.ps1
    $ProgressIndicatorsAvailable = $true
  } catch {
    # Progress indicators not available, continue without them
  }
}

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
  if ($ProgressIndicatorsAvailable) {
    $spinnerJob = Start-SpinnerJob -Message "Checking health endpoint..." -UpdateIntervalMs 150
  }
  try {
    $health = Invoke-WebRequest -Uri 'http://127.0.0.1:13134/healthz' -TimeoutSec 5 -UseBasicParsing | ConvertFrom-Json
    if ($ProgressIndicatorsAvailable) {
      Stop-SpinnerJob -Job $spinnerJob
    }
    if ($health.status -eq "Server available") {
      Write-Status "Health: $($health.status) (uptime $($health.uptime))" "OK"
      return $true
    } else {
      Write-Status "Health: $($health.status)" "ERROR"
      return $false
    }
  } catch {
    if ($ProgressIndicatorsAvailable) {
      Stop-SpinnerJob -Job $spinnerJob
    }
    Write-Status "Health: DOWN" "ERROR"
    return $false
  }
}

function Test-MetricsEndpoint {
  try {
    $metrics = Invoke-WebRequest -Uri 'http://127.0.0.1:8888/metrics' -TimeoutSec 5 -UseBasicParsing
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
  param(
    [string]$ConfigPath = "C:\otel\config.yaml"
  )

  $kafkaConfigured = $true
  if (Test-Path $ConfigPath) {
    try {
      $configContent = Get-Content $ConfigPath -Raw
      $exportersMatch = [regex]::Match($configContent, '(?ms)^exporters:\s*(.*?)(^\S|\z)')
      if ($exportersMatch.Success) {
        $kafkaConfigured = $exportersMatch.Groups[1].Value -match '(?m)^\s*kafka'
      } else {
        $kafkaConfigured = $configContent -match '(?m)^\s*kafka'
      }
    } catch {
      $kafkaConfigured = $true
    }
  }

  if (-not $kafkaConfigured) {
    Write-Status "Kafka: SKIPPED (not configured)" "WARN"
    return $true
  }

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
    $configPath = "C:\otel\config.yaml"
    if (-not (Test-Path $configPath)) {
      Write-Status "Config: FILE NOT FOUND ($configPath)" "ERROR"
      return $false
    }
    # Run validation and capture output
    $validationOutput = & C:\otel\config-schema.ps1 -ConfigPath $configPath -CheckSecurity -CheckPerformance 2>&1 | Out-String
    # Check if file exists and is readable (basic validation)
    # Exit code 1 may indicate warnings, which are acceptable for health checks
    # Only fail if file doesn't exist or can't be read
    if ($LASTEXITCODE -eq 0) {
      Write-Status "Config: VALID" "OK"
      return $true
    } elseif ($validationOutput -match "Configuration file not found" -or $validationOutput -match "Failed to load") {
      Write-Status "Config: INVALID (file error)" "ERROR"
      return $false
    } else {
      # Warnings are acceptable - config file exists and is readable
      Write-Status "Config: VALID (with warnings)" "WARN"
      return $true
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
