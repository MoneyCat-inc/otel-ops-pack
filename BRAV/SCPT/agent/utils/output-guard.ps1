# scripts/agent/utils/output-guard.ps1 - Output mode guards for all scripts

param(
    [switch]$Json,
    [switch]$Quiet,
    [switch]$Verbose
)

# Set global output mode flags
$global:OutputMode = @{
    Json = $Json
    Quiet = $Quiet
    Verbose = $Verbose
    ANSI = $false
    Progress = $false
}

# Disable ANSI and progress in JSON/Quiet modes
if ($Json -or $Quiet) {
    $env:NO_COLOR = "1"
    $global:OutputMode.ANSI = $false
    $global:OutputMode.Progress = $false
} else {
    # Check for ANSI support
    $global:OutputMode.ANSI = ($env:WT_SESSION -or $env:TERM -or $Host.UI.SupportsVirtualTerminal) -and -not $env:CI
}

# Export functions for other scripts to use
function Test-OutputMode {
    param([string]$Mode)
    return $global:OutputMode.$Mode
}

function Write-OutputMode {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    if ($global:OutputMode.Json) {
        # In JSON mode, only output JSON - suppress all other output
        return
    }
    
    if ($global:OutputMode.Quiet) {
        # In quiet mode, suppress most output
        return
    }
    
    if ($global:OutputMode.ANSI -and $Color -ne "White") {
        Write-Host $Message -ForegroundColor $Color -NoNewline:($NoNewline.IsPresent)
    } else {
        Write-Host $Message -NoNewline:($NoNewline.IsPresent)
    }
}

function Show-ProgressMode {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$Current,
        [int]$Total,
        [string]$SubStatus = ""
    )
    
    if (-not $global:OutputMode.Progress) {
        return
    }
    
    if ($global:OutputMode.ANSI) {
        # Show fancy progress bar
        $percent = [Math]::Round(($Current / $Total) * 100)
        $blocks = [Math]::Min(40, [Math]::Round(40 * $percent / 100))
        $bar = ("█" * $blocks).PadRight(40)
        $message = "`r$Activity [$bar] $percent%  $Status"
        if ($SubStatus) { $message += " - $SubStatus" }
        Write-Host $message -NoNewline
        if ($percent -ge 100) { Write-Host "" }
    } else {
        # Show simple progress
        $percent = [Math]::Round(($Current / $Total) * 100)
        Write-Host "${Activity}: ${percent}% - ${Status}"
    }
}

# Functions are now available for dot-sourcing
# Usage: . "$PSScriptRoot\utils\output-guard.ps1" -Json:$Json -Quiet:$Quiet
