# scripts/agent/utils/concurrency.ps1 - Single-instance watchdog and concurrency control

function Test-WatchdogInstance {
    param(
        [string]$PidFile = ".agent/WATCHDOG.PID"
    )
    
    try {
        if (-not (Test-Path $PidFile)) {
            return @{
                running = $false
                pid = $null
                reason = "No PID file found"
            }
        }
        
        $pid = Get-Content $PidFile -Raw
        if ([string]::IsNullOrWhiteSpace($pid)) {
            return @{
                running = $false
                pid = $null
                reason = "Empty PID file"
            }
        }
        
        # Check if process is still running
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "pwsh") {
            return @{
                running = $true
                pid = $pid
                reason = "Process running"
                process = $process
            }
        }
        
        # Process not running, clean up stale PID file
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        return @{
            running = $false
            pid = $pid
            reason = "Stale PID file cleaned up"
        }
    } catch {
        return @{
            running = $false
            pid = $null
            reason = "Error checking PID: $($_.Exception.Message)"
        }
    }
}

function Lock-WatchdogInstance {
    param(
        [string]$PidFile = ".agent/WATCHDOG.PID"
    )
    
    try {
        # Ensure .agent directory exists
        $agentDir = Split-Path $PidFile -Parent
        if (-not (Test-Path $agentDir)) {
            New-Item -ItemType Directory $agentDir -Force | Out-Null
        }
        
        # Check for existing instance
        $existing = Test-WatchdogInstance -PidFile $PidFile
        if ($existing.running) {
            Write-Warning "Watchdog already running with PID $($existing.pid)"
            return $false
        }
        
        # Create PID file
        $currentPid = $PID
        Set-Content -Path $PidFile -Value $currentPid -Encoding UTF8
        
        # Register cleanup on exit
        $cleanupScript = {
            if (Test-Path $PidFile) {
                Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        Register-EngineEvent PowerShell.Exiting -Action $cleanupScript | Out-Null
        
        # Handle CTRL+C
        $trap = {
            & $cleanupScript
            throw
        }
        
        Write-Host "Watchdog locked with PID $currentPid" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to lock watchdog instance: $($_.Exception.Message)"
        return $false
    }
}

function Unlock-WatchdogInstance {
    param(
        [string]$PidFile = ".agent/WATCHDOG.PID"
    )
    
    try {
        if (Test-Path $PidFile) {
            Remove-Item $PidFile -Force
            Write-Host "Watchdog unlocked" -ForegroundColor Green
            return $true
        }
        return $true
    } catch {
        Write-Warning "Failed to unlock watchdog: $($_.Exception.Message)"
        return $false
    }
}

function Test-AgentLock {
    param(
        [string]$LockFile = ".agent/LOCK"
    )
    
    try {
        if (-not (Test-Path $LockFile)) {
            return @{
                locked = $false
                reason = $null
                timestamp = $null
            }
        }
        
        $content = Get-Content $LockFile -Raw
        return @{
            locked = $true
            reason = $content.Trim()
            timestamp = (Get-Item $LockFile).LastWriteTime
        }
    } catch {
        return @{
            locked = $false
            reason = "Error reading lock file: $($_.Exception.Message)"
            timestamp = $null
        }
    }
}

function Set-AgentLock {
    param(
        [string]$Reason,
        [string]$LockFile = ".agent/LOCK"
    )
    
    try {
        # Ensure .agent directory exists
        $agentDir = Split-Path $LockFile -Parent
        if (-not (Test-Path $agentDir)) {
            New-Item -ItemType Directory $agentDir -Force | Out-Null
        }
        
        $timestamp = (Get-Date).ToString("o")
        $content = "$Reason (locked at $timestamp)"
        
        Set-Content -Path $LockFile -Value $content -Encoding UTF8
        Write-Host "Agent locked: $Reason" -ForegroundColor Yellow
        return $true
    } catch {
        Write-Error "Failed to set agent lock: $($_.Exception.Message)"
        return $false
    }
}

function Remove-AgentLock {
    param(
        [string]$LockFile = ".agent/LOCK"
    )
    
    try {
        if (Test-Path $LockFile) {
            Remove-Item $LockFile -Force
            Write-Host "Agent lock removed" -ForegroundColor Green
            return $true
        }
        return $true
    } catch {
        Write-Warning "Failed to remove agent lock: $($_.Exception.Message)"
        return $false
    }
}
