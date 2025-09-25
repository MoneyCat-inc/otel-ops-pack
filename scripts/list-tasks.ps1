param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-PropOrNull {
    param(
        [Parameter(Mandatory=$true)]$Object,
        [Parameter(Mandatory=$true)][string]$PropertyName
    )

    if ($null -eq $Object) { return $null }

    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in $Object.Keys) {
            if ($key -is [string] -and $key -ieq $PropertyName) {
                return $Object[$key]
            }
        }
    }

    if ($Object.PSObject) {
        $prop = $Object.PSObject.Properties |
            Where-Object { $_.Name -ieq $PropertyName } |
            Select-Object -First 1
        if ($null -ne $prop) {
            return $prop.Value
        }
    }

    return $null
}

function Read-JsonTasks {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Source
    )
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        return @()
    }

    $tasks = @()
    if ($null -ne $obj) {
        if ($obj.PSObject.Properties.Name -contains 'jobs') { $tasks = $obj.jobs }
        elseif ($obj.PSObject.Properties.Name -contains 'tasks') { $tasks = $obj.tasks }
        elseif ($obj -is [System.Array]) { $tasks = $obj }
        else { $tasks = @($obj) }
    }

    foreach ($t in $tasks) {
        [pscustomobject]@{
            source   = $Source
            id       = Get-PropOrNull -Object $t -PropertyName 'id'
            name     = Get-PropOrNull -Object $t -PropertyName 'name'
            type     = Get-PropOrNull -Object $t -PropertyName 'type'
            status   = Get-PropOrNull -Object $t -PropertyName 'status'
            schedule = Get-PropOrNull -Object $t -PropertyName 'schedule'
            command  = Get-PropOrNull -Object $t -PropertyName 'command'
            severity = Get-PropOrNull -Object $t -PropertyName 'severity'
        }
    }
}

$repoRoot = (Get-Location).Path
$agentQueue = Join-Path $repoRoot '.agent/agent_queue.json'
$codexTasks = Join-Path $repoRoot '.agent/task_queue/codex_tasks.json'

$all = @()
$all += Read-JsonTasks -Path $agentQueue -Source 'agent_queue'
$all += Read-JsonTasks -Path $codexTasks -Source 'codex_tasks'

if ($Json) {
    $all | ConvertTo-Json -Depth 5
    exit 0
}

if (-not $all -or $all.Count -eq 0) {
    Write-Output 'No tasks found.'
    exit 0
}

$all |
  Sort-Object source, status, severity, id |
  Select-Object source, id, name, type, status, schedule, command, severity |
  Format-Table -AutoSize | Out-String -Width 4096 | Write-Output