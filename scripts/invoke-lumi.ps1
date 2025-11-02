# Invoke Lumi - VIZR Lane Automation
# ECRR Phase: CLEAN → REPORT (visualization focus)
# Cat Nap Control Room - LumiPulse-MkII

param(
    [ValidateSet(4,5)]
    [int]$Ticket = 4,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$outDir = Join-Path $root "artifacts\codex"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not $env:OPENAI_API_KEY) {
    Write-Error "OPENAI_API_KEY not set. Lumi requires an API key."
    exit 1
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  ✨ Lumi VIZR Lane Invocation" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Ticket: $Ticket" -ForegroundColor Gray
Write-Host "Dry Run: $($DryRun.IsPresent)" -ForegroundColor Gray

$ticketMap = @{
    4 = @{ title = "VIZR Ticket 4"; area = "Visualizer Documentation"; prompt = @"
Remediation Ticket 4 – Visualization Documentation (VIZR lane)

Objectives:
- Document ProjectM GPU container setup
- Create troubleshooting runbook for viz-engine
- Document VirtualGL deployment and rendering pipeline
- Add ECRR report for current visualizer state
- Produce architecture diagram for telemetry flow

Targets:
- docs/vizr/**/*
- docs/runbooks/vizr-*.md
- README.viz-engine.md
- scripts/viz-engine-*

Requirements:
- Provide unified diffs
- Within ≤10 files, ≤200 LOC
- Include validation/testing plan (render check, telemetry verification)
- Use luminous metaphors, sign off `– Lumi ✨`
"@ }

    5 = @{ title = "VIZR Ticket 5"; area = "Audio Pipeline Documentation"; prompt = @"
Remediation Ticket 5 – Audio Pipeline Documentation (VIZR lane)

Objectives:
- Document audio loopback configuration for visualizer
- Explain audio threading & synchronization
- Create troubleshooting guide for audio hiss / drift
- Add ECRR report for audio pipeline health
- Document performance tuning strategies

Targets:
- docs/audio/**/*
- docs/vizr/**/*
- scripts/audio-*
- README.viz-engine.md

Requirements:
- Unified diffs
- ≤10 files, ≤200 LOC
- Include verification steps (audio capture test, loopback validation)
- Tone: luminous, shimmering descriptions
"@ }
}

$ticketInfo = $ticketMap[$Ticket]

$question = @"
LumiPulse-MkII, please generate an ECRR-compliant remediation plan.

Ticket: $($ticketInfo.title)
Lane: VIZR
Focus Area: $($ticketInfo.area)

Instructions:
- Ensure EXAMINE/CLEAN/REPORT/ROLE are present
- Provide unified diff patches with context
- Include testing strategies referencing visualizer/audio scripts
- Maintain Cat Nap, luminous tone
- Sign off with `– Lumi ✨`

Ticket Prompt:
$($ticketInfo.prompt)
"@

# Include relevant files explicitly (not directories - codex-scan skips dirs)
$includePaths = @(
    "README.viz-engine.md",
    "docs/vizr/ARCHITECTURE_DIAGRAM.md",
    "docs/runbooks/vizr-troubleshooting.md",
    "docs/gpu/RUN_AND_VERIFY.md",
    "viz-engine-projectm-gpu/README.md",
    "viz-engine-projectm-gpu/Dockerfile.projectm-vgl",
    "docker-compose.viz.yml",
    "docs/ecrr/ECRR_TEMPLATE.md",
    "docs/ecrr/INDEX.md",
    "docs/ecrr/REMEDIATION_PLAN.md"
) | Where-Object { Test-Path (Join-Path $root $_) } | Select-Object -Unique

if ($DryRun) {
    Write-Host "[DRY RUN] Lumi would run with question:" -ForegroundColor Yellow
    Write-Host $question -ForegroundColor Gray
    Write-Host "IncludePaths:" -ForegroundColor Yellow
    $includePaths | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    exit 0
}

# Invoke workplan generation
Write-Host "Running Codex request..." -ForegroundColor Cyan
& "$root\codex\codex-request-openai.ps1" `
    -Since "HEAD~20" `
    -MaxFiles 70 `
    -IncludePaths $includePaths `
    -Question $question

if ($LASTEXITCODE -ne 0) {
    Write-Error "Codex request failed."
    exit 1
}

Write-Host "==> Lumi workplan ready at artifacts\codex\workplan.json" -ForegroundColor Green
Write-Host "   Use codex-apply.ps1 to produce cursor instructions." -ForegroundColor Gray
