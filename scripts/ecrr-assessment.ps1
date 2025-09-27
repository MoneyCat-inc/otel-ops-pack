# ECRR Assessment for GPU Monitoring System
# Examine → Clean → Report → Role
# Comprehensive ECRR evaluation of GPU monitoring deployment

param(
    [Parameter(Position=0)]
    [string]$Scope = "full",
    [switch]$Force,
    [switch]$Detailed
)

Write-Host "=== ECRR Assessment: GPU Monitoring System ===" -ForegroundColor Cyan
Write-Host "Scope: $Scope | ECRR Framework: Examine → Clean → Report → Role" -ForegroundColor Yellow

# ECRR: Examine - Comprehensive system examination
Write-Host "`n🔍 ECRR PHASE 1: EXAMINE" -ForegroundColor Cyan
Write-Host "Capturing system state and evidence..." -ForegroundColor Yellow

$examinationData = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    scope = $Scope
    system_state = @{}
    artifacts = @{}
    dependencies = @{}
    performance = @{}
}

# Examine GPU sidecars
Write-Host "  📊 Examining GPU sidecars..." -ForegroundColor Yellow
try {
    $gpuCheck = python scripts\check-gpu-sidecars.py 2>&1
    $examinationData.system_state.gpu_sidecars = @{
        status = if ($LASTEXITCODE -eq 0) { "healthy" } else { "unhealthy" }
        output = $gpuCheck
        exit_code = $LASTEXITCODE
    }
} catch {
    $examinationData.system_state.gpu_sidecars = @{
        status = "error"
        error = $_.Exception.Message
    }
}

# Examine monitoring system
Write-Host "  📊 Examining monitoring system..." -ForegroundColor Yellow
$monitoringJobs = Get-Job | Where-Object {$_.Command -like "*gpu-automated-monitoring*"}
$examinationData.system_state.monitoring = @{
    jobs_running = $monitoringJobs.Count
    job_details = $monitoringJobs | Select-Object Id, State, Command
}

# Examine artifacts
Write-Host "  📊 Examining artifacts..." -ForegroundColor Yellow
$artifactFiles = @(
    "artifacts\gpu-monitoring-status.json",
    "artifacts\gpu-automated-monitoring.log",
    "artifacts\gpu-alerts-config.json",
    "artifacts\gpu-rollout-report.json"
)

foreach ($file in $artifactFiles) {
    if (Test-Path $file) {
        $examinationData.artifacts[$file] = @{
            exists = $true
            size_bytes = (Get-Item $file).Length
            last_modified = (Get-Item $file).LastWriteTime
        }
        
        # Read content for key files
        if ($file -like "*status.json") {
            try {
                $content = Get-Content $file | ConvertFrom-Json
                $examinationData.artifacts[$file].content = $content
            } catch {
                $examinationData.artifacts[$file].content = "parse_error"
            }
        }
    } else {
        $examinationData.artifacts[$file] = @{ exists = $false }
    }
}

# Examine dependencies
Write-Host "  📊 Examining dependencies..." -ForegroundColor Yellow
$dockerStatus = (Get-Service docker -ErrorAction SilentlyContinue)?.Status
$signozStatus = try { 
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 5
    "healthy (HTTP $($response.StatusCode))"
} catch { 
    "unavailable ($($_.Exception.Message))"
}
$otelStatus = (Get-Service otelcol-contrib -ErrorAction SilentlyContinue)?.Status
$taskStatus = (Get-ScheduledTask -TaskName "OTel-GPU-Monitoring" -ErrorAction SilentlyContinue)?.State

$examinationData.dependencies = @{
    docker = $dockerStatus
    signoz = $signozStatus
    otel_service = $otelStatus
    scheduled_task = $taskStatus
}

