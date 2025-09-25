# Thinking Animations Utility
# Wraps spinner-toolkit helpers to provide interactive demos and CLI usage

param(
    [string]$AnimationType = 'Default',
    [string]$Message = 'Processing...',
    [int]$DurationSeconds = 5,
    [switch]$ShowProgress,
    [switch]$Test
)

Set-StrictMode -Version 2

$toolkitPath = Join-Path $PSScriptRoot 'spinner-toolkit.ps1'
if (-not (Test-Path $toolkitPath)) {
    throw "Spinner toolkit not found at $toolkitPath"
}
. $toolkitPath

$aliasMap = @{
    Thinking = 'Default'
    Loading  = 'Loading'
    Processing = 'Processing'
    Analytics = 'Analytics'
    Bot = 'Bot'
    Health = 'Health'
    File = 'File'
    Security = 'Security'
    Network = 'Network'
    Disk = 'Disk'
}

function Resolve-AnimationType {
    param([string]$Name)

    if (-not $Name) { return 'Default' }
    if ($aliasMap.ContainsKey($Name)) { return $aliasMap[$Name] }
    if ($SpinnerToolkitState.Frames.ContainsKey($Name)) { return $Name }
    Write-Warning "Unknown animation type '$Name'. Falling back to 'Default'."
    return 'Default'
}

function Start-ThinkingSession {
    param(
        [string]$Message = 'Processing...',
        [string]$AnimationType = 'Default',
        [int]$DurationSeconds = 5,
        [switch]$ShowProgress
    )

    Write-Host "Starting thinking session: $Message" -ForegroundColor Green
    $end = (Get-Date).AddSeconds($DurationSeconds)
    $start = Get-Date

    while ((Get-Date) -lt $end) {
        $elapsed = ((Get-Date) - $start).TotalSeconds
        $progress = if ($ShowProgress) { [math]::Round(($elapsed / $DurationSeconds) * 100) } else { 0 }
        Show-ThinkingAnimation -Message $Message -AnimationType $AnimationType -DurationMs 140 -ShowProgress:$ShowProgress -ProgressPercent $progress
    }

    Clear-Spinner
    Write-Host '✅ Thinking session completed!' -ForegroundColor Green
}

function Test-AllAnimations {
    Write-Host 'Testing animation sets' -ForegroundColor Green
    foreach ($key in $SpinnerToolkitState.Frames.Keys) {
        Write-Host " - $key" -ForegroundColor Yellow
        Start-ThinkingSession -Message "Testing $key" -AnimationType $key -DurationSeconds 2 -ShowProgress
        Start-Sleep -Milliseconds 200
    }
    Write-Host '✅ Animation smoke-test complete' -ForegroundColor Green
}

function Show-AnimationTypes {
    Write-Host 'Available animation types:' -ForegroundColor Cyan
    foreach ($key in $SpinnerToolkitState.Frames.Keys) {
        Write-Host "  - $key" -ForegroundColor White
    }
}

$resolvedType = Resolve-AnimationType -Name $AnimationType

if ($Test) {
    Test-AllAnimations
    return
}

if ($DurationSeconds -le 0) {
    Show-ThinkingAnimation -Message $Message -AnimationType $resolvedType -DurationMs 0 -ShowProgress:$ShowProgress
    Clear-Spinner
} else {
    Start-ThinkingSession -Message $Message -AnimationType $resolvedType -DurationSeconds $DurationSeconds -ShowProgress:$ShowProgress
}
