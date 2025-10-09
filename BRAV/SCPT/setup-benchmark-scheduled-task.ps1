param(
  [string]$TaskName = 'OTel Benchmark ECRR Processor',
  [string]$At = '02:17',
  [int]$ReportCount = 300,
  [int]$Iterations = 3,
  [switch]$IncludeAutoParallel,
  [switch]$KeepSyntheticReports
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repoRoot 'scripts/benchmark-process-all-ecrr-reports.ps1'
if (-not (Test-Path $scriptPath)) {
  Write-Error "Benchmark harness not found at: $scriptPath"
  exit 1
}

try {
  $timeSpan = [TimeSpan]::Parse($At)
} catch {
  Write-Error "Invalid time format for -At. Use HH:mm (e.g., 02:17)."
  exit 1
}

$pwsh = (Get-Command pwsh).Source

$actionArgsList = @(
  '-NoLogo'
  '-NoProfile'
  '-File'
  "`"$scriptPath`""
  '-ReportCount'
  $ReportCount
  '-Iterations'
  $Iterations
)
if ($IncludeAutoParallel.IsPresent) {
  $actionArgsList += '-IncludeAutoParallel'
}
if ($KeepSyntheticReports.IsPresent) {
  $actionArgsList += '-KeepSyntheticReports'
}
$actionArgs = ($actionArgsList | Where-Object { $_ -ne '' }) -join ' '

$action = New-ScheduledTaskAction -Execute $pwsh -Argument $actionArgs -WorkingDirectory $repoRoot

$triggerTime = [datetime]::Today.Add($timeSpan)
$trigger = New-ScheduledTaskTrigger -Daily -At $triggerTime

try {
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Description 'Runs ECRR benchmark harness daily' -Force | Out-Null
  Write-Host "Registered scheduled task '$TaskName' to run daily at $At" -ForegroundColor Green
  return
}
catch {
  Write-Warning 'Failed to register with ScheduledTasks module. Attempting schtasks.exe fallback.'
}

$pwshQuoted = '"' + $pwsh + '"'
$actionCommand = "$pwshQuoted $actionArgs"
$escapedActionCommand = $actionCommand.Replace('"', '\"')
$timeString = $timeSpan.ToString('hh\\:mm')
$taskCmd = "/Create /SC DAILY /TN `"$TaskName`" /TR `"$escapedActionCommand`" /ST $timeString /F /RL HIGHEST"

cmd.exe /c ("schtasks.exe " + $taskCmd) | Out-Host

if ($LASTEXITCODE -ne 0) {
  Write-Error "schtasks.exe registration failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}

Write-Host "Registered scheduled task '$TaskName' to run daily at $At (via schtasks.exe)" -ForegroundColor Green
