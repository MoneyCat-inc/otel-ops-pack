# Repo-relative entry point: delegates to root verify-integration.ps1.
# BRAV\SCPT\verify-integration.ps1 is a parallel wrapper to the same root script;
# it does not delegate through this file.

$ErrorActionPreference = 'Stop'

$root = Resolve-Path -Path (Join-Path $PSScriptRoot '..')
$verifyScript = Join-Path $root 'verify-integration.ps1'

if (-not (Test-Path $verifyScript)) {
    Write-Error "verify-integration.ps1 not found at $verifyScript"
    exit 1
}

& $verifyScript @args
exit $LASTEXITCODE
