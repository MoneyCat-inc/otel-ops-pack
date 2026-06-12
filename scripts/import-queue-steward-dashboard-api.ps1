# Import Queue Steward Dashboard via SigNoz API
# Handles nested dashboard JSON format

param(
    [string]$SignozUrl = "http://localhost:8080",
    [string]$DashboardFile = "queue-steward-dashboard.json",
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Queue Steward Dashboard API Import ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# Check if dashboard file exists
if (-not (Test-Path $DashboardFile)) {
    Write-Host "❌ Dashboard file not found: $DashboardFile" -ForegroundColor Red
    exit 1
}

# Get API key from environment
$ApiKey = $env:SIGNOZ_API_KEY
if (-not $ApiKey) {
    $ApiKey = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "User")
}
if (-not $ApiKey) {
    $ApiKey = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "Machine")
}

if (-not $ApiKey) {
    Write-Host "⚠️  SIGNOZ_API_KEY not found in environment" -ForegroundColor Yellow
    Write-Host "   Attempting import without authentication..." -ForegroundColor Gray
}

# Check SigNoz connectivity
Write-Host "`n🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SignozUrl/api/v1/health" -Method Get -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ SigNoz is accessible at: $SignozUrl" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to SigNoz at: $SignozUrl" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Load dashboard configuration
Write-Host "`n📊 Loading dashboard configuration..." -ForegroundColor Yellow
$DashboardJson = Get-Content $DashboardFile -Raw | ConvertFrom-Json

# Handle nested dashboard format
if ($DashboardJson.dashboard) {
    $DashboardConfig = $DashboardJson.dashboard
    Write-Host "✅ Detected nested dashboard format" -ForegroundColor Green
} else {
    $DashboardConfig = $DashboardJson
    Write-Host "✅ Detected flat dashboard format" -ForegroundColor Green
}

Write-Host "   Title: $($DashboardConfig.title)" -ForegroundColor White
Write-Host "   Panels: $($DashboardConfig.panels.Count)" -ForegroundColor White
Write-Host "   Description: $($DashboardConfig.description)" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "`n🔍 Dry Run - Dashboard Preview:" -ForegroundColor Cyan
    Write-Host "Name: $($DashboardConfig.title)" -ForegroundColor White
    Write-Host "Description: $($DashboardConfig.description)" -ForegroundColor White
    Write-Host "Panels:" -ForegroundColor White
    foreach ($Panel in $DashboardConfig.panels) {
        Write-Host "  - $($Panel.title): $($Panel.type)" -ForegroundColor Gray
    }
    Write-Host "`nTo import, run without -DryRun flag" -ForegroundColor Yellow
    exit 0
}

# Prepare API headers
$Headers = @{
    "Content-Type" = "application/json"
}

# Try multiple authentication methods
if ($ApiKey) {
    $Headers["SIGNOZ-API-KEY"] = $ApiKey
    Write-Host "`n🔑 Using API authentication (SIGNOZ-API-KEY header)" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  No API key provided - attempting unauthenticated import" -ForegroundColor Yellow
}

# Try different API endpoints (in order of preference)
$ImportEndpoints = @(
    "$SignozUrl/api/v1/dashboards",
    "$SignozUrl/api/dashboards/db",
    "$SignozUrl/api/v1/dashboards/import"
)

$ImportSuccess = $false
$ImportResponse = $null

