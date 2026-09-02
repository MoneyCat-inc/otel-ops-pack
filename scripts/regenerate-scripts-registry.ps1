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

    # Ordinal sort: culture-aware sorting differs between ICU builds and crashes outright in
    # globalization-invariant mode (both seen 2026-09-02); ordinal is identical everywhere.
    $paths = [string[]]$entries.Keys
    [System.Array]::Sort($paths, [System.StringComparer]::Ordinal)
    $scripts = @(foreach ($path in $paths) {
        $name = [IO.Path]::GetFileName($path)
        $lane = if ($name -match 'gate|verify') { 'GATE' }
                elseif ($name -match 'monitor|canary|test') { 'SSOT' }
                elseif ($name -match 'benchmark|process') { 'COMP' }
                elseif ($name -match 'hub|export') { 'DOCS' }
                else { 'UTIL' }

        # Size of the file as git would commit it: hash the working-tree content through the
        # repo's clean filters (CRLF-safe) so an edited-but-unstaged script is measured as it is
        # now, not as the index remembers it (a stale self-size failed the first CI run). Falls
        # back to the index blob when the file is absent from disk.
        $oid = $entries[$path]
        if (Test-Path -LiteralPath (Join-Path $repoRoot $path)) {
            $hashed = (& git hash-object -w --path $path -- $path 2>$null)
            if ($LASTEXITCODE -eq 0 -and $hashed) { $oid = $hashed.Trim() }
        }
        $size = [int](& git cat-file -s $oid)

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

    $outPath = [System.IO.Path]::GetFullPath($Out, $repoRoot)

    if ($Check) {
        if (-not (Test-Path -LiteralPath $outPath)) {
            Write-Host "scripts registry: $Out missing" -ForegroundColor Red
            exit 1
        }
        $committed = [System.IO.File]::ReadAllText($outPath)
        if (-not [string]::Equals($committed, $json, [System.StringComparison]::Ordinal)) {
            Write-Host "scripts registry: $Out is stale (re-run without -Check)" -ForegroundColor Red
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
        Write-Host "scripts registry: $Out is current ($($scripts.Count) scripts)" -ForegroundColor Green
        exit 0
    }

    [System.IO.File]::WriteAllText($outPath, $json, [System.Text.UTF8Encoding]::new($false))
    Write-Host "scripts registry regenerated: $Out ($($scripts.Count) scripts)" -ForegroundColor Green
} finally {
    Pop-Location
}
