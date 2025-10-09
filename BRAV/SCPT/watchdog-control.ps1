# BRAV/SCPT/watchdog-control.ps1
# Watchdog Control Center - Manage GATE and SITE bots
# Commands: start, stop, status, logs

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("start", "stop", "status", "logs", "evidence")]
    [string]$Command,
    
    [Parameter(Position=1)]
    [ValidateSet("gate", "site", "both")]
    [string]$Bot = "both",
    
    [switch]$DryRun,
    [int]$Interval = 30
)

$ErrorActionPreference = "Stop"

function Write-Control($message, $color = "White") {
    Write-Host "[CONTROL] $message" -ForegroundColor $color
}

function Start-WatchdogBot {
    param([string]$BotName, [string]$ScriptPath, [hashtable]$BotArgs, [switch]$AsAdmin)
    
    Write-Control "Starting $BotName bot..." "Cyan"
    
    # Build command for the bot
    $command = "Set-Location '$PWD'; pwsh -NoProfile -File $ScriptPath"
    foreach ($key in $BotArgs.Keys) {
        $value = $BotArgs[$key]
        if ($value -is [bool]) {
            # Switch parameter - only add if true
            if ($value) {
                $command += " -$key"
            }
        } else {
            # Regular parameter
            $command += " -$key $value"
        }
    }
    
    if ($AsAdmin) {
        # Launch elevated in new window
        $job = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile","-Command",$command -Verb RunAs -PassThru
        Write-Control "$BotName bot started with ADMIN privileges (PID: $($job.Id))" "Green"
    } else {
        # Launch normally
        $argList = @("-NoProfile", "-File", $ScriptPath)
        foreach ($key in $BotArgs.Keys) {
            $value = $BotArgs[$key]
            if ($value -is [bool]) {
                if ($value) { $argList += "-$key" }
            } else {
                $argList += "-$key"
                $argList += $value
            }
        }
        $job = Start-Process -FilePath "pwsh" -ArgumentList $argList -NoNewWindow -PassThru
        Write-Control "$BotName bot started (PID: $($job.Id))" "Green"
    }
    
    return $job
}

function Stop-WatchdogBot {
    param([string]$BotName)
    
    $processes = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -like "*watchdog-$($BotName.ToLower())*" }
    
    if ($processes) {
        foreach ($proc in $processes) {
            Write-Control "Stopping $BotName bot (PID: $($proc.Id))..." "Yellow"
            Stop-Process -Id $proc.Id -Force
        }
        Write-Control "$BotName bot stopped" "Green"
    } else {
        Write-Control "$BotName bot not running" "Gray"
    }
}

function Get-WatchdogStatus {
    param([string]$BotName)
    
    # Check for running processes
    $scriptName = "watchdog-$($BotName.ToLower()).ps1"
    $processes = Get-Process -ErrorAction SilentlyContinue | 
        Where-Object { $_.ProcessName -eq "pwsh" -and $_.CommandLine -like "*$scriptName*" }
    
    # Check evidence files
    $evidenceFile = "DELT/ARTF/watchdog-$($BotName.ToLower())-evidence.json"
    $logFile = "DELT/ARTF/watchdog-$($BotName.ToLower()).log"
    
    $status = @{
        Bot = $BotName.ToUpper()
        Running = $processes.Count -gt 0
        ProcessCount = $processes.Count
        PIDs = $processes.Id
        EvidenceExists = Test-Path $evidenceFile
        LogExists = Test-Path $logFile
    }
    
    if ($status.EvidenceExists) {
        try {
            $evidence = Get-Content $evidenceFile -Raw | ConvertFrom-Json
            $status.LastCheck = $evidence.timestamp
            $status.ChecksPerformed = $evidence.checksPerformed
            $status.RestartsAttempted = $evidence.restartsAttempted
        } catch {
            $status.EvidenceError = $_.Exception.Message
        }
    }
    
    return [PSCustomObject]$status
}