# Examine performance metrics
Write-Host "  📊 Examining performance..." -ForegroundColor Yellow
try {
    $metricsResult = python scripts\gpu-metrics-emitter.py 2>&1
    $examinationData.performance.metrics_emission = @{
        success = $LASTEXITCODE -eq 0
        output = $metricsResult
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
} catch {
    $examinationData.performance.metrics_emission = @{
        success = $false
        error = $_.Exception.Message
    }
}

# ECRR: Clean - Identify and address issues
Write-Host "`n🧹 ECRR PHASE 2: CLEAN" -ForegroundColor Cyan
Write-Host "Identifying and addressing system drift..." -ForegroundColor Yellow

$cleanupActions = @()
$cleanupResults = @{}

# Clean up stale monitoring jobs
Write-Host "  🧹 Cleaning stale monitoring jobs..." -ForegroundColor Yellow
$staleJobs = Get-Job | Where-Object {$_.State -eq "Failed" -or $_.State -eq "Completed"}
if ($staleJobs) {
    $staleJobs | Remove-Job
    $cleanupActions += "Removed $($staleJobs.Count) stale monitoring jobs"
    $cleanupResults.stale_jobs = $staleJobs.Count
} else {
    $cleanupResults.stale_jobs = 0
}

# Clean up old log files (keep last 7 days)
Write-Host "  🧹 Cleaning old log files..." -ForegroundColor Yellow
$cutoffDate = (Get-Date).AddDays(-7)
$oldLogs = Get-ChildItem "artifacts\*.log" | Where-Object {$_.LastWriteTime -lt $cutoffDate}
if ($oldLogs) {
    $oldLogs | Remove-Item -Force
    $cleanupActions += "Removed $($oldLogs.Count) old log files"
    $cleanupResults.old_logs = $oldLogs.Count
} else {
    $cleanupResults.old_logs = 0
}

# Ensure monitoring is running
Write-Host "  🧹 Ensuring monitoring is active..." -ForegroundColor Yellow
$activeJobs = Get-Job | Where-Object {$_.Command -like "*gpu-automated-monitoring*" -and $_.State -eq "Running"}
if ($activeJobs.Count -eq 0) {
    Write-Host "    Starting monitoring system..." -ForegroundColor Yellow
    .\scripts\manage-gpu-monitoring.ps1 start
    Start-Sleep 3
    $cleanupActions += "Restarted monitoring system"
    $cleanupResults.monitoring_restart = $true
} else {
    $cleanupResults.monitoring_restart = $false
}

# ECRR: Report - Generate comprehensive report
Write-Host "`n📝 ECRR PHASE 3: REPORT" -ForegroundColor Cyan
Write-Host "Generating comprehensive ECRR report..." -ForegroundColor Yellow

$ecrrReport = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    scope = $Scope
    ecrr_phases = @{
        examine = $examinationData
        clean = @{
            actions = $cleanupActions
            results = $cleanupResults
        }
        report = @{
            generated = $true
            artifacts_created = @()
        }
        role = @{
            actor = "Cursor Agent - Observability Copilot"
            responsibility = "GPU monitoring system stewardship"
        }
    }
    system_health = @{
        gpu_sidecars_healthy = $examinationData.system_state.gpu_sidecars.status -eq "healthy"
        monitoring_active = $examinationData.system_state.monitoring.jobs_running -gt 0
        dependencies_healthy = $examinationData.dependencies.signoz -like "*healthy*"
        performance_ok = $examinationData.performance.metrics_emission.success
    }
    compliance_score = 0
}

# Calculate compliance score
$totalChecks = 4
$passedChecks = 0
if ($ecrrReport.system_health.gpu_sidecars_healthy) { $passedChecks++ }
if ($ecrrReport.system_health.monitoring_active) { $passedChecks++ }
if ($ecrrReport.system_health.dependencies_healthy) { $passedChecks++ }
if ($ecrrReport.system_health.performance_ok) { $passedChecks++ }

$ecrrReport.compliance_score = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

# Save ECRR report
$reportFile = "artifacts\ecrr-assessment-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$ecrrReport | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8
$ecrrReport.ecrr_phases.report.artifacts_created += $reportFile

Write-Host "  ✅ ECRR report saved: $reportFile" -ForegroundColor Green

# Generate human-readable summary
$summaryFile = "artifacts\ecrr-summary-$(Get-Date -Format 'yyyyMMdd-HHmm').txt"
$summary = @"
=== ECRR Assessment Summary ===
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Scope: $Scope
Compliance Score: $($ecrrReport.compliance_score)%

