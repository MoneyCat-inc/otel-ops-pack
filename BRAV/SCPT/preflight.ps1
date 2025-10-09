# BossCat OEM - Preflight Check
# Validates all prerequisites before verification to fail fast with actionable fixes

<#
.SYNOPSIS
  Checks all prerequisites for forensic-grade verification.

.DESCRIPTION
  Validates:
  - Windows OTel collector service running
  - OTLP endpoint reachable
  - Python available with required packages
  - SigNoz API key configured
  - Proxy configuration (if applicable)

  Returns:
  - Exit 0: All prerequisites met
  - Exit 2: One or more prerequisites missing (with actionable fixes)

.PARAMETER ServiceName
  Windows service name (default: otelcol-contrib)

.PARAMETER OtlpHost
  OTLP endpoint host (default: 127.0.0.1)

.PARAMETER OtlpPort
  OTLP endpoint port (default: 4318 for HTTP)

.PARAMETER VenvHint
  Suggested venv path for guidance (default: C:\otel\.venv)

.EXAMPLE
  pwsh -File scripts\preflight.ps1
#>

[CmdletBinding()]
param(
  [string]$ServiceName = "otelcol-contrib",
  [string]$OtlpHost = "127.0.0.1",
  [int]$OtlpPort = 14318,  # Docker mapped port (14318->4318)
  [string]$VenvHint = "C:\otel\.venv"
)

$ErrorActionPreference = "Stop"
$problems = @()

# 0) Fix encoding (avoid garbled output)
try { 
  chcp 65001 | Out-Null
  [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() 
} catch { }

Write-Host "🐾 BossCat OEM - Preflight Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

# --- 1) Windows OTel Collector Service ---
Write-Host "[preflight] Checking Windows collector service..." -ForegroundColor Gray
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if (-not $svc) {
  $problems += "Service '$ServiceName' not found. Is OTel collector installed?"
  Write-Host "   ❌ Service not found" -ForegroundColor Red
} elseif ($svc.Status -ne 'Running') {
  $problems += "Service '$ServiceName' is $($svc.Status). Start it: Start-Service $ServiceName"
  Write-Host "   ❌ Service is $($svc.Status)" -ForegroundColor Red
} else {
  Write-Host "   ✅ Service '$ServiceName' is Running" -ForegroundColor Green
}

# --- 2) OTLP Endpoint Reachability ---
Write-Host "[preflight] Checking OTLP endpoint..." -ForegroundColor Gray
try {
  $res = Test-NetConnection $OtlpHost -Port $OtlpPort -WarningAction SilentlyContinue -InformationLevel Quiet
  if (-not $res.TcpTestSucceeded) {
    $problems += "OTLP endpoint http://${OtlpHost}:${OtlpPort} unreachable. Check Docker: docker ps --filter 'name=signoz'"
    Write-Host "   ❌ Port $OtlpPort not reachable" -ForegroundColor Red
  } else {
    Write-Host "   ✅ OTLP endpoint http://${OtlpHost}:${OtlpPort} reachable" -ForegroundColor Green
  }
} catch {
  $problems += "Cannot test OTLP endpoint: $_"
  Write-Host "   ❌ Connection test failed" -ForegroundColor Red
}

# --- 3) Python & Virtual Environment ---
Write-Host "[preflight] Checking Python environment..." -ForegroundColor Gray
$py = Get-Command python -ErrorAction SilentlyContinue

if (-not $py) {
  $problems += "Python not on PATH. Activate venv: $VenvHint\Scripts\Activate.ps1"
  Write-Host "   ❌ Python not found" -ForegroundColor Red
} else {
  $pyVersion = & python --version 2>&1
  Write-Host "   ✅ Python found: $pyVersion" -ForegroundColor Green
  
  # Check pip
  $pipCheck = & python -m pip --version 2>$null
  if ($LASTEXITCODE -ne 0) {
    $problems += "pip not available in current Python environment"
    Write-Host "   ❌ pip not available" -ForegroundColor Red
  } else {
    Write-Host "   ✅ pip available" -ForegroundColor Green
    
    # Check required packages
    Write-Host "[preflight] Checking OpenTelemetry packages..." -ForegroundColor Gray
    $list = (& python -m pip list 2>$null) -join "`n"
    
    $hasSdk = $list -match "opentelemetry-sdk"
    $hasExporter = $list -match "opentelemetry-exporter-otlp-proto-http"
    
    if (-not $hasSdk) {
      $problems += "Missing package: opentelemetry-sdk. Install: pip install opentelemetry-sdk"
      Write-Host "   ❌ opentelemetry-sdk not installed" -ForegroundColor Red
    } else {
      Write-Host "   ✅ opentelemetry-sdk installed" -ForegroundColor Green
    }
    
    if (-not $hasExporter) {
      $problems += "Missing package: opentelemetry-exporter-otlp-proto-http. Install: pip install opentelemetry-exporter-otlp-proto-http"
      Write-Host "   ❌ opentelemetry-exporter-otlp-proto-http not installed" -ForegroundColor Red
    } else {
      Write-Host "   ✅ opentelemetry-exporter-otlp-proto-http installed" -ForegroundColor Green
    }
  }
}

# --- 4) SigNoz API Key ---
Write-Host "[preflight] Checking SigNoz API key..." -ForegroundColor Gray
$apiKey = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "Process")
if (-not $apiKey) { $apiKey = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "Machine") }

if (-not $apiKey) {
  $problems += "SIGNOZ_API_KEY not set. Create key at http://localhost:8080/settings/api-keys, then: [Environment]::SetEnvironmentVariable('SIGNOZ_API_KEY','<key>','Machine')"
  Write-Host "   ❌ API key not set" -ForegroundColor Red
} else {
  $masked = $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)) + "..." + $apiKey.Substring([Math]::Max(0, $apiKey.Length - 4))
  Write-Host "   ✅ API key is set: $masked" -ForegroundColor Green
}

# --- 5) Proxy Configuration (if applicable) ---
if ($env:HTTP_PROXY -or $env:HTTPS_PROXY) {
  Write-Host "[preflight] Checking proxy configuration..." -ForegroundColor Gray
  
  if (-not $env:NO_PROXY -or ($env:NO_PROXY -notmatch "127\.0\.0\.1" -and $env:NO_PROXY -notmatch "localhost")) {
    $problems += "Proxy detected without NO_PROXY for localhost. Set: `$env:NO_PROXY='localhost,127.0.0.1'"
    Write-Host "   ⚠️  Proxy without localhost bypass" -ForegroundColor Yellow
  } else {
    Write-Host "   ✅ Proxy configured with localhost bypass" -ForegroundColor Green
  }
}

# --- Results ---
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

if ($problems.Count -gt 0) {
  Write-Host "❌ Preflight FAILED - $($problems.Count) issue(s) found:" -ForegroundColor Red
  Write-Host ""
  
  foreach ($problem in $problems) {
    Write-Host "   • $problem" -ForegroundColor Yellow
  }
  
  Write-Host ""
  Write-Host "Fix the issues above, then rerun verification." -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
  exit 2
} else {
  Write-Host "✅ Preflight OK - All prerequisites met" -ForegroundColor Green
  Write-Host ""
  Write-Host "Ready for verification:" -ForegroundColor Cyan
  Write-Host "   pwsh -File scripts\verify-pipeline.ps1" -ForegroundColor Gray
  Write-Host "   pwsh -File scripts\verify-and-flip.ps1" -ForegroundColor Gray
  Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
  exit 0
}

