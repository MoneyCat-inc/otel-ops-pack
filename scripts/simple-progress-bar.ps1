# Simple Progress Bar with Estimated Time Left
# Clean, effective progress indication

param(
    [string]$Message = "Processing...",
    [int]$TotalSeconds = 10,
    [string]$BarStyle = "block"
)

# Progress bar styles
$barStyles = @{
    "block" = @{ filled = "█"; empty = "░" }
    "dash" = @{ filled = "▓"; empty = "▒" }
    "pipe" = @{ filled = "|"; empty = "-" }
    "dot" = @{ filled = "●"; empty = "○" }
    "hash" = @{ filled = "#"; empty = " " }
}

# Get bar style
$style = $barStyles[$BarStyle]
if (-not $style) { $style = $barStyles["block"] }

$filled = $style.filled
$empty = $style.empty

# Animation state
$startTime = Get-Date
$barWidth = 20
$lastUpdate = $startTime

Write-Host "🚀 $Message" -ForegroundColor Cyan
Write-Host "⏱️  Estimated duration: $TotalSeconds seconds" -ForegroundColor Yellow
Write-Host ""

try {
    while ($true) {
        $now = Get-Date
        $elapsed = [math]::Round(($now - $startTime).TotalSeconds, 1)
        
        # Calculate progress
        $progress = [math]::Min(100, [math]::Round(($elapsed / $TotalSeconds) * 100))
        $remaining = [math]::Max(0, $TotalSeconds - $elapsed)
        
        # Create progress bar
        $filledCount = [math]::Floor(($progress / 100) * $barWidth)
        $emptyCount = $barWidth - $filledCount
        $progressBar = ($filled * $filledCount) + ($empty * $emptyCount)
        
        # Update every 100ms for smooth animation
        if (($now - $lastUpdate).TotalMilliseconds -ge 100) {
            Write-Host "`r[$progressBar] $progress% ($elapsed/$TotalSeconds s, ~$remaining s left)" -NoNewline -ForegroundColor Cyan
            $lastUpdate = $now
        }
        
        # Check if completed
        if ($elapsed -ge $TotalSeconds) {
            break
        }
        
        # Small sleep to prevent CPU spinning
        Start-Sleep -Milliseconds 50
    }
} finally {
    # Show completion
    Write-Host "`r[$filled * $barWidth] 100% ($TotalSeconds/$TotalSeconds s, ~0 s left)" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ $Message completed!" -ForegroundColor Green
}

# Export functions for use in other scripts
function Start-ProgressBar {
    param(
        [string]$Message = "Processing...",
        [int]$TotalSeconds = 10,
        [string]$BarStyle = "block"
    )
    
    & $PSCommandPath -Message $Message -TotalSeconds $TotalSeconds -BarStyle $BarStyle
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

# Demo function
function Demo-ProgressBars {
    Write-Host "🎬 Progress Bar Demo" -ForegroundColor Yellow
    Write-Host "=" * 30 -ForegroundColor Gray
    Write-Host ""
    
    $styles = @("block", "dash", "pipe", "dot", "hash")
    
    foreach ($style in $styles) {
        Write-Host "Style: $style" -ForegroundColor White
        Start-ProgressBar -Message "Testing $style style" -TotalSeconds 3 -BarStyle $style
        Write-Host ""
    }
    
    Write-Host "🎉 Demo complete!" -ForegroundColor Green
}