function Show-WatchdogLogs {
    param([string]$BotName, [int]$Lines = 20)
    
    $logFile = "DELT/ARTF/watchdog-$($BotName.ToLower()).log"
    
    if (Test-Path $logFile) {
        Write-Control "$BotName Log (last $Lines lines):" "Cyan"
        Get-Content $logFile -Tail $Lines | ForEach-Object {
            if ($_ -like "*ERROR*") {
                Write-Host $_ -ForegroundColor Red
            } elseif ($_ -like "*ALERT*") {
                Write-Host $_ -ForegroundColor Yellow
            } elseif ($_ -like "*SUCCESS*") {
                Write-Host $_ -ForegroundColor Green
            } else {
                Write-Host $_
            }
        }
    } else {
        Write-Control "$BotName log file not found" "Gray"
    }
}

function Show-WatchdogEvidence {
    param([string]$BotName)
    
    if ($BotName -eq "gate") {
        $evidenceFile = "DELT/ARTF/watchdog-gate-evidence.json"
    } else {
        $snapshotDir = "docs/observability/snapshots/site-observations"
        if (Test-Path $snapshotDir) {
            $latest = Get-ChildItem $snapshotDir -Filter "*.json" -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1
            $evidenceFile = $latest.FullName
        }
    }
    
    if ($evidenceFile -and (Test-Path $evidenceFile)) {
        Write-Control "$BotName Evidence:" "Cyan"
        $evidence = Get-Content $evidenceFile -Raw | ConvertFrom-Json
        $evidence | ConvertTo-Json -Depth 4 | Write-Host
    } else {
        Write-Control "$BotName evidence not found" "Gray"
    }
}

# Main command execution
Write-Control "Watchdog Control Center" "Magenta"
Write-Control "Command: $Command, Bot: $Bot" "Cyan"
Write-Control "========================================" "Gray"

switch ($Command) {
    "start" {
        $bots = if ($Bot -eq "both") { @("gate", "site") } else { @($Bot) }
        
        Write-Control "All bots will run with ADMIN privileges for full capability" "Yellow"
        
        foreach ($botName in $bots) {
            $scriptPath = "BRAV/SCPT/watchdog-$botName.ps1"
            $botArgs = @{ IntervalSeconds = $Interval }
            
            # Only GATE supports DryRun
            if ($DryRun -and $botName -eq "gate") { 
                $botArgs.DryRun = $true 
            }
            
            # All bots get admin access
            Start-WatchdogBot -BotName $botName.ToUpper() -ScriptPath $scriptPath -BotArgs $botArgs -AsAdmin
        }
        
        Write-Control "" "White"
        Write-Control "Watchdogs deployed with ADMIN privileges." "Green"
        Write-Control "Check logs in DELT/ARTF/watchdog-*.log" "Cyan"
    }
    
    "stop" {
        $bots = if ($Bot -eq "both") { @("gate", "site") } else { @($Bot) }
        
        # Create kill-switch
        New-Item -ItemType File -Path ".agent/LOCK" -Force | Out-Null
        Write-Control "Kill-switch engaged (.agent/LOCK created)" "Yellow"
        
        Start-Sleep -Seconds 2
        
        foreach ($botName in $bots) {
            Stop-WatchdogBot -BotName $botName.ToUpper()
        }
        
        # Remove kill-switch
        Remove-Item ".agent/LOCK" -Force -ErrorAction SilentlyContinue
        Write-Control "Kill-switch disengaged" "Green"
    }
    
    "status" {
        $bots = if ($Bot -eq "both") { @("gate", "site") } else { @($Bot) }
        
        foreach ($botName in $bots) {
            $status = Get-WatchdogStatus -BotName $botName.ToUpper()
            
            Write-Control "$($status.Bot) Bot Status:" "Cyan"
            $status | Format-List
            Write-Control "" "White"
        }
    }
    
    "logs" {
        $bots = if ($Bot -eq "both") { @("gate", "site") } else { @($Bot) }
        
        foreach ($botName in $bots) {
            Show-WatchdogLogs -BotName $botName.ToUpper()
            Write-Control "" "White"
        }
    }
    
    "evidence" {
        $bots = if ($Bot -eq "both") { @("gate", "site") } else { @($Bot) }
        
        foreach ($botName in $bots) {
            Show-WatchdogEvidence -BotName $botName.ToUpper()
            Write-Control "" "White"
        }
    }
}

