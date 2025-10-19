#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    Extract redirect map from stub files
.DESCRIPTION
    Parses redirect stubs to build a mapping of old→new paths.
    Outputs CSV and JSON for link rewriting and human reference.
.EXAMPLE
    pwsh scripts/extract-redirect-map.ps1
.NOTES
    Authority: BossCat OEM
    Lane: DOCS
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Anchor to repository root
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "`n🗺️  Extracting Redirect Map from Stubs" -ForegroundColor Cyan

# Find stub files (detect "# Moved" marker)
$stubs = @(Get-ChildItem -Path . -Depth 0 -File -Filter *.md | Where-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -match '# Moved'
})

Write-Host "   Found $($stubs.Count) stub files" -ForegroundColor White
Write-Host ""

$map = @(foreach ($stub in $stubs) {
    $content = Get-Content $stub.FullName -Raw
    
    # Match: **New location:** [path](path)
    if ($content -match '\*\*New location:\*\*\s+\[(.+?)\]\((.+?)\)') {
        [PSCustomObject]@{
            Old = $stub.Name
            New = $matches[2]
            Title = $matches[1]
        }
    }
})

# Output redirect map
$csvPath = "docs/status/redirect-map.csv"
$jsonPath = "docs/status/redirect-map.json"

$map | Export-Csv $csvPath -NoTypeInformation
$map | ConvertTo-Json -Depth 5 | Out-File $jsonPath -Encoding UTF8

Write-Host "✅ Redirect map created" -ForegroundColor Green
Write-Host "   CSV:  $csvPath ($($map.Count) redirects)" -ForegroundColor White
Write-Host "   JSON: $jsonPath" -ForegroundColor White
Write-Host ""
Write-Host "📋 Sample redirects:" -ForegroundColor Cyan
$map | Select-Object -First 5 | Format-Table Old, New -AutoSize
Write-Host ""
Write-Host "Next: Rewrite internal links and remove stubs" -ForegroundColor Yellow
Write-Host ""

