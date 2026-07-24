# Cursor sessionStart hook - nudge agent when Bluesky weekly maintenance is overdue.
$ErrorActionPreference = 'SilentlyContinue'
$null = [Console]::In.ReadToEnd()

$repoRoot = (Get-Location).Path
$script = Join-Path $repoRoot 'scripts/bsky-weekly-reminder.ps1'
if (-not (Test-Path $script)) {
    # Social automation moved to MoneyCat-inc/socm — emit a soft pointer if runbook says due.
    Write-Output '{}'
    exit 0
}

$null = & pwsh -NoProfile -File $script 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 2) {
    $context = @"
BSKY_WEEKLY_MAINTENANCE_DUE: Resonai [OTel] Bluesky upkeep is overdue (7-day cadence).
Automation repo: https://github.com/MoneyCat-inc/socm
Runbook (ops-pack): docs/BossCat/BSKY_WEEKLY_MAINTENANCE.md
Profile: https://bsky.app/profile/resonai.bsky.social
Local reminder (if present): pwsh -File scripts/bsky-weekly-reminder.ps1
"@
    $response = @{ additional_context = $context } | ConvertTo-Json -Compress
    Write-Output $response
    exit 0
}

Write-Output '{}'
exit 0
