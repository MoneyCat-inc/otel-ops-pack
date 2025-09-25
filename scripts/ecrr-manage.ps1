# ECRR Lifecycle Management Script
# Automates review -> work -> archive stages with ledger + index upkeep

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Review','Start','Resolve','Archive','RegenerateIndex','RegenerateLedger','RegenerateAll','Status','Help')]
    [string]$Action,

    [string]$Report,
    [string]$Assign,
    [string]$Priority = 'medium',
    [string]$Notes,
    [string]$Resolution,
    [string]$Session,
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$repoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ecrrRoot   = Join-Path $repoRoot 'docs/ECRR_REPORTS'
$badgesDir  = Join-Path $repoRoot 'docs/assets/badges'
$reviewDir  = Join-Path $ecrrRoot 'reviewed'
$workingDir = Join-Path $ecrrRoot 'working'
$archiveDir = Join-Path $ecrrRoot 'archive'
$ledgerFile = Join-Path $ecrrRoot 'ledger.json'
$ledgerMd   = Join-Path $workingDir 'LEDGER.md'
$indexFile  = Join-Path $ecrrRoot 'INDEX.md'

function Write-EcrrLog {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        default   { 'Cyan' }
    }
    Write-Host "[$stamp] [$Level] $Message" -ForegroundColor $color
}

function Ensure-EcrrDirectories {
    foreach ($path in @($ecrrRoot,$badgesDir,$reviewDir,$workingDir,$archiveDir)) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    if (-not (Test-Path $ledgerFile)) {
        '[]' | Set-Content -Path $ledgerFile -Encoding UTF8
    }
    if (-not (Test-Path $ledgerMd)) {
        '# ECRR Working Ledger' | Set-Content -Path $ledgerMd -Encoding UTF8
    }
}

function New-LedgerList {
    return @()
}

function Clone-Ledger {
    param($Entries)
    $clone = @()
    foreach ($entry in $Entries) {
        if ($null -ne $entry) { $clone += ($entry | Select-Object *) }
    }
    return $clone
}

