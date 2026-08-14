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

$repo = if ($evt.cwd) { $evt.cwd } else { (Get-Location).Path }
Push-Location $repo
try {
  if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Write-Host 'H3: workflow edited — running pnpm agent:setup (registry regen nudge)'
    pnpm agent:setup
    exit $LASTEXITCODE
  }
  Write-Error 'H3: workflow edited — regenerate registry before push (pnpm agent:setup). pnpm not found.'
  exit 1
} finally {
  Pop-Location
}
