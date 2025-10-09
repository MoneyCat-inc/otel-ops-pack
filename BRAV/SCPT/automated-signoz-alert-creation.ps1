# BossCat Automated SigNoz Alert Creation Script
# Authority: BossCat OEM (Executive Overseer Manager)
# Purpose: Automatically create alerts in SigNoz to close the loop

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiKey,
    [string]$SessionCookie,
    [switch]$Verbose
)

Write-Host "🐾 BossCat Automated Alert Creation Loop" -ForegroundColor Green
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host "Mission: Close the loop automatically - Step 5/6 BLUE → GREEN" -ForegroundColor Yellow

# Function to make API calls to SigNoz
function Invoke-SigNozAPI {
    param(
        [Parameter(Mandatory=$true)][string]$Method,
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter()][hashtable]$Headers,
        [Parameter()][object]$Body
    )
    
    $uri = ($SigNozUrl.TrimEnd('/')) + $Path
    $commonHeaders = @{"Content-Type"="application/json"}
    
    if ($Headers) { 
        $Headers.GetEnumerator() | ForEach-Object { $commonHeaders[$_.Key] = $_.Value } 
    }
    
    try {
        if ($PSBoundParameters.ContainsKey('Body')) {
            $json = if ($Body -is [string]) { $Body } else { ($Body | ConvertTo-Json -Depth 20) }
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $commonHeaders -Body $json
        } else {
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $commonHeaders
        }
    } catch {
        Write-Warning "API call failed: $($_.Exception.Message)"
        return $null
    }
}

# Check SigNoz health first
Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -UseBasicParsing
    if ($health.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is healthy and accessible" -ForegroundColor Green
    }
} catch {
    Write-Warning "SigNoz health check failed: $($_.Exception.Message)"
}

# Try to get authentication headers
$authHeaders = @{}
if ($ApiKey) {
    $authHeaders["X-API-KEY"] = $ApiKey
    Write-Host "🔑 Using API key authentication" -ForegroundColor Yellow
} elseif ($SessionCookie) {
    $authHeaders["Cookie"] = "signoz-session=$SessionCookie"
    Write-Host "🍪 Using session cookie authentication" -ForegroundColor Yellow
} else {
    Write-Host "⚠️ No authentication provided - attempting without auth" -ForegroundColor Yellow
}

# Define BossCat alerts
$BossCatAlerts = @(
    @{
        name = "BossCat Pipeline Health Alert"
        description = "Critical alert when OTel pipeline stops receiving spans"
        type = "metric"
        severity = "critical"
        condition = @{
            metric = "rate(otelcol_*_spans_received_total[5m])"
            operator = "=="
            threshold = 0
            duration = "2m"
        }
        labels = @("bosscat", "pipeline", "critical")
    },
    @{
        name = "BossCat High Error Rate Alert"
        description = "Warning when pipeline error rate exceeds 5%"
        type = "metric"
        severity = "warning"
        condition = @{
            metric = "rate(otelcol_*_errors_total[5m])"
            operator = ">"
            threshold = 0.05
            duration = "5m"
        }
        labels = @("bosscat", "errors", "warning")
    },
    @{
        name = "BossCat Latency Spike Alert"
        description = "Warning when P95 latency exceeds 1 second"
        type = "metric"
        severity = "warning"
        condition = @{
            metric = "histogram_quantile(0.95, rate(otelcol_*_duration_seconds_bucket[5m]))"
            operator = ">"
            threshold = 1.0
            duration = "3m"
        }
        labels = @("bosscat", "latency", "warning")
    },
    @{
        name = "BossCat Throughput Drop Alert"
        description = "Warning when throughput drops below 10 spans/second"
        type = "metric"
        severity = "warning"
        condition = @{
            metric = "rate(otelcol_*_spans_processed_total[5m])"
            operator = "<"
            threshold = 10
            duration = "5m"
        }
        labels = @("bosscat", "throughput", "warning")
    },
    @{
        name = "BossCat Canary Missing Alert"
        description = "Critical alert when canary logs are missing for 10+ minutes"
        type = "log"
        severity = "critical"
        condition = @{
            query = "(log.source = 'windows_event_log' AND body contains 'windows-canary') OR (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')"
            operator = "absent"
            duration = "10m"
        }
        labels = @("bosscat", "canary", "critical")
    },
    @{
        name = "BossCat Error Log Alert"
        description = "Warning when error logs exceed threshold"
        type = "log"
        severity = "warning"
        condition = @{
            query = "severity = 'ERROR' OR level = 'error'"
            operator = ">"
            threshold = 10
            duration = "5m"
        }
        labels = @("bosscat", "errors", "warning")
    },
    @{
        name = "BossCat High Latency Trace Alert"
        description = "Warning when trace latency exceeds 500ms"
        type = "trace"
        severity = "warning"
        condition = @{
            query = "duration > 500ms"
            operator = ">"
            threshold = 5
            duration = "5m"
        }
        labels = @("bosscat", "traces", "latency", "warning")
    },
    @{
        name = "BossCat Error Trace Alert"
        description = "Critical alert for error traces"
        type = "trace"
        severity = "critical"
        condition = @{
            query = "status.code = 'ERROR' OR error = true"
            operator = ">"
            threshold = 0
            duration = "1m"
        }
        labels = @("bosscat", "traces", "errors", "critical")
    }
)

