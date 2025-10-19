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
    
    # Extract on: block (YAML-aware, handles both inline and multi-line formats)
    $onBlock = ""
    
    # Check for inline formats first: "on: push" or "on: [push, pull_request]"
    if ($content -match '(?m)^on:\s+(\w+)\s*$') {
        # Single trigger: "on: push"
        $onBlock = $matches[1]
    } elseif ($content -match '(?m)^on:\s+\[([^\]]+)\]') {
        # Array format: "on: [push, pull_request]"
        $onBlock = $matches[1] -replace ',', ' '
    } else {
        # Multi-line block format
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
    }
    
    # Detect triggers from on: block only
    # Build trigger object with stable alphabetical key order for deterministic JSON
    $triggerObj = [PSCustomObject]@{
        issues = $onBlock -match 'issues'
        other = @()
        pull_request = $onBlock -match 'pull_request'
        push = $onBlock -match 'push'
        release = $onBlock -match 'release'
        schedule = $onBlock -match 'schedule'
        workflow_call = $onBlock -match 'workflow_call'
        workflow_dispatch = $onBlock -match 'workflow_dispatch'
        workflow_run = $onBlock -match 'workflow_run'
    }
    
    [pscustomobject]@{
        name = $name
        modified = $_.LastWriteTime.ToString('o')  # ISO 8601 format for schema
        path = $_.FullName.Replace("$repoRoot\","").Replace('\','/')
        size = $_.Length
        triggers = $triggerObj
    }
}

# Generate registry (schema-compliant format with deterministic output)
# Note: generatedAt removed for CI determinism - use git commit history instead
# Use ordered hashtable + explicit sorting for stable JSON output
$outputPath = "docs\status\workflows.json"

# Sort workflows by name for stable output
$sortedWorkflows = $workflows | Sort-Object -Property name

$registry = [ordered]@{
    source = 'scripts/regenerate-workflows-registry.ps1'
    total = $sortedWorkflows.Count
    items = $sortedWorkflows
}

# Convert to JSON with deep nesting and save
# ConvertTo-Json depth 5 needed for nested trigger objects
$registry | ConvertTo-Json -Depth 5 | Out-File $outputPath -Encoding UTF8

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

