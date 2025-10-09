param(
  [string]$Bundle = "dist/codex-policy-bundle.tar.gz",
  [string]$Sig    = "dist/codex-policy-bundle.sig",
  [string]$PubKey = "cosign.pub",
  [string]$Pinned = "policies/pinned.json"
)
$ErrorActionPreference = "Stop"
$p = Get-Content $Pinned -Raw | ConvertFrom-Json
$ok = & "$PSScriptRoot/cosign.exe" verify-blob --key $PubKey --signature $Sig $Bundle
if ($LASTEXITCODE) { Write-Error "cosign verify failed"; exit 1 }
$sha = (Get-FileHash $Bundle -Algorithm SHA256).Hash.ToLower()
if ($sha -ne $p.sha256.ToLower()) { Write-Error "SHA256 mismatch"; exit 2 }
"Bundle verified: $Bundle"
