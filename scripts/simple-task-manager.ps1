param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('List','Status','Assign','Start','Complete','Summary','Help')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [string]$Assignee,

    [Parameter(Mandatory = $false)]
    [string]$Category,

    [Parameter(Mandatory = $false)]
    [string]$Priority,

    [Parameter(Mandatory = $false)]
    [string]$JobsPath = "jobs"
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerScript = Join-Path -Path $scriptRoot -ChildPath 'manage-tasks.ps1'

if (-not (Test-Path -Path $managerScript)) {
    throw "Expected manager script not found at $managerScript"
}

$arguments = @{
    Action = $Action
    JobsPath = $JobsPath
}

if ($TaskId)   { $arguments['TaskId'] = $TaskId }
if ($Assignee) { $arguments['Assignee'] = $Assignee }
if ($Category) { $arguments['Category'] = $Category }
if ($Priority) { $arguments['Priority'] = $Priority }

& $managerScript @arguments