function Find-ReportPath {
    param(
        [string]$ReportName,
        [string[]]$SearchOrder = @($ecrrRoot,$reviewDir,$workingDir,$archiveDir)
    )
    foreach ($base in $SearchOrder) {
        $candidate = Join-Path $base $ReportName
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

function Get-ReportTitle {
    param([string]$FullPath)
    if (-not (Test-Path $FullPath)) { return ([System.IO.Path]::GetFileNameWithoutExtension($FullPath)) }
    $heading = Get-Content -Path $FullPath -TotalCount 40 | Where-Object { $_ -match '^# ' } | Select-Object -First 1
    if ($heading) { return ($heading -replace '^#\s*','').Trim() }
    return ([System.IO.Path]::GetFileNameWithoutExtension($FullPath))
}

function Get-RelativeReportPath {
    param([string]$FullPath)
    $relative = [System.IO.Path]::GetRelativePath($ecrrRoot, $FullPath)
    return $relative.Replace('\\','/')
}

function Normalize-LedgerEntry {
    param($Item)
    $entry = [pscustomobject]@{
        report    = $Item.report
        title     = $Item.title
        status    = $Item.status
        assigned  = $Item.assigned
        priority  = $Item.priority
        created   = $Item.created
        started   = $Item.started
        completed = $Item.completed
        notes     = $Item.notes
        resolution= $Item.resolution
        session   = $Item.session
    }
    if (-not $entry.report) { $entry.report = 'unknown.md' }
    if (-not $entry.priority) { $entry.priority = 'medium' }
    if (-not $entry.status) { $entry.status = 'Outstanding' }
    if (-not $entry.created) { $entry.created = Get-Date -Format 'yyyy-MM-dd HH:mm:ss' }
    foreach ($prop in @('title','assigned','started','completed','notes','resolution','session')) {
        if (-not $entry.$prop) { $entry.$prop = '' }
    }
    if (-not $entry.title) {
        $path = Find-ReportPath $entry.report
        $entry.title = if ($path) { Get-ReportTitle $path } else { [System.IO.Path]::GetFileNameWithoutExtension($entry.report) }
    }
    return $entry
}

function Convert-LegacyEntry {
    param($Legacy)
    $details = $Legacy.details
    $entry = [pscustomobject]@{
        report    = $Legacy.report
        title     = $details.title
        status    = 'Outstanding'
        assigned  = $details.assigned
        priority  = $details.priority
        created   = $Legacy.timestamp
        started   = ''
        completed = ''
        notes     = $details.notes
        resolution= $details.resolution
        session   = $details.sessionId
    }
    switch ($Legacy.action) {
        'review'  { $entry.status = 'Outstanding' }
        'start'   { $entry.status = 'In Progress'; $entry.started = $Legacy.timestamp }
        'resolve' { $entry.status = 'Archived'; $entry.completed = $Legacy.timestamp; if (-not $entry.resolution) { $entry.resolution = 'resolved' } }
        'archive' { $entry.status = 'Archived'; $entry.completed = $Legacy.timestamp; if (-not $entry.resolution) { $entry.resolution = 'archived' } }
    }
    return Normalize-LedgerEntry $entry
}

function Load-Ledger {
    # Read and normalize the JSON ledger. Supports:
    # - Empty/missing file → empty list
    # - Single object (PSCustomObject) → list with one entry
    # - Array of objects → list
    # - Legacy entries with "action" property → converted
    Write-EcrrLog "Load-Ledger: starting (file=$ledgerFile)" 'INFO'
    if (-not (Test-Path $ledgerFile)) { Write-EcrrLog 'Load-Ledger: ledger file missing; returning empty list' 'WARN'; return New-LedgerList }
    $raw = Get-Content -Path $ledgerFile -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { Write-EcrrLog 'Load-Ledger: empty file; returning empty list' 'WARN'; return New-LedgerList }
    $parsed = $null
    try {
        $parsed = $raw | ConvertFrom-Json
    } catch {
        Write-EcrrLog "Invalid JSON in ledger: $ledgerFile" 'WARN'
        return New-LedgerList
    }
    Write-EcrrLog ("Load-Ledger: parsed type=" + ($parsed.GetType().FullName)) 'INFO'
    # Build result using a plain PowerShell array to avoid .Add() null-method issues in some hosts
    $list = @()
    if ($null -eq $parsed) { return $list }

    $items = @()
    if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string]) -and -not ($parsed -is [System.Management.Automation.PSCustomObject])) {
        foreach ($it in $parsed) { $items += $it }
    } else {
        # Single object (PSCustomObject) or primitive → wrap
        $items += $parsed
    }

    foreach ($it in $items) {
        if ($null -eq $it) { continue }
        try {
            $hasAction = $false
            try { $hasAction = $it.PSObject.Properties['action'] -ne $null } catch { $hasAction = $false }
            $normalized = if ($hasAction) { Convert-LegacyEntry $it } else { Normalize-LedgerEntry $it }
            $list += ,$normalized
        } catch {
            Write-EcrrLog ("Load-Ledger: failed to normalize entry; skipping") 'WARN'
        }
    }
    Write-EcrrLog ("Load-Ledger: loaded entries=" + ($list | Measure-Object | Select-Object -ExpandProperty Count)) 'INFO'
    return $list
}

