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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        default   { 'Cyan' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    try {
        return [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)
    }
    catch {
        return $TargetPath
    }
}

function Ensure-JobsLayout {
    param([string]$Root)

    foreach ($sub in @('pending','in-progress','completed','templates')) {
        $full = Join-Path -Path $Root -ChildPath $sub
        if (-not (Test-Path -Path $full)) {
            New-Item -ItemType Directory -Path $full -Force | Out-Null
            Write-Log "Created directory: $full" 'SUCCESS'
        }
    }
}

function Get-ExistingTaskSources {
    param([string]$Root)

    $sources = [System.Collections.Generic.HashSet[string]]::new()

    $taskFiles = Get-ChildItem -Path $Root -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue
    foreach ($file in $taskFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        }
        catch {
            continue
        }

        $matches = [regex]::Matches($content, '\*\*Source Report\*\*:\s*`?(?<path>[^`\r\n]+)`?')
        if ($matches.Count -eq 0) {
            $matches = [regex]::Matches($content, 'Source reference:\s*`?(?<path>[^`\r\n]+)`?')
        }

        foreach ($match in $matches) {
            $value = $match.Groups['path'].Value.Trim().ToLowerInvariant()
            if ($value) {
                [void]$sources.Add($value)
            }
        }
    }

    return $sources
}

function Get-ReportFiles {
    param([string]$Root)

    if (-not (Test-Path -Path $Root)) {
        throw "ECRR reports path not found: $Root"
    }

    Get-ChildItem -Path $Root -Recurse -File -Filter '*.md' -ErrorAction Stop |
        Where-Object {
            $_.Name -notmatch '^(INDEX|LATEST|PROCESS|SUMMARY|README|LEDGER)' -and
            $_.FullName -notmatch '\\templates\\'
        } |
        Sort-Object LastWriteTime -Descending
}

function Get-Highlights {
    param([string[]]$Lines)

    $results = @()

    foreach ($line in $Lines) {
        if ($line -match '^\s*Next Steps\s*:') {
            break
        }

        if ($line -match '^\s*-\s+(?<text>.+)$') {
            $text = $Matches['text'].Trim()
            if ($text) {
                $results += $text
            }
        }

        if ($results.Count -ge 3) {
            break
        }
    }

    return ($results | Select-Object -Unique)
}

function Get-ActionableItems {
    param([string[]]$Lines)

    $results = @()

    for ($i = 0; $i -lt $Lines.Length; $i++) {
        $line = $Lines[$i]
        if ($line -match '^\s*(##\s*(Next Steps|Next Actions|Follow[- ]?up|Action Items|TODO)|Next Steps\s*:|Follow[- ]?up\s*:|TODOs?\s*:|Action Items\s*:)\s*$') {
            for ($j = $i + 1; $j -lt $Lines.Length; $j++) {
                $candidate = $Lines[$j]

                if ($candidate -match '^\s*[-*]\s+(?<item>.+)$') {
                    $item = $Matches['item'].Trim()
                    if ($item) {
                        $results += $item
                    }
                }
                elseif ($candidate -match '^\s*\d+\.\s+(?<item>.+)$') {
                    $item = $Matches['item'].Trim()
                    if ($item) {
                        $results += $item
                    }
                }
                elseif ($candidate.Trim().Length -eq 0) {
                    continue
                }
                else {
                    break
                }
            }
        }
    }

    $unique = $results | Where-Object { $_ } | Select-Object -Unique
    if ($unique.Count -eq 0) {
        return @(
            'Review the source ECRR report for unresolved actions.',
            'Capture verification output and link it back to the report.'
        )
    }

    return $unique
}

function Get-EmbeddedCommands {
    param([string]$Content)

    $commands = @()
    $matches = [regex]::Matches($Content, '`([^`\r\n]+)`')

    foreach ($match in $matches) {
        $cmd = $match.Groups[1].Value.Trim()
        if (-not $cmd) {
            continue
        }

        if ($cmd -match '^(pwsh|bash|docker|sc|Get-|Set-|Invoke-|New-|Start-|Stop|Remove-|Restart-|python|node|kubectl|curl|rg)\b') {
            if ($commands -notcontains $cmd) {
                $commands += $cmd
            }
        }
    }

    return $commands
}

$CategoryKeywords = @{
    observability = @('signoz','log','logs','metric','trace','clickhouse','otlp','telemetry','collector')
    infrastructure = @('service','windows','docker','container','port','endpoint','network','firewall','registry')
    automation = @('script','automation','schedule','job','lifecycle','workflow','orchestrator','ps1','powershell')
    monitoring = @('alert','monitor','health','status','watch','heartbeat','dashboard','threshold')
    development = @('code','implementation','feature','enhancement','refactor','optimize','bugfix')
    maintenance = @('cleanup','clean','disk','archive','tidy','housekeeping','rotate')
}

