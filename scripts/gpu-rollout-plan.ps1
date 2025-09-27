# GPU Monitoring Rollout Plan
# ECRR: Examine → Clean → Report → Role
# Comprehensive rollout strategy for OTel GPU monitoring system

param(
    [Parameter(Position=0)]
    [string]$Phase = "assess",
    [switch]$Force,
    [switch]$Detailed
)

# ECRR: Examine - Capture current system state
Write-Host "=== GPU Monitoring Rollout Plan ===" -ForegroundColor Cyan
Write-Host "ECRR: Examining system state for rollout..." -ForegroundColor Yellow

function Get-SystemState {
    Write-Host "`n📊 Examining System State..." -ForegroundColor Cyan
    
    $state = @{
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        gpu_sidecars = @{}
        monitoring_system = @{}
        dependencies = @{}
        readiness = @{}
    }
    
    # Check GPU sidecars
    Write-Host "  🔍 Checking GPU sidecars..." -ForegroundColor Yellow
    try {
        $gpuStatus = python scripts\check-gpu-sidecars.py 2>&1
        if ($LASTEXITCODE -eq 0) {
            $state.gpu_sidecars.status = "healthy"
            $state.gpu_sidecars.details = $gpuStatus
        } else {
            $state.gpu_sidecars.status = "unhealthy"
            $state.gpu_sidecars.details = $gpuStatus
        }
    } catch {
        $state.gpu_sidecars.status = "error"
        $state.gpu_sidecars.details = $_.Exception.Message
    }
    
    # Check monitoring system
    Write-Host "  🔍 Checking monitoring system..." -ForegroundColor Yellow
    try {
        $monitoringJob = Get-Job | Where-Object {$_.Command -like "*gpu-automated-monitoring*"}
        if ($monitoringJob) {
            $state.monitoring_system.status = "running"
            $state.monitoring_system.job_id = $monitoringJob.Id
            $state.monitoring_system.state = $monitoringJob.State
        } else {
            $state.monitoring_system.status = "stopped"
        }
        
        # Check status file
        if (Test-Path "artifacts\gpu-monitoring-status.json") {
            $statusData = Get-Content "artifacts\gpu-monitoring-status.json" | ConvertFrom-Json
            $state.monitoring_system.uptime_minutes = $statusData.uptime_minutes
            $state.monitoring_system.metrics_count = $statusData.metrics_count
            $state.monitoring_system.failures = $statusData.failures
        }
    } catch {
        $state.monitoring_system.status = "error"
        $state.monitoring_system.details = $_.Exception.Message
    }
    
    # Check dependencies
    Write-Host "  🔍 Checking dependencies..." -ForegroundColor Yellow
    $state.dependencies.docker = (Get-Service docker -ErrorAction SilentlyContinue)?.Status
    $state.dependencies.signoz = try { 
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
        if ($response.StatusCode -eq 200) { "healthy" } else { "unhealthy" }
    } catch { "unavailable" }
    $state.dependencies.otel_service = (Get-Service otelcol-contrib -ErrorAction SilentlyContinue)?.Status
    
    # Check scheduled task
    $scheduledTask = Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue
    $state.dependencies.scheduled_task = $scheduledTask?.State
    
    # Assess readiness
    Write-Host "  🔍 Assessing rollout readiness..." -ForegroundColor Yellow
    $readiness_score = 0
    $total_checks = 0
    
    if ($state.gpu_sidecars.status -eq "healthy") { $readiness_score += 25; $total_checks++ }
    if ($state.monitoring_system.status -eq "running") { $readiness_score += 25; $total_checks++ }
    if ($state.dependencies.signoz -eq "healthy") { $readiness_score += 25; $total_checks++ }
    if ($state.dependencies.otel_service -eq "Running") { $readiness_score += 25; $total_checks++ }
    
    $state.readiness.score = $readiness_score
    $state.readiness.total_checks = $total_checks
    $state.readiness.percentage = if ($total_checks -gt 0) { ($readiness_score / $total_checks) * 100 } else { 0 }
    
    return $state
}

