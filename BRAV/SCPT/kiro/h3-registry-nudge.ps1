#Requires -Version 7
<#
.SYNOPSIS
  H3 — registry nudge on workflow edits (registry-guard / drift shift-left).
  Reads Kiro postToolUse JSON from stdin; if .github/workflows/** touched, nudge regen.
#>
$ErrorActionPreference = 'Stop'
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try { $evt = $raw | ConvertFrom-Json } catch { Write-Error "H3: invalid hook JSON"; exit 1 }

$paths = @()
if ($evt.tool_input.operations) {
  foreach ($op in $evt.tool_input.operations) {
    if ($op.path) { $paths += [string]$op.path }
  }
}
if ($evt.tool_input.path) { $paths += [string]$evt.tool_input.path }
if ($evt.tool_input.file_path) { $paths += [string]$evt.tool_input.file_path }

$hit = $false
foreach ($p in $paths) {
  $n = $p -replace '\\', '/'
  if ($n -match '(^|/)\.github/workflows/') { $hit = $true; break }
}
if (-not $hit) { exit 0 }

# registry-guard.yml compares docs/status/workflows.json against a fresh run of
# scripts/regenerate-workflows-registry.ps1, so that is the regeneration to nudge.
# (An earlier version ran `pnpm agent:setup`, which generated the bots roster in
# docs/BossCat/AGENTS.md — unrelated to the workflows registry, and the alias no
# longer exists in package.json.)
$repo = if ($evt.cwd) { $evt.cwd } else { (Get-Location).Path }
Push-Location $repo
try {
  $regen = Join-Path $repo 'scripts/regenerate-workflows-registry.ps1'
  if (-not (Test-Path -LiteralPath $regen)) {
    Write-Error "H3: workflow edited — regenerate docs/status/workflows.json before push; $regen not found."
    exit 1
  }
  Write-Host 'H3: workflow edited — running scripts/regenerate-workflows-registry.ps1 (registry-guard shift-left)'
  & $regen
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  $drift = @(& git status --porcelain -- docs/status/workflows.json)
  if ($drift.Count -gt 0) {
    Write-Host 'H3: docs/status/workflows.json changed — stage it with the workflow edit.'
  }
  exit 0
} finally {
  Pop-Location
}
