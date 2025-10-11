<#
 .SYNOPSIS
  Standard BossCat progress HUD utilities for PowerShell scripts.

 .DESCRIPTION
  Provides lightweight, terminal-friendly progress with spinner and ETA.
  Use Start-BossCatProgress once, Update-BossCatProgress per phase, and
  Complete-BossCatProgress at the end. All functions degrade gracefully
  if Write-Progress is suppressed in CI logs.

 .USAGE
  Import-Module scripts/lib/BossCat.Progress.psm1
  Start-BossCatProgress -Activity 'GPU_FIX Lane' -ExpectedTotalSeconds 120
  Update-BossCatProgress -Phase 'Preflight' -CompletedSeconds 5
  Complete-BossCatProgress
#>

$script:BCP_Start   = Get-Date
$script:BCP_Activity = 'BossCat'
$script:BCP_Expected = 60
$script:BCP_Spinner  = @('|','/','-','\\')
$script:BCP_SpinIdx  = 0

function Start-BossCatProgress {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string]$Activity,
    [Parameter(Mandatory)] [int]$ExpectedTotalSeconds
  )
  $script:BCP_Start    = Get-Date
  $script:BCP_Activity = $Activity
  $script:BCP_Expected = [Math]::Max(1, $ExpectedTotalSeconds)
}

function Update-BossCatProgress {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)] [string]$Phase,
    [Parameter(Mandatory)] [int]$CompletedSeconds
  )
  try {
    $elapsed = [int]((Get-Date) - $script:BCP_Start).TotalSeconds
    $done    = [int][Math]::Min($CompletedSeconds, $script:BCP_Expected)
    $pct     = [int]([Math]::Min(100, [Math]::Round(($done / [double]$script:BCP_Expected) * 100)))
    $eta     = [int]([Math]::Max(0, $script:BCP_Expected - $elapsed))
    $mins    = [int]($eta / 60); $secs = $eta % 60
    $script:BCP_SpinIdx = ($script:BCP_SpinIdx + 1) % $script:BCP_Spinner.Count
    $spin    = $script:BCP_Spinner[$script:BCP_SpinIdx]
    $status  = "{0} | ETA: {1:D2}m{2:D2}s  {3}" -f $Phase, $mins, $secs, $spin
    Write-Progress -Activity $script:BCP_Activity -Status $status -PercentComplete $pct
  } catch {}
}

function Complete-BossCatProgress {
  [CmdletBinding()] param()
  try { Write-Progress -Activity $script:BCP_Activity -Completed -Status 'Done' } catch {}
}

Export-ModuleMember -Function Start-BossCatProgress, Update-BossCatProgress, Complete-BossCatProgress

