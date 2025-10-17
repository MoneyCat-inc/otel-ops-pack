#Requires -Version 7.0

<#
.SYNOPSIS
  Wrapper entry point kept under scripts/ for compatibility with BossCat charter references.
.DESCRIPTION
  Delegates to BRAV/SCPT/nightly-dashboard-export.ps1 after resolving repository root.
  Parameters mirror the downstream script so existing automation keeps working.
#>

[CmdletBinding(DefaultParameterSetName='Default')]
param(
  [string]$SignozUrl,
  [string]$SignozSession,
  [string]$DashboardListPath,
  [string]$OutputRoot,
  [string]$ReportDir,
  [string]$SecurityScanDir,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$delegate = Join-Path $repoRoot 'BRAV/SCPT/nightly-dashboard-export.ps1'
if (-not (Test-Path -LiteralPath $delegate)) {
  throw "Delegate script not found at $delegate"
}

$forward = @{}
foreach ($key in $PSBoundParameters.Keys) {
  $forward[$key] = $PSBoundParameters[$key]
}

& $delegate @forward
