param([string]$Out="docs/sbom/codex-local.cdx.json")
$ErrorActionPreference = "Stop"
if (-not (Test-Path "docs/sbom")) { New-Item -Type Directory "docs/sbom" | Out-Null }
pnpm dlx @cyclonedx/cyclonedx-npm --output-format json --output-file $Out
"SBOM written to $Out"
