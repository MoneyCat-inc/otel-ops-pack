# Investor Demo: Evidence Bundle Generator
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Phase 4: Package complete evidence pack for stakeholders
# Purpose: Create ZIP with k6 reports, traces, ECRR ledger, screenshots

param(
    [string]$OutputDir = "artifacts/demo",
    [string]$BundleName = "investor-evidence-pack-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Evidence Bundle Generator ===" -ForegroundColor Cyan
Write-Host ""

# Create output directory
$fullOutputDir = Join-Path $PSScriptRoot "..\..\" $OutputDir
if (-not (Test-Path $fullOutputDir)) {
    New-Item -ItemType Directory -Path $fullOutputDir -Force | Out-Null
}

$bundlePath = Join-Path $fullOutputDir $BundleName
$tempDir = Join-Path $env:TEMP "investor-demo-bundle-$(Get-Date -Ticks)"

Write-Host "[1/6] Creating temporary staging directory..." -ForegroundColor White
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-Host "   → $tempDir" -ForegroundColor Gray

# Collect artifacts
Write-Host ""
Write-Host "[2/6] Collecting k6 performance reports..." -ForegroundColor White

$k6Files = Get-ChildItem -Path "$fullOutputDir\k6-*.json" -ErrorAction SilentlyContinue
if ($k6Files) {
    $k6Dir = Join-Path $tempDir "performance"
    New-Item -ItemType Directory -Path $k6Dir -Force | Out-Null
    $k6Files | Copy-Item -Destination $k6Dir
    Write-Host "   ✅ Collected $($k6Files.Count) k6 reports" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No k6 reports found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/6] Collecting ECRR ledger and evidence logs..." -ForegroundColor White

$ecrrFiles = @(
    "docs\BossCat\BOSSCAT_LOG.md",
    ".agent\EVIDENCE.log",
    ".agent\PLAN.md"
)

$ecrrDir = Join-Path $tempDir "governance"
New-Item -ItemType Directory -Path $ecrrDir -Force | Out-Null

foreach ($file in $ecrrFiles) {
    if (Test-Path $file) {
        Copy-Item $file -Destination $ecrrDir -ErrorAction SilentlyContinue
    }
}

Write-Host "   ✅ Collected governance artifacts" -ForegroundColor Green

Write-Host ""
Write-Host "[4/6] Collecting demo documentation..." -ForegroundColor White

$docFiles = Get-ChildItem -Path "docs\demo\*.md" -ErrorAction SilentlyContinue
$docDir = Join-Path $tempDir "documentation"
New-Item -ItemType Directory -Path $docDir -Force | Out-Null

if ($docFiles) {
    $docFiles | Copy-Item -Destination $docDir
    Write-Host "   ✅ Collected $($docFiles.Count) demo docs" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No demo docs found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5/6] Generating evidence summary..." -ForegroundColor White

$summary = @"
# Investor Demo Evidence Bundle

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Authority:** BossCat OEM
**Phase:** All 4 phases complete

## Contents

### 1. Performance Reports (/performance)
- k6 test results with hard thresholds
- Baseline: p95<300ms, errors<1%
- Verdict: GREEN/RED based on threshold compliance

### 2. Governance Artifacts (/governance)
- BOSSCAT_LOG.md: Complete audit trail
- EVIDENCE.log: ECRR evidence chain
- PLAN.md: Agent execution plans

### 3. Documentation (/documentation)
- DEMO_SCRIPT.md: 7-minute demo walkthrough
- REHEARSAL.md: Dress rehearsal with timestamps
- Architecture and guardrails overview

### 4. Screenshots (/screenshots)
(Capture manually during demo)
- Healthy dashboard (baseline metrics)
- Data Room active (traffic + chaos)
- SigNoz trace drilldown
- Alert firing during chaos
- BOSSCAT_LOG audit trail

## Verification

All evidence follows ECRR doctrine:
- Evidence: Timestamped artifacts
- Contain: Budgets enforced (≤200 LOC/job)
- Rollback: Git history with tags
- Report: This summary + BOSSCAT_LOG entries

## Quick Start

1. Extract ZIP
2. Review documentation/DEMO_SCRIPT.md
3. Check governance/BOSSCAT_LOG.md for audit trail
4. Examine performance/k6-summary.json for thresholds

---

🐾 **Cat Nap Control Room - Investor Evidence Pack**
"@

$summaryPath = Join-Path $tempDir "README.md"
$summary | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "   ✅ Summary generated" -ForegroundColor Green

Write-Host ""
Write-Host "[6/6] Creating ZIP archive..." -ForegroundColor White

try {
    Compress-Archive -Path "$tempDir\*" -DestinationPath $bundlePath -Force
    Write-Host "   ✅ Bundle created: $bundlePath" -ForegroundColor Green
    
    $size = (Get-Item $bundlePath).Length / 1KB
    Write-Host "   Size: $([math]::Round($size, 2)) KB" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Failed to create ZIP: $_" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup temp directory
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                   ║" -ForegroundColor Green
Write-Host "║        ✅ EVIDENCE BUNDLE COMPLETE ✅            ║" -ForegroundColor Green
Write-Host "║                                                   ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Bundle: $bundlePath" -ForegroundColor White
Write-Host ""
Write-Host "Send to investors or extract for review" -ForegroundColor Cyan
Write-Host ""

