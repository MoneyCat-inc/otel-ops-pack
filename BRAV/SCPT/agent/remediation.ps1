# Automated Remediation Script for Production Agent System
# This script handles hung daemon detection and automated restart

param(
    [string]$Action = "restart",
    [string]$Reason = "hung_daemon_detected",
    [int]$TimeoutSeconds = 30,
    [switch]$DryRun = $false
)

Write-Host "🔧 Production Agent System - Automated Remediation" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Reason: $Reason" -ForegroundColor Yellow
Write-Host "Timeout: $TimeoutSeconds seconds" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "Mode: DRY RUN (no actual changes will be made)" -ForegroundColor Magenta
}
Write-Host ""

# Set working directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $ProjectRoot

# Function to log remediation failure alert
function Write-RemediationFailureAlert {
    param(
        [string]$Action,
        [string]$Reason,
        [int]$ExitCode,
        [string]$ErrorMessage = ""
    )
    
    try {
        $FailureAlert = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = "ERROR"
            system = "production-agent-system"
            type = "remediation_failure"
            message = "Remediation action failed - $Action"
            details = @{
                action = $Action
                reason = $Reason
                exitCode = $ExitCode
                errorMessage = $ErrorMessage
                status = "failed"
            }
        } | ConvertTo-Json -Compress
        
        $LogFile = "C:\logs\queue\health.log"
        Add-Content -Path $LogFile -Value $FailureAlert
        
        Write-RemediationLog "Remediation failure alert logged to SigNoz" "ERROR"
        
    } catch {
        Write-RemediationLog "Failed to log remediation failure alert: $($_.Exception.Message)" "ERROR"
    }
}

# Function to log remediation actions
function Write-RemediationLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $LogEntry = @{
        timestamp = $Timestamp
        level = $Level
        system = "production-agent-remediation"
        action = $Action
        reason = $Reason
        message = $Message
    } | ConvertTo-Json -Compress
    
    # Write to OTel metrics log for SigNoz
    $LogFile = "C:\logs\queue\health.log"
    Add-Content -Path $LogFile -Value $LogEntry
    
    # Console output
    $Color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# Function to check if daemon is running
