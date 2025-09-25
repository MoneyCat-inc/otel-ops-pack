# Health Gate Integration Script
# Combined environment + OTel health check for autopilot integration
# Part of the push-button automation system

param(
    [switch]$Verbose,
    [switch]$UpdateStatus = $true
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "🔍 Running Health Gate Integration..." -ForegroundColor Cyan

# Check if lock file exists
$lockFile = ".agent/LOCK"
if (Test-Path $lockFile) {
    Write-Host "⚠️  Lock file detected, skipping health gate" -ForegroundColor Yellow
    if ($UpdateStatus) {
        $statusUpdate = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            section = "health-gate"
            status = "paused:lock"
            details = "Lock file present, operations paused"
        } | ConvertTo-Json -Compress
        
        $statusFile = ".agent/status.json"
        $statusData = if (Test-Path $statusFile) { 
            Get-Content $statusFile -Raw | ConvertFrom-Json 
        } else { 
            @{} 
        }
        
        $statusData | Add-Member -NotePropertyName "health-gate" -NotePropertyValue $statusUpdate -Force
        $statusData | ConvertTo-Json -Depth 10 | Set-Content $statusFile
    }
    exit 0
}

# Run environment health check
Write-Host "`n1. Checking environment readiness..." -ForegroundColor Yellow
try {
    $envCheck = & "C:\otel\scripts\ecrr-doctor.ps1" 2>&1
    $envExitCode = $LASTEXITCODE
    
    if ($envExitCode -eq 0) {
        Write-Host "   Environment: Healthy ✅" -ForegroundColor Green
        $envStatus = "healthy"
    } else {
        Write-Host "   Environment: Issues detected ⚠️" -ForegroundColor Yellow
        $envStatus = "issues"
    }
} catch {
    Write-Host "   Environment: Check failed ❌" -ForegroundColor Red
    $envStatus = "failed"
}

# Run OTel verification
Write-Host "`n2. Checking OTel pipeline..." -ForegroundColor Yellow
try {
    $otelCheck = & "C:\otel\scripts\ci-verify.ps1" -CronMode 2>&1
    $otelExitCode = $LASTEXITCODE
    
    if ($otelExitCode -eq 0) {
        Write-Host "   OTel Pipeline: Healthy ✅" -ForegroundColor Green
        $otelStatus = "healthy"
    } else {
        Write-Host "   OTel Pipeline: Issues detected ⚠️" -ForegroundColor Yellow
        $otelStatus = "issues"
    }
} catch {
    Write-Host "   OTel Pipeline: Check failed ❌" -ForegroundColor Red
    $otelStatus = "failed"
}

# Determine overall status
$overallStatus = if ($envStatus -eq "healthy" -and $otelStatus -eq "healthy") { "healthy" } 
                elseif ($envStatus -eq "failed" -or $otelStatus -eq "failed") { "failed" } 
                else { "issues" }

# Update status file
if ($UpdateStatus) {
    Write-Host "`n3. Updating status..." -ForegroundColor Yellow
    
    $statusUpdate = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        section = "health-gate"
        status = $overallStatus
        details = @{
            environment = $envStatus
            otel = $otelStatus
            checks = @{
                env_exit_code = $envExitCode
                otel_exit_code = $otelExitCode
            }
        }
    }
    
    $statusFile = ".agent/status.json"
    $statusData = if (Test-Path $statusFile) { 
        Get-Content $statusFile -Raw | ConvertFrom-Json 
    } else { 
        @{} 
    }
    
    $statusData | Add-Member -NotePropertyName "health-gate" -NotePropertyValue $statusUpdate -Force
    $statusData | ConvertTo-Json -Depth 10 | Set-Content $statusFile
    
    Write-Host "   Status updated ✅" -ForegroundColor Green
}

# Summary
$elapsed = (Get-Date) - $startTime
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "Health Gate Summary" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "Environment: $envStatus" -ForegroundColor $(if($envStatus -eq "healthy"){"Green"}elseif($envStatus -eq "issues"){"Yellow"}else{"Red"})
Write-Host "OTel Pipeline: $otelStatus" -ForegroundColor $(if($otelStatus -eq "healthy"){"Green"}elseif($otelStatus -eq "issues"){"Yellow"}else{"Red"})
Write-Host "Overall: $overallStatus" -ForegroundColor $(if($overallStatus -eq "healthy"){"Green"}elseif($overallStatus -eq "issues"){"Yellow"}else{"Red"})
Write-Host "Completed in $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Gray

# Exit with appropriate code
if ($overallStatus -eq "failed") {
    exit 1
} else {
    exit 0
}