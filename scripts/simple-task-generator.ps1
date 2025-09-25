param(
    [Parameter(Mandatory = $false)]
    [string]$EcrrReportPath = "docs/ECRR_REPORTS",

    [Parameter(Mandatory = $false)]
    [string]$JobsPath = "jobs",

    [Parameter(Mandatory = $false)]
    [int]$MaxTasks = 5,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$AutoAssign
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$automationScript = Join-Path -Path $scriptRoot -ChildPath 'ecrr-task-automation.ps1'

if (-not (Test-Path -Path $automationScript)) {
    throw "Expected automation script not found at $automationScript"
}

$arguments = @{
    EcrrReportPath = $EcrrReportPath
    JobsPath = $JobsPath
    MaxTasks = $MaxTasks
}

if ($DryRun)   { $arguments['DryRun'] = $true }
if ($Force)    { $arguments['Force'] = $true }
if ($AutoAssign) { $arguments['AutoAssign'] = $true }

& $automationScript @arguments
