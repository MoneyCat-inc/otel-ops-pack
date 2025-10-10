# BRAV/SCPT/watchdog-gate.ps1
# GATE Bot - Windows Collector Guardian
# Monitors otelcol-contrib service and keeps gate open
# ECRR: Examine (check) → Clean (restart) → Report (log) → Role (GATE guardian)

[CmdletBinding()]
param(
    [int]$IntervalSeconds = 30,
    [string]$ServiceName = "otelcol-contrib",
    [string]$LogPath = "DELT/ARTF/watchdog-gate.log",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-GateLog($message, $level = "INFO") {
    # Log rotation check before writing
    Invoke-LogRotation -Path $LogPath -MaxSizeMB 10 -KeepFiles 5
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] [GATE:$level] $message"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry -Encoding UTF8
}

function Invoke-LogRotation {
    param(
        [string]$Path,
        [int]$MaxSizeMB = 10,
        [int]$KeepFiles = 5
    )
    
    if (-not (Test-Path $Path)) { return }
    
    $file = Get-Item $Path
    $sizeMB = [math]::Round($file.Length / 1MB, 2)
    
    if ($sizeMB -ge $MaxSizeMB) {
        # Rotate existing numbered logs
        for ($i = $KeepFiles - 1; $i -ge 1; $i--) {
            $oldLog = "$Path.$i"
            $newLog = "$Path.$($i + 1)"
            if (Test-Path $oldLog) {
                Move-Item -Path $oldLog -Destination $newLog -Force
            }
        }
        
        # Archive current log as .1
        Move-Item -Path $Path -Destination "$Path.1" -Force
        
        # Log rotation event to new file
        $rotationMsg = "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [GATE:ROTATION] Log rotated at ${sizeMB}MB (keeping $KeepFiles old logs)"
        Set-Content -Path $Path -Value $rotationMsg -Encoding UTF8
    }
}

function Test-KillSwitch {
    if (Test-Path ".agent/LOCK") {
        Write-GateLog "Kill-switch engaged (.agent/LOCK) - GATE shutting down" "WARN"
        return $true
    }
    return $false
}

function Get-ServiceState {
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction Stop
        return [PSCustomObject]@{
            Status = $svc.Status
            StartType = $svc.StartType
            DisplayName = $svc.DisplayName
            CanStop = $svc.CanStop
        }
    } catch {
        return [PSCustomObject]@{
            Status = "NotFound"
            Error = $_.Exception.Message
        }
    }
}

function Restart-CollectorService {
    param([switch]$Force)
    
    Write-GateLog "Attempting to restart $ServiceName..." "ACTION"
    
    if ($DryRun) {
        Write-GateLog "DRY-RUN: Would restart $ServiceName" "DRYRUN"
        return $true
    }
    
    try {
        # First, check if service is disabled and enable it
        $svc = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($svc.StartType -eq "Disabled") {
            Write-GateLog "Service is DISABLED - enabling it first..." "ACTION"
            Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
            Write-GateLog "Service enabled (set to Automatic)" "SUCCESS"
        }
        
        # Try to start the service
        Start-Service -Name $ServiceName -ErrorAction Stop
        Start-Sleep -Seconds 3
        
        $newState = Get-ServiceState
        if ($newState.Status -eq "Running") {
            Write-GateLog "Successfully restarted $ServiceName" "SUCCESS"
            return $true
        } else {
            Write-GateLog "Service start command executed but status is: $($newState.Status)" "WARN"
            return $false
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-GateLog "Failed to restart service: $errorMsg" "ERROR"
        
        # Check if it's a permission error
        if ($errorMsg -like "*Access is denied*" -or $errorMsg -like "*privilege*") {
            Write-GateLog "PERMISSION ERROR: GATE requires admin privileges to restart service" "ERROR"
            Write-GateLog "Run: Start-Process powershell -Verb RunAs -ArgumentList '-File BRAV/SCPT/watchdog-gate.ps1'" "HINT"
        }
        
        # Check if it's a config error
        if ($errorMsg -like "*cannot be started*") {
            Write-GateLog "CONFIG ERROR: Service may have configuration issues" "ERROR"
            Write-GateLog "Check: Get-EventLog -LogName Application -Source otelcol-contrib -Newest 5" "HINT"
        }
        
        return $false
    }
}

function Export-GateEvidence {
    param($checkCount, $restartCount, $failCount)
    
    $evidence = @{
        timestamp = (Get-Date).ToString("o")
        bot = "GATE"
        service = $ServiceName
        checksPerformed = $checkCount
        restartsAttempted = $restartCount
        failedRestarts = $failCount
        uptime = (Get-Date) - $script:startTime
        logPath = $LogPath
    }
    
    $evidencePath = "DELT/ARTF/watchdog-gate-evidence.json"
    $evidence | ConvertTo-Json -Depth 3 | Set-Content -Path $evidencePath -Encoding UTF8
}

# Initialize
New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force -ErrorAction SilentlyContinue | Out-Null
$script:startTime = Get-Date
$checkCount = 0
$restartCount = 0
$failCount = 0

Write-GateLog "========================================" "INIT"
Write-GateLog "GATE Bot Starting" "INIT"
Write-GateLog "Target Service: $ServiceName" "INIT"
Write-GateLog "Check Interval: $IntervalSeconds seconds" "INIT"
Write-GateLog "Dry Run Mode: $($DryRun.IsPresent)" "INIT"
Write-GateLog "========================================" "INIT"

if ($DryRun) {
    Write-GateLog "DRY-RUN MODE: No actual service restarts will occur" "WARN"
}

# Check initial admin status
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-GateLog "WARNING: Running without admin privileges - service restarts will fail" "WARN"
    Write-GateLog "Consider running as admin or using DryRun mode for monitoring only" "WARN"
}

# Main watch loop
Write-GateLog "Entering watch loop (Ctrl+C to stop)..." "INFO"

try {
    while ($true) {
        # Check kill-switch
        if (Test-KillSwitch) {
            break
        }
        
        $checkCount++
        
        # Examine - Check service state
        $state = Get-ServiceState
        Write-GateLog "Check #$checkCount - Service status: $($state.Status)" "CHECK"
        
        # Clean - Restart if needed
        if ($state.Status -ne "Running") {
            Write-GateLog "GATE OPEN: Service is $($state.Status) - taking action" "ALERT"
            $restartCount++
            
            $success = Restart-CollectorService
            if (-not $success) {
                $failCount++
            }
        } else {
            Write-GateLog "Gate closed: Service running normally" "OK"
        }
        
        # Report - Export evidence every 10 checks
        if ($checkCount % 10 -eq 0) {
            Export-GateEvidence -checkCount $checkCount -restartCount $restartCount -failCount $failCount
            Write-GateLog "Evidence exported (checks: $checkCount, restarts: $restartCount, fails: $failCount)" "REPORT"
        }
        
        # Wait for next check
        Start-Sleep -Seconds $IntervalSeconds
    }
} catch {
    Write-GateLog "GATE Bot interrupted: $($_.Exception.Message)" "ERROR"
} finally {
    Write-GateLog "GATE Bot shutting down..." "SHUTDOWN"
    Export-GateEvidence -checkCount $checkCount -restartCount $restartCount -failCount $failCount
    Write-GateLog "Final stats - Checks: $checkCount, Restarts: $restartCount, Fails: $failCount" "FINAL"
}