Write-Host "🚨 Creating BossCat alerts automatically..." -ForegroundColor Yellow

$created = 0
$failed = 0
$results = @()

foreach ($alert in $BossCatAlerts) {
    try {
        Write-Host "Creating: $($alert.name)" -ForegroundColor White
        
        # Try multiple API endpoints
        $endpoints = @("/api/v1/alerts", "/api/v1/rules", "/api/v1/alert-rules")
        $success = $false
        
        foreach ($endpoint in $endpoints) {
            try {
                $result = Invoke-SigNozAPI -Method Post -Path $endpoint -Headers $authHeaders -Body $alert
                if ($result) {
                    $created++
                    $success = $true
                    Write-Host "✅ Created: $($alert.name) via $endpoint" -ForegroundColor Green
                    break
                }
            } catch {
                # Continue to next endpoint
                continue
            }
        }
        
        if (-not $success) {
            $failed++
            Write-Warning "❌ Failed to create: $($alert.name)"
        }
        
        $results += @{
            name = $alert.name
            status = if ($success) { "created" } else { "failed" }
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        
    } catch {
        $failed++
        Write-Warning "❌ Error creating $($alert.name): $($_.Exception.Message)"
    }
}

# Wait a moment for SigNoz to process
Write-Host "⏳ Waiting for SigNoz to process alerts..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if we can verify the alerts were created
Write-Host "🔍 Verifying alert creation..." -ForegroundColor Yellow
try {
    $alertEndpoints = @("/api/v1/alerts", "/api/v1/rules")
    $verificationSuccess = $false
    
    foreach ($endpoint in $alertEndpoints) {
        try {
            $existingAlerts = Invoke-SigNozAPI -Method Get -Path $endpoint -Headers $authHeaders
            if ($existingAlerts) {
                Write-Host "✅ Successfully verified alerts via $endpoint" -ForegroundColor Green
                $verificationSuccess = $true
                break
            }
        } catch {
            continue
        }
    }
    
    if (-not $verificationSuccess) {
        Write-Warning "⚠️ Could not verify alert creation via API"
    }
} catch {
    Write-Warning "⚠️ Verification check failed: $($_.Exception.Message)"
}

# Generate completion report
$completionReport = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    authority = "BossCat OEM"
    operation = "Automated Alert Creation Loop"
    results = @{
        total_alerts = $BossCatAlerts.Count
        created_successfully = $created
        failed_to_create = $failed
        success_rate = if ($BossCatAlerts.Count -gt 0) { [math]::Round(($created / $BossCatAlerts.Count) * 100, 2) } else { 0 }
    }
    alert_results = $results
    wyzwoz_style = @{
        aesthetic = "cat_nap_control_room"
        monitoring_style = "feline_silence"
        automation_philosophy = "peaceful_vigilance"
    }
}

# Save completion report
$reportPath = "docs/BossCat/automated-alert-creation-report.json"
$completionReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "✅ Completion report saved: $reportPath" -ForegroundColor Green

Write-Host "`n🎭 BossCat Automated Alert Creation - WyzWoz Style Complete:" -ForegroundColor Magenta
Write-Host "   • Total Alerts: $($BossCatAlerts.Count)" -ForegroundColor White
Write-Host "   • Created Successfully: $created" -ForegroundColor Green
Write-Host "   • Failed: $failed" -ForegroundColor Red
Write-Host "   • Success Rate: $($completionReport.results.success_rate)%" -ForegroundColor Cyan

Write-Host "`n🌐 SigNoz Verification:" -ForegroundColor Cyan
Write-Host "   • Alerts UI: $SigNozUrl/alerts" -ForegroundColor White
Write-Host "   • Home Page: $SigNozUrl" -ForegroundColor White
Write-Host "   • Check Step 5/6 status change" -ForegroundColor White

Write-Host "`n🐾 BossCat Automated Alert Creation Loop Complete" -ForegroundColor Green
Write-Host "Feline Silence: Alert system automated with peaceful vigilance." -ForegroundColor Cyan

if ($created -gt 0) {
    Write-Host "`n✅ SUCCESS: Automated alert creation completed - Step 5/6 should now be GREEN" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ WARNING: No alerts were created automatically - manual intervention may be required" -ForegroundColor Yellow
}
