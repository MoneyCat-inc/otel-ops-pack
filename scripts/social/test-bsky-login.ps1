#Requires -Version 7.0
# Test Bluesky app password (never prints full password)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$envFile = Join-Path $repo '.env.socm'
if (-not (Test-Path $envFile)) { throw ".env.socm not found" }

$vars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([A-Z_]+)=(.+)$') { $vars[$matches[1]] = $matches[2].Trim() }
}

$handle = $vars['BSKY_HANDLE']
$pass = $vars['BSKY_APP_PASSWORD']
$service = if ($vars['BSKY_SERVICE']) { $vars['BSKY_SERVICE'] } else { 'https://bsky.social' }

if (-not $pass) { throw 'BSKY_APP_PASSWORD missing in .env.socm' }

$clean = $pass -replace '\s', ''
Write-Host "Handle: $handle"
Write-Host "Password: $($clean.Substring(0,4))…$($clean.Substring($clean.Length-4)) ($($clean.Length) chars)"
Write-Host ""

$uri = ($service.TrimEnd('/') + '/xrpc/com.atproto.server.createSession')
$ok = $false

foreach ($id in @($handle, ($handle -replace '\.bsky\.social$',''), ($handle -replace '^@',''))) {
    if (-not $id) { continue }
    $body = @{ identifier = $id; password = $pass } | ConvertTo-Json
    try {
        $r = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json'
        Write-Host "API login: OK with identifier '$id'" -ForegroundColor Green
        Write-Host "DID: $($r.did)"
        $ok = $true
        break
    } catch {
        Write-Host "Failed with identifier '$id'" -ForegroundColor DarkGray
    }
}

if ($ok) {
    Write-Host ""
    Write-Host "SkyFeed login fields:" -ForegroundColor Cyan
    Write-Host "  Service:  bsky.social"
    Write-Host "  Username: resonai.bsky.social"
    Write-Host "  Password: same value as BSKY_APP_PASSWORD in .env.socm"
    exit 0
}

Write-Host ""
Write-Host "API login failed for all identifier variants." -ForegroundColor Red
Write-Host ""
Write-Host "If you created a NEW SkyFeed app password:" -ForegroundColor Yellow
Write-Host "  Bluesky only shows it ONCE at creation — you cannot view it again."
Write-Host "  1. Delete the SkyFeed entry at bsky.app/settings/app-passwords"
Write-Host "  2. Add App Password → name it SkyFeed → COPY the xxxx-xxxx-xxxx-xxxx string"
Write-Host "  3. Paste into SkyFeed immediately AND update .env.socm BSKY_APP_PASSWORD="
Write-Host "  4. Re-run: pwsh -File scripts/social/test-bsky-login.ps1"
exit 1