function Save-Ledger {
    param($Entries)
    # Always persist as a JSON array to avoid PSCustomObject collapse on next load
    $arr = @()
    foreach ($e in $Entries) { $arr += $e }
    $json = $arr | ConvertTo-Json -Depth 6
    Set-Content -Path $ledgerFile -Value $json -Encoding UTF8
    Write-EcrrLog 'Ledger saved' 'SUCCESS'
}
function Upsert-LedgerEntry {
    param(
        $Entries,
        [string]$ReportName,
        [hashtable]$Updates,
        [string]$DefaultStatus = 'Outstanding'
    )
    # Coerce to a PowerShell array to support addition and indexing
    $list = @()
    if ($null -ne $Entries) { $list += $Entries }
    $existingIndex = -1
    for ($i = 0; $i -lt $list.Count; $i++) {
        if ($list[$i].report -eq $ReportName) { $existingIndex = $i; break }
    }
    if ($existingIndex -lt 0) {
        $path = Find-ReportPath $ReportName
        $title = if ($path) { Get-ReportTitle $path } else { [System.IO.Path]::GetFileNameWithoutExtension($ReportName) }
        $newEntry = Normalize-LedgerEntry ([pscustomobject]@{
            report    = $ReportName
            title     = $title
            status    = $DefaultStatus
            assigned  = ''
            priority  = 'medium'
            created   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            started   = ''
            completed = ''
            notes     = ''
            resolution= ''
            session   = ''
        })
        $list += ,$newEntry
        $existingIndex = $list.Count - 1
    }
    $entry = $list[$existingIndex]
    foreach ($key in $Updates.Keys) {
        $value = $Updates[$key]
        if ($entry.PSObject.Properties[$key]) {
            $entry.$key = $value
        } else {
            $entry | Add-Member -NotePropertyName $key -Value $value -Force
        }
    }
    if (-not $entry.title) {
        $path = Find-ReportPath $ReportName
        $entry.title = if ($path) { Get-ReportTitle $path } else { [System.IO.Path]::GetFileNameWithoutExtension($ReportName) }
    }
    return $list
}

function Format-DateForDisplay {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return '-' }
    try { return ([datetime]::Parse($Raw)).ToString('yyyy-MM-dd HH:mm') } catch { return $Raw }
}

function Build-LedgerMarkdown {
    param($Entries)
    $snapshot = Clone-Ledger $Entries
    $lines = @()
    $lines += '# ECRR Working Ledger'
    $lines += ''
    $lines += '> Auto-generated ledger tracking reports through review, work, and archive stages.'
    $lines += ''
    $sections = @(
        @{ Title = 'Outstanding'; Summary = 'Reports awaiting review or initial triage.'; Filter = 'Outstanding' },
        @{ Title = 'In Progress'; Summary = 'Reports currently being worked on.'; Filter = 'In Progress' },
        @{ Title = 'Archived'; Summary = 'Reports resolved or archived.'; Filter = 'Archived' }
    )
    foreach ($section in $sections) {
        $lines += "## $($section.Title)"
        $lines += ''
        $lines += $section.Summary
        $lines += ''
        $lines += '| Report | Status | Assigned | Priority | Timestamp | Notes |'
        $lines += '|--------|--------|----------|----------|-----------|-------|'
        $rows = $snapshot | Where-Object { $_.status -eq $section.Filter } |
            Sort-Object {
                try {
                    if ($section.Filter -eq 'In Progress' -and $_.started) { [datetime]::Parse($_.started) }
                    elseif ($section.Filter -eq 'Archived' -and $_.completed) { [datetime]::Parse($_.completed) }
                    else { [datetime]::Parse($_.created) }
                } catch { Get-Date '1900-01-01' }
            } -Descending
        if (-not $rows -or $rows.Count -eq 0) {
            $lines += '| *No entries* | - | - | - | - | - |'
        } else {
            foreach ($row in $rows) {
                $timestampRaw = $row.created
                if ($section.Filter -eq 'In Progress' -and $row.started) { $timestampRaw = $row.started }
                elseif ($section.Filter -eq 'Archived' -and $row.completed) { $timestampRaw = $row.completed }
                $timestamp = Format-DateForDisplay $timestampRaw
                $assigned = if ($row.assigned) { $row.assigned } else { '-' }
                $priority = if ($row.priority) { $row.priority } else { 'medium' }
                $notes    = if ($row.notes) { $row.notes } else { '-' }
                $lines += "| $($row.report) | $($row.status) | $assigned | $priority | $timestamp | $notes |"
            }
        }
        $lines += ''
    }
    $lines += '---'
    $lines += "Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
    $lines += 'Generated by scripts/ecrr-manage.ps1'
    Set-Content -Path $ledgerMd -Value $lines -Encoding UTF8
    Write-EcrrLog 'Ledger markdown updated' 'SUCCESS'
}

