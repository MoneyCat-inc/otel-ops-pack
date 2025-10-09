# BossCat OEM - Forensic Verification Setup
# Automated setup for forensic-grade verification

<#
.SYNOPSIS
  Sets up Python environment and dependencies for forensic-grade verification.

.DESCRIPTION
  This script:
  1. Creates isolated Python venv
  2. Installs OpenTelemetry dependencies
  3. Verifies API key is set
  4. Validates setup
  5. Optionally runs first verification

.PARAMETER RunVerification
  If set, runs verify-pipeline.ps1 after setup.

.EXAMPLE
  pwsh -File scripts\setup-forensic-verification.ps1
  
.EXAMPLE
  pwsh -File scripts\setup-forensic-verification.ps1 -RunVerification
#>

param(
  [switch]$RunVerification
)

Write-Host "🐾 BossCat OEM - Forensic Verification Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

$venvPath = "C:\otel\.venv"
$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- 1) Create virtual environment ---
Write-Host "[setup] Step 1/5: Creating Python virtual environment..." -ForegroundColor Cyan

if (Test-Path $venvPath) {
  Write-Host "   ℹ️  Virtual environment already exists: $venvPath" -ForegroundColor Yellow
  $recreate = Read-Host "   Recreate? (y/N)"
  if ($recreate -eq 'y') {
    Write-Host "   Removing existing venv..." -ForegroundColor Gray
    Remove-Item $venvPath -Recurse -Force
  }
}

if (-not (Test-Path $venvPath)) {
  Write-Host "   Creating venv at: $venvPath" -ForegroundColor Gray
  python -m venv $venvPath
  
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create virtual environment"
    exit 1
  }
  Write-Host "   ✅ Virtual environment created" -ForegroundColor Green
} else {
  Write-Host "   ✅ Using existing virtual environment" -ForegroundColor Green
}

# --- 2) Activate venv and install dependencies ---
Write-Host "`n[setup] Step 2/5: Installing OpenTelemetry dependencies..." -ForegroundColor Cyan

$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
& $activateScript

Write-Host "   Upgrading pip..." -ForegroundColor Gray
python -m pip install --upgrade pip --quiet

Write-Host "   Installing opentelemetry-sdk..." -ForegroundColor Gray
python -m pip install opentelemetry-sdk --quiet

Write-Host "   Installing opentelemetry-exporter-otlp-proto-http..." -ForegroundColor Gray
python -m pip install opentelemetry-exporter-otlp-proto-http --quiet

if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to install dependencies"
  exit 1
}

Write-Host "   ✅ Dependencies installed" -ForegroundColor Green

# --- 3) Verify dependencies ---
Write-Host "`n[setup] Step 3/5: Verifying installation..." -ForegroundColor Cyan

try {
  $testImport = python -c "from opentelemetry import trace; from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter; print('OK')" 2>&1
  
  if ($testImport -match "OK") {
    Write-Host "   ✅ OpenTelemetry imports verified" -ForegroundColor Green
  } else {
    Write-Warning "   Import test returned: $testImport"
  }
} catch {
  Write-Warning "   Could not verify imports: $_"
}

# --- 4) Check API key ---
Write-Host "`n[setup] Step 4/5: Checking SigNoz API key..." -ForegroundColor Cyan

$apiKey = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "Machine")
if (-not $apiKey) { $apiKey = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "Process") }

if ($apiKey) {
  $maskedKey = $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)) + "..." + 
               $apiKey.Substring([Math]::Max(0, $apiKey.Length - 4))
  Write-Host "   ✅ API key is set: $maskedKey" -ForegroundColor Green
} else {
  Write-Host "   ⚠️  API key not set in SIGNOZ_API_KEY" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "   To set API key:" -ForegroundColor Cyan
  Write-Host '   1. Create key: Start-Process http://localhost:8080/settings/api-keys' -ForegroundColor Gray
  Write-Host '   2. Set env var: [Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY","<key>","Machine")' -ForegroundColor Gray
  Write-Host '   3. Restart PowerShell to load environment' -ForegroundColor Gray
}

# --- 5) Set NO_PROXY for localhost (good hygiene) ---
Write-Host "`n[setup] Step 5/5: Configuring environment..." -ForegroundColor Cyan

$env:NO_PROXY = "localhost,127.0.0.1"
Write-Host "   ✅ NO_PROXY set for localhost bypass" -ForegroundColor Green

# --- Summary ---
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "📋 Setup Summary:" -ForegroundColor Cyan
Write-Host "   Virtual Environment: $venvPath" -ForegroundColor White
Write-Host "   Python: $(python --version 2>&1)" -ForegroundColor White
Write-Host "   OpenTelemetry SDK: Installed" -ForegroundColor White
Write-Host "   OTLP HTTP Exporter: Installed" -ForegroundColor White
Write-Host "   API Key: $(if ($apiKey) { 'Set ✅' } else { 'Not set ⚠️' })" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

# --- Next steps ---
Write-Host ""
if ($apiKey) {
  Write-Host "✅ Setup complete! Ready for forensic-grade verification." -ForegroundColor Green
  Write-Host ""
  Write-Host "Next steps:" -ForegroundColor Cyan
  Write-Host "   1. Keep this PowerShell window open (venv is activated)" -ForegroundColor Gray
  Write-Host "   2. Run: pwsh -File scripts\verify-pipeline.ps1" -ForegroundColor Gray
  Write-Host "   3. Or use wrapper: pwsh -File scripts\verify-and-flip.ps1" -ForegroundColor Gray
  
  if ($RunVerification) {
    Write-Host ""
    Write-Host "🚀 Running verification now..." -ForegroundColor Cyan
    Write-Host ""
    & pwsh -NoProfile -File (Join-Path $scriptsDir "verify-pipeline.ps1")
  }
} else {
  Write-Host "⚠️  Setup incomplete: API key not configured" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Complete setup:" -ForegroundColor Cyan
  Write-Host "   1. Create API key: Start-Process http://localhost:8080/settings/api-keys" -ForegroundColor Gray
  Write-Host '   2. Set env var: [Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY","<key>","Machine")' -ForegroundColor Gray
  Write-Host "   3. Restart PowerShell" -ForegroundColor Gray
  Write-Host "   4. Rerun this script: pwsh -File scripts\setup-forensic-verification.ps1 -RunVerification" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🐾 BossCat OEM - Setup Complete" -ForegroundColor Cyan

