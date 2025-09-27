# Quick Demo of Waiting Animations
# Shows all animation styles and use cases

param(
    [switch]$All = $false,
    [string]$Style = "dots"
)

# Import animation functions
. "$PSScriptRoot/waiting-animations.ps1"

Write-Host "🎬 Waiting Animation Demo" -ForegroundColor Yellow
Write-Host "=" * 40 -ForegroundColor Gray
Write-Host ""

if ($All) {
    Write-Host "🎭 All Animation Styles:" -ForegroundColor Cyan
    Write-Host ""
    
    $styles = @("dots", "spinner", "pulse", "wave", "minimal")
    foreach ($style in $styles) {
        Write-Host "Style: $style" -ForegroundColor White
        Start-WaitingAnimation -Message "Testing $style animation" -DurationSeconds 2 -Style $style
        Write-Host ""
    }
} else {
    Write-Host "🎯 Single Style Demo: $Style" -ForegroundColor Cyan
    Write-Host ""
    
    # Show different use cases
    Write-Host "1. Short operation (2 seconds):" -ForegroundColor White
    Start-WaitingAnimation -Message "Quick task" -DurationSeconds 2 -Style $Style
    Write-Host ""
    
    Write-Host "2. Medium operation (4 seconds):" -ForegroundColor White
    Start-WaitingAnimation -Message "Processing data" -DurationSeconds 4 -Style $Style
    Write-Host ""
    
    Write-Host "3. Progress bar simulation:" -ForegroundColor White
    for ($i = 0; $i -le 10; $i++) {
        Show-QuickProgress -Message "Installing components" -TotalSteps 10 -CurrentStep $i
        Start-Sleep -Milliseconds 200
    }
    Write-Host "`r✅ Installation completed! [████████████] 100%" -ForegroundColor Green
    Write-Host ""
}

Write-Host "💡 Usage Examples:" -ForegroundColor Cyan
Write-Host "   pwsh -File scripts/demo-animations.ps1 -All" -ForegroundColor Gray
Write-Host "   pwsh -File scripts/demo-animations.ps1 -Style spinner" -ForegroundColor Gray
Write-Host "   pwsh -File scripts/verify-wiring-with-animations.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 Demo complete!" -ForegroundColor Green
