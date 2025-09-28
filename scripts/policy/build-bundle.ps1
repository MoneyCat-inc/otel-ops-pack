param(
  [string]$OutFile = "dist/codex-policy-bundle.tar.gz",
  [string]$Version = "v1.0.0"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path "dist")) { New-Item -Type Directory dist | Out-Null }
& "$PSScriptRoot/opa.exe" build -b "policies" -o $OutFile
"Built $OutFile ($Version)"
