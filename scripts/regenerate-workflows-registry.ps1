#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    Regenerate GitHub Actions workflows registry
.DESCRIPTION
    Extracts workflow metadata with YAML-aware on: block parsing.
    Updates docs/status/workflows.json with accurate trigger information.
.EXAMPLE
    pwsh scripts/regenerate-workflows-registry.ps1
.NOTES
    Authority: BossCat OEM
    Lane: DOCS
    Run this after: Adding/modifying/deleting workflows in .github/workflows/
#>

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "`n🔄 Regenerating workflows registry..." -ForegroundColor Cyan

$workflows = Get-ChildItem .github\workflows\*.yml,.github\workflows\*.yaml -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $name = $_.BaseName
    $triggers = @()
    
    # Extract on: block (YAML-aware)
    $lines = $content -split "`n"
    $inOnBlock = $false
    $onBlockLines = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^on:\s*$') {
            $inOnBlock = $true
            continue
        }
        if ($inOnBlock) {
            if ($line -match '^\w+:' -and $line -notmatch '^\s+') {
                break
            }
            if ($line -match '^\s+(\w+):') {
                $onBlockLines += $matches[1]
            }
        }
    }
    
    $onBlock = $onBlockLines -join ' '
    
    # Detect triggers from on: block only
    if ($onBlock -match 'push') { $triggers += 'push' }
    if ($onBlock -match 'pull_request') { $triggers += 'pull_request' }
    if ($onBlock -match 'schedule') { $triggers += 'schedule' }
    if ($onBlock -match 'workflow_dispatch') { $triggers += 'workflow_dispatch' }
    if ($onBlock -match 'workflow_call') { $triggers += 'workflow_call' }
    if ($onBlock -match 'workflow_run') { $triggers += 'workflow_run' }
    if ($onBlock -match 'release') { $triggers += 'release' }
    if ($onBlock -match 'issues') { $triggers += 'issues' }
    
    $triggerStr = if ($triggers.Count -gt 0) {
        ($triggers | Sort-Object -Unique) -join ', '
    } else {
        'none'
    }
    
    $scheduled = $triggers -contains 'schedule'
    
    [pscustomobject]@{
        name = $name
        path = $_.FullName.Replace("$PWD\","").Replace('\','/')
        size = $_.Length
        modified = $_.LastWriteTime
        triggers = $triggerStr
        scheduled = $scheduled
    }
}

# Generate registry
$registry = @{
    updated = (Get-Date -Format 'o')
    total = $workflows.Count
    description = 'GitHub Actions workflows registry - triggers extracted from on: block only'
    workflows = $workflows
}

$outputPath = "docs\status\workflows.json"
$registry | ConvertTo-Json -Depth 4 | Out-File $outputPath -Encoding UTF8

Write-Host "✅ workflows.json regenerated" -ForegroundColor Green
Write-Host "   Total workflows: $($workflows.Count)" -ForegroundColor White
Write-Host "   Output: $outputPath" -ForegroundColor White

# Validation check
Write-Host "`n🔍 Running validation checks..." -ForegroundColor Cyan

$json = Get-Content $outputPath -Raw | ConvertFrom-Json
$falseIssues = @($json.workflows | Where-Object { $_.triggers -match '\bissues\b' })

if ($falseIssues.Count -gt 0) {
    Write-Host "⚠️  WARNING: Found workflows with 'issues' trigger" -ForegroundColor Yellow
    Write-Host "   These may be false positives from permissions: blocks" -ForegroundColor Yellow
    Write-Host "   Verify these workflows actually trigger on issues events:`n" -ForegroundColor Yellow
    $falseIssues | Select-Object name, triggers | Format-Table
} else {
    Write-Host "✅ No false 'issues' triggers detected" -ForegroundColor Green
}

# Spot-check key workflows
Write-Host "`n📋 Spot-check (key workflows):" -ForegroundColor Cyan
$keyWorkflows = @('bosscat-gate-bot-native', 'bosscat-gate-verify', 'apisec-scan')
$spotCheck = $json.workflows | Where-Object { $_.name -in $keyWorkflows }

if ($spotCheck) {
    $spotCheck | Format-Table name, triggers -AutoSize
} else {
    Write-Host "   (Key workflows not found - registry may be incomplete)" -ForegroundColor Yellow
}

Write-Host "`n✅ Registry regeneration complete" -ForegroundColor Green
Write-Host "   Next: Review changes and commit with descriptive message`n" -ForegroundColor White