foreach ($Endpoint in $ImportEndpoints) {
    Write-Host "`n📤 Attempting import via: $Endpoint" -ForegroundColor Yellow
    try {
        $Body = $DashboardConfig | ConvertTo-Json -Depth 20
        $ImportResponse = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $Headers -Body $Body -TimeoutSec 30 -ErrorAction Stop
        
        Write-Host "✅ Dashboard imported successfully!" -ForegroundColor Green
        if ($ImportResponse.id) {
            Write-Host "   Dashboard ID: $($ImportResponse.id)" -ForegroundColor White
            Write-Host "   Dashboard URL: $SignozUrl/dashboard/$($ImportResponse.id)" -ForegroundColor Cyan
        } elseif ($ImportResponse.uid) {
            Write-Host "   Dashboard UID: $($ImportResponse.uid)" -ForegroundColor White
            Write-Host "   Dashboard URL: $SignozUrl/dashboard/$($ImportResponse.uid)" -ForegroundColor Cyan
        } else {
            Write-Host "   Response: $($ImportResponse | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
        }
        $ImportSuccess = $true
        break
    } catch {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        $ErrorMessage = $_.Exception.Message
        
        Write-Host "   ❌ Failed (Status: $StatusCode): $ErrorMessage" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            try {
                $ErrorStream = $_.Exception.Response.GetResponseStream()
                $Reader = New-Object System.IO.StreamReader($ErrorStream)
                $ErrorBody = $Reader.ReadToEnd()
                Write-Host "   Error details: $ErrorBody" -ForegroundColor Gray
            } catch {
                # Ignore error reading response
            }
        }
        
        # If 401/403, try next endpoint with different auth
        if ($StatusCode -in @(401, 403) -and $ApiKey) {
            Write-Host "   Trying alternative authentication..." -ForegroundColor Yellow
            continue
        }
    }
}

if (-not $ImportSuccess) {
    Write-Host "`n❌ All import attempts failed" -ForegroundColor Red
    Write-Host "`nManual import steps:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz: $SignozUrl" -ForegroundColor White
    Write-Host "2. Go to Dashboards → + New Dashboard" -ForegroundColor White
    Write-Host "3. Click Import JSON" -ForegroundColor White
    Write-Host "4. Upload: $DashboardFile" -ForegroundColor White
    exit 1
}

# Verify dashboard
Write-Host "`n🔍 Verifying dashboard..." -ForegroundColor Yellow
try {
    $DashboardId = if ($ImportResponse.id) { $ImportResponse.id } elseif ($ImportResponse.uid) { $ImportResponse.uid } else { $null }
    
    if ($DashboardId) {
        $VerifyEndpoints = @(
            "$SignozUrl/api/v1/dashboards/$DashboardId",
            "$SignozUrl/api/dashboards/db/$DashboardId"
        )
        
        foreach ($VerifyEndpoint in $VerifyEndpoints) {
            try {
                $VerifyResponse = Invoke-RestMethod -Uri $VerifyEndpoint -Method Get -Headers $Headers -TimeoutSec 10 -ErrorAction Stop
                Write-Host "✅ Dashboard verification successful!" -ForegroundColor Green
                Write-Host "   Name: $($VerifyResponse.title -or $VerifyResponse.name)" -ForegroundColor White
                Write-Host "   Panels: $($VerifyResponse.panels.Count)" -ForegroundColor White
                break
            } catch {
                # Try next endpoint
                continue
            }
        }
    }
} catch {
    Write-Host "⚠️  Dashboard verification failed, but import may have succeeded" -ForegroundColor Yellow
}

Write-Host "`n🎉 Queue Steward Dashboard Import Complete!" -ForegroundColor Cyan
Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
if ($ImportResponse.id -or $ImportResponse.uid) {
    $DashboardId = if ($ImportResponse.id) { $ImportResponse.id } else { $ImportResponse.uid }
    Write-Host "1. Open dashboard: $SignozUrl/dashboard/$DashboardId" -ForegroundColor White
}
Write-Host "2. Verify all 6 panels are displaying correctly" -ForegroundColor White
Write-Host "3. Check panel queries return data (may need queue telemetry)" -ForegroundColor White
Write-Host "4. Capture screenshots for ECRR report" -ForegroundColor White

Write-Host "`n📊 Dashboard Panels:" -ForegroundColor Cyan
foreach ($Panel in $DashboardConfig.panels) {
    Write-Host "  - $($Panel.title) ($($Panel.type))" -ForegroundColor White
}