function Classify-StatusKey {
    param(
        [string]$FullPath,
        $Entries
    )
    $snapshot = Clone-Ledger $Entries
    if ([string]::IsNullOrWhiteSpace($FullPath)) { return 'open' }
    $statusKey = 'open'
    if ($FullPath.StartsWith($workingDir, [System.StringComparison]::OrdinalIgnoreCase)) { $statusKey = 'not-working' }
    elseif ($FullPath.StartsWith($reviewDir, [System.StringComparison]::OrdinalIgnoreCase)) { $statusKey = 'reviewed' }
    elseif ($FullPath.StartsWith($archiveDir, [System.StringComparison]::OrdinalIgnoreCase)) { $statusKey = 'resolved' }
    $reportName = [System.IO.Path]::GetFileName($FullPath)
    $entry = $snapshot | Where-Object { $_.report -eq $reportName } | Select-Object -First 1
    if ($entry) {
        switch ($entry.status) {
            'Outstanding' { $statusKey = 'open' }
            'In Progress' { $statusKey = 'not-working' }
            'Archived'    { $statusKey = 'resolved' }
        }
    }
    return $statusKey
}

function Build-Index {
    param($Entries)
    $snapshot = Clone-Ledger $Entries
    Write-EcrrLog 'Regenerating ECRR index' 'INFO'
    $reports = Get-ChildItem -Path $ecrrRoot -Filter '*.md' -Recurse |
        Where-Object { $_.Name -notin @('INDEX.md','README.md','LATEST.md','PROCESS.md','LEDGER.md') }
    $compiled = foreach ($item in $reports) {
        $statusKey = Classify-StatusKey -FullPath $item.FullName -Entries $snapshot
        [pscustomobject]@{
            StatusKey = $statusKey
            Title = Get-ReportTitle $item.FullName
            RelativePath = Get-RelativeReportPath $item.FullName
            DateValue = $item.LastWriteTimeUtc
        }
    }
    $statusOrder = @('open','reviewed','not-working','resolved')
    $statusLabels = @{ 'open' = 'Open'; 'reviewed' = 'Reviewed'; 'not-working' = 'Not Working'; 'resolved' = 'Resolved' }
    $statusBadges = @{ 'open' = 'open.svg'; 'reviewed' = 'reviewed.svg'; 'not-working' = 'not-working.svg'; 'resolved' = 'resolved.svg' }
    $counts = @{ 'open' = 0; 'reviewed' = 0; 'not-working' = 0; 'resolved' = 0 }
    foreach ($entry in $compiled) { $counts[$entry.StatusKey]++ }
    $indexLines = @()
    $indexLines += '# ECRR Reports Index'
    $indexLines += ''
    $indexLines += '> Status-sorted directory of ECRR reports with local badges in `docs/assets/badges`. Use this list to triage follow-ups quickly.'
    $indexLines += ''
    $indexLines += '## Status Overview'
    $indexLines += ''
    $indexLines += '| Status | Badge | Count |'
    $indexLines += '|--------|-------|-------|'
    foreach ($key in $statusOrder) {
        $label = $statusLabels[$key]
        $badge = $statusBadges[$key]
        $indexLines += "| $label | ![$label](../assets/badges/$badge) | $($counts[$key]) |"
    }
    foreach ($key in $statusOrder) {
        $label = $statusLabels[$key]
        $badge = $statusBadges[$key]
        $indexLines += ''
        $indexLines += "## $label"
        $indexLines += ''
        $indexLines += "![$label](../assets/badges/$badge)"
        $indexLines += ''
        $items = $compiled | Where-Object { $_.StatusKey -eq $key } | Sort-Object DateValue -Descending
        if (-not $items -or $items.Count -eq 0) {
            $indexLines += '- _No reports currently categorized here._'
        } else {
            foreach ($entry in $items) {
                $stamp = $entry.DateValue.ToString('yyyy-MM-dd HH:mm')
                $indexLines += "- [$($entry.Title)](./$($entry.RelativePath)) — $stamp"
            }
        }
    }
    $indexLines += ''
    $indexLines += '## Chronological Index'
    $indexLines += ''
    $indexLines += '| Date | Status | Badge | Report |'
    $indexLines += '|------|--------|-------|--------|'
    foreach ($entry in ($compiled | Sort-Object DateValue -Descending)) {
        $label = $statusLabels[$entry.StatusKey]
        $badge = $statusBadges[$entry.StatusKey]
        $stamp = $entry.DateValue.ToString('yyyy-MM-dd HH:mm')
        $indexLines += "| $stamp | $label | ![$label](../assets/badges/$badge) | [$($entry.Title)](./$($entry.RelativePath)) |"
    }
    $indexLines += ''
    $indexLines += '> Generated automatically by scripts/ecrr-manage.ps1 based on directory placement and ledger status.'
    Set-Content -Path $indexFile -Value $indexLines -Encoding UTF8
    Write-EcrrLog 'Index regenerated' 'SUCCESS'
}

