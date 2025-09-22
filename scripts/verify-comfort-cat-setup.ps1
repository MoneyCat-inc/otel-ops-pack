# See C:\otel\docs\comfort cat

<#
.SYNOPSIS
    Verifies Comfort Cat creative guidelines setup and compliance.

.DESCRIPTION
    This script checks that the Comfort Cat creative guidelines are properly
    set up in both the repo and Windows mirror locations, and validates
    that key integration points are working correctly.

.EXAMPLE
    pwsh -File scripts\verify-comfort-cat-setup.ps1
#>

param(
    [switch]$Detailed,
    [switch]$FixIssues
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Configuration
$RepoPath = "docs\comfort-cat"
$WinPath = "C:\otel\docs\comfort cat"
$RequiredFiles = @(
    "README.md",
    "palette.md", 
    "type.md",
    "motion.md",
    "copy.md",
    "storyboard.md",
    "proofpoints.md",
    "accessibility.md",
    "success-criteria.md",
    "CHANGELOG.md"
)

# Set environment variable for space-safe path handling
$env:COMFORT_CAT_DIR = $WinPath

Write-Host "🐱 Comfort Cat Setup Verification" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$Issues = @()
$Warnings = @()

# Check repo structure
Write-Host "`n📁 Checking repo structure..." -ForegroundColor Yellow
if (Test-Path $RepoPath) {
    Write-Host "✅ Repo path exists: $RepoPath" -ForegroundColor Green
} else {
    $Issues += "Repo path missing: $RepoPath"
    Write-Host "❌ Repo path missing: $RepoPath" -ForegroundColor Red
}

# Check Windows mirror
Write-Host "`n🪟 Checking Windows mirror..." -ForegroundColor Yellow
if (Test-Path $WinPath) {
    Write-Host "✅ Windows mirror exists: $WinPath" -ForegroundColor Green
} else {
    $Issues += "Windows mirror missing: $WinPath"
    Write-Host "❌ Windows mirror missing: $WinPath" -ForegroundColor Red
}

# Check required files in both locations
Write-Host "`n📄 Checking required files..." -ForegroundColor Yellow
foreach ($File in $RequiredFiles) {
    $RepoFile = Join-Path $RepoPath $File
    $WinFile = Join-Path $WinPath $File
    
    $RepoExists = Test-Path $RepoFile
    $WinExists = Test-Path $WinFile
    
    if ($RepoExists -and $WinExists) {
        Write-Host "✅ $File - Both locations" -ForegroundColor Green
    } elseif ($RepoExists) {
        $Warnings += "File only in repo: $File"
        Write-Host "⚠️  $File - Repo only" -ForegroundColor Yellow
    } elseif ($WinExists) {
        $Warnings += "File only in Windows: $File"
        Write-Host "⚠️  $File - Windows only" -ForegroundColor Yellow
    } else {
        $Issues += "File missing: $File"
        Write-Host "❌ $File - Missing" -ForegroundColor Red
    }
}

# Check assets directory
Write-Host "`n🎨 Checking assets directory..." -ForegroundColor Yellow
$RepoAssets = Join-Path $RepoPath "assets"
$WinAssets = Join-Path $WinPath "assets"

if (Test-Path $RepoAssets) {
    Write-Host "✅ Repo assets directory exists" -ForegroundColor Green
} else {
    $Warnings += "Repo assets directory missing"
    Write-Host "⚠️  Repo assets directory missing" -ForegroundColor Yellow
}

if (Test-Path $WinAssets) {
    Write-Host "✅ Windows assets directory exists" -ForegroundColor Green
} else {
    $Warnings += "Windows assets directory missing"
    Write-Host "⚠️  Windows assets directory missing" -ForegroundColor Yellow
}

# Check PR template integration
Write-Host "`n📋 Checking PR template integration..." -ForegroundColor Yellow
$PRTemplate = ".github\PULL_REQUEST_TEMPLATE.md"
if (Test-Path $PRTemplate) {
    $Content = Get-Content $PRTemplate -Raw
    if ($Content -match "Comfort Cat") {
        Write-Host "✅ PR template includes Comfort Cat compliance" -ForegroundColor Green
    } else {
        $Issues += "PR template missing Comfort Cat compliance section"
        Write-Host "❌ PR template missing Comfort Cat compliance section" -ForegroundColor Red
    }
} else {
    $Issues += "PR template missing"
    Write-Host "❌ PR template missing" -ForegroundColor Red
}

# Check package.json scripts
Write-Host "`n📦 Checking package.json scripts..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    $PackageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
    if ($PackageJson.scripts -and $PackageJson.scripts."comfort:sync") {
        Write-Host "✅ Comfort Cat sync script configured" -ForegroundColor Green
    } else {
        $Warnings += "Comfort Cat sync script not configured"
        Write-Host "⚠️  Comfort Cat sync script not configured" -ForegroundColor Yellow
    }
} else {
    $Warnings += "package.json not found"
    Write-Host "⚠️  package.json not found" -ForegroundColor Yellow
}

