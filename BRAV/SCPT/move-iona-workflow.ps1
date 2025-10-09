#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Move IONA workflow to correct GitHub Actions location
    
.DESCRIPTION
    GitHub Actions only reads workflows from .github/workflows/ directory.
    This script moves workflows/iona-gate-verify.yml to the correct location.
    
.EXAMPLE
    .\scripts\move-iona-workflow.ps1
    
.NOTES
    Part of: IONA-GATE-001 - Final Fixes
    Required for: GitHub Actions detection
#>

$ErrorActionPreference = "Stop"

Write-Host @"

╔═══════════════════════════════════════════╗
║   IONA Workflow Location Fix             ║
║   Moving to .github/workflows/           ║
╚═══════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Paths
$sourcePath = "workflows/iona-gate-verify.yml"
$targetDir = ".github/workflows"
$targetPath = "$targetDir/iona-gate-verify.yml"

# Check source exists
Write-Host "Checking source file..." -ForegroundColor Yellow
if (-not (Test-Path $sourcePath)) {
    Write-Host "✗ Source file not found: $sourcePath" -ForegroundColor Red
    Write-Host "  This script expects: workflows/iona-gate-verify.yml" -ForegroundColor Gray
    exit 1
}
Write-Host "✓ Source file found: $sourcePath" -ForegroundColor Green

# Create target directory
Write-Host "`nCreating .github/workflows directory..." -ForegroundColor Yellow
try {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Write-Host "✓ Directory ready: $targetDir" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create directory: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check if target already exists
if (Test-Path $targetPath) {
    Write-Host "`n⚠ Target file already exists: $targetPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "✓ Skipping copy - using existing file" -ForegroundColor Green
        exit 0
    }
}

# Copy file
Write-Host "`nCopying workflow file..." -ForegroundColor Yellow
try {
    Copy-Item -Path $sourcePath -Destination $targetPath -Force
    Write-Host "✓ File copied to: $targetPath" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to copy file: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nManual copy required:" -ForegroundColor Yellow
    Write-Host "  1. Read: $sourcePath" -ForegroundColor Gray
    Write-Host "  2. Create: $targetPath" -ForegroundColor Gray
    Write-Host "  3. Paste content and save" -ForegroundColor Gray
    exit 1
}

# Verify copy
Write-Host "`nVerifying file..." -ForegroundColor Yellow
if (Test-Path $targetPath) {
    $sourceSize = (Get-Item $sourcePath).Length
    $targetSize = (Get-Item $targetPath).Length
    
    if ($sourceSize -eq $targetSize) {
        Write-Host "✓ File verified: sizes match ($sourceSize bytes)" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: file sizes differ" -ForegroundColor Yellow
        Write-Host "  Source: $sourceSize bytes" -ForegroundColor Gray
        Write-Host "  Target: $targetSize bytes" -ForegroundColor Gray
    }
} else {
    Write-Host "✗ Verification failed: target file not found" -ForegroundColor Red
    exit 1
}

# Show git status
Write-Host "`nGit status:" -ForegroundColor Yellow
try {
    git status --short $targetPath
} catch {
    Write-Host "  (git not available or not in repo)" -ForegroundColor Gray
}

# Success message
Write-Host @"

╔═══════════════════════════════════════════╗
║   ✓ Workflow Move Complete               ║
╚═══════════════════════════════════════════╝

Next steps:
  1. Commit the file:
     git add .github/workflows/iona-gate-verify.yml
     git commit -m "ci(gate): move IONA workflow to correct location"
  
  2. Push to remote:
     git push
  
  3. Verify in GitHub:
     Actions → Workflows → IONA Gate Verify

"@ -ForegroundColor Green

Write-Host "File location: $targetPath" -ForegroundColor Cyan
Write-Host "Status: Ready for commit" -ForegroundColor Green

