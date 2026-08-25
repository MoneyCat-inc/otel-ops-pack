#Requires -Version 7
<#
.SYNOPSIS
  Regenerate .kiro/steering/*.md from canonical AGENTS.md (+ clean-host port table).
  Do not hand-edit steering files — edit AGENTS.md / briefing, then re-run this script.
#>
param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\lib\OtelPorts.psm1') -Force
$otelPorts = Get-OtelPorts
$agents = Join-Path $RepoRoot 'AGENTS.md'
$outDir = Join-Path $RepoRoot '.kiro\steering'
if (-not (Test-Path $agents)) { throw "Missing canonical $agents" }
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$agentsText = Get-Content -Raw -Path $agents
# Collector pin comes from the single canonical pin file (#594) - hardcoding it here is how
# the steering doc served 0.104.0 for two upgrades after Phase 1 retired it.
$pinFile = Join-Path $RepoRoot 'scripts\windows\collector-version.txt'
if (-not (Test-Path $pinFile)) { throw "Missing collector pin file $pinFile" }
$collectorPin = (Get-Content -Raw $pinFile).Trim()
$generated = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$seatMatch = [regex]::Match($agentsText, '(?ms)^## Actor seats.*?(?=^## |\z)')
$seatBlock = if ($seatMatch.Success) { $seatMatch.Value.Trim() } else { '(see AGENTS.md — seats section missing)' }

$gov = @"
<!-- GENERATED FILE — do not hand-edit. Source: /AGENTS.md. Regen: pwsh -File BRAV/SCPT/kiro/regen-steering.ps1 -->
# BossCat governance (steering projection)

SOURCE: ``/AGENTS.md`` (canonical). Generated: $generated

$seatBlock

## Standing rules (projection)

- Credential/mint/login steps are **machine-operator only**
- Credentials that transit automation are **rotated — no deliberation**
- CI keys: least privilege / scoped — never classic repo-wide PAT class
- Governance trail is **GitHub-native** (Actions, PR evidence, BOSSCAT_LOG, ECRR)
- Do **not** open a second evidence plane on AWS
- Cursor and Kiro are **peers**, not a nested chain
- Briefings are canonical; Kiro specs are **projections** (header: ``projection — not canonical``)
- Lane discipline: ``docs_gate`` owns ``docs/**`` + ``README.md``; split code/docs/evidence when mixed scope would fail GR-02

## Pilot abort (Examine ECRR 2026-07-26)

- KIRO PRO · Y=1000 · reset 2026-08-01
- Examine open X=0.69 consumed
- **Hard abort at consumed >= 500.69**
- D4: same Pro pool for hooks (conservative); H1–H3 session-adjacent
"@

$otel = @"
<!-- GENERATED FILE - do not hand-edit. Sources: BRIEFING_CLEAN_HOST_E2E.md + DELT/CONF/otel-ports.json. Regen: regen-steering.ps1 -->
# OTel stranger-path ports (steering projection)

Generated: $generated

| Concern | Canonical |
|---------|-----------|
| SigNoz UI | http://localhost:$($otelPorts.SignozUiHttp) |
| SigNoz OTLP (Docker) | $($otelPorts.SignozOtlpGrpc) gRPC / $($otelPorts.SignozOtlpHttp) HTTP |
| Windows collector ingest | **$($otelPorts.IngestGrpc)** gRPC / **$($otelPorts.IngestHttp)** HTTP |
| Collector -> SigNoz | localhost:$($otelPorts.SignozOtlpGrpc) |
| Collector pin | otelcol-contrib **$collectorPin** |

Do **not** bind Windows collector ingest in the PlariumPlay range 5300-5319; use DELT/CONF/otel-ports.json.
"@

$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $outDir 'bosscat-governance.md'), $gov.Trim() + "`n", $utf8)
[IO.File]::WriteAllText((Join-Path $outDir 'otel-pipeline.md'), $otel.Trim() + "`n", $utf8)
Write-Host "Regenerated steering under $outDir"
