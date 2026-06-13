# Cursor sessionStart hook — nudge agent when Ko-fi weekly maintenance is overdue.
$ErrorActionPreference = 'SilentlyContinue'
$null = [Console]::In.ReadToEnd()

$repoRoot = (Get-Location).Path
$script = Join-Path $repoRoot 'scripts/kofi-weekly-reminder.ps1'
if (-not (Test-Path $script)) {
    Write-Output '{}'
    exit 0
}

$null = & pwsh -NoProfile -File $script 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 2) {
    $context = @"
KOFI_WEEKLY_MAINTENANCE_DUE: Resonai [OTel] Ko-fi upkeep is overdue (7-day cadence).
Run: pwsh -File scripts/kofi-weekly-reminder.ps1
Runbook: docs/BossCat/KOFI_WEEKLY_MAINTENANCE.md
Page: https://ko-fi.com/fubumaki
After checklist: pwsh -File scripts/kofi-weekly-reminder.ps1 -MarkComplete
"@
    $response = @{ additional_context = $context } | ConvertTo-Json -Compress
    Write-Output $response
    exit 0
}

Write-Output '{}'
exit 0
