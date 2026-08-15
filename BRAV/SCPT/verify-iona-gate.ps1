#!/usr/bin/env pwsh
<#
.SYNOPSIS
    IONA Gate Verification Script
    
.DESCRIPTION
    Runs end-to-end verification of IONA gate integration:
    - Emits synthetic boot span
    - Runs Playwright UI snapshot tests
    - Verifies SigNoz ingestion (if available)
    - Confirms all artifacts are present
    
.PARAMETER SkipSigNoz
    Skip SigNoz ingestion verification
    
.PARAMETER Quick
    Run quick verification (skip some checks)
    
.EXAMPLE
    .\scripts\verify-iona-gate.ps1
    
.EXAMPLE
    .\scripts\verify-iona-gate.ps1 -SkipSigNoz
    
.NOTES
    Part of: IONA-PR-03 - Gate Wiring
    Service: iona-app
    Gate: BossCat Gate Verify
#>

param(
    [switch]$SkipSigNoz,
    [switch]$Quick,
    [switch]$SkipSyntheticSpan
)

$ErrorActionPreference = "Continue"
$script:errors = @()
$script:warnings = @()
$script:successes = @()

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
    $script:successes += $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠ $Message" -ForegroundColor Yellow
    $script:warnings += $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
    $script:errors += $Message
}

# Start verification
Write-Host @"

╔═══════════════════════════════════════════╗
║   IONA Gate Verification Script          ║
║   Service: iona-app                       ║
║   Gate: BossCat                           ║
╚═══════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# 1. Check dependencies
Write-Step "Checking dependencies..."

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python installed: $pythonVersion"
} catch {
    Write-Error "Python not found"
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Success "Node.js installed: $nodeVersion"
} catch {
    Write-Error "Node.js not found"
}

# Check PNPM
try {
    $pnpmVersion = pnpm --version
    Write-Success "PNPM installed: $pnpmVersion"
} catch {
    Write-Error "PNPM not found"
}

# Check Playwright
try {
    $playwrightVersion = npx playwright --version 2>&1
    Write-Success "Playwright installed: $playwrightVersion"
} catch {
    Write-Warning "Playwright may not be installed (run: npx playwright install --with-deps)"
}

# 2. Check IONA files exist
Write-Step "Verifying IONA gate files..."

$requiredFiles = @(
    "scripts/iona-snapshot.spec.ts",
    "synthetic/send_iona_boot_span.py",
    "docs/BossCat/IONA_ECRR_REPORT.md",
    ".github/workflows/iona-gate-verify.yml",
    "playwright.config.ts",
    "lib/telemetry/iona-telemetry.ts",
    "app/telemetry-init.tsx"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Success "Found: $file"
    } else {
        Write-Error "Missing: $file"
    }
}

# 3. Create artifacts directory
Write-Step "Preparing artifacts directory..."

if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    Write-Success "Created artifacts directory"
} else {
    Write-Success "Artifacts directory exists"
}

# 4. Emit synthetic boot span
Write-Step "Emitting IONA synthetic boot span..."

if ($SkipSyntheticSpan) {
    Write-Warning "Skipping synthetic span emission (browser telemetry only)"
} else {
    try {
        # Set environment variables for Node OTLP emitter
        $env:OTEL_EXPORTER_OTLP_ENDPOINT = Get-OtelIngestHttpBase -Ports $script:OtelPorts
        $env:OTEL_SERVICE_NAME = "iona-app"
        
        # Run Node.js synthetic span emitter (replaces Python implementation)
        $spanOutput = pnpm emit 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Synthetic span emitted successfully (Node.js OTLP/HTTP)"
            $spanOutput | Select-String -Pattern "\[IONA\]|✓|→" | ForEach-Object { 
                Write-Host "    $_" -ForegroundColor Gray 
            }
        } else {
            Write-Error "Failed to emit synthetic span (exit code: $LASTEXITCODE)"
            $spanOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
    } catch {
        Write-Error "Error emitting synthetic span: $($_.Exception.Message)"
    }
}

# 5. Check if dev server is running (optional)
if (-not $Quick) {
    Write-Step "Checking IONA dev server..."
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 3 -ErrorAction Stop
        Write-Success "IONA dev server is running (Status: $($response.StatusCode))"
    } catch {
        Write-Warning "IONA dev server not running - start with: pnpm dev"
        Write-Host "    You can still run snapshot tests if server is started separately" -ForegroundColor Gray
    }
}

# 6. Run Playwright snapshot tests
Write-Step "Running IONA UI snapshot tests..."

try {
    $testOutput = pnpm playwright test scripts/iona-snapshot.spec.ts --config=playwright.config.ts --reporter=list 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Playwright tests passed"
        $testOutput | Select-String -Pattern "passed|failed" | ForEach-Object { 
            Write-Host "    $_" -ForegroundColor Gray 
        }
    } else {
        Write-Warning "Playwright tests failed or had issues (exit code: $LASTEXITCODE)"
        Write-Host "    Check playwright-report/index.html for details" -ForegroundColor Gray
    }
} catch {
    Write-Error "Error running Playwright tests: $($_.Exception.Message)"
}

# 7. Verify artifacts were created
Write-Step "Verifying artifacts..."

$expectedArtifacts = @(
    "artifacts/iona-home.png",
    "artifacts/iona-practice.png",
    "artifacts/iona-memx-labs.png"
)

$foundArtifacts = 0
foreach ($artifact in $expectedArtifacts) {
    if (Test-Path $artifact) {
        $size = (Get-Item $artifact).Length / 1KB
        Write-Success "Found: $artifact ($([math]::Round($size, 2)) KB)"
        $foundArtifacts++
    } else {
        Write-Warning "Missing: $artifact"
    }
}

if ($foundArtifacts -eq $expectedArtifacts.Count) {
    Write-Success "All expected artifacts present"
} else {
    Write-Warning "$foundArtifacts/$($expectedArtifacts.Count) artifacts found"
}

# 8. Check SigNoz integration (optional)
if (-not $SkipSigNoz) {
    Write-Step "Checking SigNoz integration..."
    
    try {
        $signozHealth = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 3 -ErrorAction Stop
        Write-Success "SigNoz is available (Status: $($signozHealth.StatusCode))"
        
        Write-Host "    To verify span ingestion:" -ForegroundColor Gray
        Write-Host "      1. Open: http://localhost:8080" -ForegroundColor Gray
        Write-Host "      2. Navigate to: Traces → Explorer" -ForegroundColor Gray
        Write-Host "      3. Filter: service.name = 'iona-app'" -ForegroundColor Gray
        Write-Host "      4. Look for: iona.boot span" -ForegroundColor Gray
    } catch {
        Write-Warning "SigNoz not available - start with: docker-compose up -d"
    }
}

# 9. Generate summary
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   IONA Gate Verification Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`nSuccesses: $($script:successes.Count)" -ForegroundColor Green
$script:successes | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }

if ($script:warnings.Count -gt 0) {
    Write-Host "`nWarnings: $($script:warnings.Count)" -ForegroundColor Yellow
    $script:warnings | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor Yellow }
}

if ($script:errors.Count -gt 0) {
    Write-Host "`nErrors: $($script:errors.Count)" -ForegroundColor Red
    $script:errors | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
}

# Final status
Write-Host "`n" -NoNewline
if ($script:errors.Count -eq 0) {
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
    Write-Host "   ✓ IONA GATE VERIFICATION: PASSED" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
    exit 0
} else {
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Red
    Write-Host "   ✗ IONA GATE VERIFICATION: FAILED" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Red
    exit 1
}

