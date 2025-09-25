# Spinner Toolkit - Shared Progress Animation Helpers
# Provides consistent animated indicators for long-running operations across scripts

Set-StrictMode -Version 2

if (-not (Get-Variable -Name SpinnerToolkitState -Scope Script -ErrorAction SilentlyContinue)) {
    $script:SpinnerToolkitState = [ordered]@{
        Frames = @{
            Default   = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
            Bot       = @('[BOT]⠋','[BOT]⠙','[BOT]⠹','[BOT]⠸','[BOT]⠼','[BOT]⠴','[BOT]⠦','[BOT]⠧','[BOT]⠇','[BOT]⠏')
            Analytics = @('[ANL]⠋','[ANL]⠙','[ANL]⠹','[ANL]⠸','[ANL]⠼','[ANL]⠴','[ANL]⠦','[ANL]⠧','[ANL]⠇','[ANL]⠏')
            Network   = @('[NET]⠋','[NET]⠙','[NET]⠹','[NET]⠸','[NET]⠼','[NET]⠴','[NET]⠦','[NET]⠧','[NET]⠇','[NET]⠏')
            Disk      = @('[DSK]⠋','[DSK]⠙','[DSK]⠹','[DSK]⠸','[DSK]⠼','[DSK]⠴','[DSK]⠦','[DSK]⠧','[DSK]⠇','[DSK]⠏')
            Health    = @('[HLT]⠋','[HLT]⠙','[HLT]⠹','[HLT]⠸','[HLT]⠼','[HLT]⠴','[HLT]⠦','[HLT]⠧','[HLT]⠇','[HLT]⠏')
            File      = @('[FIL]⠋','[FIL]⠙','[FIL]⠹','[FIL]⠸','[FIL]⠼','[FIL]⠴','[FIL]⠦','[FIL]⠧','[FIL]⠇','[FIL]⠏')
            Security  = @('[SEC]⠋','[SEC]⠙','[SEC]⠹','[SEC]⠸','[SEC]⠼','[SEC]⠴','[SEC]⠦','[SEC]⠧','[SEC]⠇','[SEC]⠏')
            Processing= @('[PRC]⠋','[PRC]⠙','[PRC]⠹','[PRC]⠸','[PRC]⠼','[PRC]⠴','[PRC]⠦','[PRC]⠧','[PRC]⠇','[PRC]⠏')
            Loading   = @('[LOD]⠋','[LOD]⠙','[LOD]⠹','[LOD]⠸','[LOD]⠼','[LOD]⠴','[LOD]⠦','[LOD]⠧','[LOD]⠇','[LOD]⠏')
        }
        Indices = @{}
        IntervalMs = 120
        ClearWidth = 80
    }
}

function Get-SpinnerFrames {
    param([string]$AnimationType = 'Default')

    if (-not $AnimationType) { $AnimationType = 'Default' }
    $frames = $script:SpinnerToolkitState.Frames[$AnimationType]
    if (-not $frames) { $frames = $script:SpinnerToolkitState.Frames['Default'] }
    return $frames
}

function Get-NextSpinnerFrame {
    param([string]$AnimationType = 'Default')

    $frames = Get-SpinnerFrames -AnimationType $AnimationType
    $index = 0
    if ($script:SpinnerToolkitState.Indices.ContainsKey($AnimationType)) {
        $index = ($script:SpinnerToolkitState.Indices[$AnimationType] + 1) % $frames.Count
    }
    $script:SpinnerToolkitState.Indices[$AnimationType] = $index
    return $frames[$index]
}

function Clear-Spinner {
    $spaces = ' ' * $script:SpinnerToolkitState.ClearWidth
    Write-Host "`r$spaces`r" -NoNewline
}

function Show-ThinkingAnimation {
    param(
        [string]$Message = 'Processing...',
        [string]$AnimationType = 'Default',
        [int]$DurationMs = 150,
        [switch]$ShowProgress,
        [int]$ProgressPercent = 0,
        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    $frame = Get-NextSpinnerFrame -AnimationType $AnimationType
    if ($ShowProgress) {
        $progress = [math]::Max(0, [math]::Min(100, $ProgressPercent))
        $completed = [math]::Floor($progress / 10)
        $bar = '[' + ('█' * $completed) + ('░' * (10 - $completed)) + "] $progress%"
        $text = "${frame} $Message $bar"
    } else {
        $text = "${frame} $Message"
    }

    Write-Host "`r$text" -NoNewline -ForegroundColor $Color
    if ($DurationMs -gt 0) {
        Start-Sleep -Milliseconds $DurationMs
    }
}

function Show-Spinner {
    param(
        [string]$Message = 'Processing...',
        [string]$AnimationType = 'Default',
        [int]$DurationMs = 120
    )

    Show-ThinkingAnimation -Message $Message -AnimationType $AnimationType -DurationMs $DurationMs
}

function Wait-WithSpinner {
    param(
        [int]$Seconds,
        [string]$Message = 'Waiting...',
        [string]$AnimationType = 'Default'
    )

    $totalMs = [math]::Max(1, $Seconds * 1000)
    $interval = $script:SpinnerToolkitState.IntervalMs
    for ($elapsed = 0; $elapsed -lt $totalMs; $elapsed += $interval) {
        $progress = [math]::Round((($elapsed + $interval) / $totalMs) * 100)
        Show-ThinkingAnimation -Message $Message -AnimationType $AnimationType -DurationMs $interval -ShowProgress -ProgressPercent $progress
    }
    Clear-Spinner
    Write-Host "`r✅ $Message complete" -ForegroundColor Green
}

function Show-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Message = 'Processing...',
        [string]$AnimationType = 'Default'
    )

    if ($Total -le 0) { $Total = 1 }
    $progress = [math]::Round(($Current / $Total) * 100)
    Show-ThinkingAnimation -Message $Message -AnimationType $AnimationType -DurationMs 0 -ShowProgress -ProgressPercent $progress
}

function Show-CompletionMessage {
    param(
        [string]$Message = 'Complete!',
        [string]$Details = '',
        [ConsoleColor]$Color = [ConsoleColor]::Green
    )

    Clear-Spinner
    Write-Host "✅ $Message" -ForegroundColor $Color
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor [ConsoleColor]::Gray
    }
}

function Reset-SpinnerState {
    $script:SpinnerToolkitState.Indices.Clear()
}
