#Requires -Version 7.0
<#
.SYNOPSIS
  Interactive SkyFeed setup wizard for Resonai AntiClickbait feeds.
.DESCRIPTION
  SkyFeed is a Flutter web app — DOM automation is unreliable. This wizard opens
  skyfeed.app, prints copy-paste rules per feed, and waits for you to publish each one.
.EXAMPLE
  pwsh -File scripts/social/skyfeed-wizard.ps1
.EXAMPLE
  pwsh -File scripts/social/skyfeed-wizard.ps1 -FinalizeOnly
#>
[CmdletBinding()]
param([switch]$FinalizeOnly)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $RepoRoot

$SkyFeedUrl = 'https://skyfeed.app/'
$StarterPackUrl = 'https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t'
$EnvFile = Join-Path $RepoRoot '.env.socm'
$FeedsDoc = Join-Path $RepoRoot 'docs/social/custom-feeds-skyfeed.yaml'
$StatusDoc = Join-Path $RepoRoot 'docs/social/SKYFEED_SETUP_STATUS.md'

function Write-Step([string]$Title, [string]$Color = 'Cyan') {
    Write-Host "`n=== $Title ===" -ForegroundColor $Color
}

function Get-BskyHandle {
    if (-not (Test-Path $EnvFile)) { return 'resonai.bsky.social' }
    $line = Get-Content $EnvFile | Where-Object { $_ -match '^BSKY_HANDLE=' } | Select-Object -First 1
    if ($line -match '^BSKY_HANDLE=(.+)$') { return $matches[1].Trim() }
    return 'resonai.bsky.social'
}

$feeds = @(
    @{
        Name = 'Fact-Check Firehose (Trusted)'
        Slug = 'factcheck-firehose'
        Description = 'High-signal posts from vetted fact-checkers and newswires; quotes get a boost.'
        Authors = @('fullfact.org', 'factcheck.afp.com', 'politifact.bsky.social', 'reuters.com')
        Hashtags = @('FactCheck', 'Debunk')
        TextContains = @('fact check', 'debunk', 'misleading', 'correction', 'false claim')
        Exclude = @('satire', 'parody')
    },
    @{
        Name = 'OSINT + Verification'
        Slug = 'osint-verification'
        Description = 'Reverse image, geolocation, EXIF/metadata, and method threads.'
        Authors = @('bellingcat.com', 'eliothiggins.bsky.social', 'sector035.bsky.social', 'mariannaspringbbc.bsky.social', 'quiztime.bsky.social')
        Hashtags = @('OSINT', 'Verification')
        TextContains = @('reverse image', 'exif', 'metadata', 'geolocate', 'osint', 'verify', 'geolocation')
        Exclude = @()
    },
    @{
        Name = 'AntiClickbait HQ'
        Slug = 'anticlickbait-hq'
        Description = "BossCat evidence-first posts + community engagement with #AntiClickbait."
        Authors = @('resonai.bsky.social')
        Hashtags = @('AntiClickbait', 'OpenTelemetry')
        TextContains = @('hub.resonai.uk', 'otel-ops-pack', 'evidence', 'transparency')
        Exclude = @()
    }
)

function Show-FeedRules([hashtable]$Feed) {
    Write-Host "Name: $($Feed.Name)" -ForegroundColor White
    Write-Host "Description: $($Feed.Description)" -ForegroundColor DarkGray
    Write-Host "Slug (if asked): $($Feed.Slug)" -ForegroundColor DarkGray
    Write-Host "`nInclude — Authors:" -ForegroundColor Yellow
    $Feed.Authors | ForEach-Object { Write-Host "  @$_" }
    Write-Host "Include — Hashtags:" -ForegroundColor Yellow
    $Feed.Hashtags | ForEach-Object { Write-Host "  #$_" }
    Write-Host "Include — Text contains (any):" -ForegroundColor Yellow
    $Feed.TextContains | ForEach-Object { Write-Host "  $_" }
    if ($Feed.Exclude.Count -gt 0) {
        Write-Host "Exclude — Text contains:" -ForegroundColor Red
        $Feed.Exclude | ForEach-Object { Write-Host "  $_" }
    }
}

function Invoke-Finalize {
    Write-Step 'Finalizing — list feed URIs from Bluesky'
    & pwsh -NoProfile -File (Join-Path $RepoRoot 'scripts/social/finalize-skyfeed.ps1')
}

if ($FinalizeOnly) {
    Invoke-Finalize
    exit $LASTEXITCODE
}

Write-Host "`n🦋 SkyFeed Wizard — Resonai AntiClickbait" -ForegroundColor Cyan
Write-Host "SkyFeed uses Flutter (no reliable bot automation). You'll publish 3 feeds manually." -ForegroundColor DarkGray
Write-Host "Credentials: BSKY_HANDLE + BSKY_APP_PASSWORD in .env.socm" -ForegroundColor DarkGray
Write-Host "Handle: $(Get-BskyHandle)" -ForegroundColor DarkGray

Write-Step 'Step 1: Login to SkyFeed'
Write-Host "Opening $SkyFeedUrl"
Write-Host "Login with app password from .env.socm (not your main account password)." -ForegroundColor Yellow
Start-Process $SkyFeedUrl
Read-Host "Press Enter after you are logged into SkyFeed"

$i = 0
foreach ($feed in $feeds) {
    $i++
    Write-Step "Feed $i/3 — $($feed.Name)" 'Green'
    Show-FeedRules $feed
    Write-Host "`nIn SkyFeed: Create Feed → paste rules above → Publish" -ForegroundColor Yellow
    Read-Host "Press Enter when feed $i is published"
}

Write-Step 'Step 4: Add feeds to Starter Pack' 'Magenta'
Write-Host "Open Starter Pack editor and add all 3 feeds under Choose Feeds:" -ForegroundColor Yellow
Write-Host $StarterPackUrl
Start-Process $StarterPackUrl
Read-Host "Press Enter when Starter Pack lists all 3 feeds"

Invoke-Finalize
