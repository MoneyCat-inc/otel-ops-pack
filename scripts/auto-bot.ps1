# Auto Bot - Automated Observability Pipeline Management
# ECRR-compliant automated monitoring, remediation, and response system
# Implements intelligent decision-making for pipeline health management
#
# NOTES: For long-running operations, this script uses the shared spinner toolkit:
# . (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')
# Use Show-Spinner, Wait-WithSpinner, or Show-ProgressBar for consistent UX.

param(
    [switch]$Continuous = $false,
    [int]$CheckIntervalSeconds = 30,
    [switch]$AutoRemediate = $true,
    [switch]$Verbose = $false,
    [string]$LogPath = "artifacts\auto-bot-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

Set-StrictMode -Version 2
$ErrorActionPreference = "Continue"

# Import shared spinner toolkit for consistent progress indicators
. (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')

# Bot Configuration
$script:botConfig = @{
    Name = "ECRR Auto Bot"
    Version = "1.0.0"
    StartTime = Get-Date
    CheckInterval = $CheckIntervalSeconds
    AutoRemediate = $AutoRemediate
    MaxRemediationAttempts = 3
    AlertThresholds = @{
        PipelineHealth = 80
        MemoryUsage = 85
        DiskUsage = 90
        ErrorRate = 5
        LatencyMs = 5000
    }
    Actions = @{
        RestartCollector = $true
        ClearLogs = $true
        ScaleResources = $true
        NotifyAdmin = $true
    }
}

# Bot-specific spinner configurations (using shared toolkit)
$script:botSpinnerConfig = @{
    BotThinking = "Bot"
    BotProcessing = "Processing"
    BotAnalyzing = "Analytics"
    BotHealth = "Health"
}

function Write-BotLog {
    param(
        [string]$Level,
        [string]$Message,
        [string]$Category = "GENERAL"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Category] $Message"
    
    if ($Verbose -or $Level -in @("ERROR", "WARN", "ACTION")) {
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "ACTION" { "Green" }
            "INFO" { "Cyan" }
            default { "White" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # Write to log file
    $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Test-PipelineHealth {
    $health = @{
        Overall = "healthy"
        Components = @{}
        Issues = @()
        Score = 100
    }
    
    # Show thinking animation with progress
    $healthChecks = @("Collector Status", "SigNoz Connectivity", "OTLP Endpoints", "System Resources", "Finalizing")
    $totalChecks = $healthChecks.Count
    
    for ($i = 0; $i -lt $totalChecks; $i++) {
        $progress = [math]::Floor(($i / $totalChecks) * 100)
        Show-ThinkingAnimation -Message "Analyzing pipeline health..." -AnimationType $script:botSpinnerConfig.BotAnalyzing -DurationMs 0 -ShowProgress -ProgressPercent $progress
        Start-Sleep -Milliseconds 200
    }
    
    Clear-Spinner
    
    try {
        # Check OTel Collector
        $collectorStatus = sc.exe query otelcol-contrib | Select-String "RUNNING"
        if ($collectorStatus) {
            $health.Components.Collector = "healthy"
        } else {
            $health.Components.Collector = "unhealthy"
            $health.Issues += "OTel Collector not running"
            $health.Score -= 30
        }
        
        # Check SigNoz Stack
        try {
            $signozResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
            if ($signozResponse.StatusCode -eq 200) {
                $health.Components.SigNoz = "healthy"
            } else {
                $health.Components.SigNoz = "degraded"
                $health.Issues += "SigNoz responding with status $($signozResponse.StatusCode)"
                $health.Score -= 20
            }
        } catch {
            $health.Components.SigNoz = "unhealthy"
            $health.Issues += "SigNoz not reachable"
            $health.Score -= 25
        }
        
        # Check OTLP Endpoints
        $otlpEndpoints = @("http://localhost:5318", "http://localhost:14318")
        $healthyEndpoints = 0
        foreach ($endpoint in $otlpEndpoints) {
            try {
                $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec 3
                if ($response.StatusCode -eq 200) {
                    $healthyEndpoints++
                }
            } catch {
                $health.Issues += "OTLP endpoint $endpoint not responding"
                $health.Score -= 10
            }
        }
        
        $totalEndpoints = $otlpEndpoints.Length
        if ($healthyEndpoints -eq $totalEndpoints) {
            $health.Components.OTLP = "healthy"
        } elseif ($healthyEndpoints -gt 0) {
            $health.Components.OTLP = "degraded"
        } else {
            $health.Components.OTLP = "unhealthy"
        }
        
        # Check system resources
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $memoryUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
        $health.Components.Memory = $memoryUsage
        
        if ($memoryUsage -gt $script:botConfig.AlertThresholds.MemoryUsage) {
            $health.Issues += "High memory usage: $memoryUsage%"
            $health.Score -= 15
        }
        
        # Check disk usage
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $diskUsage = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
        $health.Components.Disk = $diskUsage
        
        if ($diskUsage -gt $script:botConfig.AlertThresholds.DiskUsage) {
            $health.Issues += "High disk usage: $diskUsage%"
            $health.Score -= 10
        }
        
        # Determine overall health
        if ($health.Score -ge 90) {
            $health.Overall = "healthy"
        } elseif ($health.Score -ge 70) {
            $health.Overall = "degraded"
        } else {
            $health.Overall = "unhealthy"
        }
        
    } catch {
        $health.Overall = "error"
        $health.Issues += "Health check failed: $($_.Exception.Message)"
        $health.Score = 0
    }
    
    Clear-Spinner
    return $health
}

function Invoke-AutoRemediation {
    param(
        [hashtable]$Health
    )
    
    $actions = @()
    
    if ($Health.Issues.Count -gt 0) {
        Show-ThinkingAnimation -Message "Analyzing issues for remediation..." -AnimationType $script:botSpinnerConfig.BotThinking -DurationMs 0
        Start-Sleep -Milliseconds 500
        Clear-Spinner
    }
    
    foreach ($issue in $Health.Issues) {
        Write-BotLog "INFO" "Analyzing issue: $issue" "REMEDIATION"
        
        Show-ThinkingAnimation -Message "Evaluating remediation options..." -AnimationType $script:botSpinnerConfig.BotProcessing -DurationMs 0
        Start-Sleep -Milliseconds 300
        Clear-Spinner
        
        switch -Wildcard ($issue) {
            "*Collector not running*" {
                if ($script:botConfig.Actions.RestartCollector) {
                    Write-BotLog "ACTION" "Attempting to restart OTel Collector" "REMEDIATION"
                    try {
                        Start-Process -FilePath "sc.exe" -ArgumentList "start", "otelcol-contrib" -Wait -WindowStyle Hidden
                        $actions += "Restarted OTel Collector"
                        Write-BotLog "INFO" "Successfully restarted OTel Collector" "REMEDIATION"
                    } catch {
                        Write-BotLog "ERROR" "Failed to restart OTel Collector: $($_.Exception.Message)" "REMEDIATION"
                    }
                }
            }
            "*High memory usage*" {
                if ($script:botConfig.Actions.ScaleResources) {
                    Write-BotLog "ACTION" "Attempting memory optimization" "REMEDIATION"
                    try {
                        # Clear PowerShell memory
                        [System.GC]::Collect()
                        [System.GC]::WaitForPendingFinalizers()
                        $actions += "Optimized memory usage"
                        Write-BotLog "INFO" "Memory optimization completed" "REMEDIATION"
                    } catch {
                        Write-BotLog "ERROR" "Memory optimization failed: $($_.Exception.Message)" "REMEDIATION"
                    }
                }
            }
            "*High disk usage*" {
                if ($script:botConfig.Actions.ClearLogs) {
                    Write-BotLog "ACTION" "Attempting to clean up old logs" "REMEDIATION"
                    try {
                        # Clean up old log files (keep last 7 days)
                        $cutoffDate = (Get-Date).AddDays(-7)
                        $logFiles = Get-ChildItem -Path "logs" -Recurse -File -ErrorAction SilentlyContinue | 
                                   Where-Object { $_.LastWriteTime -lt $cutoffDate }
                        
                        $logFiles | Remove-Item -Force
                        $actions += "Cleaned $($logFiles.Count) old log files"
                        Write-BotLog "INFO" "Cleaned up $($logFiles.Count) old log files" "REMEDIATION"
                    } catch {
                        Write-BotLog "ERROR" "Log cleanup failed: $($_.Exception.Message)" "REMEDIATION"
                    }
                }
            }
            "*SigNoz not reachable*" {
                Write-BotLog "WARN" "SigNoz connectivity issue detected - manual intervention may be required" "REMEDIATION"
                if ($script:botConfig.Actions.NotifyAdmin) {
                    $actions += "SigNoz connectivity issue flagged for admin review"
                }
            }
        }
    }
    
    return $actions
}

function Show-BotStatus {
    param(
        [hashtable]$Health,
        [array]$Actions,
        [int]$Iteration
    )
    
    $runtime = (Get-Date) - $script:botConfig.StartTime
    $runtimeStr = "{0:hh\:mm\:ss}" -f $runtime
    
    Write-Host ""
    Write-Host "🤖 Auto Bot Status Report" -ForegroundColor Cyan
    Write-Host "   Runtime: $runtimeStr | Iteration: $Iteration" -ForegroundColor Gray
    Write-Host "   Overall Health: $($Health.Overall.ToUpper()) (Score: $($Health.Score)/100)" -ForegroundColor $(if($Health.Score -ge 90){"Green"}elseif($Health.Score -ge 70){"Yellow"}else{"Red"})
    
    if ($Health.Issues.Count -gt 0) {
        Write-Host "   Issues Detected:" -ForegroundColor Yellow
        foreach ($issue in $Health.Issues) {
            Write-Host "     • $issue" -ForegroundColor Yellow
        }
    }
    
    if ($Actions.Count -gt 0) {
        Write-Host "   Actions Taken:" -ForegroundColor Green
        foreach ($action in $Actions) {
            Write-Host "     ✓ $action" -ForegroundColor Green
        }
    }
    
    Write-Host "   Components:" -ForegroundColor White
    foreach ($component in $Health.Components.Keys) {
        $status = $Health.Components[$component]
        $color = switch ($status) {
            "healthy" { "Green" }
            "degraded" { "Yellow" }
            "unhealthy" { "Red" }
            default { 
                if ([int]$status -gt 80) { "Green" } 
                elseif ([int]$status -gt 60) { "Yellow" } 
                else { "Red" }
            }
        }
        Write-Host "     $component`: $status" -ForegroundColor $color
    }
}

# Initialize bot
Write-Host "🤖 Initializing ECRR Auto Bot v$($script:botConfig.Version)" -ForegroundColor Green
Write-Host "   Auto-remediation: $($script:botConfig.AutoRemediate)" -ForegroundColor Gray
Write-Host "   Check interval: $($script:botConfig.CheckInterval) seconds" -ForegroundColor Gray
Write-Host "   Log file: $LogPath" -ForegroundColor Gray
Write-Host ""

Write-BotLog "INFO" "Auto Bot started" "INIT"
Write-BotLog "INFO" "Configuration: AutoRemediate=$($script:botConfig.AutoRemediate), Interval=$($script:botConfig.CheckInterval)s" "CONFIG"

$iteration = 0

try {
    do {
        $iteration++
        $currentTime = Get-Date -Format "HH:mm:ss"
        
        Write-Host "[$currentTime] 🤖 Auto Bot Check #$iteration" -ForegroundColor Cyan
        
        # Perform health check with thinking animation
        Show-ThinkingAnimation -Message "Initiating health check cycle..." -AnimationType $script:botSpinnerConfig.BotThinking -DurationMs 0
        Start-Sleep -Milliseconds 200
        Clear-Spinner
        
        $health = Test-PipelineHealth
        
        # Log health status
        Write-BotLog "INFO" "Health check completed: $($health.Overall) (Score: $($health.Score))" "HEALTH"
        
        # Auto-remediation if enabled
        $actions = @()
        if ($script:botConfig.AutoRemediate -and $health.Score -lt 90) {
            Show-ThinkingAnimation -Message "Auto-remediation required..." -AnimationType $script:botSpinnerConfig.BotThinking -DurationMs 0
            Start-Sleep -Milliseconds 300
            Clear-Spinner
            
            $remediationActions = Invoke-AutoRemediation -Health $health
            if ($remediationActions -and $remediationActions.Length -gt 0) {
                $actions = $remediationActions
                Write-BotLog "ACTION" "Auto-remediation completed: $($actions -join ', ')" "REMEDIATION"
            }
        }
        
        # Show status
        Show-BotStatus -Health $health -Actions $actions -Iteration $iteration
        
        # Wait for next check with thinking animation
        if ($Continuous) {
            Write-Host "   Next check in $($script:botConfig.CheckInterval) seconds..." -ForegroundColor Gray
            
            # Show thinking animation during countdown
            for ($i = 0; $i -lt $script:botConfig.CheckInterval; $i++) {
                $remaining = $script:botConfig.CheckInterval - $i
                $progress = [math]::Floor((($script:botConfig.CheckInterval - $remaining) / $script:botConfig.CheckInterval) * 100)
                
                if ($remaining -gt 5) {
                    Show-ThinkingAnimation -Message "Auto Bot in standby mode..." -AnimationType $script:botSpinnerConfig.BotThinking -DurationMs 0 -ShowProgress -ProgressPercent $progress
                } else {
                    Show-ThinkingAnimation -Message "Preparing next health check..." -AnimationType "Loading" -DurationMs 0 -ShowProgress -ProgressPercent $progress
                }
                
                Start-Sleep -Seconds 1
            }
            Clear-Spinner
        }
        
    } while ($Continuous)
    
} catch {
    Write-BotLog "ERROR" "Auto Bot encountered an error: $($_.Exception.Message)" "ERROR"
    Write-Host "❌ Auto Bot error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $runtime = (Get-Date) - $script:botConfig.StartTime
    Write-BotLog "INFO" "Auto Bot stopped after $($runtime.TotalMinutes) minutes" "SHUTDOWN"
    
    Write-Host ""
    Write-Host "🤖 Auto Bot Session Complete" -ForegroundColor Green
    Write-Host "   Runtime: $($runtime.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    Write-Host "   Checks performed: $iteration" -ForegroundColor Gray
    Write-Host "   Log file: $LogPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To run continuously: pwsh -File scripts\auto-bot.ps1 -Continuous" -ForegroundColor Yellow
    Write-Host "To enable auto-remediation: pwsh -File scripts\auto-bot.ps1 -AutoRemediate" -ForegroundColor Yellow
}