function Determine-Category {
    param([string]$Content)

    $text = $Content.ToLowerInvariant()
    $scores = @{}

    foreach ($key in $CategoryKeywords.Keys) {
        $scores[$key] = 0
        foreach ($keyword in $CategoryKeywords[$key]) {
            if ($text -match [regex]::Escape($keyword)) {
                $scores[$key]++
            }
        }
    }

    $best = $scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1

    if ($best.Value -gt 0) {
        return $best.Key
    }

    return 'maintenance'
}

function Determine-Priority {
    param(
        [string]$Content,
        [string]$Category
    )

    $text = $Content.ToLowerInvariant()

    if ($text -match 'critical|urgent|sev\s*1|p0|outage|blocker') {
        return 'critical'
    }

    if ($text -match 'error|failure|broken|unstable|degraded|incident|fix') {
        return 'high'
    }

    if ($text -match 'improve|optimize|enhance|refine|stabilize') {
        return 'medium'
    }

    if ($Category -in @('observability','infrastructure') -and $text -match 'monitor|verify|audit') {
        return 'high'
    }

    return 'low'
}

function Determine-Effort {
    param(
        [string]$Content,
        [string]$Category
    )

    $text = $Content.ToLowerInvariant()

    if ($text -match 'overhaul|migration|multi-step|cross-team') {
        return 'L'
    }

    switch ($Category) {
        'observability'  { return 'M' }
        'infrastructure' { return 'M' }
        'automation'     { return 'S' }
        'monitoring'     { return 'S' }
        'development'    { return 'L' }
        default          { return 'XS' }
    }
}

function Determine-Assignee {
    param([string]$Category)

    switch ($Category) {
        'observability'  { return 'observability-engineer' }
        'infrastructure' { return 'system-admin' }
        'automation'     { return 'devops-engineer' }
        'monitoring'     { return 'observability-engineer' }
        'development'    { return 'team-lead' }
        default          { return 'operations-duty' }
    }
}

function Get-DefaultCommands {
    param([string]$Category)

    switch ($Category) {
        'observability' {
            return @(
                'pwsh -File scripts/verify-wiring.ps1',
                'pwsh -File scripts/monitor-analytics-ingestion.ps1'
            )
        }
        'infrastructure' {
            return @(
                'sc query otelcol-contrib',
                'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
            )
        }
        'automation' {
            return @(
                'pwsh -File scripts/verify-automation.ps1'
            )
        }
        'monitoring' {
            return @(
                'pwsh -File scripts/monitor-analytics-ingestion.ps1',
                'pwsh -File scripts/test-alerts.ps1'
            )
        }
        'development' {
            return @(
                'pwsh -File scripts/ci-verify.ps1'
            )
        }
        default {
            return @(
                'pwsh -File scripts/system-health-check.ps1'
            )
        }
    }
}

function Get-SuccessNotes {
    param([string]$Category)

    switch ($Category) {
        'observability' {
            return @(
                'SigNoz dashboards reflect the expected signal after verification.',
                'Collector logs remain clean with no new ERROR entries.'
            )
        }
        'infrastructure' {
            return @(
                'All infrastructure checks report healthy status with no failing services.',
                'Port mappings remain stable and documented in the source report.'
            )
        }
        'automation' {
            return @(
                'Automation scripts run cleanly and refresh the targeted artifacts.',
                'Idempotent reruns produce the same results without drift.'
            )
        }
        'monitoring' {
            return @(
                'Dashboards and alerts reflect the updated thresholds with acceptable noise levels.',
                'Alert destinations receive the expected test notifications.'
            )
        }
        'development' {
            return @(
                'CI verification succeeds without regressions.',
                'Any code changes are linked back to the originating ECRR tasks.'
            )
        }
        default {
            return @(
                'Environment housekeeping commands complete without warnings.',
                'Documentation is refreshed with the latest state.'
            )
        }
    }
}

function Build-TaskContent { return '' }

function Write-TaskFile {
    param(
        [string]$JobsPath,
        [string]$TaskId,
        [string]$Content,
        [switch]$DryRun
    )

    $pendingPath = Join-Path -Path $JobsPath -ChildPath 'pending'
    $taskPath = Join-Path -Path $pendingPath -ChildPath "$TaskId.md"

    if ($DryRun) {
        Write-Log "DRY RUN: would create $taskPath" 'WARN'
        return $taskPath
    }

    Set-Content -Path $taskPath -Value $Content -Encoding UTF8
    Write-Log "Created task: $taskPath" 'SUCCESS'
    return $taskPath
}

