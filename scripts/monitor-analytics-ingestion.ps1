# Live monitoring script for Resonai analytics ingestion
# Watches SigNoz for new analytics events and displays real-time stats

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== Resonai Analytics Live Monitoring ===" -ForegroundColor Green

# Get SigNoz auth headers if available
$script:sigNozHeaders = $null
$envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_TOKEN')
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_BEARER') }
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_JWT') }
if ($envToken) { $script:sigNozHeaders = @{ Authorization = "Bearer $envToken" } }

function Write-Info { param([string]$Message) Write-Host "   [INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "   [SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "   [WARNING] $Message" -ForegroundColor Yellow }

function Get-AnalyticsCount {
    param([int]$MinutesBack = 5)
    $now = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $start = $now - [long]($MinutesBack * 60000)
    $filterExpression = "attributes.dataset = `"resonai_analytics`""
    $payload = @{ 
        start=$start; 
        end=$now; 
        requestType="raw"; 
        compositeQuery=@{ 
            queries=@(@{ 
                type="builder_query"; 
                spec=@{ 
                    name="analytics_count"; 
                    signal="logs"; 
                    filter=@{ expression=$filterExpression }; 
                    order=@(@{ key=@{ name="timestamp" }; direction="desc" }); 
                    limit=100; 
                    offset=0 
                }
            }) 
        } 
    } | ConvertTo-Json -Depth 8
    
    $params = @{ Method='Post'; Uri='http://localhost:8080/api/v5/query_range'; ContentType='application/json'; Body=$payload; TimeoutSec=10 }
    if ($script:sigNozHeaders) { $params.Headers = $script:sigNozHeaders }
    
    try {
        $response = Invoke-RestMethod @params
        if ($response -and $response.data -and $response.data.result) {
            $count = $response.data.result[0].values.Count
            return $count
        }
        return 0
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 401) {
            Write-Warning "Authentication required - set SIGNOZ_API_TOKEN for live monitoring"
            return -1
        }
        Write-Warning "Query failed: $($_.Exception.Message)"
        return -1
    }
}

function Get-EventTypes {
    param([int]$MinutesBack = 5)
    $now = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $start = $now - [long]($MinutesBack * 60000)
    $filterExpression = "attributes.dataset = `"resonai_analytics`""
    $payload = @{ 
        start=$start; 
        end=$now; 
        requestType="raw"; 
        compositeQuery=@{ 
            queries=@(@{ 
                type="builder_query"; 
                spec=@{ 
                    name="event_types"; 
                    signal="logs"; 
                    filter=@{ expression=$filterExpression }; 
                    groupBy=@(@{ name="attributes.event" }); 
                    order=@(@{ key=@{ name="timestamp" }; direction="desc" }); 
                    limit=20; 
                    offset=0 
                }
            }) 
        } 
    } | ConvertTo-Json -Depth 8
    
    $params = @{ Method='Post'; Uri='http://localhost:8080/api/v5/query_range'; ContentType='application/json'; Body=$payload; TimeoutSec=10 }
    if ($script:sigNozHeaders) { $params.Headers = $script:sigNozHeaders }
    
    try {
        $response = Invoke-RestMethod @params
        if ($response -and $response.data -and $response.data.result) {
            return $response.data.result
        }
        return @()
    } catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode.value__ -eq 401) {
            return @()
        }
        return @()
    }
}

Write-Host "`nStarting live monitoring..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$lastCount = -1
$iteration = 0

try {
    while ($true) {
        $iteration++
        $timestamp = Get-Date -Format "HH:mm:ss"
        
        Write-Host "[$timestamp] Monitoring iteration $iteration" -ForegroundColor Cyan
        
        # Get current analytics count
        $currentCount = Get-AnalyticsCount -MinutesBack 2
        
        if ($currentCount -eq -1) {
            Write-Warning "Cannot query SigNoz (authentication required)"
            Write-Host "   Set SIGNOZ_API_TOKEN environment variable for live monitoring" -ForegroundColor Gray
            Write-Host "   Manual check: http://localhost:8080 → Logs → Filter: attributes.dataset = `"resonai_analytics`"" -ForegroundColor Gray
        } elseif ($currentCount -gt $lastCount -and $lastCount -ne -1) {
            $newEvents = $currentCount - $lastCount
            Write-Success "New analytics events detected: +$newEvents (total: $currentCount)"
            
            # Get event types breakdown
            $eventTypes = Get-EventTypes -MinutesBack 2
            if ($eventTypes.Count -gt 0) {
                Write-Info "Recent event types:"
                foreach ($eventType in $eventTypes[0..([Math]::Min(5, $eventTypes.Count - 1))]) {
                    $eventName = $eventType.metric.attributes.event
                    $count = $eventType.values.Count
                    Write-Host "     - $eventName : $count events" -ForegroundColor White
                }
            }
        } elseif ($currentCount -ge 0) {
            Write-Info "Analytics events in last 2 minutes: $currentCount"
        }
        
        $lastCount = $currentCount
        
        # Check if Resonai dev server is still running
        try {
            $apiResponse = Invoke-RestMethod -Uri "http://localhost:3003/api/events" -Method GET -TimeoutSec 3
            Write-Info "Resonai API responding (buffer: $($apiResponse.total) events)"
        } catch {
            Write-Warning "Resonai API not responding - dev server may be down"
        }
        
        # Check OTel Collector health
        try {
            $healthResponse = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -TimeoutSec 3
            if ($healthResponse.StatusCode -eq 200) {
                Write-Info "OTel Collector healthy"
            }
        } catch {
            Write-Warning "OTel Collector health check failed"
        }
        
        Write-Host ""
        Start-Sleep -Seconds 10
    }
} catch {
    Write-Host "`nMonitoring stopped." -ForegroundColor Yellow
}

Write-Host "`n=== Monitoring Complete ===" -ForegroundColor Green
Write-Host "To continue monitoring manually:" -ForegroundColor Yellow
Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "2. Go to Logs section" -ForegroundColor White
Write-Host "3. Filter: attributes.dataset = `"resonai_analytics`"" -ForegroundColor White
Write-Host "4. Set up alerts using docs/QUERY_RECIPES.md" -ForegroundColor White
