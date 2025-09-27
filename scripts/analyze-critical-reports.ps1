# Analyze Critical ECRR Reports for Task Planning
# Extract and categorize the 44 critical reports for focused task management

param(
    [switch]$Verbose = $false,
    [string]$OutputPath = "artifacts/critical-reports-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

$ledgerPath = "docs/ECRR_REPORTS/ledger.json"

# Load ledger
Write-Host "⠋ Loading ECRR ledger..." -NoNewline -ForegroundColor Cyan
$ledger = Get-Content $ledgerPath | ConvertFrom-Json
$critical = $ledger | Where-Object { $_.status -eq 'Outstanding' -and $_.priority -eq 'critical' }
Write-Host "`r✅ Loaded $($critical.Count) critical reports" -ForegroundColor Green

# Categorize reports
$categories = @{
    'Parser Errors' = @()
    'Canary Monitoring' = @()
    'Pipeline Verification' = @()
    'GPU Metrics' = @()
    'Health Verification' = @()
    'OTLP/Wiring' = @()
    'Disk Monitoring' = @()
    'System Health' = @()
    'Other' = @()
}

foreach ($report in $critical) {
    $title = $report.title.ToLower()
    $reportName = $report.report.ToLower()
    
    if ($title -match 'parser|error') {
        $categories['Parser Errors'] += $report
    } elseif ($title -match 'canary|monitoring') {
        $categories['Canary Monitoring'] += $report
    } elseif ($title -match 'pipeline|verification') {
        $categories['Pipeline Verification'] += $report
    } elseif ($title -match 'gpu|metrics') {
        $categories['GPU Metrics'] += $report
    } elseif ($title -match 'health|rollout') {
        $categories['Health Verification'] += $report
    } elseif ($title -match 'otlp|wiring') {
        $categories['OTLP/Wiring'] += $report
    } elseif ($title -match 'disk|monitoring') {
        $categories['Disk Monitoring'] += $report
    } elseif ($title -match 'system|stability|infrastructure') {
        $categories['System Health'] += $report
    } else {
        $categories['Other'] += $report
    }
}

# Generate task list
$taskList = @()
$taskId = 1

foreach ($category in $categories.Keys) {
    $reports = $categories[$category]
    if ($reports.Count -gt 0) {
        $priority = switch ($category) {
            'Parser Errors' { 'P0' }
            'Canary Monitoring' { 'P0' }
            'Pipeline Verification' { 'P0' }
            'GPU Metrics' { 'P1' }
            'Health Verification' { 'P1' }
            'OTLP/Wiring' { 'P1' }
            'Disk Monitoring' { 'P1' }
            'System Health' { 'P2' }
            default { 'P2' }
        }
        
        $taskList += @{
            id = "T$($taskId.ToString('D2'))"
            category = $category
            priority = $priority
            reportCount = $reports.Count
            reports = $reports | ForEach-Object { @{
                report = $_.report
                title = $_.title
                assigned = $_.assigned
                created = $_.created
            }}
            description = "Address $($category.ToLower()) issues - $($reports.Count) critical reports"
            estimatedEffort = switch ($reports.Count) {
                {$_ -le 2} { '2-4 hours' }
                {$_ -le 5} { '4-8 hours' }
                {$_ -le 10} { '1-2 days' }
                default { '2-3 days' }
            }
        }
        $taskId++
    }
}

# Sort by priority and report count
$taskList = $taskList | Sort-Object @{Expression = {
    switch ($_.priority) {
        'P0' { 1 }
        'P1' { 2 }
        'P2' { 3 }
    }
}}, @{Expression = { -$_.reportCount }}

# Generate summary
$summary = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalCriticalReports = $critical.Count
    totalTasks = $taskList.Count
    categoryBreakdown = $categories.GetEnumerator() | ForEach-Object { @{
        category = $_.Key
        count = $_.Value.Count
    }} | Where-Object { $_.count -gt 0 } | Sort-Object count -Descending
    taskList = $taskList
    priorityDistribution = @{
        P0 = ($taskList | Where-Object { $_.priority -eq 'P0' }).Count
        P1 = ($taskList | Where-Object { $_.priority -eq 'P1' }).Count
        P2 = ($taskList | Where-Object { $_.priority -eq 'P2' }).Count
    }
}

# Save analysis
$summary | ConvertTo-Json -Depth 10 | Set-Content $OutputPath -Encoding UTF8

# Display results
Write-Host ""
Write-Host "🎯 Critical Reports Task Analysis:" -ForegroundColor Yellow
Write-Host "  Total Critical Reports: $($summary.totalCriticalReports)" -ForegroundColor Red
Write-Host "  Total Tasks: $($summary.totalTasks)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Priority Distribution:" -ForegroundColor Yellow
Write-Host "  P0 (Immediate): $($summary.priorityDistribution.P0) tasks" -ForegroundColor Red
Write-Host "  P1 (High): $($summary.priorityDistribution.P1) tasks" -ForegroundColor Magenta
Write-Host "  P2 (Medium): $($summary.priorityDistribution.P2) tasks" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Category Breakdown:" -ForegroundColor Yellow
foreach ($category in $summary.categoryBreakdown) {
    Write-Host "  $($category.category): $($category.count) reports" -ForegroundColor White
}

if ($Verbose) {
    Write-Host ""
    Write-Host "🔍 Detailed Task List:" -ForegroundColor Yellow
    foreach ($task in $taskList) {
        $color = switch ($task.priority) {
            'P0' { 'Red' }
            'P1' { 'Magenta' }
            'P2' { 'Yellow' }
        }
        Write-Host "  [$($task.priority)] $($task.id): $($task.description)" -ForegroundColor $color
        Write-Host "    Reports: $($task.reportCount) | Effort: $($task.estimatedEffort)" -ForegroundColor DarkGray
        if ($task.reports.Count -le 3) {
            foreach ($report in $task.reports) {
                Write-Host "    - $($report.title)" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "    - $($task.reports[0].title)" -ForegroundColor DarkGray
            Write-Host "    - ... and $($task.reports.Count - 1) more" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

Write-Host ""
Write-Host "📄 Analysis saved to: $OutputPath" -ForegroundColor Green
Write-Host "🚀 Ready for task execution!" -ForegroundColor Green

return $summary
