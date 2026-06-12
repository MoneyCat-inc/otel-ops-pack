# Check Hub Website Links for 404 Errors
# Usage: pwsh -File scripts\check-hub-links.ps1

$base = 'https://hub.resonai.uk/'
$links = @(
    'CHAR/DOCS/docs/dashboards/live-metrics.html',
    'CHAR/DOCS/docs/BossCat/data_room_enhanced.html',
    'portal.html',
    'docs/status.html',
    'CHAR/DOCS/docs/index.html',
    'docs/anticlickbait/index.html',
    'docs/assets/hub.css',
    'assets/hub.js',
    'favicon.svg',
    'docs/status/kpis.json'
)

$results = @()

Write-Host "Checking links on hub.resonai.uk..." -ForegroundColor Cyan
Write-Host ""

foreach ($link in $links) {
    $url = $base + $link
    Write-Host "Checking: $link" -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction Stop
        $status = $response.StatusCode
        $color = if ($status -eq 200) { "Green" } else { "Yellow" }
        Write-Host " → $status" -ForegroundColor $color
        $results += [PSCustomObject]@{
            Link = $link
            Status = $status
            URL = $url
            Error = $null
        }
    } catch {
        $status = if ($_.Exception.Response) { 
            $_.Exception.Response.StatusCode.value__ 
        } else { 
            'Error' 
        }
        Write-Host " → $status" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Link = $link
            Status = $status
            URL = $url
            Error = $_.Exception.Message
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan

$broken = $results | Where-Object { $_.Status -ne 200 }
$working = $results | Where-Object { $_.Status -eq 200 }

Write-Host "Working: $($working.Count)/$($results.Count)" -ForegroundColor Green
Write-Host "Broken: $($broken.Count)/$($results.Count)" -ForegroundColor $(if ($broken.Count -gt 0) { "Red" } else { "Green" })

if ($broken.Count -gt 0) {
    Write-Host ""
    Write-Host "Broken Links:" -ForegroundColor Red
    $broken | Format-Table -AutoSize
}

# Export results
$results | ConvertTo-Json -Depth 3 | Out-File -FilePath "artifacts\hub-link-check-$(Get-Date -Format 'yyyyMMdd-HHmmss').json" -Encoding UTF8
Write-Host ""
Write-Host "Results saved to artifacts\hub-link-check-*.json" -ForegroundColor Gray
