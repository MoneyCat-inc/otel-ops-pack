#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    Rewrite internal links to new paths and remove stub files
.DESCRIPTION
    Rewrites markdown links pointing to old root locations to point to new consolidated paths.
    After rewriting, removes the stub files.
.PARAMETER Apply
    Execute the changes (default is dry-run)
.EXAMPLE
    pwsh scripts/replace-redirects-and-clean-stubs.ps1        # Dry-run
    pwsh scripts/replace-redirects-and-clean-stubs.ps1 -Apply # Execute
.NOTES
    Authority: BossCat OEM
    Lane: DOCS
#>

param(
    [switch]$Apply = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Anchor to repository root
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "`n🔗 Internal Link Rewriting + Stub Removal" -ForegroundColor Cyan
Write-Host "   Mode: $(if($Apply){'APPLY'}else{'DRY-RUN'})" -ForegroundColor $(if($Apply){'Yellow'}else{'Cyan'})
Write-Host ""

# Load redirect map
if (-not (Test-Path "docs/status/redirect-map.json")) {
    Write-Host "❌ redirect-map.json not found. Run extract-redirect-map.ps1 first." -ForegroundColor Red
    exit 1
}

$map = Get-Content "docs/status/redirect-map.json" -Raw | ConvertFrom-Json

Write-Host "📋 Loaded $($map.Count) redirects" -ForegroundColor Cyan
Write-Host ""

# File types where markdown links appear
$globs = @("*.md", "*.mdx", "*.yml", "*.yaml", "*.html", "*.ts", "*.tsx", "*.js", "*.json")

# Find files (exclude .git, node_modules, CHAR, DELT, ALFA, etc.)
$files = @()
foreach ($glob in $globs) {
    $found = Get-ChildItem -Recurse -File -Include $glob -ErrorAction SilentlyContinue | 
        Where-Object { 
            $_.FullName -notmatch '[\\/](\.git|node_modules|CHAR|DELT|ALFA|BRAV|SELE|docs[\\/]BossCat[\\/]BossCat)[\\/]' 
        }
    $files += $found
}

Write-Host "📄 Scanning $($files.Count) files for links..." -ForegroundColor Yellow

$changedFiles = @()
$totalReplacements = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $original = $content
    $fileReplacements = 0
    
    foreach ($redirect in $map) {
        $oldName = [regex]::Escape($redirect.Old)
        
        # Pattern 1: Markdown links [](.../file.md)
        $pattern1 = "\]\((?:\.{1,2}/)?$oldName\)"
        if ($content -match $pattern1) {
            $content = $content -replace $pattern1, "]($($redirect.New))"
            $fileReplacements++
        }
        
        # Pattern 2: Markdown links with anchors [](.../file.md#anchor)
        $pattern2 = "\]\((?:\.{1,2}/)?$oldName(\#[^\)]+)\)"
        if ($content -match $pattern2) {
            $content = $content -replace $pattern2, "]($($redirect.New)`$1)"
            $fileReplacements++
        }
    }
    
    if ($content -ne $original) {
        $changedFiles += $file.FullName
        $totalReplacements += $fileReplacements
        
        if ($Apply) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        }
    }
}

Write-Host ""
Write-Host "✅ Link rewriting analysis complete" -ForegroundColor Green
Write-Host "   Files with changes: $($changedFiles.Count)" -ForegroundColor White
Write-Host "   Total link replacements: $totalReplacements" -ForegroundColor White

if (-not $Apply) {
    Write-Host ""
    Write-Host "💡 DRY RUN - No changes made" -ForegroundColor Yellow
    Write-Host "   To execute: pwsh $($MyInvocation.MyCommand.Path) -Apply" -ForegroundColor White
    Write-Host ""
    exit 0
}

# Apply changes
Write-Host ""
Write-Host "📝 Committing link rewrites..." -ForegroundColor Green
git add $changedFiles 2>&1 | Out-Null
git commit -m "docs: rewrite internal links to new consolidated paths" -m "Rewrote $totalReplacements links in $($changedFiles.Count) files to point to docs/<domain>/<date>/ structure" 2>&1 | Out-Null

# Now remove stubs
Write-Host ""
Write-Host "🗑️  Removing $($map.Count) stub files from root..." -ForegroundColor Yellow

$stubFiles = $map | ForEach-Object { $_.Old }
git rm -- $stubFiles 2>&1 | Out-Null
git commit -m "docs: remove root stubs after link rewrite" -m "Removed $($map.Count) redirect stubs from root" -m "All internal links now point to new consolidated locations" 2>&1 | Out-Null

Write-Host "✅ Stub removal complete" -ForegroundColor Green
Write-Host ""

# Final count
$remaining = @(Get-ChildItem -Path . -Depth 0 -File -Filter *.md)
Write-Host "📊 Final root markdown count: $($remaining.Count)" -ForegroundColor Cyan
Write-Host "   Target: ≤15" -ForegroundColor White
Write-Host "   Status: $(if($remaining.Count -le 15){'✅ MET'}else{'⚠️  ABOVE TARGET'})" -ForegroundColor $(if($remaining.Count -le 15){'Green'}else{'Yellow'})
Write-Host ""

if ($remaining.Count -gt 0) {
    Write-Host "Remaining root markdown files:" -ForegroundColor Cyan
    $remaining | Select-Object Name | Sort-Object Name | Format-Table -AutoSize
}

Write-Host "✅ Closeout complete" -ForegroundColor Green
Write-Host ""