function Start-RolloutPhase {
    param([string]$PhaseName, [string]$Description)
    
    Write-Host "`n🚀 Starting Rollout Phase: $PhaseName" -ForegroundColor Cyan
    Write-Host "   $Description" -ForegroundColor White
    
    switch ($PhaseName.ToLower()) {
        "pre-rollout" {
            Write-Host "  📋 Pre-rollout checklist..." -ForegroundColor Yellow
            
            # Validate all components
            $checks = @(
                @{ name = "GPU Sidecars"; cmd = "python scripts\check-gpu-sidecars.py"; weight = 25 },
                @{ name = "OTel Service"; cmd = "sc query otelcol-contrib"; weight = 25 },
                @{ name = "SigNoz Health"; cmd = "Invoke-WebRequest http://localhost:8080/api/v1/health"; weight = 25 },
                @{ name = "Monitoring Script"; cmd = "Test-Path scripts\gpu-automated-monitoring.py"; weight = 25 }
            )
            
            $totalScore = 0
            foreach ($check in $checks) {
                try {
                    if ($check.cmd -like "Test-Path*") {
                        $result = Invoke-Expression $check.cmd
                        if ($result) { 
                            Write-Host "    ✅ $($check.name)" -ForegroundColor Green
                            $totalScore += $check.weight
                        } else {
                            Write-Host "    ❌ $($check.name)" -ForegroundColor Red
                        }
                    } else {
                        $result = Invoke-Expression $check.cmd 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "    ✅ $($check.name)" -ForegroundColor Green
                            $totalScore += $check.weight
                        } else {
                            Write-Host "    ❌ $($check.name)" -ForegroundColor Red
                        }
                    }
                } catch {
                    Write-Host "    ❌ $($check.name) - Error: $_" -ForegroundColor Red
                }
            }
            
            Write-Host "  📊 Pre-rollout Score: $totalScore/100" -ForegroundColor $(if($totalScore -ge 75) {"Green"} else {"Yellow"})
            return $totalScore -ge 75
        }
        
        "deployment" {
            Write-Host "  🚀 Deploying GPU monitoring system..." -ForegroundColor Yellow
            
            # Start monitoring if not running
            $monitoringJob = Get-Job | Where-Object {$_.Command -like "*gpu-automated-monitoring*"}
            if (!$monitoringJob) {
                Write-Host "    Starting GPU monitoring..." -ForegroundColor Yellow
                .\scripts\manage-gpu-monitoring.ps1 start
                Start-Sleep 3
            }
            
            # Verify deployment
            Write-Host "    Verifying deployment..." -ForegroundColor Yellow
            Start-Sleep 5
            $status = .\scripts\manage-gpu-monitoring.ps1 status 2>&1
            Write-Host "    Status: $status" -ForegroundColor White
            
            return $LASTEXITCODE -eq 0
        }
        
        "validation" {
            Write-Host "  ✅ Validating rollout..." -ForegroundColor Yellow
            
            # Test metrics emission
            Write-Host "    Testing GPU metrics emission..." -ForegroundColor Yellow
            $metricsResult = python scripts\gpu-metrics-emitter.py 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✅ GPU metrics emission successful" -ForegroundColor Green
            } else {
                Write-Host "    ❌ GPU metrics emission failed" -ForegroundColor Red
                return $false
            }
            
            # Test monitoring status
            Write-Host "    Testing monitoring status..." -ForegroundColor Yellow
            $monitoringStatus = .\scripts\manage-gpu-monitoring.ps1 status 2>&1
            if ($monitoringStatus -like "*running*") {
                Write-Host "    ✅ Monitoring system active" -ForegroundColor Green
            } else {
                Write-Host "    ❌ Monitoring system not active" -ForegroundColor Red
                return $false
            }
            
            return $true
        }
        
        "post-rollout" {
            Write-Host "  📊 Post-rollout assessment..." -ForegroundColor Yellow
            
            # Generate comprehensive report
            $finalState = Get-SystemState
            $reportFile = "artifacts\gpu-rollout-final-report.json"
            $finalState | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding UTF8
            
            Write-Host "    Final report saved: $reportFile" -ForegroundColor Green
            
            # Summary
            Write-Host "  📋 Rollout Summary:" -ForegroundColor Cyan
            Write-Host "    GPU Sidecars: $($finalState.gpu_sidecars.status)" -ForegroundColor White
            Write-Host "    Monitoring: $($finalState.monitoring_system.status)" -ForegroundColor White
            Write-Host "    SigNoz: $($finalState.dependencies.signoz)" -ForegroundColor White
            Write-Host "    Readiness: $([math]::Round($finalState.readiness.percentage, 1))%" -ForegroundColor White
            
            return $finalState.readiness.percentage -ge 75
        }
    }
}

# Main rollout execution
$systemState = Get-SystemState

Write-Host "`n📊 Current System State:" -ForegroundColor Cyan
Write-Host "  GPU Sidecars: $($systemState.gpu_sidecars.status)" -ForegroundColor White
Write-Host "  Monitoring System: $($systemState.monitoring_system.status)" -ForegroundColor White
Write-Host "  SigNoz: $($systemState.dependencies.signoz)" -ForegroundColor White
Write-Host "  OTel Service: $($systemState.dependencies.otel_service)" -ForegroundColor White
Write-Host "  Readiness Score: $([math]::Round($systemState.readiness.percentage, 1))%" -ForegroundColor $(if($systemState.readiness.percentage -ge 75) {"Green"} else {"Yellow"})

# Execute rollout phases
$rolloutPhases = @(
    @{ name = "pre-rollout"; description = "Validate system readiness" },
    @{ name = "deployment"; description = "Deploy monitoring system" },
    @{ name = "validation"; description = "Validate deployment success" },
    @{ name = "post-rollout"; description = "Generate final assessment" }
)

$rolloutResults = @{}
foreach ($phase in $rolloutPhases) {
    $success = Start-RolloutPhase -PhaseName $phase.name -Description $phase.description
    $rolloutResults[$phase.name] = $success
    
    if (!$success -and $phase.name -ne "post-rollout") {
        Write-Host "`n❌ Rollout failed at phase: $($phase.name)" -ForegroundColor Red
        break
    }
}

# ECRR: Report - Generate rollout report
Write-Host "`n=== ECRR Rollout Report ===" -ForegroundColor Cyan

$rolloutReport = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    action = "gpu-monitoring-rollout"
    phases = $rolloutResults
    system_state = $systemState
    overall_success = ($rolloutResults.values | Where-Object {$_ -eq $true}).Count -eq $rolloutResults.Count
    readiness_percentage = $systemState.readiness.percentage
}

$reportFile = "artifacts\gpu-rollout-report.json"
$rolloutReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ Rollout Report Generated: $reportFile" -ForegroundColor Green

# ECRR: Role - Declare actor and next steps
Write-Host "`n🎭 ECRR Role: Cursor Agent - Observability Copilot" -ForegroundColor Cyan
Write-Host "   GPU monitoring rollout executed with Cat Nap Control Room aesthetic" -ForegroundColor White

if ($rolloutReport.overall_success) {
    Write-Host "`n🎉 ROLLOUT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "   GPU monitoring system is fully operational and ready for production" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ ROLLOUT NEEDS ATTENTION" -ForegroundColor Yellow
    Write-Host "   Some phases require remediation before production deployment" -ForegroundColor Yellow
}