function Write-AutomationSummary {
    param(
        [string]$JobsPath,
        [System.Collections.Generic.List[object]]$Tasks
    )

    if ($Tasks.Count -eq 0) {
        return $null
    }

    $reportName = "automation-report-{0}.md" -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    $reportPath = Join-Path -Path $JobsPath -ChildPath $reportName

    $lines = @()
    $lines += "# ECRR Task Automation Summary"
    $lines += ""
    $lines += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC"
    $lines += ""
    $lines += "## Tasks"
    $lines += ""

    foreach ($task in $Tasks) {
        $lines += "- $($task.Id) - $($task.Title) (Source: $($task.Report))"
    }

    Set-Content -Path $reportPath -Value ($lines -join "`n") -Encoding UTF8
    Write-Log "Automation summary written to $reportPath" 'SUCCESS'
    return $reportPath
}

try {
    Write-Log "Starting ECRR task automation" 'INFO'

    Ensure-JobsLayout -Root $JobsPath

    $repoRoot = (Get-Location).ProviderPath
    $reports = Get-ReportFiles -Root $EcrrReportPath
    if ($reports.Count -eq 0) {
        Write-Log "No ECRR reports found under $EcrrReportPath" 'WARN'
        return
    }

    $existingSources = Get-ExistingTaskSources -Root $JobsPath
    $createdTasks = [System.Collections.Generic.List[object]]::new()

    foreach ($report in $reports) {
        if ($createdTasks.Count -ge $MaxTasks) {
            break
        }

        $relativePath = Get-RelativePath -BasePath $repoRoot -TargetPath $report.FullName
        $normalized = $relativePath.ToLowerInvariant()

        if (-not $Force -and $existingSources.Contains($normalized)) {
            Write-Log "Skipping $relativePath (task already exists)" 'WARN'
            continue
        }

        $content = Get-Content -Path $report.FullName -Raw -ErrorAction Stop
        $lines = $content -split "`r?`n"

        $titleLine = $lines | Where-Object { $_ -match '^#\s+(.+)$' } | Select-Object -First 1
        $title = if ($titleLine) { $titleLine -replace '^#\s+', '' } else { [System.IO.Path]::GetFileNameWithoutExtension($report.Name) }

        $category = Determine-Category -Content $content
        $priority = Determine-Priority -Content $content -Category $category
        $effort = Determine-Effort -Content $content -Category $category
        $assignee = if ($AutoAssign) { Determine-Assignee -Category $category } else { 'unassigned' }

        $highlights = Get-Highlights -Lines $lines
        $actionItems = Get-ActionableItems -Lines $lines
        $commands = Get-EmbeddedCommands -Content $content
        if ($commands.Count -eq 0) {
            $commands = Get-DefaultCommands -Category $category
        }
        $successNotes = Get-SuccessNotes -Category $category

        $taskId = "TASK-{0}-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), (Get-Random -Minimum 100 -Maximum 999)
        $taskContent = Build-TaskContent -Title $title -TaskId $taskId -ReportRelPath $relativePath -Category $category -Priority $priority -Effort $effort -Assignee $assignee -Highlights $highlights -ActionableItems $actionItems -Commands $commands -SuccessNotes $successNotes

        $taskPath = Write-TaskFile -JobsPath $JobsPath -TaskId $taskId -Content $taskContent -DryRun:$DryRun

        $createdTasks.Add([PSCustomObject]@{
            Id = $taskId
            Title = $title
            Report = $relativePath
            Category = $category
            Priority = $priority
            File = $taskPath
        })

        if (-not $DryRun) {
            [void]$existingSources.Add($normalized)
        }

        Start-Sleep -Milliseconds 150
    }

    Write-Log "Task automation finished: generated $($createdTasks.Count) task(s)" 'SUCCESS'
    foreach ($task in $createdTasks) {
        Write-Log "  - $($task.Id) [$($task.Category)] $($task.Title)" 'INFO'
    }

    if (-not $DryRun -and $createdTasks.Count -gt 0) {
        Write-AutomationSummary -JobsPath $JobsPath -Tasks $createdTasks | Out-Null
    }

    if ($DryRun) {
        Write-Log "Dry run mode enabled; no files were written." 'WARN'
    }
}
catch {
    Write-Log "Task automation failed: $($_.Exception.Message)" 'ERROR'
    throw
}

