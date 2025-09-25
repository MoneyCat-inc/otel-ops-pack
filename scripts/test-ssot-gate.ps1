# SSOT Gate End-to-End Test Script
# Tests the complete SSOT Gate workflow locally

param(
    [switch]$Verbose
)

Write-Host "🧪 SSOT Gate End-to-End Test" -ForegroundColor Cyan
Write-Host ""

# Test 1: Verify all components exist
Write-Host "📋 Step 1: Verify SSOT Gate Components" -ForegroundColor Green
$components = @(
    "package.json",
    "vitest.config.ts", 
    "playwright.ssot.config.ts",
    "tests/ssot/landing.spec.ts",
    "tests/unit/kpi-calculator.test.ts",
    "scripts/run-playwright-ssot.mjs",
    "scripts/generate-ssot.mjs",
    ".github/workflows/ssot-gate.yml"
)

$allExist = $true
foreach ($component in $components) {
    if (Test-Path $component) {
        Write-Host "  ✅ $component" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $component" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host "❌ Missing components detected!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Run Vitest
Write-Host "📋 Step 2: Run Vitest Suite" -ForegroundColor Green
try {
    $vitestResult = pnpm test:vitest 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Vitest passed" -ForegroundColor Green
        if ($Verbose) { Write-Host $vitestResult -ForegroundColor Gray }
    } else {
        Write-Host "  ❌ Vitest failed" -ForegroundColor Red
        Write-Host $vitestResult -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Vitest execution failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Run Playwright SSOT
Write-Host "📋 Step 3: Run Playwright SSOT Suite" -ForegroundColor Green
try {
    $playwrightResult = pnpm test:playwright:ssot 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Playwright SSOT passed" -ForegroundColor Green
        if ($Verbose) { Write-Host $playwrightResult -ForegroundColor Gray }
    } else {
        Write-Host "  ❌ Playwright SSOT failed" -ForegroundColor Red
        Write-Host $playwrightResult -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Playwright SSOT execution failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Generate SSOT Report
Write-Host "📋 Step 4: Generate SSOT Report" -ForegroundColor Green
try {
    $ssotResult = node scripts/generate-ssot.mjs 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ SSOT report generated successfully" -ForegroundColor Green
        if ($Verbose) { Write-Host $ssotResult -ForegroundColor Gray }
    } else {
        Write-Host "  ❌ SSOT report generation failed" -ForegroundColor Red
        Write-Host $ssotResult -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ SSOT report generation failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 5: Verify SSOT Report Content
Write-Host "📋 Step 5: Verify SSOT Report Content" -ForegroundColor Green
if (Test-Path ".artifacts/SSOT.md") {
    $ssotContent = Get-Content -Raw ".artifacts/SSOT.md"
    
    if ($ssotContent -match "\| Vitest \| PASS 1/1" -and $ssotContent -match "\| Playwright \| PASS 1/1") {
        Write-Host "  ✅ SSOT report shows both suites PASS 1/1" -ForegroundColor Green
    } else {
        Write-Host "  ❌ SSOT report does not show expected PASS results" -ForegroundColor Red
        Write-Host "Report content:" -ForegroundColor Yellow
        Write-Host $ssotContent -ForegroundColor Yellow
        exit 1
    }
    
    if ($ssotContent -match "PASS Overall status") {
        Write-Host "  ✅ SSOT report shows overall PASS status" -ForegroundColor Green
    } else {
        Write-Host "  ❌ SSOT report missing overall PASS status" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ❌ SSOT report file not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 6: Verify Label Exists
Write-Host "📋 Step 6: Verify Repository Label" -ForegroundColor Green
try {
    $labelResult = gh label list | Select-String "ready-for-gate"
    if ($labelResult) {
        Write-Host "  ✅ Label '@cloud ready-for-gate' exists" -ForegroundColor Green
        Write-Host "  📝 $labelResult" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Label '@cloud ready-for-gate' not found" -ForegroundColor Red
        Write-Host "  💡 Run: gh label create '@cloud ready-for-gate' --description 'PR ready for SSOT Gate merge approval' --color '0e8a16'" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  ❌ Failed to check repository labels: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 7: Verify Workflow File
Write-Host "📋 Step 7: Verify CI Workflow" -ForegroundColor Green
if (Test-Path ".github/workflows/ssot-gate.yml") {
    $workflowContent = Get-Content -Raw ".github/workflows/ssot-gate.yml"
    
    if ($workflowContent -match "SSOT Gate" -and $workflowContent -match "ready-for-gate") {
        Write-Host "  ✅ SSOT Gate workflow configured with label enforcement" -ForegroundColor Green
    } else {
        Write-Host "  ❌ SSOT Gate workflow missing required configuration" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ❌ SSOT Gate workflow file not found" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Summary
Write-Host "🎉 SSOT Gate End-to-End Test Results" -ForegroundColor Cyan
Write-Host "✅ All components verified" -ForegroundColor Green
Write-Host "✅ Vitest suite passing" -ForegroundColor Green  
Write-Host "✅ Playwright SSOT suite passing" -ForegroundColor Green
Write-Host "✅ SSOT report generation working" -ForegroundColor Green
Write-Host "✅ Repository label created" -ForegroundColor Green
Write-Host "✅ CI workflow configured" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 SSOT Gate is ready for production!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set up branch protection rules (see scripts/setup-branch-protection.ps1)" -ForegroundColor White
Write-Host "2. Create a test PR to verify the complete workflow" -ForegroundColor White
Write-Host "3. Add '@cloud ready-for-gate' label when ready to merge" -ForegroundColor White
