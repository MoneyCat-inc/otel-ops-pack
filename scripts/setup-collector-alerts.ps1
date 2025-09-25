# Setup Collector Alerting Configuration
# Creates SigNoz alerts for Windows Collector stability monitoring

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$DryRun,
    [switch]$Import
)

# Create artifacts directory if it doesn't exist
$artifactsDir = "artifacts"
if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
}

# Alert configurations
$alerts = @(
    @{
        Name = "Collector Service Down"
        Description = "Windows OTel Collector service is not running"
        Query = "up{job='otelcol-contrib'} == 0"
        Duration = "1m"
        Severity = "critical"
        Labels = @{
            alertname = "CollectorServiceDown"
            service = "otelcol-contrib"
            severity = "critical"
        }
        Annotations = @{
            summary = "OTel Collector service is down"
            description = "Windows OTel Collector service has been down for more than 1 minute"
            runbook_url = "https://docs.signoz.io/docs/runbooks/collector-service-down"
        }
    },
    @{
        Name = "Collector High Error Rate"
        Description = "OTel Collector is experiencing high error rates"
        Query = "rate(otelcol_exporter_send_failed_total[5m]) > 0.1"
        Duration = "2m"
        Severity = "warning"
        Labels = @{
            alertname = "CollectorHighErrorRate"
            service = "otelcol-contrib"
            severity = "warning"
        }
        Annotations = @{
            summary = "OTel Collector high error rate"
            description = "OTel Collector error rate is above 0.1 failures per second for 2 minutes"
            runbook_url = "https://docs.signoz.io/docs/runbooks/collector-errors"
        }
    },
    @{
        Name = "Collector Memory Usage High"
        Description = "OTel Collector memory usage is critically high"
        Query = "process_resident_memory_bytes{job='otelcol-contrib'} > 1073741824"
        Duration = "5m"
        Severity = "warning"
        Labels = @{
            alertname = "CollectorMemoryHigh"
            service = "otelcol-contrib"
            severity = "warning"
        }
        Annotations = @{
            summary = "OTel Collector memory usage high"
            description = "OTel Collector memory usage is above 1GB for 5 minutes"
            runbook_url = "https://docs.signoz.io/docs/runbooks/collector-memory"
        }
    },
    @{
        Name = "Collector Port Not Listening"
        Description = "OTel Collector OTLP ports are not responding"
        Query = "up{job='otelcol-otlp-ports'} == 0"
        Duration = "1m"
        Severity = "critical"
        Labels = @{
            alertname = "CollectorPortsDown"
            service = "otelcol-contrib"
            severity = "critical"
        }
        Annotations = @{
            summary = "OTel Collector ports not listening"
            description = "OTel Collector OTLP ports (5317/5318) are not responding for 1 minute"
            runbook_url = "https://docs.signoz.io/docs/runbooks/collector-ports"
        }
    }
)

# Generate alert configuration JSON
function Generate-AlertConfig {
    param($Alert)
    
    $config = @{
        alert = $Alert.Name
        expr = $Alert.Query
        for = $Alert.Duration
        labels = $Alert.Labels
        annotations = $Alert.Annotations
    }
    
    return $config
}

# Create alert rule file
function Create-AlertRules {
    param($AlertConfigs)
    
    $rules = @{
        groups = @(
            @{
                name = "otel-collector-alerts"
                rules = $AlertConfigs
            }
        )
    }
    
    return $rules
}

# Test SigNoz connectivity
function Test-SigNozConnectivity {
    param($Url)
    
    try {
        $response = Invoke-WebRequest -Uri "$Url/api/v1/health" -TimeoutSec 10 -ErrorAction Stop
        return $response.StatusCode -eq 200
    } catch {
        Write-Warning "Cannot connect to SigNoz at $Url`: $($_.Exception.Message)"
        return $false
    }
}

# Import alerts to SigNoz
function Import-AlertsToSigNoz {
    param($Url, $Rules)
    
    try {
        $jsonBody = $Rules | ConvertTo-Json -Depth 10
        $headers = @{
            'Content-Type' = 'application/json'
        }
        
        $response = Invoke-RestMethod -Uri "$Url/api/v1/alerts" -Method POST -Body $jsonBody -Headers $headers -ErrorAction Stop
        return $true
    } catch {
        Write-Error "Failed to import alerts to SigNoz: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-Host "Setting up OTel Collector Alerting Configuration" -ForegroundColor Cyan
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Gray

# Generate alert configurations
$alertConfigs = @()
foreach ($alert in $alerts) {
    $config = Generate-AlertConfig -Alert $alert
    $alertConfigs += $config
    
    Write-Host "Generated alert: $($alert.Name)" -ForegroundColor Green
}

# Create rules configuration
$rulesConfig = Create-AlertRules -AlertConfigs $alertConfigs

# Export to file
$exportFile = "$artifactsDir/signoz-collector-alerts.json"
$rulesConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportFile -Encoding UTF8

Write-Host "`nAlert configuration exported to: $exportFile" -ForegroundColor Green

# Display configuration summary
Write-Host "`n=== Alert Configuration Summary ===" -ForegroundColor Cyan
foreach ($alert in $alerts) {
    Write-Host "• $($alert.Name)" -ForegroundColor White
    Write-Host "  Query: $($alert.Query)" -ForegroundColor Gray
    Write-Host "  Duration: $($alert.Duration)" -ForegroundColor Gray
    Write-Host "  Severity: $($alert.Severity)" -ForegroundColor Gray
    Write-Host ""
}

if ($DryRun) {
    Write-Host "Dry run mode - configuration generated but not imported" -ForegroundColor Yellow
    Write-Host "Use -Import flag to import to SigNoz" -ForegroundColor Yellow
} elseif ($Import) {
    Write-Host "`nTesting SigNoz connectivity..." -ForegroundColor Yellow
    
    if (Test-SigNozConnectivity -Url $SigNozUrl) {
        Write-Host "SigNoz is accessible" -ForegroundColor Green
        
        Write-Host "Importing alerts to SigNoz..." -ForegroundColor Yellow
        if (Import-AlertsToSigNoz -Url $SigNozUrl -Rules $rulesConfig) {
            Write-Host "Alerts imported successfully!" -ForegroundColor Green
        } else {
            Write-Host "Failed to import alerts" -ForegroundColor Red
        }
    } else {
        Write-Host "SigNoz is not accessible - skipping import" -ForegroundColor Red
        Write-Host "Please ensure SigNoz is running and accessible at $SigNozUrl" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nTo import alerts to SigNoz, run:" -ForegroundColor Yellow
    Write-Host "pwsh -File scripts/setup-collector-alerts.ps1 -Import" -ForegroundColor White
}

Write-Host "`nAlert setup complete!" -ForegroundColor Cyan
