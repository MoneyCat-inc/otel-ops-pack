# Ultra-Lightweight Waiting Animations
# Minimal compute, maximum visual feedback

param(
    [string]$Message = "Processing...",
    [int]$DurationSeconds = 0,
    [int]$MaxDots = 3,
    [string]$Style = "dots"
)

# Animation characters (minimal set for low compute)
$animations = @{
    "dots" = @(".", "..", "...", "")
    "spinner" = @("|", "/", "-", "\")
    "pulse" = @("●", "○", "●", "○")
    "wave" = @("~", "~", "~", "~")
    "minimal" = @("•", "•", "•", "•")
}

# Duration estimates for common operations (in seconds)
$durationEstimates = @{
    "npm_lint" = 3
    "npm_typecheck" = 2
    "service_check" = 1
    "port_check" = 1
    "api_test" = 2
    "e2e_verification" = 3
    "file_scan" = 2
    "git_operations" = 1
    "docker_operations" = 5
    "signoz_health" = 2
    "otel_restart" = 3
    "data_processing" = 4
    "network_test" = 2
    "default" = 3
}

# Get animation set
$chars = $animations[$Style]
if (-not $chars) { $chars = $animations["dots"] }

# Animation state
$frame = 0
$startTime = Get-Date
$lastUpdate = $startTime

# Function to get duration estimate for operation type
function Get-DurationEstimate {
    param([string]$operationType)
    
    if ($durationEstimates.ContainsKey($operationType)) {
        return $durationEstimates[$operationType]
    }
    return $durationEstimates["default"]
}

# Function to show current frame with better progress indication
function Show-Frame {
    param([string]$msg, [int]$frameIndex)
    
    $char = $chars[$frameIndex % $chars.Length]
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    
    if ($DurationSeconds -gt 0) {
        $progress = [math]::Round(($elapsed / $DurationSeconds) * 100)
        $remaining = [math]::Max(0, $DurationSeconds - $elapsed)
        $progressBar = "█" * [math]::Floor($progress / 10) + "░" * (10 - [math]::Floor($progress / 10))
        Write-Host "`r$char $msg [$progressBar] $progress% ($elapsed/$DurationSeconds s, ~$remaining s left)" -NoNewline -ForegroundColor Cyan
    } else {
        Write-Host "`r$char $msg ($elapsed s)" -NoNewline -ForegroundColor Cyan
    }
}

# Main animation loop
try {
    while ($true) {
        $now = Get-Date
        
        # Update every 200ms for smooth animation
        if (($now - $lastUpdate).TotalMilliseconds -ge 200) {
            Show-Frame -msg $Message -frameIndex $frame
            $frame++
            $lastUpdate = $now
        }
        
        # Check if duration reached
        if ($DurationSeconds -gt 0 -and (($now - $startTime).TotalSeconds -ge $DurationSeconds)) {
            break
        }
        
        # Small sleep to prevent CPU spinning
        Start-Sleep -Milliseconds 50
    }
} finally {
    # Clear the line and show completion
    Write-Host "`r✅ $Message completed!                    " -ForegroundColor Green
}

# Export functions for use in other scripts
function Start-WaitingAnimation {
    param(
        [string]$Message = "Processing...",
        [int]$DurationSeconds = 0,
        [string]$Style = "dots",
        [string]$OperationType = "default"
    )
    
    # Auto-estimate duration if not provided
    if ($DurationSeconds -eq 0) {
        $DurationSeconds = Get-DurationEstimate -operationType $OperationType
    }
    
    & $PSCommandPath -Message $Message -DurationSeconds $DurationSeconds -Style $Style
}

function Start-SmartAnimation {
    param(
        [string]$Message = "Processing...",
        [string]$OperationType = "default",
        [string]$Style = "dots"
    )
    
    $estimatedDuration = Get-DurationEstimate -operationType $OperationType
    Write-Host "⏱️  Estimated duration: $estimatedDuration seconds" -ForegroundColor Yellow
    Start-WaitingAnimation -Message $Message -DurationSeconds $estimatedDuration -Style $Style
}

function Show-QuickProgress {
    param(
        [string]$Message = "Working...",
        [int]$TotalSteps = 10,
        [int]$CurrentStep = 0
    )
    
    $progress = [math]::Round(($CurrentStep / $TotalSteps) * 100)
    $bar = "█" * [math]::Floor($progress / 10)
    $space = "░" * (10 - [math]::Floor($progress / 10))
    
    Write-Host "`r$Message [$bar$space] $progress%" -NoNewline -ForegroundColor Cyan
}

function Show-Spinner {
    param(
        [string]$Message = "Loading...",
        [int]$DurationSeconds = 5
    )
    
    & $PSCommandPath -Message $Message -DurationSeconds $DurationSeconds -Style "spinner"
}

# Quick demo function
function Demo-Animations {
    Write-Host "🎬 Animation Demo - Ultra Lightweight" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Dots animation (3 seconds):" -ForegroundColor White
    Start-WaitingAnimation -Message "Processing data" -DurationSeconds 3 -Style "dots"
    
    Write-Host "`nSpinner animation (2 seconds):" -ForegroundColor White
    Start-WaitingAnimation -Message "Connecting to server" -DurationSeconds 2 -Style "spinner"
    
    Write-Host "`nProgress bar demo:" -ForegroundColor White
    for ($i = 0; $i -le 10; $i++) {
        Show-QuickProgress -Message "Installing components" -TotalSteps 10 -CurrentStep $i
        Start-Sleep -Milliseconds 300
    }
    Write-Host "`r✅ Installation completed! [████████████] 100%" -ForegroundColor Green
    
    Write-Host "`n🎉 Demo complete!" -ForegroundColor Yellow
}
