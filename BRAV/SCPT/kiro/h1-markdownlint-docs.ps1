#Requires -Version 7
<#
.SYNOPSIS
  H1 — markdownlint on docs writes (docs_gate GR-03 shift-left).
  Reads Kiro postToolUse JSON from stdin; lints changed docs/** or README.md paths.
#>
$ErrorActionPreference = 'Stop'
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try { $evt = $raw | ConvertFrom-Json } catch { Write-Error "H1: invalid hook JSON"; exit 1 }

$paths = @()
if ($evt.tool_input.operations) {
  foreach ($op in $evt.tool_input.operations) {
    if ($op.path) { $paths += [string]$op.path }
  }
}
if ($evt.tool_input.path) { $paths += [string]$evt.tool_input.path }
if ($evt.tool_input.file_path) { $paths += [string]$evt.tool_input.file_path }

$docs = @()
foreach ($p in $paths) {
  $n = $p -replace '\\', '/'
  if ($n -match '(^|/)docs/' -or $n -match '(^|/)README\.md$') {
    if (Test-Path -LiteralPath $p) { $docs += $p }
  }
}
if ($docs.Count -eq 0) { exit 0 }

$repo = if ($evt.cwd) { $evt.cwd } else { (Get-Location).Path }
$config = Join-Path $repo '.markdownlint-cli2.yaml'
$npxArgs = @('--yes', 'markdownlint-cli2@0.14.0')
if (Test-Path $config) { $npxArgs += @('--config', $config) }
$npxArgs += $docs

& npx @npxArgs
exit $LASTEXITCODE
