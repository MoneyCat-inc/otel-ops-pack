# Wrapper to run the root verify-integration.ps1 from any location

$ErrorActionPreference = 'Stop'

$root = Resolve-Path -Path (Join-Path $PSScriptRoot '..')
$verifyScript = Join-Path $root 'verify-integration.ps1'

if (-not (Test-Path $verifyScript)) {
    Write-Error "verify-integration.ps1 not found at $verifyScript"
    exit 1
}

& $verifyScript @args
exit $LASTEXITCODE