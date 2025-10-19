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
    Can be run from any directory - script anchors to repo root
#>

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Anchor to repository root
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "`n🔄 Regenerating workflows registry..." -ForegroundColor Cyan
Write-Host "   Repository root: $repoRoot" -ForegroundColor DarkGray

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
    
    # Detect triggers from on: block only (build object for schema compliance)
    $triggerObj = @{
        push = $onBlock -match 'push'
        pull_request = $onBlock -match 'pull_request'
        workflow_dispatch = $onBlock -match 'workflow_dispatch'
        workflow_call = $onBlock -match 'workflow_call'
        workflow_run = $onBlock -match 'workflow_run'
        schedule = $onBlock -match 'schedule'
        release = $onBlock -match 'release'
        issues = $onBlock -match 'issues'
        other = @()
    }
    
    [pscustomobject]@{
        name = $name
        path = $_.FullName.Replace("$repoRoot\","").Replace('\','/')
        size = $_.Length
        modified = $_.LastWriteTime.ToString('o')  # ISO 8601 format for schema
        triggers = $triggerObj
    }
}

# Generate registry (schema-compliant format)
$registry = @{
    generatedAt = (Get-Date -Format 'o')
    source = 'scripts/regenerate-workflows-registry.ps1'
    total = $workflows.Count
    items = $workflows
}

$outputPath = "docs\status\workflows.json"
$registry | ConvertTo-Json -Depth 4 | Out-File $outputPath -Encoding UTF8

Write-Host "✅ workflows.json regenerated" -ForegroundColor Green
Write-Host "   Total workflows: $($workflows.Count)" -ForegroundColor White
Write-Host "   Output: $outputPath" -ForegroundColor White

# Validation check
Write-Host "`n🔍 Running validation checks..." -ForegroundColor Cyan

$json = Get-Content $outputPath -Raw | ConvertFrom-Json
$falseIssues = @($json.items | Where-Object { $_.triggers.issues -eq $true })

if ($falseIssues.Count -gt 0) {
    Write-Host "⚠️  WARNING: Found workflows with 'issues' trigger" -ForegroundColor Yellow
    Write-Host "   These may be false positives from permissions: blocks" -ForegroundColor Yellow
    Write-Host "   Verify these workflows actually trigger on issues events:`n" -ForegroundColor Yellow
    $falseIssues | Select-Object name, path | Format-Table
} else {
    Write-Host "✅ No false 'issues' triggers detected" -ForegroundColor Green
}

# Spot-check key workflows
Write-Host "`n📋 Spot-check (key workflows):" -ForegroundColor Cyan
$keyWorkflows = @('bosscat-gate-bot-native', 'bosscat-gate-verify', 'apisec-scan')
$spotCheck = $json.items | Where-Object { $_.name -in $keyWorkflows }

if ($spotCheck) {
    $spotCheck | ForEach-Object {
        $activeTriggers = $_.triggers.PSObject.Properties | Where-Object { $_.Value -eq $true } | Select-Object -ExpandProperty Name
        [PSCustomObject]@{
            name = $_.name
            triggers = ($activeTriggers | Sort-Object) -join ', '
        }
    } | Format-Table -AutoSize
} else {
    Write-Host "   (Key workflows not found - registry may be incomplete)" -ForegroundColor Yellow
}

Write-Host "`n✅ Registry regeneration complete" -ForegroundColor Green
Write-Host "   Next: Review changes and commit with descriptive message`n" -ForegroundColor White