function Add-WorkFooter {
    param(
        [string]$FullPath,
        [string]$SessionId,
        [string]$Owner,
        [string]$PriorityInfo
    )
    $content = Get-Content -Path $FullPath -Raw
    $content = [regex]::Replace($content, "(?s)---\r?\n## Work Session \(Active\).*?\*ECRR or it didn't happen\.\*\r?\n?", '')
    if (-not $content.EndsWith("`n")) { $content += "`n" }
    $footer = @"
---
## Work Session (Active)

* Session ID: $SessionId
* Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
* Owner: $Owner
* Priority: $PriorityInfo

Next Steps:
- Complete the ECRR methodology (Examine -> Clean -> Report -> Role)
- Capture progress notes as the session evolves
- Gather evidence artifacts before resolution

*ECRR or it didn't happen.*
"@
    $content += "$footer`n"
    Set-Content -Path $FullPath -Value $content -Encoding UTF8
    Write-EcrrLog "Work session footer updated for $FullPath" 'SUCCESS'
}

function Add-ResolutionFooter {
    param(
        [string]$FullPath,
        [string]$ResolutionSummary,
        [string]$NotesText
    )
    $content = Get-Content -Path $FullPath -Raw
    if (-not $content.EndsWith("`n")) { $content += "`n" }
    $footer = @"
---
## Resolution Summary

* Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
* Outcome: $ResolutionSummary
* Notes: $NotesText

*Report archived by scripts/ecrr-manage.ps1.*
"@
    $content += "$footer`n"
    Set-Content -Path $FullPath -Value $content -Encoding UTF8
    Write-EcrrLog "Resolution footer appended to $FullPath" 'SUCCESS'
}

