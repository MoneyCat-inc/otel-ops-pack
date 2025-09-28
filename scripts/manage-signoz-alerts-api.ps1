# Manage SigNoz Alerts via API Script
# List, update, delete alerts using SigNoz REST API

param(
    [string]$ApiToken = "eE5syxJUco90j8vq34YPlbHaUg3NpS0UUEYYCzgE7mc=",
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$ListAlerts,
    [switch]$DeleteAlert,
    [switch]$UpdateAlert,
    [string]$AlertId,
    [string]$AlertName,
    [switch]$DryRun
)

Write-Host "=== SigNoz Alert Management via API ===" -ForegroundColor Green

# API Configuration
$Headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

# Test SigNoz connectivity
Write-Host "`n=== Testing SigNoz API Connectivity ===" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Headers $Headers -TimeoutSec 10
    Write-Host "✅ SigNoz API accessible" -ForegroundColor Green
    Write-Host "   Status: $($healthResponse.status)" -ForegroundColor Gray
} catch {
    Write-Host "❌ SigNoz API not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($ListAlerts) {
    Write-Host "`n=== Listing All Alerts ===" -ForegroundColor Yellow
    
    try {
        $alertsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Headers $Headers -TimeoutSec 30
        Write-Host "Found $($alertsResponse.Count) alerts:" -ForegroundColor Green
        
        foreach ($alert in $alertsResponse) {
            Write-Host "`n📋 Alert: $($alert.name)" -ForegroundColor Cyan
            Write-Host "   ID: $($alert.id)" -ForegroundColor Gray
            Write-Host "   Severity: $($alert.severity)" -ForegroundColor Gray
            Write-Host "   Status: $($alert.state)" -ForegroundColor Gray
            Write-Host "   Created: $($alert.created_at)" -ForegroundColor Gray
            
            if ($alert.query -and $alert.query.logsQuery) {
                Write-Host "   Query: $($alert.query.logsQuery.query)" -ForegroundColor Gray
            }
            
            if ($alert.labels) {
                Write-Host "   Labels: $($alert.labels | ConvertTo-Json -Compress)" -ForegroundColor Gray
            }
        }
        
        # Save alert list to file
        $alertListFile = "artifacts/signoz-alerts-list-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $alertsResponse | ConvertTo-Json -Depth 6 | Set-Content -Path $alertListFile -Encoding UTF8
        Write-Host "`nAlert list saved to: $alertListFile" -ForegroundColor Blue
        
    } catch {
        Write-Host "❌ Failed to list alerts: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($DeleteAlert) {
    if (-not $AlertId -and -not $AlertName) {
        Write-Host "❌ Error: Please specify either -AlertId or -AlertName for deletion" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n=== Deleting Alert ===" -ForegroundColor Yellow
    
    try {
        # If AlertName is provided, find the alert ID first
        if ($AlertName -and -not $AlertId) {
            $alertsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Headers $Headers -TimeoutSec 30
            $targetAlert = $alertsResponse | Where-Object { $_.name -eq $AlertName }
            
            if ($targetAlert) {
                $AlertId = $targetAlert.id
                Write-Host "Found alert '$AlertName' with ID: $AlertId" -ForegroundColor Green
            } else {
                Write-Host "❌ Alert '$AlertName' not found" -ForegroundColor Red
                exit 1
            }
        }
        
        if ($DryRun) {
            Write-Host "🔍 DRY RUN: Would delete alert with ID: $AlertId" -ForegroundColor Yellow
        } else {
            $deleteResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts/$AlertId" -Method Delete -Headers $Headers -TimeoutSec 30
            Write-Host "✅ Alert deleted successfully" -ForegroundColor Green
            Write-Host "   Alert ID: $AlertId" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "❌ Failed to delete alert: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($UpdateAlert) {
    if (-not $AlertId -and -not $AlertName) {
        Write-Host "❌ Error: Please specify either -AlertId or -AlertName for update" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n=== Updating Alert ===" -ForegroundColor Yellow
    
    try {
        # If AlertName is provided, find the alert ID first
        if ($AlertName -and -not $AlertId) {
            $alertsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Headers $Headers -TimeoutSec 30
            $targetAlert = $alertsResponse | Where-Object { $_.name -eq $AlertName }
            
            if ($targetAlert) {
                $AlertId = $targetAlert.id
                Write-Host "Found alert '$AlertName' with ID: $AlertId" -ForegroundColor Green
            } else {
                Write-Host "❌ Alert '$AlertName' not found" -ForegroundColor Red
                exit 1
            }
        }
        
        # Get current alert configuration
        $currentAlert = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts/$AlertId" -Headers $Headers -TimeoutSec 30
        Write-Host "Current alert configuration:" -ForegroundColor Cyan
        $currentAlert | ConvertTo-Json -Depth 4 | Write-Host -ForegroundColor White
        
        # Example update: modify evaluation window
        $updatePayload = $currentAlert
        $updatePayload.condition.evaluationWindow = "10m"  # Change from 5m to 10m
        
        if ($DryRun) {
            Write-Host "🔍 DRY RUN: Would update alert with payload:" -ForegroundColor Yellow
            $updatePayload | ConvertTo-Json -Depth 4 | Write-Host -ForegroundColor White
        } else {
            $updateResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts/$AlertId" -Method Put -Body ($updatePayload | ConvertTo-Json -Depth 6) -Headers $Headers -TimeoutSec 30
            Write-Host "✅ Alert updated successfully" -ForegroundColor Green
            Write-Host "   Alert ID: $AlertId" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "❌ Failed to update alert: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Alert Management Complete ===" -ForegroundColor Green
