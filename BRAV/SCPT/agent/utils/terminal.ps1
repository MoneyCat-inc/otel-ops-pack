# utils/terminal.ps1 - Terminal-aware rendering utilities

function Supports-Ansi {
    return ($env:WT_SESSION -or $env:TERM -or $Host.UI.SupportsVirtualTerminal) -and -not $env:CI
}

function Initialize-TerminalCleanup {
    $script:cleanup = {
        if (Supports-Ansi) { 
            Write-Host "`e[?25h" -NoNewline  # show cursor
            Write-Host "`e[0m" -NoNewline    # reset colors
        }
    }
    
    # Register cleanup on PowerShell exit
    try {
        Register-EngineEvent PowerShell.Exiting -Action $script:cleanup | Out-Null
    } catch {
        # Fallback for older PowerShell versions
        $null = $script:cleanup
    }
    
    # Set trap for script termination
    trap { & $script:cleanup; throw }
}

function Write-ProgressBar {
    param(
        [string]$Title,
        [int]$Percent,
        [double]$EtaSecs,
        [string]$Status = ""
    )
    
    if (-not (Supports-Ansi)) {
        $statusText = if ($Status) { " - $Status" } else { "" }
        Write-Host ("{0} {1,3}% (~{2:N1}s){3}" -f $Title, $Percent, $EtaSecs, $statusText)
        return
    }
    
    $blocks = [Math]::Min(40, [Math]::Round(40 * $Percent / 100))
    $bar = ("█" * $blocks).PadRight(40)
    $statusText = if ($Status) { " - $Status" } else { "" }
    
    $message = "`r$Title [$bar] $Percent%  ETA: {0:N1}s{1}" -f $EtaSecs, $statusText
    Write-Host $message -NoNewline
    
    if ($Percent -ge 100) { 
        Write-Host ""
    }
}

function Write-Spinner {
    param(
        [string]$Message,
        [int]$Index = 0
    )
    
    if (-not (Supports-Ansi)) {
        Write-Host "$Message..."
        return
    }
    
    $spinners = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $spinner = $spinners[$Index % $spinners.Count]
    
    Write-Host "`r$spinner $Message" -NoNewline
}

function Get-ColorCode {
    param([string]$Color)
    
    if (-not (Supports-Ansi)) { return "" }
    
    $colors = @{
        'red'    = '`e[31m'
        'green'  = '`e[32m'
        'yellow' = '`e[33m'
        'blue'   = '`e[34m'
        'cyan'   = '`e[36m'
        'white'  = '`e[37m'
        'gray'   = '`e[90m'
        'reset'  = '`e[0m'
    }
    
    return $colors[$Color] ?? $colors['reset']
}

function Write-Colored {
    param(
        [string]$Message,
        [string]$Color = 'reset'
    )
    
    if (Supports-Ansi) {
        Write-Host "$(Get-ColorCode $Color)$Message$(Get-ColorCode 'reset')"
    } else {
        Write-Host $Message
    }
}
