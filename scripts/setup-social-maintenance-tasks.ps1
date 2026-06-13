#!/usr/bin/env pwsh
#Requires -Version 7
<#
.SYNOPSIS
  Register all Resonai weekly social/maintenance scheduled tasks.
.EXAMPLE
  pwsh -File scripts/setup-social-maintenance-tasks.ps1
#>
$ErrorActionPreference = 'Stop'
$scripts = @(
    @{ Name = 'Ko-fi';   File = 'kofi-weekly-reminder.ps1';   Time = '10:15' }
    @{ Name = 'Patreon'; File = 'patreon-weekly-reminder.ps1'; Time = '10:20' }
    @{ Name = 'Bluesky'; File = 'bsky-weekly-reminder.ps1';   Time = '10:30' }
)
foreach ($s in $scripts) {
    $path = Join-Path $PSScriptRoot $s.File
    Write-Host "Registering $($s.Name) ($($s.Time) Mondays)..." -ForegroundColor Cyan
    & pwsh -NoProfile -File $path -RegisterScheduledTask
}
Write-Host "`nDone. Verify: Get-ScheduledTask -TaskName 'Resonai-*'" -ForegroundColor Green
