# See C:\otel\docs\comfort cat

<#
.SYNOPSIS
    One-command sanity sweep for Comfort Cat guidelines compliance.

.DESCRIPTION
    This script performs a comprehensive check of Comfort Cat guidelines
    compliance across the repository, including header comments, file
    presence, and integration points.

.EXAMPLE
    pwsh -File scripts\comfort-cat-sanity-sweep.ps1
#>

param(
    [switch]$FixIssues,
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "?? Comfort Cat Sanity Sweep" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$Issues = @()
$Warnings = @()
$Fixed = @()

# Set environment variable for space-safe path handling
$ComfortCatDir = "C:\otel\docs\comfort cat"
$env:COMFORT_CAT_DIR = $ComfortCatDir

Write-Host "`n?? Running comfort:check..." -ForegroundColor Yellow
try {
    $npmCmd = (Get-Command npm -CommandType Application | Select-Object -First 1).Source
    $CheckResult = & $npmCmd run comfort:check 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "? Comfort check passed" -ForegroundColor Green
    } else {
        $Issues += "Comfort check failed"
        Write-Host "? Comfort check failed" -ForegroundColor Red
        if ($CheckResult) {
            Write-Host $CheckResult -ForegroundColor Red
        }
    }
} catch {
    $Issues += "Comfort check command not available"
    Write-Host "? Comfort check command not available" -ForegroundColor Red
}

