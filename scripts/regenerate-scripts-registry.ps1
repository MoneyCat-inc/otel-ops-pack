#!/usr/bin/env pwsh
#Requires -Version 7
<#
.SYNOPSIS
    Regenerate docs/status/scripts.json from the tracked PowerShell scripts under scripts/.
.DESCRIPTION
    Deterministic on every platform and every clone: the file set comes from `git ls-files`
    and `size` is the committed blob size (no CRLF drift, no filesystem mtimes). There is
    deliberately no per-file date and no generated-at field — a first cut used
    `git log -1` dates, which differ between a shallow CI/cloud clone and a full clone
    (Cursor seat, 2026-09-02); git history is the timestamp source, as for workflows.json.
    Lanes follow the categorisation documented in docs/status/README.md.

    Enforced in CI by registry-guard.yml (`-Check`).
.PARAMETER Out
    Output path (default docs/status/scripts.json).
.PARAMETER Check
    Do not write; exit 1 if the committed registry differs from a fresh regeneration.
.EXAMPLE
    pwsh scripts/regenerate-scripts-registry.ps1
    pwsh scripts/regenerate-scripts-registry.ps1 -Check
.NOTES
    Authority: BossCat OEM. Lane: DOCS. Companion of regenerate-workflows-registry.ps1.
#>
[CmdletBinding()]
param(
    [string]$Out = 'docs/status/scripts.json',
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $repoRoot
try {
    # `git ls-files -s` gives "<mode> <oid> <stage>\t<path>" for tracked files only.
    $index = @(& git ls-files -s -- 'scripts/*.ps1' 'scripts/**/*.ps1' 2>$null)
    if ($LASTEXITCODE -ne 0 -or $index.Count -eq 0) {
        throw 'git ls-files returned nothing for scripts/**/*.ps1 (not a git checkout?)'
    }

    $entries = @{}
    foreach ($line in $index) {
        $meta, $path = $line -split "`t", 2
        $oid = ($meta -split ' ')[1]
        if ($entries.ContainsKey($path)) { continue }
        $entries[$path] = $oid
    }

    $scripts = @(foreach ($path in ($entries.Keys | Sort-Object -Culture 'en-US' -CaseSensitive)) {
        $name = [IO.Path]::GetFileName($path)
        $lane = if ($name -match 'gate|verify') { 'GATE' }
                elseif ($name -match 'monitor|canary|test') { 'SSOT' }
                elseif ($name -match 'benchmark|process') { 'COMP' }
                elseif ($name -match 'hub|export') { 'DOCS' }
                else { 'UTIL' }

        $size = [int](& git cat-file -s $entries[$path])

        [ordered]@{
            name = $name
            path = $path
            size = $size
            lane = $lane
        }
    })

    $registry = [ordered]@{
        source  = 'scripts/regenerate-scripts-registry.ps1'
        total   = $scripts.Count
        scripts = $scripts
    }
    $json = ($registry | ConvertTo-Json -Depth 4) + "`n"

    if ($Check) {
        if (-not (Test-Path -LiteralPath $Out)) {
            Write-Host "scripts registry: $Out missing" -ForegroundColor Red
            exit 1
        }
        $committed = Get-Content -LiteralPath $Out -Raw
        if ($committed -ne $json) {
            Write-Host "scripts registry: $Out is stale (re-run without -Check)" -ForegroundColor Red
            exit 1
        }
        Write-Host "scripts registry: $Out is current ($($scripts.Count) scripts)" -ForegroundColor Green
        exit 0
    }

    [IO.File]::WriteAllText((Join-Path $repoRoot $Out), $json, [Text.UTF8Encoding]::new($false))
    Write-Host "scripts registry regenerated: $Out ($($scripts.Count) scripts)" -ForegroundColor Green
} finally {
    Pop-Location
}
