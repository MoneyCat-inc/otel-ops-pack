param(
  [string]$Bundle = "dist/codex-policy-bundle.tar.gz",
  [string]$Key    = "cosign.key",
  [string]$SigOut = "dist/codex-policy-bundle.sig"
)
$ErrorActionPreference = "Stop"
$bytes = Get-Content $Bundle -AsByteStream
$null = & "$PSScriptRoot/cosign.exe" sign-blob --key $Key --output-signature $SigOut --yes $Bundle
"Signed $Bundle -> $SigOut"
