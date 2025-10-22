# Monitor Hub Production Health
# Checks hub.resonai.uk availability and key endpoints

param(
    [int]$IntervalSeconds = 300,  # Default: check every 5 minutes
    [int]$DurationMinutes = 60,   # Default: run for 1 hour
    [switch]$Once                 # Run once and exit
)

$hubUrl = "https://hub.resonai.uk"
$endpoints = @(
    "/",
    "/docs/status.html",
    "/CHAR/DOCS/docs/dashboards/live-metrics.html",
    "/CHAR/DOCS/docs/BossCat/data_room_enhanced.html",
    "/robots.txt",
    "/favicon.svg"
)

$startTime = Get-Date
$endTime = $startTime.AddMinutes($DurationMinutes)

Write-Host "=== Hub Production Monitoring ===" -ForegroundColor Cyan
Write-Host "URL: $hubUrl"
Write-Host "Endpoints: $($endpoints.Count)"
if ($Once) {
    Write-Host "Mode: Single check"
} else {
    Write-Host "Interval: $IntervalSeconds seconds"
    Write-Host "Duration: $DurationMinutes minutes"
    Write-Host "End Time: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
}
Write-Host ""

function Test-HubEndpoint {
    param([string]$Url)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -UseBasicParsing
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            Time = (Get-Date).ToString("HH:mm:ss")
        }
    } catch {
        return @{
            Success = $false
            StatusCode = $_.Exception.Response.StatusCode.value__
            Error = $_.Exception.Message
            Time = (Get-Date).ToString("HH:mm:ss")
        }
    }
}

$checkCount = 0

do {
    $checkCount++
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host "[$timestamp] Check #$checkCount" -ForegroundColor Yellow
    
    $results = @()
    $allSuccess = $true
    
    foreach ($endpoint in $endpoints) {
        $url = "$hubUrl$endpoint"
        $result = Test-HubEndpoint -Url $url
        
        if ($result.Success) {
            Write-Host "  ✓ $endpoint" -ForegroundColor Green -NoNewline
            Write-Host " ($($result.StatusCode))"
        } else {
            Write-Host "  ✗ $endpoint" -ForegroundColor Red -NoNewline
            Write-Host " ($($result.StatusCode) - $($result.Error))"
            $allSuccess = $false
        }
        
        $results += @{
            Timestamp = $timestamp
            Endpoint = $endpoint
            Success = $result.Success
            StatusCode = $result.StatusCode
        }
    }
    
    if ($allSuccess) {
        Write-Host "  Status: ✓ ALL PASS" -ForegroundColor Green
    } else {
        Write-Host "  Status: ✗ FAILURES DETECTED" -ForegroundColor Red
    }
    
    Write-Host ""
    
    if (-not $Once -and (Get-Date) -lt $endTime) {
        Start-Sleep -Seconds $IntervalSeconds
    }
    
} while (-not $Once -and (Get-Date) -lt $endTime)

Write-Host "=== Monitoring Complete ===" -ForegroundColor Cyan
Write-Host "Total checks: $checkCount"

