# Cursor sessionStart hook — nudge agent when Patreon weekly maintenance is overdue.
# Reads stdin JSON from Cursor; writes hook response JSON to stdout.
$ErrorActionPreference = 'SilentlyContinue'
$null = [Console]::In.ReadToEnd()

$repoRoot = (Get-Location).Path
$script = Join-Path $repoRoot 'scripts/patreon-weekly-reminder.ps1'
if (-not (Test-Path $script)) {
    Write-Output '{}'
    exit 0
}

$output = & pwsh -NoProfile -File $script 2>&1 | Out-String
$exitCode = $LASTEXITCODE

if ($exitCode -eq 2) {
    $context = @"
PATREON_WEEKLY_MAINTENANCE_DUE: Resonai [OTel] Patreon upkeep is overdue (7-day cadence).
Run: pwsh -File scripts/patreon-weekly-reminder.ps1
Runbook: docs/BossCat/PATREON_WEEKLY_MAINTENANCE.md
Page: https://www.patreon.com/c/FaeMcLachlan
After checklist: pwsh -File scripts/patreon-weekly-reminder.ps1 -MarkComplete
"@
    $response = @{ additional_context = $context } | ConvertTo-Json -Compress
    Write-Output $response
    exit 0
}

Write-Output '{}'
exit 0
