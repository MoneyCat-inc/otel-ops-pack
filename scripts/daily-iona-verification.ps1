# Daily IONA SigNoz Verification Script
# Runs automated verification and logs results for regression detection
# Designed to be scheduled via Windows Task Scheduler or cron

param(
    [string]$LogDir = "artifacts",
    [int]$JobCount = 2,
    [switch]$EnableTracing = $false,
    [switch]$Quiet = $false
)

# Ensure log directory exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Generate log filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogDir/daily-iona-verification-$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    
    if (-not $Quiet) {
        Write-Host $logEntry
    }
    
    $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites for IONA verification"
    
    # Check if verification script exists
    $verifyScript = "$PSScriptRoot\..\verify-iona-signoz-integration.ps1"
    if (-not (Test-Path $verifyScript)) {
        Write-Log "Verification script not found: $verifyScript" "ERROR"
        return $false
    }
    
    # Check if metrics helper exists
    $metricsScript = "$PSScriptRoot\metrics.ps1"
    if (-not (Test-Path $metricsScript)) {
        Write-Log "Metrics helper script not found: $metricsScript" "ERROR"
        return $false
    }
    
    Write-Log "Prerequisites check passed"
    return $true
}

function Invoke-Verification {
    Write-Log "Starting IONA SigNoz verification with $JobCount jobs"
    
    try {
        $verifyScript = "$PSScriptRoot\..\verify-iona-signoz-integration.ps1"
        $tracingFlag = if ($EnableTracing) { "-EnableTracing" } else { "" }
        
        # Run verification script and capture output
        $output = & pwsh -NoProfile -File $verifyScript -JobCount $JobCount $tracingFlag 2>&1
        
        # Log the output
        foreach ($line in $output) {
            Write-Log $line
        }
        
        # Check exit code
        if ($LASTEXITCODE -eq 0) {
            Write-Log "IONA verification completed successfully" "SUCCESS"
            return $true
        }
        else {
            Write-Log "IONA verification failed with exit code $LASTEXITCODE" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "IONA verification failed with exception: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Write-SummaryReport {
    param([bool]$Success)
    
    $summaryFile = "$LogDir/daily-iona-summary-$timestamp.json"
    $summary = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        success = $Success
        jobCount = $JobCount
        tracingEnabled = $EnableTracing
        logFile = $logFile
        nextRun = (Get-Date).AddDays(1).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $summary | ConvertTo-Json -Depth 2 | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Log "Summary report saved to: $summaryFile"
}

function Cleanup-OldLogs {
    Write-Log "Cleaning up old verification logs (keeping last 30 days)"
    
    $cutoffDate = (Get-Date).AddDays(-30)
    $oldLogs = Get-ChildItem -Path $LogDir -Filter "daily-iona-verification-*.log" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    foreach ($log in $oldLogs) {
        Remove-Item $log.FullName -Force
        Write-Log "Removed old log: $($log.Name)"
    }
}

# Main execution
try {
    Write-Log "=== Daily IONA SigNoz Verification Started ==="
    Write-Log "Configuration: JobCount=$JobCount, Tracing=$EnableTracing, Quiet=$Quiet"
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Log "Prerequisites check failed, aborting verification" "ERROR"
        exit 1
    }
    
    # Run verification
    $success = Invoke-Verification
    
    # Write summary report
    Write-SummaryReport -Success $success
    
    # Cleanup old logs
    Cleanup-OldLogs
    
    Write-Log "=== Daily IONA SigNoz Verification Completed ==="
    
    if ($success) {
        Write-Log "Verification PASSED - IONA SigNoz integration is healthy" "SUCCESS"
        exit 0
    }
    else {
        Write-Log "Verification FAILED - IONA SigNoz integration needs attention" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Daily verification script failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