# Check for header comments in key files
Write-Host "`n💬 Checking header comments..." -ForegroundColor Yellow
$FilesToCheck = @(
    "scripts\monitor-optimized-pipeline.ps1",
    "scripts\quick-monitor.ps1",
    "preview\index.html"
)

foreach ($File in $FilesToCheck) {
    if (Test-Path $File) {
        $Content = Get-Content $File -Raw
        if ($Content -match "See C:\\otel\\docs\\comfort cat") {
            Write-Host "✅ $File has comfort-cat header" -ForegroundColor Green
        } else {
            $Warnings += "Missing comfort-cat header in $File"
            Write-Host "⚠️  $File missing comfort-cat header" -ForegroundColor Yellow
        }
    }
}

# Check version headers in guideline files
Write-Host "`n📋 Checking version headers..." -ForegroundColor Yellow
$GuidelineFiles = Get-ChildItem $RepoPath\*.md | Where-Object { $_.Name -ne "CHANGELOG.md" }
foreach ($File in $GuidelineFiles) {
    $Content = Get-Content $File -Raw
    if ($Content -match "version: cc-v\d+\.\d+\.\d+") {
        Write-Host "✅ $($File.Name) has version header" -ForegroundColor Green
    } else {
        $Warnings += "Missing version header in $($File.Name)"
        Write-Host "⚠️  $($File.Name) missing version header" -ForegroundColor Yellow
    }
}

# Check environment variable
Write-Host "`n🌍 Checking environment variable..." -ForegroundColor Yellow
if ($env:COMFORT_CAT_DIR) {
    Write-Host "✅ COMFORT_CAT_DIR set to: $env:COMFORT_CAT_DIR" -ForegroundColor Green
} else {
    $Warnings += "COMFORT_CAT_DIR environment variable not set"
    Write-Host "⚠️  COMFORT_CAT_DIR environment variable not set" -ForegroundColor Yellow
}

# Summary
Write-Host "`n📊 Summary" -ForegroundColor Cyan
Write-Host "=========" -ForegroundColor Cyan

if ($Issues.Count -eq 0) {
    Write-Host "🎉 All critical checks passed!" -ForegroundColor Green
    if ($Warnings.Count -gt 0) {
        Write-Host "⚠️  $($Warnings.Count) warnings found (see above)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ $($Issues.Count) critical issues found:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host "  • $Issue" -ForegroundColor Red
    }
}

if ($Warnings.Count -gt 0) {
    Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
    foreach ($Warning in $Warnings) {
        Write-Host "  • $Warning" -ForegroundColor Yellow
    }
}

# Detailed report
if ($Detailed) {
    Write-Host "`n📋 Detailed Report" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    Write-Host "`nRepo Structure:" -ForegroundColor Yellow
    if (Test-Path $RepoPath) {
        Get-ChildItem $RepoPath | Format-Table Name, Length, LastWriteTime
    }
    
    Write-Host "`nWindows Mirror:" -ForegroundColor Yellow
    if (Test-Path $WinPath) {
        Get-ChildItem $WinPath | Format-Table Name, Length, LastWriteTime
    }
}

# Exit with appropriate code
if ($Issues.Count -gt 0) {
    exit 1
} else {
    exit 0
}