Write-Host "`n?? Checking header comments..." -ForegroundColor Yellow
try {
    $gitCmd = (Get-Command git -CommandType Application | Select-Object -First 1).Source
    $pattern = 'See C:\otel\docs\comfort cat'
    $HeaderCheck = & $gitCmd 'grep' '-n' '--fixed-strings' '--' $pattern ':!docs/comfort-cat/*' 2>&1
    $gitExit = $LASTEXITCODE

    if ($gitExit -eq 0 -and $HeaderCheck) {
        $HeaderCount = ($HeaderCheck -split "`n").Count
        Write-Host "? Found $HeaderCount files with comfort-cat headers" -ForegroundColor Green

        if ($Detailed) {
            Write-Host "`nFiles with comfort-cat headers:" -ForegroundColor Yellow
            $HeaderCheck | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
    } elseif ($gitExit -eq 1) {
        $Warnings += "No files found with comfort-cat headers"
        Write-Host "??  No files found with comfort-cat headers" -ForegroundColor Yellow
    } else {
        $Warnings += "Could not check header comments"
        Write-Host "??  Could not check header comments" -ForegroundColor Yellow
        if ($Detailed -and $HeaderCheck) {
            Write-Host $HeaderCheck -ForegroundColor Gray
        }
    }
} catch {
    $Warnings += "Could not check header comments"
    Write-Host "??  Could not check header comments" -ForegroundColor Yellow
}

Write-Host "`n?? Checking guideline files..." -ForegroundColor Yellow
$RequiredFiles = @(
    "docs\comfort-cat\README.md",
    "docs\comfort-cat\palette.md",
    "docs\comfort-cat\type.md",
    "docs\comfort-cat\motion.md",
    "docs\comfort-cat\copy.md",
    "docs\comfort-cat\proofpoints.md",
    "docs\comfort-cat\accessibility.md",
    "docs\comfort-cat\success-criteria.md",
    "docs\comfort-cat\storyboard.md",
    "docs\comfort-cat\CHANGELOG.md"
)

foreach ($File in $RequiredFiles) {
    if (Test-Path $File) {
        Write-Host "? $File" -ForegroundColor Green
    } else {
        $Issues += "Missing file: $File"
        Write-Host "? Missing: $File" -ForegroundColor Red

        if ($FixIssues -and $File -eq "docs\comfort-cat\CHANGELOG.md") {
            Write-Host "?? Creating CHANGELOG.md..." -ForegroundColor Yellow
            Set-Content -Path $File -Value "# Comfort Cat CHANGELOG" -NoNewline
            $Fixed += "Created $File"
        }
    }
}

Write-Host "`n?? Checking Windows mirror..." -ForegroundColor Yellow
if (Test-Path $ComfortCatDir) {
    Write-Host "? Windows mirror exists" -ForegroundColor Green
} else {
    $Issues += "Windows mirror missing"
    Write-Host "? Windows mirror missing" -ForegroundColor Red
}

Write-Host "`n?? Checking PR template integration..." -ForegroundColor Yellow
$PRTemplate = ".github\PULL_REQUEST_TEMPLATE.md"
if (Test-Path $PRTemplate) {
    $Content = Get-Content $PRTemplate -Raw
    if ($Content -match "Comfort Cat") {
        Write-Host "? PR template includes Comfort Cat compliance" -ForegroundColor Green
    } else {
        $Issues += "PR template missing Comfort Cat compliance"
        Write-Host "? PR template missing Comfort Cat compliance" -ForegroundColor Red
    }
} else {
    $Issues += "PR template missing"
    Write-Host "? PR template missing" -ForegroundColor Red
}

Write-Host "`n?? Checking package.json scripts..." -ForegroundColor Yellow
if (Test-Path "package.json") {
    $PackageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
    $ComfortScripts = @("comfort:sync", "comfort:check", "comfort:scaffold")
    $MissingScripts = @()

    foreach ($Script in $ComfortScripts) {
        if ($PackageJson.scripts -and $PackageJson.scripts.$Script) {
            Write-Host "? $Script configured" -ForegroundColor Green
        } else {
            $MissingScripts += $Script
        }
    }

    if ($MissingScripts.Count -gt 0) {
        $Warnings += "Missing scripts: $($MissingScripts -join ', ')"
        Write-Host "??  Missing scripts: $($MissingScripts -join ', ')" -ForegroundColor Yellow
    }
} else {
    $Warnings += "package.json not found"
    Write-Host "??  package.json not found" -ForegroundColor Yellow
}

Write-Host "`n?? Checking version headers..." -ForegroundColor Yellow
$GuidelineFiles = Get-ChildItem "docs\comfort-cat\*.md" | Where-Object { $_.Name -ne "CHANGELOG.md" }
foreach ($File in $GuidelineFiles) {
    $Content = Get-Content $File -Raw
    if ($Content -match "version: cc-v\d+\.\d+\.\d+") {
        Write-Host "? $($File.Name) has version header" -ForegroundColor Green
    } else {
        $Warnings += "Missing version header in $($File.Name)"
        Write-Host "??  $($File.Name) missing version header" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n?? Sanity Sweep Summary" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

if ($Issues.Count -eq 0) {
    Write-Host "?? All critical checks passed!" -ForegroundColor Green
} else {
    Write-Host "? $($Issues.Count) critical issues found:" -ForegroundColor Red
    foreach ($Issue in $Issues) {
        Write-Host "  `a $Issue" -ForegroundColor Red
    }
}

if ($Warnings.Count -gt 0) {
    Write-Host "`n??  $($Warnings.Count) warnings:" -ForegroundColor Yellow
    foreach ($Warning in $Warnings) {
        Write-Host "  `a $Warning" -ForegroundColor Yellow
    }
}

if ($Fixed.Count -gt 0) {
    Write-Host "`n?? $($Fixed.Count) issues fixed:" -ForegroundColor Green
    foreach ($Fix in $Fixed) {
        Write-Host "  `a $Fix" -ForegroundColor Green
    }
}

# Environment variable info
Write-Host "`n?? Environment:" -ForegroundColor Cyan
Write-Host "  COMFORT_CAT_DIR = $env:COMFORT_CAT_DIR" -ForegroundColor Gray

# Exit with appropriate code
if ($Issues.Count -gt 0) {
    exit 1
} else {
    exit 0
}
