# Invoke Quil - DOCS Lane Automation
# ECRR Phase: CLEAN → REPORT (automation assist)
# Cat Nap Control Room - VelvetQuill-42

param(
    [ValidateSet(1,2,3)]
    [int]$Ticket = 1,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
$outDir = Join-Path $root "artifacts\codex"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if (-not $env:OPENAI_API_KEY) {
    Write-Error "OPENAI_API_KEY not set. Quil requires an API key."
    exit 1
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  🪶 Quil DOCS Lane Invocation" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Ticket: $Ticket" -ForegroundColor Gray
Write-Host "Dry Run: $($DryRun.IsPresent)" -ForegroundColor Gray

$ticketMap = @{
    1 = @{ title = "DOCS Ticket 1"; area = "Architecture Documentation Cleanup"; prompt = @"
ECRR Remediation Ticket 1 – Architecture Documentation Cleanup (DOCS lane)

Context:
- Remove Windows Collector references
- Document direct-to-SigNoz as canonical architecture
- Update runbooks, onboarding, diagrams

Artifacts:
- README.md
- docs/runbooks/unified-telemetry-proofs.md
- docs/architecture/**/*
- docs/ecrr/ECRR_TEMPLATE.md
- docs/ecrr/INDEX.md

Requirements:
- Produce unified diff patches
- Ensure Clean & Role phases are documented
- Budget ≤10 files, ≤200 LOC
- Include testing/validation steps for docs (peer review, lint, link check)
- Tone: VelvetQuill (calm, parchment metaphors)
"@ }

    2 = @{ title = "DOCS Ticket 2"; area = "ECRR Template Rollout"; prompt = @"
ECRR Remediation Ticket 2 – Template Rollout (DOCS lane)

Tasks:
- Publish docs/ecrr/ECRR_TEMPLATE.md
- Update CONTRIBUTING.md with template requirement
- Create scripts/new-ecrr-report.ps1 helper
- Document usage in docs/ecrr/INDEX.md
- (Optional) add pre-commit or CI reminder for missing Clean/Role

Requirements:
- Unified diff patches with Clean/Role coverage
- ≤10 files, ≤150 LOC
- Include validation plan (lint, dry-run template generation)
- Tone: Quil (gentle, precise)
"@ }

    3 = @{ title = "DOCS Ticket 3"; area = "Monitoring Script Updates"; prompt = @"
ECRR Remediation Ticket 3 – Monitoring Script Updates (DOCS lane)

Tasks:
- Update scripts/quick-monitor.ps1
- Update scripts/monitor-optimized-pipeline.ps1
- Update scripts/verify-pipeline.ps1
- Remove Windows Collector STOPPED warnings or mark expected
- Document changes in docs/ecrr/INDEX.md

Requirements:
- Unified diffs with PowerShell context
- ≤5 files, ≤100 LOC
- Include testing plan (script dry-run, lint)
- Tone: Quil (ink metaphors)
"@ }
}

$ticketInfo = $ticketMap[$Ticket]

$question = @"
VelvetQuill-42, please generate an ECRR-compliant remediation workplan.

Ticket: $($ticketInfo.title)
Lane: DOCS
Focus Area: $($ticketInfo.area)

Instructions:
- Respect ECRR template (Examine, Clean, Report, Role)
- Provide unified diff patches with context
- Ensure testing strategies reference current scripts
- Maintain Cat Nap Control Room aesthetics (calm, ink, parchment)
- Sign off with `– Quil 🪶`

Ticket Prompt:
$($ticketInfo.prompt)
"@

# Include relevant files explicitly
$includePaths = @(
    "README.md",
    "docs/ecrr/ECRR_TEMPLATE.md",
    "docs/ecrr/INDEX.md",
    "docs/runbooks/unified-telemetry-proofs.md",
    "scripts/new-ecrr-report.ps1",
    "scripts/quick-monitor.ps1",
    "scripts/monitor-optimized-pipeline.ps1",
    "scripts/verify-pipeline.ps1"
) | Select-Object -Unique

if ($DryRun) {
    Write-Host "[DRY RUN] Quil would run with question:" -ForegroundColor Yellow
    Write-Host $question -ForegroundColor Gray
    Write-Host "IncludePaths:" -ForegroundColor Yellow
    $includePaths | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    exit 0
}

# Invoke workplan generation
Write-Host "Running Codex request..." -ForegroundColor Cyan
& "$root\codex\codex-request-openai.ps1" `
    -Since "HEAD~15" `
    -MaxFiles 60 `
    -IncludePaths $includePaths `
    -Question $question

if ($LASTEXITCODE -ne 0) {
    Write-Error "Codex request failed."
    exit 1
}

Write-Host "==> Quil workplan ready at artifacts\codex\workplan.json" -ForegroundColor Green
Write-Host "   Use codex-apply.ps1 to generate cursor instructions." -ForegroundColor Gray