function Test-DaemonRunning {
    try {
        $PidFile = Join-Path $ProjectRoot ".agent/production-agent.pid"
        Write-RemediationLog "Checking PID file: $PidFile" "INFO"
        
        if (Test-Path $PidFile) {
            $PidData = Get-Content $PidFile | ConvertFrom-Json
            Write-RemediationLog "PID file found, PID: $($PidData.pid)" "INFO"
            
            $Process = Get-Process -Id $PidData.pid -ErrorAction SilentlyContinue
            if ($Process) {
                Write-RemediationLog "Process found: $($Process.ProcessName)" "INFO"
                return $true
            } else {
                Write-RemediationLog "Process not found for PID: $($PidData.pid)" "WARNING"
            }
        } else {
            Write-RemediationLog "PID file not found: $PidFile" "WARNING"
        }
        return $false
    } catch {
        Write-RemediationLog "Error checking daemon: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to stop daemon gracefully
function Stop-DaemonGracefully {
    Write-RemediationLog "Attempting graceful daemon stop" "INFO"
    
    if ($DryRun) {
        Write-RemediationLog "DRY RUN: Would attempt graceful stop" "INFO"
        return $true
    }
    
    try {
        # Try graceful stop first
        $StopResult = & pnpm agent:stop 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-RemediationLog "Daemon stopped gracefully" "SUCCESS"
            return $true
        } else {
            Write-RemediationLog "Graceful stop failed: $StopResult" "WARNING"
            return $false
        }
    } catch {
        Write-RemediationLog "Error during graceful stop: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to force kill daemon
function Stop-DaemonForce {
    Write-RemediationLog "Attempting force kill of daemon" "WARNING"
    
    if ($DryRun) {
        Write-RemediationLog "DRY RUN: Would attempt force kill" "WARNING"
        return $true
    }
    
    try {
        $PidFile = Join-Path $ProjectRoot ".agent/production-agent.pid"
        if (Test-Path $PidFile) {
            $PidData = Get-Content $PidFile | ConvertFrom-Json
            $Process = Get-Process -Id $PidData.pid -ErrorAction SilentlyContinue
            
            if ($Process) {
                Stop-Process -Id $PidData.pid -Force
                Write-RemediationLog "Daemon force killed (PID: $($PidData.pid))" "SUCCESS"
                
                # Clean up PID file
                Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
                return $true
            }
        }
        
        Write-RemediationLog "No daemon process found to kill" "INFO"
        return $true
    } catch {
        Write-RemediationLog "Error during force kill: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to start daemon
function Start-Daemon {
    Write-RemediationLog "Starting daemon" "INFO"
    
    if ($DryRun) {
        Write-RemediationLog "DRY RUN: Would start daemon" "INFO"
        return $true
    }
    
    try {
        # Start daemon in background
        $StartJob = Start-Job -ScriptBlock {
            Set-Location $using:ProjectRoot
            & pnpm agent:start
        }
        
        # Wait for daemon to start
        $Timeout = $TimeoutSeconds * 1000
        $Elapsed = 0
        $Interval = 1000
        
        while ($Elapsed -lt $Timeout) {
            Start-Sleep -Milliseconds $Interval
            $Elapsed += $Interval
            
            if (Test-DaemonRunning) {
                Write-RemediationLog "Daemon started successfully" "SUCCESS"
                Stop-Job $StartJob -ErrorAction SilentlyContinue
                Remove-Job $StartJob -ErrorAction SilentlyContinue
                return $true
            }
        }
        
        Write-RemediationLog "Daemon start timeout after $TimeoutSeconds seconds" "ERROR"
        Stop-Job $StartJob -ErrorAction SilentlyContinue
        Remove-Job $StartJob -ErrorAction SilentlyContinue
        return $false
        
    } catch {
        Write-RemediationLog "Error starting daemon: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to verify daemon health
function Test-DaemonHealth {
    Write-RemediationLog "Verifying daemon health" "INFO"
    
    try {
        $StatusResult = & pnpm agent:status-system 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Try to parse JSON from the output - look for the main JSON object
            $StatusString = $StatusResult -join "`n"
            # Look for the main JSON object by finding the first { that's followed by "system"
            $SystemPattern = '\{\s*"system"'
            $SystemMatch = [regex]::Match($StatusString, $SystemPattern)
            if ($SystemMatch.Success) {
                $JsonStart = $SystemMatch.Index
                try {
                    $JsonPart = $StatusString.Substring($JsonStart)
                    $Status = $JsonPart | ConvertFrom-Json
                    if ($Status.system.running -eq $true) {
                        Write-RemediationLog "Daemon health verified - running and responsive" "SUCCESS"
                        return $true
                    } else {
                        Write-RemediationLog "Daemon not running according to status" "WARNING"
                        return $false
                    }
                } catch {
                    Write-RemediationLog "Failed to parse status JSON: $($_.Exception.Message)" "WARNING"
                    return $false
                }
            } else {
                Write-RemediationLog "Could not find main JSON object in status output" "WARNING"
                return $false
            }
        } else {
            Write-RemediationLog "Status check failed with exit code: $LASTEXITCODE" "ERROR"
            return $false
        }
    } catch {
        Write-RemediationLog "Error checking daemon health: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main remediation logic
Write-RemediationLog "Starting automated remediation" "INFO"

$RemediationSuccess = $true
$RemediationExitCode = 0

switch ($Action.ToLower()) {
    "restart" {
        Write-RemediationLog "Performing daemon restart" "INFO"
        
        # Step 1: Stop daemon gracefully
        if (-not (Stop-DaemonGracefully)) {
            Write-RemediationLog "Graceful stop failed, attempting force kill" "WARNING"
            if (-not (Stop-DaemonForce)) {
                Write-RemediationLog "Failed to stop daemon" "ERROR"
                $RemediationSuccess = $false
                $RemediationExitCode = 1
            }
        }
        
        if ($RemediationSuccess) {
            # Step 2: Wait a moment
            Start-Sleep -Seconds 2
            
            # Step 3: Start daemon
            if (-not (Start-Daemon)) {
                Write-RemediationLog "Failed to start daemon" "ERROR"
                $RemediationSuccess = $false
                $RemediationExitCode = 2
            } else {
                # Step 4: Verify health
                if (-not (Test-DaemonHealth)) {
                    Write-RemediationLog "Daemon health check failed after restart" "ERROR"
                    $RemediationSuccess = $false
                    $RemediationExitCode = 3
                } else {
                    Write-RemediationLog "Daemon restart completed successfully" "SUCCESS"
                }
            }
        }
    }
    
    "stop" {
        Write-RemediationLog "Performing daemon stop" "INFO"
        
        if (-not (Stop-DaemonGracefully)) {
            Write-RemediationLog "Graceful stop failed, attempting force kill" "WARNING"
            if (-not (Stop-DaemonForce)) {
                Write-RemediationLog "Failed to stop daemon" "ERROR"
                $RemediationSuccess = $false
                $RemediationExitCode = 1
            }
        }
        
        if ($RemediationSuccess) {
            Write-RemediationLog "Daemon stop completed successfully" "SUCCESS"
        }
    }
    
    "start" {
        Write-RemediationLog "Performing daemon start" "INFO"
        
        if (Test-DaemonRunning) {
            Write-RemediationLog "Daemon already running" "WARNING"
        } else {
            if (-not (Start-Daemon)) {
                Write-RemediationLog "Failed to start daemon" "ERROR"
                $RemediationSuccess = $false
                $RemediationExitCode = 1
            } else {
                if (-not (Test-DaemonHealth)) {
                    Write-RemediationLog "Daemon health check failed after start" "ERROR"
                    $RemediationSuccess = $false
                    $RemediationExitCode = 2
                } else {
                    Write-RemediationLog "Daemon start completed successfully" "SUCCESS"
                }
            }
        }
    }
    
    "status" {
        Write-RemediationLog "Checking daemon status" "INFO"
        
        if (Test-DaemonRunning) {
            Write-RemediationLog "Daemon is running" "SUCCESS"
            if (Test-DaemonHealth) {
                Write-RemediationLog "Daemon is healthy" "SUCCESS"
            } else {
                Write-RemediationLog "Daemon is running but unhealthy" "WARNING"
                $RemediationSuccess = $false
                $RemediationExitCode = 2
            }
        } else {
            Write-RemediationLog "Daemon is not running" "WARNING"
            $RemediationSuccess = $false
            $RemediationExitCode = 1
        }
    }
    
    default {
        Write-RemediationLog "Unknown action: $Action" "ERROR"
        $RemediationSuccess = $false
        $RemediationExitCode = 4
    }
}

# Log remediation failure alert if needed
if (-not $RemediationSuccess) {
    Write-RemediationFailureAlert -Action $Action -Reason $Reason -ExitCode $RemediationExitCode
}

Write-RemediationLog "Automated remediation completed" "INFO"

if ($RemediationSuccess) {
    Write-Host ""
    Write-Host "✅ Remediation completed successfully" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Remediation failed with exit code: $RemediationExitCode" -ForegroundColor Red
    exit $RemediationExitCode
}
