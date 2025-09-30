# scripts/agent/nightly-verify.ps1
# Nightly verification script for shadow vs canonical artifacts
# This script should be run via cron/scheduled task to monitor drift

param(
    [switch]$Quiet,
    [switch]$EmailOnFailure,
    [string]$EmailRecipient = "admin@resonai.com"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if (-not $Quiet) {
        Write-Host "[$timestamp] [$Level] $Message"
    }
    # Could add file logging here if needed
}

function Send-FailureEmail {
    param([string]$Subject, [string]$Body)
    if ($EmailOnFailure) {
        try {
            # This is a placeholder - implement actual email sending
            Write-Log "Would send email: $Subject" "EMAIL"
        }
        catch {
            Write-Log "Failed to send email: $_" "ERROR"
        }
    }
}

try {
    Write-Log "Starting nightly shadow vs canonical verification..."
    
    # Run the verification
    $result = & pnpm agent:verify 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Log "✅ Verification PASSED - No drift detected" "SUCCESS"
        Write-Log "Shadow and canonical artifacts are identical"
    }
    else {
        Write-Log "❌ Verification FAILED - Drift detected" "ERROR"
        Write-Log "Shadow and canonical artifacts differ"
        
        # Extract drift details from output
        $driftLines = $result | Where-Object { $_ -match "DRIFT DETECTED" }
        $driftCount = ($driftLines | Measure-Object).Count
        
        Write-Log "Drift count: $driftCount"
        
        # Send email notification if requested
        $emailSubject = "Queue Steward: Shadow/Canonical Drift Detected"
        $emailBody = @"
Nightly verification detected drift between shadow and canonical artifacts.

Drift Count: $driftCount
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Please investigate and resolve any issues.

Verification output:
$result
"@
        Send-FailureEmail -Subject $emailSubject -Body $emailBody
    }
    
    # Always save the verification report
    $reportPath = ".agent/shadow-canonical-verification.json"
    if (Test-Path $reportPath) {
        Write-Log "Verification report saved: $reportPath"
    }
    
    Write-Log "Nightly verification completed"
    exit $exitCode
}
catch {
    Write-Log "Nightly verification failed with error: $_" "ERROR"
    
    $emailSubject = "Queue Steward: Nightly Verification Error"
    $emailBody = @"
Nightly verification script failed with an error.

Error: $_
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Please investigate the verification system.

Stack Trace:
$($_.ScriptStackTrace)
"@
    Send-FailureEmail -Subject $emailSubject -Body $emailBody
    
    exit 1
}
