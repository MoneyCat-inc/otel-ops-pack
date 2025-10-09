# GPU Automation Quickstart
# One-stop script to integrate GPU sidecars into your automated workflow

param(
    [switch]$FullIntegration,
    [switch]$QuickSetup,
    [switch]$ValidateOnly,
    [switch]$DryRun,
    [string]$Environment = "local"
)

Write-Host "🚀 GPU Automation Quickstart" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Full Integration: $FullIntegration" -ForegroundColor Yellow
Write-Host "Quick Setup: $QuickSetup" -ForegroundColor Yellow
Write-Host "Validate Only: $ValidateOnly" -ForegroundColor Yellow
Write-Host "Dry Run: $DryRun" -ForegroundColor Yellow
Write-Host ""

if ($ValidateOnly) {
    Write-Host "🔍 Validating GPU Integration..." -ForegroundColor Yellow
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-integration-automation.ps1" -Action validate -DryRun:$DryRun
    exit $LASTEXITCODE
}

if ($QuickSetup) {
    Write-Host "⚡ Quick GPU Setup..." -ForegroundColor Yellow
    
    # Start GPU sidecars
    Write-Host "1. Starting GPU sidecars..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-workflow-orchestrator.ps1" -Action start -IncludeGPU -DryRun:$DryRun
    
    # Start basic monitoring
    Write-Host "2. Starting basic monitoring..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-workflow-orchestrator.ps1" -Action monitor -DurationMinutes 5 -DryRun:$DryRun
    
    # Run integration test
    Write-Host "3. Running integration test..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-workflow-orchestrator.ps1" -Action test -DryRun:$DryRun
    
    Write-Host "`n✅ Quick GPU Setup Complete!" -ForegroundColor Green
    Write-Host "Check GPU status: .\scripts\gpu-workflow-orchestrator.ps1 -Action status" -ForegroundColor Yellow
    Write-Host "View SigNoz: http://localhost:8080" -ForegroundColor Yellow
    exit 0
}

if ($FullIntegration) {
    Write-Host "🔗 Full GPU Integration..." -ForegroundColor Yellow
    
    # Step 1: Integrate with existing workflow
    Write-Host "1. Integrating with existing workflow..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-integration-automation.ps1" -Action integrate -IncludeExistingWorkflow -DryRun:$DryRun
    
    # Step 2: Deploy GPU infrastructure
    Write-Host "2. Deploying GPU infrastructure..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-integration-automation.ps1" -Action deploy -IncludeHealthChecks -IncludeMetrics -IncludeAlerts -IncludeDashboard -DryRun:$DryRun
    
    # Step 3: Set up automated monitoring
    Write-Host "3. Setting up automated monitoring..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-automated-monitoring.ps1" -EnableScheduledTasks -EnableHealthChecks -EnableMetricsCollection -EnableAlerting -EnableDashboard -DryRun:$DryRun
    
    # Step 4: Validate integration
    Write-Host "4. Validating integration..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-integration-automation.ps1" -Action validate -DryRun:$DryRun
    
    # Step 5: Start monitoring
    Write-Host "5. Starting monitoring..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-integration-automation.ps1" -Action monitor -DryRun:$DryRun
    
    # Step 6: Generate report
    Write-Host "6. Generating integration report..." -ForegroundColor Cyan
    & pwsh -ExecutionPolicy Bypass -File "scripts/gpu-integration-automation.ps1" -Action report -DryRun:$DryRun
    
    Write-Host "`n✅ Full GPU Integration Complete!" -ForegroundColor Green
    Write-Host "Integration Report: artifacts/gpu-integration-report-*.html" -ForegroundColor Yellow
    Write-Host "View SigNoz: http://localhost:8080" -ForegroundColor Yellow
    Write-Host "Monitor GPU: .\scripts\gpu-workflow-orchestrator.ps1 -Action status" -ForegroundColor Yellow
    exit 0
}

# Default: Show usage
Write-Host "📋 GPU Automation Quickstart Usage:" -ForegroundColor Cyan
Write-Host ""
Write-Host 'Quick Setup (5 minutes):' -ForegroundColor Yellow
Write-Host "  .\scripts\gpu-automation-quickstart.ps1 -QuickSetup" -ForegroundColor White
Write-Host ""
Write-Host 'Full Integration (15 minutes):' -ForegroundColor Yellow
Write-Host "  .\scripts\gpu-automation-quickstart.ps1 -FullIntegration" -ForegroundColor White
Write-Host ""
Write-Host "Validate Only:" -ForegroundColor Yellow
Write-Host "  .\scripts\gpu-automation-quickstart.ps1 -ValidateOnly" -ForegroundColor White
Write-Host ""
Write-Host 'Dry Run (test without changes):' -ForegroundColor Yellow
Write-Host "  .\scripts\gpu-automation-quickstart.ps1 -FullIntegration -DryRun" -ForegroundColor White
Write-Host ""
Write-Host "Available Scripts:" -ForegroundColor Cyan
Write-Host "  📊 GPU Workflow Orchestrator: scripts/gpu-workflow-orchestrator.ps1" -ForegroundColor White
Write-Host "  🤖 GPU Automated Monitoring: scripts/gpu-automated-monitoring.ps1" -ForegroundColor White
Write-Host "  🔗 GPU Integration Automation: scripts/gpu-integration-automation.ps1" -ForegroundColor White
Write-Host "  🎮 GPU Sidecar Management: scripts/manage-gpu-sidecars.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "1. Run Quick Setup to get started immediately" -ForegroundColor Yellow
Write-Host "2. Run Full Integration for production deployment" -ForegroundColor Yellow
Write-Host "3. Check integration status and reports" -ForegroundColor Yellow
