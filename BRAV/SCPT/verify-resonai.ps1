# Verify Resonai Startup Script
# Checks if Resonai is running on port 3003 and provides startup guidance

param(
    [int]$Port = 3000,
    [string]$BaseUrl = "http://localhost:$Port",
    [switch]$StartIfNotRunning = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Resonai Verification - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check if Resonai is running
Write-Host "`nExamine: Checking Resonai status on port $Port..." -ForegroundColor Green

$ResonaiStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    port = $Port
    base_url = $BaseUrl
    is_running = $false
    health_check = $false
    api_accessible = $false
    recommendations = @()
}

# Check if port is listening
Write-Host "Checking if port $Port is listening..." -ForegroundColor Yellow
$PortCheck = netstat -an | Select-String ":$Port "
if ($PortCheck) {
    Write-Host "  OK Port $Port is listening" -ForegroundColor Green
    $ResonaiStatus.is_running = $true
} else {
    Write-Host "  ERROR Port $Port is not listening" -ForegroundColor Red
    $ResonaiStatus.recommendations += "Start Resonai application on port $Port"
}

# Test health endpoint
Write-Host "`nTesting health endpoint..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$BaseUrl/health" -TimeoutSec 5
    Write-Host "  OK Health endpoint accessible" -ForegroundColor Green
    $ResonaiStatus.health_check = $true
} catch {
    Write-Host "  ERROR Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    $ResonaiStatus.recommendations += "Fix Resonai health endpoint"
}

# Test API endpoint
Write-Host "`nTesting API endpoint..." -ForegroundColor Yellow
try {
    $ApiResponse = Invoke-RestMethod -Uri "$BaseUrl/api/status" -TimeoutSec 5
    Write-Host "  OK API endpoint accessible" -ForegroundColor Green
    $ResonaiStatus.api_accessible = $true
} catch {
    Write-Host "  ERROR API endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    $ResonaiStatus.recommendations += "Fix Resonai API endpoint"
}

# Test webhook endpoint
Write-Host "`nTesting webhook endpoint..." -ForegroundColor Yellow
try {
    $WebhookTest = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        test = $true
        message = "Resonai webhook test"
    }
    
    $WebhookResponse = Invoke-RestMethod -Uri "$BaseUrl/api/webhooks/alerts" -Method POST -Body ($WebhookTest | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 5
    Write-Host "  OK Webhook endpoint accessible" -ForegroundColor Green
} catch {
    Write-Host "  ERROR Webhook endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    $ResonaiStatus.recommendations += "Fix Resonai webhook endpoint"
}

# Clean: Provide startup guidance if not running
if (-not $ResonaiStatus.is_running) {
    Write-Host "`nClean: Resonai startup guidance..." -ForegroundColor Green
    
    Write-Host "`nTo start Resonai:" -ForegroundColor Yellow
    Write-Host "1. Navigate to Resonai project directory" -ForegroundColor White
    Write-Host "2. Install dependencies: npm install" -ForegroundColor White
    Write-Host "3. Start development server: npm run dev" -ForegroundColor White
    Write-Host "4. Or start production server: npm start" -ForegroundColor White
    Write-Host "5. Verify startup on port $Port" -ForegroundColor White
    
    Write-Host "`nAlternative startup methods:" -ForegroundColor Yellow
    Write-Host "- Docker: docker-compose up" -ForegroundColor White
    Write-Host "- PM2: pm2 start ecosystem.config.js" -ForegroundColor White
    Write-Host "- Direct: node server.js" -ForegroundColor White
}

# Report: Generate status report
Write-Host "`nReport: Resonai status summary" -ForegroundColor Green

Write-Host "`nResonai Status:" -ForegroundColor Cyan
Write-Host "  Port ${Port}: $(if ($ResonaiStatus.is_running) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($ResonaiStatus.is_running) { 'Green' } else { 'Red' })
Write-Host "  Health Check: $(if ($ResonaiStatus.health_check) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($ResonaiStatus.health_check) { 'Green' } else { 'Red' })
Write-Host "  API Access: $(if ($ResonaiStatus.api_accessible) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($ResonaiStatus.api_accessible) { 'Green' } else { 'Red' })

if ($ResonaiStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $ResonaiStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save status report
$ResonaiStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/resonai-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/resonai-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($ResonaiStatus.is_running -and $ResonaiStatus.health_check -and $ResonaiStatus.api_accessible) {
    Write-Host "Next: Resonai is running correctly - proceed with webhook testing" -ForegroundColor Green
} else {
    Write-Host "Next: Start Resonai application and verify all endpoints" -ForegroundColor Yellow
    Write-Host "Then: Test webhook notifications and alert delivery" -ForegroundColor Yellow
}
