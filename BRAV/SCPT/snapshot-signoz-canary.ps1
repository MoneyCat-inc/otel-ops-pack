param(
    [string]$Window = '15m',
    [int]$StallMinutes = 5
)

$secrets = "scripts/secrets/signoz.secrets.ps1"
if (Test-Path $secrets) { . $secrets }

$query = 'message:"windows-canary" AND attributes.dataset:"resonai_analytics"'
$summaryJson = .\scripts\test-signoz-logs-query.ps1 -Query $query -LastMinutes ([int]($Window.TrimEnd('m'))) -Summary
if (-not $summaryJson) { Write-Error "No summary produced"; exit 1 }
$summary = $summaryJson | ConvertFrom-Json

$dir = "artifacts/signoz"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$path  = Join-Path $dir "canary-$stamp.json"
$summaryJson | Set-Content -Path $path -Encoding UTF8

$latest = Join-Path $dir "latest.json"
if (Test-Path $latest) {
    $prev = (Get-Content $latest -Raw) | ConvertFrom-Json
    $prevTs = $null
    $nowTs  = $null
    if ($prev.lastTs) { $prevTs = [datetime]$prev.lastTs }
    if ($summary.lastTs) { $nowTs = [datetime]$summary.lastTs }
    $deltaMin = if ($prevTs -and $nowTs) { [math]::Round( ($nowTs - $prevTs).TotalMinutes, 2 ) } else { 0 }
    $isStalled = ($summary.count -eq 0) -or ($deltaMin -lt 0.01 -and $StallMinutes -gt 0)

    if ($isStalled) {
        Write-Warning "Canary stalled: count=$($summary.count), lastTs=$($summary.lastTs)."
        if ($env:SIGNOZ_WEBHOOK_URL) {
            $payload = @{ text = "⚠️ SigNoz canary stalled: count=$($summary.count), lastTs=$($summary.lastTs) ($Window)" } | ConvertTo-Json
            try { Invoke-WebRequest -Uri $env:SIGNOZ_WEBHOOK_URL -Method POST -ContentType 'application/json' -Body $payload | Out-Null } catch {}
        }
    } else {
        Write-Host "Canary healthy: count=$($summary.count), lastTs=$($summary.lastTs). Δmin=$deltaMin" -ForegroundColor Green
    }
} else {
    Write-Host "Bootstrapping latest.json" -ForegroundColor Yellow
}

Copy-Item $path $latest -Force

