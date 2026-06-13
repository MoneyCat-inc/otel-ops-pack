#Requires -Version 7.0
<#
.SYNOPSIS
  After SkyFeed publish: capture URIs, update docs, post Bluesky announcement.
#>
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $RepoRoot

Write-Host "Listing feed generators..." -ForegroundColor Cyan
& npx tsx scripts/social/list-feed-generators.ts
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$livePath = Join-Path $RepoRoot 'docs/social/skyfeed-feeds-live.json'
if (-not (Test-Path $livePath)) {
    Write-Host "No skyfeed-feeds-live.json — publish feeds in SkyFeed first." -ForegroundColor Red
    exit 1
}

$live = Get-Content $livePath -Raw | ConvertFrom-Json
$count = @($live.feeds).Count
Write-Host "Found $count feed generator record(s)." -ForegroundColor $(if ($count -ge 3) { 'Green' } else { 'Yellow' })

if ($count -lt 1) {
    Write-Host "No feeds on account yet. Complete SkyFeed wizard first." -ForegroundColor Red
    exit 1
}

if ($count -ge 1) {
    Write-Host "Posting Bluesky launch thread..." -ForegroundColor Cyan
    & npx tsx scripts/social/post-skyfeed-launch.ts
}

if ($count -ge 3) {
    & npm run social:export | Out-Null
    & pwsh -NoProfile -File scripts/bsky-weekly-reminder.ps1 -MarkComplete -Notes "SkyFeed 3 feeds published"
    Write-Host "`n✅ SkyFeed setup complete ($count feeds)." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Partial setup ($count/3 feeds). Re-run wizard for remaining feeds." -ForegroundColor Yellow
}
