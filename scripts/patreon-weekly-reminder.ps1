#Requires -Version 7.0
<#
.SYNOPSIS
  Weekly Patreon maintenance reminder for Resonai [OTel].
.DESCRIPTION
  Tracks cadence in artifacts/patreon-maintenance-state.json.
  Agents and humans: run without flags when due; -MarkComplete after the checklist.
#>
[CmdletBinding()]
param(
    [switch]$MarkComplete,
    [switch]$RegisterScheduledTask,
    [switch]$UnregisterScheduledTask,
    [switch]$Notify,
    [int]$CadenceDays = 7,
    [string]$Notes = ''
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$StatePath = Join-Path $RepoRoot 'artifacts/patreon-maintenance-state.json'
$Runbook = 'docs/BossCat/PATREON_WEEKLY_MAINTENANCE.md'
$PatreonUrl = 'https://www.patreon.com/c/FaeMcLachlan'
$TaskName = 'Resonai-Patreon-Weekly-Maintenance'

function Write-Status([string]$Message, [string]$Color = 'Cyan') {
    Write-Host $Message -ForegroundColor $Color
}

function Get-State {
    if (-not (Test-Path $StatePath)) {
        return $null
    }
    Get-Content -Path $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Save-State([object]$State) {
    $dir = Split-Path $StatePath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $State | ConvertTo-Json -Depth 5 | Set-Content -Path $StatePath -Encoding UTF8
}

function Show-Checklist {
    Write-Status "`n=== Patreon weekly maintenance DUE ===" 'Yellow'
    Write-Status "Page: $PatreonUrl"
    Write-Status "Runbook: $Runbook`n"
    Write-Status @'
Checklist (summary):
  [ ] Page published; 3 tiers ($5 / $15 / $50) visible
  [ ] Welcome post free; about + GitHub link current
  [ ] Payouts healthy; patron messages answered
  [ ] README + portal links match live page
  [ ] Mark complete: pwsh -File scripts/patreon-weekly-reminder.ps1 -MarkComplete
'@ 'White'
}

function Show-Toast([string]$Title, [string]$Body) {
    if (-not $Notify) { return }
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop | Out-Null
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $xml = @"
<toast><visual><binding template="ToastText02">
<text id="1">$Title</text>
<text id="2">$Body</text>
</binding></visual></toast>
"@
        $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Resonai OTel').Show($toast)
    } catch {
        Write-Status "(Toast unavailable: $($_.Exception.Message))" 'DarkGray'
    }
}

if ($UnregisterScheduledTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Status "Removed scheduled task: $TaskName" 'Green'
    exit 0
}

if ($RegisterScheduledTask) {
    $scriptPath = Join-Path $RepoRoot 'scripts/patreon-weekly-reminder.ps1'
    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoProfile -File `"$scriptPath`" -Notify"
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At '10:00'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Status "Registered weekly task '$TaskName' (Mondays 10:00, -Notify)." 'Green'
    exit 0
}

$now = [DateTime]::UtcNow
$state = Get-State

if ($MarkComplete) {
    $nextDue = $now.AddDays($CadenceDays)
    $payload = [ordered]@{
        last_completed_utc = $now.ToString('o')
        next_due_utc       = $nextDue.ToString('o')
        cadence_days       = $CadenceDays
        patreon_url        = $PatreonUrl
        runbook            = $Runbook
        notes              = $Notes
    }
    if ($state -and $state.notes -and -not $Notes) {
        $payload.notes = $state.notes
    }
    Save-State $payload
    Write-Status "Patreon maintenance marked complete. Next due: $($nextDue.ToLocalTime().ToString('yyyy-MM-dd HH:mm')) local." 'Green'
    exit 0
}

if (-not $state) {
    Show-Checklist
    Write-Status "`nNo state file yet — first run after publish. Complete checklist, then -MarkComplete." 'DarkYellow'
    exit 2
}

$nextDueRaw = $state.next_due_utc
$nextDueUtc = if ($nextDueRaw -is [datetime]) {
    $nextDueRaw.ToUniversalTime()
} else {
    [datetime]::Parse(
        [string]$nextDueRaw,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::RoundtripKind
    )
}
$daysUntil = ($nextDueUtc - $now).TotalDays

if ($daysUntil -gt 0) {
    Write-Status "Patreon maintenance OK — due in $([math]::Ceiling($daysUntil)) day(s) ($($nextDueUtc.ToLocalTime().ToString('yyyy-MM-dd')))" 'Green'
    if ($state.notes) {
        Write-Status "Last notes: $($state.notes)" 'DarkGray'
    }
    exit 0
}

Show-Checklist
Show-Toast 'Patreon maintenance due' 'Run scripts/patreon-weekly-reminder.ps1 — see docs/BossCat/PATREON_WEEKLY_MAINTENANCE.md'
exit 2
