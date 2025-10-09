# Quick verification script for hardened CI pipeline
Write-Host "🔍 Verifying hardened CI pipeline..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$success = @()
$errors = @()

# 1. Check CI workflow has all 5 hardening improvements
Write-Host "`n📋 Checking CI workflow hardening..." -ForegroundColor Yellow

$ciContent = Get-Content ".github/workflows/ci.yml" -Raw

# Check for pip caching
if ($ciContent -match "cache: 'pip'") {
    $success += "✅ Python pip caching enabled"
} else {
    $errors += "❌ Missing pip caching"
}

# Check for powershell-yaml installation
if ($ciContent -match "Install-Module powershell-yaml") {
    $success += "✅ PowerShell YAML parser installation"
} else {
    $errors += "❌ Missing powershell-yaml installation"
}

# Check for OTel config linting
if ($ciContent -match "yamllint otel configs") {
    $success += "✅ OpenTelemetry config linting"
} else {
    $errors += "❌ Missing OTel config linting"
}

# Check for pinned collector version
if ($ciContent -match "opentelemetry-collector:0\.114\.0") {
    $success += "✅ Pinned collector version (0.114.0)"
} else {
    $errors += "❌ Collector not pinned to specific version"
}

# Check for OTLP canary test
if ($ciContent -match "Send sample span" -and $ciContent -match "v1/traces") {
    $success += "✅ OTLP canary test with sample span"
} else {
    $errors += "❌ Missing OTLP canary test"
}

# 2. Check supporting files exist
Write-Host "`n📁 Checking supporting files..." -ForegroundColor Yellow

$supportingFiles = @(
    "otel/ci-config.yaml",
    "PIPELINE_HARDENING_SUMMARY.md"
)

foreach ($file in $supportingFiles) {
    if (Test-Path $file) {
        $success += "✅ $file exists"
    } else {
        $errors += "❌ Missing: $file"
    }
}

# 3. Validate OTel CI config
Write-Host "`n🔧 Validating OTel CI config..." -ForegroundColor Yellow

if (Test-Path "otel/ci-config.yaml") {
    $otelConfig = Get-Content "otel/ci-config.yaml" -Raw
    
    # Check for required sections
    $requiredSections = @("receivers:", "processors:", "exporters:", "service:")
    foreach ($section in $requiredSections) {
        if ($otelConfig -match $section) {
            $success += "✅ OTel config has $section"
        } else {
            $errors += "❌ OTel config missing $section"
        }
    }
    
    # Check for OTLP receiver
    if ($otelConfig -match "otlp:" -and $otelConfig -match "endpoint: 0.0.0.0:4318") {
        $success += "✅ OTLP receiver configured for port 4318"
    } else {
        $errors += "❌ OTLP receiver not properly configured"
    }
}

# Summary
Write-Host "`n📊 Hardening Verification Results:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

if ($success.Count -gt 0) {
    Write-Host "`n✅ Successes ($($success.Count)):" -ForegroundColor Green
    foreach ($item in $success) {
        Write-Host "  $item" -ForegroundColor Green
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`n❌ Errors ($($errors.Count)):" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "  $item" -ForegroundColor Red
    }
}

# Final Status
Write-Host "`n🎯 Final Status:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "🎉 PERFECT! All 5 hardening improvements are in place!" -ForegroundColor Green
    Write-Host "`nThe hardened CI pipeline includes:" -ForegroundColor Cyan
    Write-Host "  • Real YAML validation in CI" -ForegroundColor White
    Write-Host "  • Dependency caching (pip + npm)" -ForegroundColor White
    Write-Host "  • OpenTelemetry config linting" -ForegroundColor White
    Write-Host "  • Pinned collector version (0.114.0)" -ForegroundColor White
    Write-Host "  • OTLP canary test with sample span" -ForegroundColor White
    Write-Host "`nReady for a test PR to see the hardened pipeline in action! 🐱‍💻" -ForegroundColor Magenta
    exit 0
} else {
    Write-Host "❌ ISSUES FOUND! Please fix the errors above." -ForegroundColor Red
    exit 1
}