EXAMINE Results:
- GPU Sidecars: $($examinationData.system_state.gpu_sidecars.status)
- Monitoring Jobs: $($examinationData.system_state.monitoring.jobs_running) active
- Dependencies: SigNoz $($examinationData.dependencies.signoz.Split(' ')[0])
- Performance: Metrics emission $($examinationData.performance.metrics_emission.success)

CLEAN Actions:
$($cleanupActions -join "`n")

REPORT Artifacts:
- ECRR Report: $reportFile
- Summary: $summaryFile

ROLE Declaration:
- Actor: $($ecrrReport.ecrr_phases.role.actor)
- Responsibility: $($ecrrReport.ecrr_phases.role.responsibility)

System Health: $($ecrrReport.compliance_score)%
"@

$summary | Out-File -FilePath $summaryFile -Encoding UTF8
$ecrrReport.ecrr_phases.report.artifacts_created += $summaryFile

Write-Host "  ✅ ECRR summary saved: $summaryFile" -ForegroundColor Green

# ECRR: Role - Declare actor and responsibilities
Write-Host "`n🎭 ECRR PHASE 4: ROLE" -ForegroundColor Cyan
Write-Host "Declaring actor responsibilities and next actions..." -ForegroundColor Yellow

Write-Host "`n=== ECRR Role Declaration ===" -ForegroundColor Cyan
Write-Host "Actor: Cursor Agent - Observability Copilot" -ForegroundColor White
Write-Host "Responsibility: GPU monitoring system stewardship" -ForegroundColor White
Write-Host "Scope: OTel observability pipeline with Cat Nap Control Room aesthetic" -ForegroundColor White

Write-Host "`n📊 ECRR Assessment Results:" -ForegroundColor Yellow
Write-Host "  Compliance Score: $($ecrrReport.compliance_score)%" -ForegroundColor $(if($ecrrReport.compliance_score -ge 75) {"Green"} else {"Yellow"})
Write-Host "  GPU Sidecars: $(if($ecrrReport.system_health.gpu_sidecars_healthy) {'✅ Healthy'} else {'❌ Issues'})" -ForegroundColor $(if($ecrrReport.system_health.gpu_sidecars_healthy) {"Green"} else {"Red"})
Write-Host "  Monitoring: $(if($ecrrReport.system_health.monitoring_active) {'✅ Active'} else {'❌ Inactive'})" -ForegroundColor $(if($ecrrReport.system_health.monitoring_active) {"Green"} else {"Red"})
Write-Host "  Dependencies: $(if($ecrrReport.system_health.dependencies_healthy) {'✅ Healthy'} else {'❌ Issues'})" -ForegroundColor $(if($ecrrReport.system_health.dependencies_healthy) {"Green"} else {"Red"})
Write-Host "  Performance: $(if($ecrrReport.system_health.performance_ok) {'✅ OK'} else {'❌ Issues'})" -ForegroundColor $(if($ecrrReport.system_health.performance_ok) {"Green"} else {"Red"})

if ($cleanupActions.Count -gt 0) {
    Write-Host "`n🧹 Cleanup Actions Performed:" -ForegroundColor Yellow
    foreach ($action in $cleanupActions) {
        Write-Host "  • $action" -ForegroundColor White
    }
}

Write-Host "`n📁 ECRR Artifacts Generated:" -ForegroundColor Yellow
foreach ($artifact in $ecrrReport.ecrr_phases.report.artifacts_created) {
    Write-Host "  • $artifact" -ForegroundColor White
}

Write-Host "`n🎯 Next Actions:" -ForegroundColor Yellow
if ($ecrrReport.compliance_score -ge 75) {
    Write-Host "  ✅ System is ECRR compliant and ready for production" -ForegroundColor Green
    Write-Host "  📊 Continue monitoring and periodic ECRR assessments" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ System requires attention before production readiness" -ForegroundColor Yellow
    Write-Host "  🔧 Address identified issues and re-run ECRR assessment" -ForegroundColor Yellow
}

Write-Host "`n🎭 ECRR Assessment Complete" -ForegroundColor Cyan
Write-Host "   GPU monitoring system evaluated with Cat Nap Control Room aesthetic" -ForegroundColor White
