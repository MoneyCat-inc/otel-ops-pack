#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    Regenerate docs/status/workflows.json from the tracked workflow files under .github/workflows/.
.DESCRIPTION
    Extracts workflow metadata with YAML-aware on: block parsing.

    Deterministic on every platform and every clone, like regenerate-scripts-registry.ps1: the
    file set comes from `git ls-files` (an untracked draft workflow never appears), `size` is the
    blob size as git would commit it (no CRLF drift), and there is no per-file date. The old
    `modified` field was the checkout's filesystem mtime, so every clone produced a different
    file and 43 of 60 committed sizes had gone stale (2026-09-24); git history is the timestamp
    source. `modified` stays optional in workflows.schema.json and is simply not emitted.

    Enforced in CI by registry-guard.yml.
.PARAMETER Out
    Output path (default docs/status/workflows.json).
.PARAMETER Check
    Do not write; exit 1 if the committed registry differs from a fresh regeneration.
.EXAMPLE
    pwsh scripts/regenerate-workflows-registry.ps1
    pwsh scripts/regenerate-workflows-registry.ps1 -Check
.NOTES
    Authority: BossCat OEM
    Lane: DOCS
    Run this after: Adding/modifying/deleting workflows in .github/workflows/
    Can be run from any directory - script anchors to repo root
#>
[CmdletBinding()]
param(
    [string]$Out = 'docs/status/workflows.json',
    [switch]$Check
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Anchor to repository root
$repoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $repoRoot
try {
    if (-not $Check) {
        Write-Host "`n🔄 Regenerating workflows registry..." -ForegroundColor Cyan
        Write-Host "   Repository root: $repoRoot" -ForegroundColor DarkGray
    }

    # `git ls-files -s` gives "<mode> <oid> <stage>\t<path>" for tracked files only. GitHub reads
    # workflows from the top level of .github/workflows only, and a git pathspec `*` also
    # matches `/`, so subdirectories are filtered out.
    $index = @(& git ls-files -s -- '.github/workflows/*.yml' '.github/workflows/*.yaml' 2>$null)
    if ($LASTEXITCODE -ne 0 -or $index.Count -eq 0) {
        throw 'git ls-files returned nothing for .github/workflows/*.y*ml (not a git checkout?)'
    }

    $entries = @{}
    foreach ($line in $index) {
        $meta, $path = $line -split "`t", 2
        if ($path -notmatch '^\.github/workflows/[^/]+\.ya?ml$') { continue }
        $oid = ($meta -split ' ')[1]
        if ($entries.ContainsKey($path)) { continue }
        $entries[$path] = $oid
    }

    # Ordinal sort by name (items are keyed by name): culture-aware sorting differs between ICU
    # builds and crashes in globalization-invariant mode (see regenerate-scripts-registry.ps1).
    $paths = [string[]]$entries.Keys
    $names = [string[]]($paths | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
    [System.Array]::Sort($names, $paths, [System.StringComparer]::Ordinal)

    $workflows = @(foreach ($path in $paths) {
        $name = [IO.Path]::GetFileNameWithoutExtension($path)
        $full = Join-Path $repoRoot $path

        # Size and content of the file as git would commit it: hash the working-tree content
        # through the repo's clean filters (CRLF-safe) so an edited-but-unstaged workflow is
        # measured as it is now, not as the index remembers it. Falls back to the index blob
        # when the file is absent from disk.
        $oid = $entries[$path]
        if (Test-Path -LiteralPath $full) {
            $hashed = (& git hash-object -w --path $path -- $path 2>$null)
            if ($LASTEXITCODE -eq 0 -and $hashed) { $oid = $hashed.Trim() }
            $content = [System.IO.File]::ReadAllText($full)
        } else {
            $content = (& git cat-file -p $oid) -join "`n"
        }
        $size = [int](& git cat-file -s $oid)

        # A CRLF checkout on Windows must parse the same triggers as the LF runner.
        $content = $content -replace "`r`n", "`n"
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
            path = $path
            size = $size
            triggers = $triggerObj
        }
    })

    # Generate registry (schema-compliant format with deterministic output)
    $registry = [ordered]@{
        source = 'scripts/regenerate-workflows-registry.ps1'
        total = $workflows.Count
        items = $workflows
    }

    # ConvertTo-Json depth 5 needed for nested trigger objects. It joins lines with the platform
    # newline (CRLF on Windows); the committed file is LF, so normalise the generated text, and
    # the committed text in -Check, to compare like for like.
    $json = (($registry | ConvertTo-Json -Depth 5) -replace "`r`n", "`n") + "`n"

    $outPath = [System.IO.Path]::GetFullPath($Out, $repoRoot)

    if ($Check) {
        if (-not (Test-Path -LiteralPath $outPath)) {
            Write-Host "workflows registry: $Out missing" -ForegroundColor Red
            exit 1
        }
        $committed = [System.IO.File]::ReadAllText($outPath) -replace "`r`n", "`n"
        if (-not [string]::Equals($committed, $json, [System.StringComparison]::Ordinal)) {
            Write-Host "workflows registry: $Out is stale (re-run without -Check)" -ForegroundColor Red
            $a = $committed -split "`n"; $b = $json -split "`n"
            $n = [Math]::Max($a.Count, $b.Count)
            for ($i = 0; $i -lt $n; $i++) {
                $l = if ($i -lt $a.Count) { $a[$i] } else { '<eof>' }
                $r = if ($i -lt $b.Count) { $b[$i] } else { '<eof>' }
                if (-not [string]::Equals($l, $r, [System.StringComparison]::Ordinal)) {
                    Write-Host ("  first difference at line {0}: committed {1} | expected {2}" -f ($i + 1), $l.Trim(), $r.Trim())
                    break
                }
            }
            Write-Host ("  committed {0} lines / {1} chars; expected {2} lines / {3} chars" -f $a.Count, $committed.Length, $b.Count, $json.Length)
            exit 1
        }
        Write-Host "workflows registry: $Out is current ($($workflows.Count) workflows)" -ForegroundColor Green
        exit 0
    }

    [System.IO.File]::WriteAllText($outPath, $json, [System.Text.UTF8Encoding]::new($false))

    Write-Host "✅ workflows.json regenerated" -ForegroundColor Green
    Write-Host "   Total workflows: $($workflows.Count)" -ForegroundColor White
    Write-Host "   Output: $Out" -ForegroundColor White

    # Validation check
    Write-Host "`n🔍 Running validation checks..." -ForegroundColor Cyan

    $falseIssues = @($workflows | Where-Object { $_.triggers.issues -eq $true })

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
    $spotCheck = @($workflows | Where-Object { $_.name -in $keyWorkflows })

    if ($spotCheck.Count -gt 0) {
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
} finally {
    Pop-Location
}
