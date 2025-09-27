# Enhanced Wiring Verification with Waiting Animations
# Ultra-lightweight progress feedback

param(
    [switch]$Verbose = $false,
    [switch]$Quick = $false
)

# Import animation functions
. "$PSScriptRoot/waiting-animations.ps1"

Write-Host "🔌 Enhanced Wiring Verification with Animations" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host ""

# Step 1: Toolchain Sanity Checks
Write-Host "🔧 Step 1/4: Toolchain Sanity Checks" -ForegroundColor Cyan
Start-SmartAnimation -Message "Running npm lint and typecheck" -OperationType "npm_lint" -Style "dots"

# Run actual checks
$lintResult = npm run lint --silent 2>&1
$typecheckResult = npm run typecheck --silent 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`r✅ Toolchain checks passed!                    " -ForegroundColor Green
} else {
    Write-Host "`r⚠️  Toolchain checks failed (continuing...)     " -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Prerequisites Check
Write-Host "🔍 Step 2/4: Prerequisites Check" -ForegroundColor Cyan
Start-SmartAnimation -Message "Checking services and ports" -OperationType "service_check" -Style "spinner"

# Check services
$otelService = Get-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
$signozHealth = try { Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health' -TimeoutSec 5 } catch { $null }

Write-Host "`r✅ Prerequisites check completed!                 " -ForegroundColor Green
Write-Host "   Service otelcol-contrib: $(if ($otelService -and $otelService.Status -eq 'Running') { '✅ Running' } else { '❌ Not running' })" -ForegroundColor White
Write-Host "   SigNoz UI (8080): $(if ($signozHealth) { '✅ Healthy' } else { '❌ Unreachable' })" -ForegroundColor White
Write-Host "   OTLP Port 5318: $(if (Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet) { '✅ Reachable' } else { '❌ Unreachable' })" -ForegroundColor White
Write-Host ""

# Step 3: Analytics API Test
Write-Host "📊 Step 3/4: Analytics API Test" -ForegroundColor Cyan
Start-SmartAnimation -Message "Testing analytics API connection" -OperationType "api_test" -Style "pulse"

# Test API
$apiTest = try {
    $body = @{
        event = "test_event"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        dataset = "resonai_analytics"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri 'http://localhost:3003/api/events' -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 5
    $true
} catch {
    $false
}

if ($apiTest) {
    Write-Host "`r✅ Analytics API test successful!               " -ForegroundColor Green
} else {
    Write-Host "`r❌ Analytics API test failed                   " -ForegroundColor Red
    Write-Host "   💡 Start dev server: pnpm dev" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: End-to-End Verification
Write-Host "🔄 Step 4/4: End-to-End Verification" -ForegroundColor Cyan
Start-SmartAnimation -Message "Running end-to-end verification" -OperationType "e2e_verification" -Style "wave"

# Send test data
$testData = @{
    event = "wiring_verification_test"
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    dataset = "resonai_analytics"
    test_id = [System.Guid]::NewGuid().ToString()
} | ConvertTo-Json

$e2eTest = try {
    Invoke-RestMethod -Uri 'http://localhost:3003/api/events' -Method POST -Body $testData -ContentType 'application/json' -TimeoutSec 5
    $true
} catch {
    $false
}

Write-Host "`r✅ End-to-end verification completed!             " -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "📋 Verification Summary" -ForegroundColor Cyan
Write-Host "=" * 30 -ForegroundColor Gray

$checks = @(
    @{ Name = "Toolchain"; Status = $LASTEXITCODE -eq 0; Required = $false }
    @{ Name = "OTel Service"; Status = $otelService -and $otelService.Status -eq 'Running'; Required = $true }
    @{ Name = "SigNoz Health"; Status = $signozHealth -ne $null; Required = $true }
    @{ Name = "OTLP Port"; Status = Test-NetConnection -ComputerName localhost -Port 5318 -InformationLevel Quiet; Required = $true }
    @{ Name = "Analytics API"; Status = $apiTest; Required = $true }
    @{ Name = "End-to-End"; Status = $e2eTest; Required = $true }
)

$passed = 0
$total = $checks.Count

foreach ($check in $checks) {
    $status = if ($check.Status) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($check.Status) { "Green" } else { "Red" }
    $required = if ($check.Required) { " (Required)" } else { " (Optional)" }
    
    Write-Host "   $($check.Name): $status$required" -ForegroundColor $color
    if ($check.Status) { $passed++ }
}

Write-Host ""
Write-Host "📊 Results: $passed/$total checks passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

if ($passed -eq $total) {
    Write-Host "🎉 All systems operational! Data should be flowing to SigNoz." -ForegroundColor Green
} else {
    Write-Host "⚠️  Some issues detected. Check the details above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔧 Quick Fixes:" -ForegroundColor Cyan
Write-Host "   • Start dev server: pnpm dev" -ForegroundColor White
Write-Host "   • Check SigNoz: http://localhost:8080" -ForegroundColor White
Write-Host "   • Restart OTel: sc restart otelcol-contrib" -ForegroundColor White
Write-Host ""

# Demo function
function Show-AnimationDemo {
    Write-Host "🎬 Animation Demo" -ForegroundColor Yellow
    Write-Host "=" * 20 -ForegroundColor Gray
    Write-Host ""
    
    # Import and run demo
    . "$PSScriptRoot/waiting-animations.ps1"
    Demo-Animations
}
