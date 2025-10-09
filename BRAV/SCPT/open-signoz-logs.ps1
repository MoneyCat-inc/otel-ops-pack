param(
    [string]$UiBaseUrl = 'http://localhost:8080',
    [int]$Minutes = 15
)

$ErrorActionPreference = 'Stop'

# Construct a minimal deep-link. SigNoz supports query params for time; filter may vary by version.
$to = [DateTimeOffset]::UtcNow
$from = $to.AddMinutes(-1 * $Minutes)
$fromMs = [int64]([TimeSpan]::FromSeconds([Math]::Floor(($from.ToUnixTimeMilliseconds())/1000))).TotalMilliseconds
$toMs = [int64]([TimeSpan]::FromSeconds([Math]::Floor(($to.ToUnixTimeMilliseconds())/1000))).TotalMilliseconds

# Basic logs page; user will apply filters if deep link format differs
$url = "$UiBaseUrl/logs?selected="

try {
    Start-Process $url | Out-Null
    Write-Host "Opened SigNoz Logs UI: $url"
} catch {
    Write-Warning "Failed to open browser: $($_.Exception.Message)"
    Write-Output $url
}


