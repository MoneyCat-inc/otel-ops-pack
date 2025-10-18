# SOCM Credentials Helper
# Loads Bluesky credentials from .env.socm file
# Usage: . ./scripts/social/set-credentials.ps1

$envFile = Join-Path $PSScriptRoot "../../.env.socm"

if (-not (Test-Path $envFile)) {
    Write-Host "❌ .env.socm not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create it from the example:" -ForegroundColor Yellow
    Write-Host "  Copy-Item .env.socm.example .env.socm" -ForegroundColor Cyan
    Write-Host "  Edit .env.socm with your App Password" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Get App Password from: https://bsky.app/settings/app-passwords" -ForegroundColor Gray
    exit 1
}

Write-Host "🔐 Loading Bluesky credentials from .env.socm..." -ForegroundColor Green

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "  ✓ $key" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "✅ Credentials loaded!" -ForegroundColor Green
Write-Host "   Handle: $env:BSKY_HANDLE" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready to post:" -ForegroundColor Yellow
Write-Host "  npm run social:post" -ForegroundColor Cyan

