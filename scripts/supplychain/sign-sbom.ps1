param(
  [string]$Sbom="docs/sbom/codex-local.cdx.json",
  [string]$Key="cosign.key",
  [string]$SigOut="docs/sbom/codex-local.cdx.sig"
)
$ErrorActionPreference = "Stop"
& "$PSScriptRoot/../policy/cosign.exe" sign-blob --key $Key --output-signature $SigOut --yes $Sbom
"Signed SBOM: $SigOut"
