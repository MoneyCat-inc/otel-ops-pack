#Requires -Version 7.0

<#
.SYNOPSIS
    Interactive countdown wait with skip/halt controls

.DESCRIPTION
    Provides a visible countdown timer with operator controls:
    - Press 'S' to skip wait and continue immediately
    - Press 'Q' to quit/halt the entire operation
    - Auto-proceeds when countdown reaches 0

.PARAMETER Seconds
    Duration to wait (default: 180 seconds / 3 minutes)

.PARAMETER Message
    Custom message to display during countdown

.OUTPUTS
    Returns:
    - 0 = Completed normally (countdown finished)
    - 1 = Skipped by operator (pressed 'S')
    - 2 = Halted by operator (pressed 'Q')

.EXAMPLE
    $result = .\Wait-WithControl.ps1 -Seconds 180 -Message "Cooling down before next chunk"
    if ($result -eq 2) { 
        Write-Host "Operator halted execution"
        exit 0
    }
#>

param(
    [int]$Seconds = 180,
    [string]$Message = "Cooldown period between chunks"
)

Write-Host "`n⏱️  $Message" -ForegroundColor Cyan
Write-Host "   [S] Skip wait  |  [Q] Quit/Halt  |  Auto-continue in..." -ForegroundColor DarkGray
Write-Host ""

$remaining = $Seconds
$startTime = Get-Date

while ($remaining -gt 0) {
    # Format time display
    $mins = [int][math]::Floor($remaining / 60)
    $secs = [int]($remaining % 60)
    $timeStr = "{0:00}:{1:00}" -f $mins, $secs
    
    # Progress bar (simple visual)
    $pct = ($Seconds - $remaining) / $Seconds
    $progress = [int][math]::Floor($pct * 40)
    $bar = "█" * $progress + "░" * (40 - $progress)
    
    # Display countdown
    Write-Host "`r   $bar  $timeStr  " -NoNewline -ForegroundColor Yellow
    
    # Check for keypress (non-blocking) - only if console is available
    try {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                'S' {
                    Write-Host "`n`n✅ Skipped by operator - continuing immediately...`n" -ForegroundColor Green
                    return 1
                }
                'Q' {
                    Write-Host "`n`n🛑 HALTED by operator - stopping execution...`n" -ForegroundColor Red
                    return 2
                }
            }
        }
    }
    catch {
        # Console not available (redirected stdin) - skip keypress check
    }
    
    Start-Sleep -Milliseconds 1000
    $remaining = $Seconds - [int]((Get-Date) - $startTime).TotalSeconds
}

Write-Host "`n`n✅ Cooldown complete - continuing...`n" -ForegroundColor Green
return 0

