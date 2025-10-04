# Test SigNoz Logs Query Script
# Query SigNoz for Windows canary logs

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$Query = 'message contains "windows-canary" AND attributes[''dataset''] = "resonai_analytics"',
    [int]$LastMinutes = 15,
    [string]$ApiToken,
    [string]$SessionCookie,
    [switch]$Summary
)

Write-Host "=== Testing SigNoz Logs Query ===" -ForegroundColor Green

try {
    # pick up env fallbacks if not explicitly provided
    if (-not $ApiToken -and $env:SIGNOZ_API_TOKEN) { $ApiToken = $env:SIGNOZ_API_TOKEN }
    if (-not $SessionCookie -and $env:SIGNOZ_SESSION) { $SessionCookie = $env:SIGNOZ_SESSION }
    if (-not $SigNozUrl -and $env:SIGNOZ_BASE_URL) { $SigNozUrl = $env:SIGNOZ_BASE_URL }
    # Test query for canary logs
    $queryPayload = @{
        query = $Query
        limit = 25
        start = (Get-Date).AddMinutes(-1 * $LastMinutes).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    Write-Host "Query: $($queryPayload.query)" -ForegroundColor Yellow
    Write-Host "Time range: Last $LastMinutes minutes" -ForegroundColor Yellow
    
    $headers = @{}
    if ($ApiToken -and $ApiToken.Trim().Length -gt 0) {
        $headers["Authorization"] = "Bearer $ApiToken"
    }
    if ($SessionCookie -and $SessionCookie.Trim().Length -gt 0) {
        $headers["Cookie"] = $SessionCookie
    }

    $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method Post -Headers $headers -Body ($queryPayload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10

    # Detect HTML login page (missing/invalid auth)
    if ($response -is [string] -and $response.TrimStart().StartsWith("<!doctype html>", [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "\n❗ Authentication required or token/cookie invalid. The API returned the login HTML." -ForegroundColor Yellow
        Write-Host "- Use -ApiToken '<SIGNOZ_API_TOKEN>' (Authorization: Bearer)" -ForegroundColor Yellow
        Write-Host "- Or use -SessionCookie 'signoz-session=<cookie_value>' (name=value only)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n✅ SigNoz Query Successful!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 4
    
    if ($response.logs -and $response.logs.Count -gt 0) {
        Write-Host "`n📊 Found $($response.logs.Count) matching log entries" -ForegroundColor Green
        $first = $response.logs[0]
        Write-Host "Sample attributes.dataset: $($first.attributes.dataset)" -ForegroundColor Yellow
        $response.logs[0] | ConvertTo-Json -Depth 4
    } else {
        Write-Host "`n⚠️ No canary logs found in SigNoz" -ForegroundColor Yellow
        Write-Host "This might be due to:" -ForegroundColor Gray
        Write-Host "- Time range too narrow" -ForegroundColor Gray
        Write-Host "- Logs still being processed" -ForegroundColor Gray
        Write-Host "- Different field names in SigNoz" -ForegroundColor Gray
    }

    if ($Summary) {
        # Compact summary for downstream automation
        # Note: shape according to observed response model
        $rows = @()
        if ($response.logs) { $rows = @($response.logs) }
        $count = $rows.Count
        $lastTs = $null
        if ($count -gt 0) {
            $lastTs = ($rows | Sort-Object ts | Select-Object -Last 1).ts
        }
        @{ count = $count; lastTs = $lastTs; window = "$LastMinutes`m"; query = $Query; ts = (Get-Date).ToUniversalTime().ToString("o") } |
            ConvertTo-Json -Depth 5
        return
    }
    
} catch {
    Write-Host "❌ SigNoz query failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Gray
}

Write-Host "`n=== Manual Verification Steps ===" -ForegroundColor Cyan
Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Go to Logs section" -ForegroundColor White
Write-Host "3. Set time range to 'Last 15 minutes'" -ForegroundColor White
Write-Host "4. Clear all filters" -ForegroundColor White
Write-Host "5. Add filter: log.file.path = 'C:/logs/windows-canary-test.log'" -ForegroundColor White
Write-Host "6. Add quick search: body contains 'windows-canary'" -ForegroundColor White
Write-Host "7. Click Apply" -ForegroundColor White

Write-Host "`n=== Alternative Query ===" -ForegroundColor Cyan
Write-Host "Try this query in SigNoz Logs:" -ForegroundColor White
Write-Host "log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'" -ForegroundColor Gray
