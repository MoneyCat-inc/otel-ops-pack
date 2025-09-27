# Demo of Duration Estimates and Smart Animations
# Shows how the system estimates operation durations

param(
    [switch]$All = $false,
    [string]$OperationType = "default"
)

# Import animation functions
. "$PSScriptRoot/waiting-animations.ps1"

Write-Host "⏱️  Duration Estimates Demo" -ForegroundColor Yellow
Write-Host "=" * 50 -ForegroundColor Gray
Write-Host ""

if ($All) {
    Write-Host "🎯 All Operation Types with Duration Estimates:" -ForegroundColor Cyan
    Write-Host ""
    
    $operationTypes = @(
        @{ Type = "npm_lint"; Description = "NPM Lint Check" },
        @{ Type = "npm_typecheck"; Description = "NPM TypeScript Check" },
        @{ Type = "service_check"; Description = "Service Status Check" },
        @{ Type = "port_check"; Description = "Port Connectivity Check" },
        @{ Type = "api_test"; Description = "API Endpoint Test" },
        @{ Type = "e2e_verification"; Description = "End-to-End Verification" },
        @{ Type = "file_scan"; Description = "File System Scan" },
        @{ Type = "git_operations"; Description = "Git Operations" },
        @{ Type = "docker_operations"; Description = "Docker Container Operations" },
        @{ Type = "signoz_health"; Description = "SigNoz Health Check" },
        @{ Type = "otel_restart"; Description = "OpenTelemetry Restart" },
        @{ Type = "data_processing"; Description = "Data Processing" },
        @{ Type = "network_test"; Description = "Network Connectivity Test" }
    )
    
    foreach ($op in $operationTypes) {
        $duration = Get-DurationEstimate -operationType $op.Type
        Write-Host "📊 $($op.Description): $duration seconds" -ForegroundColor White
        Write-Host "   Type: $($op.Type)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "🎬 Quick Demo of Smart Animations:" -ForegroundColor Cyan
    Write-Host ""
    
    # Demo a few different operation types
    Write-Host "1. Service Check (1 second):" -ForegroundColor White
    Start-SmartAnimation -Message "Checking services" -OperationType "service_check" -Style "spinner"
    Write-Host ""
    
    Write-Host "2. API Test (2 seconds):" -ForegroundColor White
    Start-SmartAnimation -Message "Testing API connection" -OperationType "api_test" -Style "pulse"
    Write-Host ""
    
    Write-Host "3. Data Processing (4 seconds):" -ForegroundColor White
    Start-SmartAnimation -Message "Processing data" -OperationType "data_processing" -Style "dots"
    Write-Host ""
    
} else {
    Write-Host "🎯 Single Operation Demo: $OperationType" -ForegroundColor Cyan
    Write-Host ""
    
    $duration = Get-DurationEstimate -operationType $OperationType
    Write-Host "⏱️  Estimated Duration: $duration seconds" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "🚀 Running Smart Animation:" -ForegroundColor White
    Start-SmartAnimation -Message "Processing $OperationType" -OperationType $OperationType -Style "dots"
    Write-Host ""
}

Write-Host "💡 Usage Examples:" -ForegroundColor Cyan
Write-Host "   pwsh -File scripts/demo-duration-estimates.ps1 -All" -ForegroundColor Gray
Write-Host "   pwsh -File scripts/demo-duration-estimates.ps1 -OperationType npm_lint" -ForegroundColor Gray
Write-Host "   pwsh -File scripts/verify-wiring-with-animations.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 Demo complete!" -ForegroundColor Green
