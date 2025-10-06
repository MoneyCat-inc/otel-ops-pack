# Simple SigNoz Setup Script - Fixed Version
# ECRR Framework Implementation

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = "local-signoz-jwt-secret-rotate",
    [switch]$DryRun = $false
)

Write-Host "🚨 Simple SigNoz Setup - Fixed Version" -ForegroundColor Cyan
Write-Host "ECRR Framework Implementation" -ForegroundColor Yellow
Write-Host ""

# Configuration
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

# Test SigNoz connectivity
Write-Host "🔍 Testing SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -Headers $Headers -TimeoutSec 10
    Write-Host "  ✅ SigNoz is accessible" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Cannot connect to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  💡 Make sure SigNoz is running: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

# Simple Alert Configuration
$SimpleAlerts = @(
    @{
        name = "Queue Utilization High"
        description = "Queue utilization above 80%"
        query = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100"
        condition = "> 80"
        duration = "5m"
        severity = "warning"
    },
    @{
        name = "Send Failure Rate High"
        description = "Send failure rate above 5%"
        query = "rate(otelcol_exporter_send_failed_log_records_total[5m]) / rate(otelcol_exporter_sent_log_records_total[5m]) * 100"
        condition = "> 5"
        duration = "5m"
        severity = "critical"
    },
    @{
        name = "Backend Error Rate High"
        description = "Backend error rate above 5%"
        query = "rate(http_requests_total{status_code=~'5..'}[5m]) / rate(http_requests_total[5m]) * 100"
        condition = "> 5"
        duration = "5m"
        severity = "critical"
    }
)

Write-Host "`n📊 Creating simple alerts..." -ForegroundColor Yellow
$CreatedAlerts = @()

foreach ($Alert in $SimpleAlerts) {
    Write-Host "  Creating alert: $($Alert.name)" -ForegroundColor Cyan
    
    if (-not $DryRun) {
        try {
            $AlertConfig = @{
                name = $Alert.name
                description = $Alert.description
                query = $Alert.query
                condition = $Alert.condition
                duration = $Alert.duration
                severity = $Alert.severity
                enabled = $true
            }
            
            $AlertResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Method POST -Headers $Headers -Body ($AlertConfig | ConvertTo-Json -Depth 3) -TimeoutSec 10
            
            Write-Host "    ✅ Alert created: $($Alert.name)" -ForegroundColor Green
            $CreatedAlerts += $Alert.name
            
        } catch {
            Write-Host "    ❌ Failed to create alert: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "    🔍 Dry run: Alert would be created" -ForegroundColor Gray
        $CreatedAlerts += $Alert.name
    }
}

# Generate summary
Write-Host "`n📊 Setup Summary" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green
Write-Host "✅ Created alerts: $($CreatedAlerts.Count)" -ForegroundColor Green
Write-Host "📊 Total alerts: $($SimpleAlerts.Count)" -ForegroundColor Cyan

# Save configuration
$ConfigPath = "artifacts/simple-signoz-setup.json"
$SetupConfig = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    signoz_url = $SigNozUrl
    alerts = $SimpleAlerts
    created_alerts = $CreatedAlerts
}

$SetupConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigPath
Write-Host "`n📝 Configuration saved to: $ConfigPath" -ForegroundColor Green

# Next steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Access SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Check alerts: $SigNozUrl/alerts" -ForegroundColor White
Write-Host "3. View logs: $SigNozUrl/logs" -ForegroundColor White
Write-Host "4. View traces: $SigNozUrl/traces" -ForegroundColor White

Write-Host "`n✅ Simple setup completed!" -ForegroundColor Green