function Invoke-ReviewAction {
    param($Entries)
    $list = $Entries
    if (-not $Report -and -not $All) {
        throw "Review action requires -Report <file.md> or -All"
    }
    $targets = @()
    if ($All) {
        $targets = Get-ChildItem -Path $ecrrRoot -Filter '*.md' |
            Where-Object { $_.DirectoryName -eq $ecrrRoot }
    } else {
        $path = Find-ReportPath $Report @($ecrrRoot,$reviewDir,$workingDir,$archiveDir)
        if (-not $path) { throw "Report not found: $Report" }
        $targets = ,(Get-Item $path)
    }
    foreach ($item in $targets) {
        $name = $item.Name
        $sourcePath = $item.FullName
        if ($sourcePath.StartsWith($reviewDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-EcrrLog "Already in reviewed directory: $name" 'WARN'
        } elseif ($sourcePath.StartsWith($workingDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-EcrrLog "Report currently in working; cannot review without resetting: $name" 'WARN'
            continue
        } elseif ($sourcePath.StartsWith($archiveDir, [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-EcrrLog "Report already archived: $name" 'WARN'
            continue
        } else {
            $destination = Join-Path $reviewDir $name
            Move-Item -Path $sourcePath -Destination $destination -Force
            Write-EcrrLog "Moved to reviewed: $name" 'SUCCESS'
        }
        $updates = @{
            status   = 'Outstanding'
            assigned = if ($Assign) { $Assign } else { '' }
            priority = if ($Priority) { $Priority } else { 'medium' }
            notes    = if ($Notes) { $Notes } else { 'Initial review recorded' }
        }
        $list = Upsert-LedgerEntry -Entries $list -ReportName $name -Updates $updates -DefaultStatus 'Outstanding'
    }
    return $list
}

function Invoke-StartAction {
    param($Entries)
    $list = $Entries
    if (-not $Report) { throw 'Start action requires -Report <file.md>' }
    $sourcePath = Find-ReportPath $Report @($reviewDir,$ecrrRoot,$workingDir)
    if (-not $sourcePath) { throw "Report not found for start: $Report" }
    $destination = Join-Path $workingDir $Report
    $sessionId = if ($Session) { $Session } else { "session-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
    if ($sourcePath.StartsWith($workingDir, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-EcrrLog "Report already in working directory: $Report" 'WARN'
    } else {
        Move-Item -Path $sourcePath -Destination $destination -Force
        Write-EcrrLog "Moved to working: $Report" 'SUCCESS'
    }
    $ownerValue = if ($Assign) { $Assign } else { 'unassigned' }
    Add-WorkFooter -FullPath $destination -SessionId $sessionId -Owner $ownerValue -PriorityInfo $Priority
    $updates = @{
        status   = 'In Progress'
        assigned = if ($Assign) { $Assign } else { '' }
        priority = if ($Priority) { $Priority } else { 'medium' }
        notes    = if ($Notes) { $Notes } else { 'Work session started' }
        session  = $sessionId
    }
    $entry = $list | Where-Object { $_.report -eq $Report } | Select-Object -First 1
    if (-not $entry -or -not $entry.started) {
        $updates.started = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    $list = Upsert-LedgerEntry -Entries $list -ReportName $Report -Updates $updates -DefaultStatus 'In Progress'
    return $list
}

function Invoke-ResolveAction {
    param($Entries)
    $list = $Entries
    if (-not $Report) { throw 'Resolve action requires -Report <file.md>' }
    $workingPath = Find-ReportPath $Report @($workingDir,$reviewDir,$ecrrRoot)
    if (-not $workingPath -or -not ($workingPath.StartsWith($workingDir, [System.StringComparison]::OrdinalIgnoreCase))) {
        throw "Report must be in working directory before resolving: $Report"
    }
    $destination = Join-Path $archiveDir $Report
    Move-Item -Path $workingPath -Destination $destination -Force
    Write-EcrrLog "Archived report: $Report" 'SUCCESS'
    $resolutionText = if ($Resolution) { $Resolution } else { 'resolved' }
    $notesText = if ($Notes) { $Notes } else { 'Resolved via lifecycle automation' }
    Add-ResolutionFooter -FullPath $destination -ResolutionSummary $resolutionText -NotesText $notesText
    $updates = @{
        status     = 'Archived'
        notes      = $notesText
        resolution = $resolutionText
        completed  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    $list = Upsert-LedgerEntry -Entries $list -ReportName $Report -Updates $updates -DefaultStatus 'Archived'
    return $list
}

function Show-Status {
    param($Entries)
    $snapshot = Clone-Ledger $Entries
    Write-Host 'ECRR Lifecycle Status' -ForegroundColor Cyan
    Write-Host "Root:      $ecrrRoot"
    Write-Host "Reviewed:  $reviewDir"
    Write-Host "Working:   $workingDir"
    Write-Host "Archive:   $archiveDir"
    Write-Host ''
    Write-Host "Ledger entries: $($snapshot.Count)" -ForegroundColor Green
    $groups = $snapshot | Group-Object status
    foreach ($g in $groups) {
        Write-Host "  $($g.Name): $($g.Count)" -ForegroundColor Yellow
    }
}

Ensure-EcrrDirectories
$ledgerData = Load-Ledger

try {
    switch ($Action) {
        'Review' {
            $ledgerData = Invoke-ReviewAction -Entries $ledgerData
            $saveNeeded = $true
        }
        'Start' {
            $ledgerData = Invoke-StartAction -Entries $ledgerData
            $saveNeeded = $true
        }
        'Resolve' {
            $ledgerData = Invoke-ResolveAction -Entries $ledgerData
            $saveNeeded = $true
        }
        'Archive' {
            $ledgerData = Invoke-ResolveAction -Entries $ledgerData
            $saveNeeded = $true
        }
        'RegenerateIndex' {
            Build-Index -Entries $ledgerData
        }
        'RegenerateLedger' {
            Build-LedgerMarkdown -Entries $ledgerData
        }
        'RegenerateAll' {
            Build-Index -Entries $ledgerData
            Build-LedgerMarkdown -Entries $ledgerData
        }
        'Status' {
            Show-Status -Entries $ledgerData
        }
        'Help' {
            Write-Host 'ECRR Lifecycle Management' -ForegroundColor Cyan
            Write-Host 'Usage: pwsh -File scripts/ecrr-manage.ps1 -Action <action> [options]' -ForegroundColor Yellow
            Write-Host ''
            Write-Host 'Actions:' -ForegroundColor Green
            Write-Host '  Review           Move report(s) into reviewed stage and capture triage metadata.'
            Write-Host '  Start            Move a reviewed report into working, append footer, update ledger.'
            Write-Host '  Resolve/Archive  Move a working report into archive and mark it completed.'
            Write-Host '  RegenerateIndex  Rebuild docs/ECRR_REPORTS/INDEX.md.'
            Write-Host '  RegenerateLedger Refresh docs/ECRR_REPORTS/working/LEDGER.md.'
            Write-Host '  RegenerateAll    Run both index and ledger refresh.'
            Write-Host '  Status           Show directory + ledger summary.'
            Write-Host '  Help             Display this message.'
            Write-Host ''
            Write-Host 'Common flags:' -ForegroundColor Green
            Write-Host '  -Report <file.md>     Target specific report.'
            Write-Host '  -All                  Apply to all eligible reports (Review only).'
            Write-Host '  -Assign <owner>       Set or override owner/assignee.'
            Write-Host '  -Priority <level>     Track priority (default: medium).'
            Write-Host '  -Notes <text>         Attach notes for ledger entries.'
            Write-Host '  -Resolution <text>    Describe resolution outcome (Resolve/Archive).'
            Write-Host ''
            Write-Host 'Examples:' -ForegroundColor Yellow
            Write-Host "  pwsh -File scripts/ecrr-manage.ps1 -Action Review -Report '2025-09-30-lint-toolchain-gap.md' -Assign 'team-lead' -Priority high"
            Write-Host "  pwsh -File scripts/ecrr-manage.ps1 -Action Start -Report '2025-09-30-lint-toolchain-gap.md' -Assign 'engineer'"
            Write-Host "  pwsh -File scripts/ecrr-manage.ps1 -Action Resolve -Report '2025-09-30-lint-toolchain-gap.md' -Resolution 'validated fix'"
        }
    }

    if ($saveNeeded) {
        Save-Ledger -Entries $ledgerData
        Build-LedgerMarkdown -Entries $ledgerData
        Build-Index -Entries $ledgerData
    }

    Write-Host "Action completed: $Action" -ForegroundColor Green
} catch {
    Write-EcrrLog $_.Exception.Message 'ERROR'
    throw
}



