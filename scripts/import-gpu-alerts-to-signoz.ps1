# Import GPU Alerts to SigNoz
# ECRR-compliant GPU alert import with progress animation

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$AlertConfigPath = "artifacts/gpu-alerts-config.json"
)

Write-Host "=== GPU Alert Import to SigNoz ===" -ForegroundColor Cyan
Write-Host "ECRR: Importing GPU monitoring alerts..." -ForegroundColor Yellow

# Animation characters for progress indication
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0

function Show-Progress {
    param([string]$Message, [int]$Current, [int]$Total)
    $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
    $progress = [math]::Round(($Current / $Total) * 100)
    Write-Host "`r$($spinner[$spinnerIndex]) $Message... $Current/$Total ($progress%)" -NoNewline -ForegroundColor Cyan
}

# Check SigNoz connectivity
Write-Host "`n🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -TimeoutSec 10 -UseBasicParsing
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is accessible" -ForegroundColor Green
    } else {
        throw "SigNoz health check failed: $($healthResponse.StatusCode)"
    }
} catch {
    Write-Host "❌ Cannot connect to SigNoz: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Make sure SigNoz is running on $SigNozUrl" -ForegroundColor Yellow
    exit 1
}

# Load GPU alert configuration
Write-Host "`n📋 Loading GPU alert configuration..." -ForegroundColor Yellow
if (-not (Test-Path $AlertConfigPath)) {
    Write-Host "❌ Alert configuration not found: $AlertConfigPath" -ForegroundColor Red
    exit 1
}

$alertConfig = Get-Content $AlertConfigPath | ConvertFrom-Json
$alerts = $alertConfig.alerts
Write-Host "✅ Loaded $($alerts.Count) GPU alerts" -ForegroundColor Green

# Convert to SigNoz alert format
Write-Host "`n🔄 Converting alerts to SigNoz format..." -ForegroundColor Yellow
$signozAlerts = @()

foreach ($alert in $alerts) {
    Show-Progress "Converting alert" ($signozAlerts.Count + 1) $alerts.Count
    
    $signozAlert = @{
        name = $alert.name
        description = $alert.description
        query = $alert.query
        threshold = $alert.threshold
        severity = $alert.severity.ToUpper()
        duration = $alert.duration
        enabled = $true
        tags = @("gpu", "monitoring", "automated")
        createdAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    
    $signozAlerts += $signozAlert
}

Write-Host "`r✅ Converted $($signozAlerts.Count) alerts to SigNoz format" -ForegroundColor Green

# Create SigNoz alert import payload
$importPayload = @{
    alerts = $signozAlerts
    metadata = @{
        source = "gpu-monitoring-system"
        version = "1.0"
        imported_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        imported_by = "OTel-GPU-Monitoring"
    }
}

# Save SigNoz-compatible configuration
$signozConfigPath = "artifacts/signoz-gpu-alerts.json"
$importPayload | ConvertTo-Json -Depth 4 | Out-File -FilePath $signozConfigPath -Encoding UTF8
Write-Host "📁 SigNoz alert config saved: $signozConfigPath" -ForegroundColor Yellow

# Generate import instructions
$importInstructions = @"
=== GPU Alert Import Instructions ===

1. Open SigNoz UI: $SigNozUrl
2. Navigate to: Alerts → Create Alert
  3. For each alert in ${signozConfigPath}:

   Alert: $($alert.name)
   Query: $($alert.query)
   Threshold: $($alert.threshold)
   Duration: $($alert.duration)
   Severity: $($alert.severity)

4. Or use SigNoz API:
   POST $SigNozUrl/api/v1/alerts
   Content-Type: application/json
   Body: $(Get-Content $signozConfigPath -Raw)

=== Manual Import Commands ===

# Import via PowerShell
`$alerts = Get-Content '$signozConfigPath' | ConvertFrom-Json
foreach (`$alert in `$alerts.alerts) {
    `$body = `$alert | ConvertTo-Json -Depth 3
    Invoke-WebRequest -Uri '$SigNozUrl/api/v1/alerts' -Method Post -Body `$body -ContentType 'application/json'
}

=== Verification ===

After import, verify alerts in SigNoz:
- Go to Alerts → List
- Filter by tag: gpu
- Check alert status: Active/Inactive
"@

$instructionsPath = "artifacts/gpu-alert-import-instructions.txt"
$importInstructions | Out-File -FilePath $instructionsPath -Encoding UTF8

Write-Host "`n=== ECRR Report: GPU Alert Import Complete ===" -ForegroundColor Cyan
Write-Host "✅ GPU alerts converted to SigNoz format" -ForegroundColor Green
Write-Host "📁 SigNoz config: $signozConfigPath" -ForegroundColor Yellow
Write-Host "📋 Import instructions: $instructionsPath" -ForegroundColor Yellow
Write-Host "🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor White

# Create ECRR report
$ecrrReport = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    action = "import-gpu-alerts"
    status = "completed"
    artifacts = @{
        signoz_config = $signozConfigPath
        import_instructions = $instructionsPath
        original_config = $AlertConfigPath
    }
    summary = @{
        alerts_converted = $signozAlerts.Count
        signoz_url = $SigNozUrl
        import_method = "manual_ui_and_api"
    }
}

$reportPath = "artifacts/gpu-alert-import-report.json"
$ecrrReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n✅ GPU Alert Import Setup Complete!" -ForegroundColor Green
Write-Host "📊 Next: Import alerts into SigNoz UI or use API" -ForegroundColor Yellow
Write-Host "🔗 SigNoz URL: $SigNozUrl" -ForegroundColor Cyan
