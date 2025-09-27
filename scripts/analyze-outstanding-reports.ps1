# ECRR Outstanding Reports Priority Analysis
# Analyze outstanding reports and assign priority levels based on content and age

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ledgerPath = "docs/ECRR_REPORTS/ledger.json"
$outputPath = "artifacts/ecrr-priority-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

# Load ledger
Write-Host "⠋ Loading ECRR ledger..." -NoNewline -ForegroundColor Cyan
$ledger = Get-Content $ledgerPath | ConvertFrom-Json
$outstanding = $ledger | Where-Object { $_.status -eq 'Outstanding' }
Write-Host "`r✅ Loaded $($outstanding.Count) outstanding reports" -ForegroundColor Green

# Priority keywords and their weights
$priorityKeywords = @{
    'critical' = @('critical', 'urgent', 'blocker', 'broken', 'failure', 'error', 'crash', 'down', 'outage')
    'high' = @('security', 'performance', 'health', 'monitoring', 'pipeline', 'production', 'rollout', 'integration')
    'medium' = @('optimization', 'enhancement', 'implementation', 'analysis', 'automation', 'verification')
    'low' = @('summary', 'report', 'documentation', 'cleanup', 'processing', 'complete')
}

# Date-based priority adjustment
$now = Get-Date
$recentThreshold = $now.AddDays(-7)    # Last 7 days = higher priority
$staleThreshold = $now.AddDays(-30)    # Older than 30 days = lower priority

# Analyze each report
$analysis = @()
$counter = 0
foreach ($report in $outstanding) {
    $counter++
    $progress = [math]::Round(($counter / $outstanding.Count) * 100)
    Write-Host "`r⠙ Analyzing reports... $counter/$($outstanding.Count) ($progress%)" -NoNewline -ForegroundColor Cyan
    
    $score = 0
    $factors = @()
    
    # Content-based scoring
    $title = $report.title.ToLower()
    $reportName = $report.report.ToLower()
    
    foreach ($level in $priorityKeywords.Keys) {
        foreach ($keyword in $priorityKeywords[$level]) {
            if ($title -match $keyword -or $reportName -match $keyword) {
                switch ($level) {
                    'critical' { $score += 10; $factors += "Critical keyword: $keyword" }
                    'high' { $score += 5; $factors += "High keyword: $keyword" }
                    'medium' { $score += 2; $factors += "Medium keyword: $keyword" }
                    'low' { $score += 1; $factors += "Low keyword: $keyword" }
                }
                break
            }
        }
    }
    
    # Date-based scoring
    if ($report.created) {
        $createdDate = [DateTime]::Parse($report.created)
        if ($createdDate -gt $recentThreshold) {
            $score += 3
            $factors += "Recent report (last 7 days)"
        } elseif ($createdDate -lt $staleThreshold) {
            $score -= 2
            $factors += "Stale report (>30 days)"
        }
    }
    
    # System/Infrastructure priority boost
    if ($title -match 'signoz|otel|pipeline|monitoring|health|collector') {
        $score += 3
        $factors += "System/Infrastructure related"
    }
    
    # ECRR process priority boost
    if ($title -match 'ecrr|lifecycle|automation|rollout') {
        $score += 2
        $factors += "ECRR process improvement"
    }
    
    # Determine final priority
    $priority = if ($score -ge 10) { 'critical' } 
               elseif ($score -ge 6) { 'high' } 
               elseif ($score -ge 3) { 'medium' } 
               else { 'low' }
    
    $analysis += @{
        report = $report.report
        title = $report.title
        currentPriority = $report.priority
        suggestedPriority = $priority
        score = $score
        factors = $factors
        assigned = $report.assigned
        created = $report.created
        notes = $report.notes
    }
}

Write-Host "`r✅ Analysis complete! Processed $($outstanding.Count) reports" -ForegroundColor Green

# Sort by priority and score
$analysis = $analysis | Sort-Object @{Expression = {
    switch ($_.suggestedPriority) {
        'critical' { 1 }
        'high' { 2 }
        'medium' { 3 }
        'low' { 4 }
    }
}}, @{Expression = { -$_.score }}

# Generate summary
$summary = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalReports = $outstanding.Count
    priorityDistribution = @{
        critical = ($analysis | Where-Object { $_.suggestedPriority -eq 'critical' }).Count
        high = ($analysis | Where-Object { $_.suggestedPriority -eq 'high' }).Count
        medium = ($analysis | Where-Object { $_.suggestedPriority -eq 'medium' }).Count
        low = ($analysis | Where-Object { $_.suggestedPriority -eq 'low' }).Count
    }
    changesNeeded = ($analysis | Where-Object { $_.currentPriority -ne $_.suggestedPriority }).Count
    analysis = $analysis
}

# Save analysis
$summary | ConvertTo-Json -Depth 10 | Set-Content $outputPath -Encoding UTF8

# Display results
Write-Host ""
Write-Host "🎯 Priority Analysis Results:" -ForegroundColor Yellow
Write-Host "  Critical: $($summary.priorityDistribution.critical)" -ForegroundColor Red
Write-Host "  High: $($summary.priorityDistribution.high)" -ForegroundColor Magenta
Write-Host "  Medium: $($summary.priorityDistribution.medium)" -ForegroundColor Yellow
Write-Host "  Low: $($summary.priorityDistribution.low)" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Priority Changes Needed: $($summary.changesNeeded)" -ForegroundColor Cyan
Write-Host "📄 Analysis saved to: $outputPath" -ForegroundColor Green

if ($Verbose) {
    Write-Host ""
    Write-Host "🔍 Top 10 Priority Reports:" -ForegroundColor Yellow
    $analysis | Select-Object -First 10 | ForEach-Object {
        $color = switch ($_.suggestedPriority) {
            'critical' { 'Red' }
            'high' { 'Magenta' }
            'medium' { 'Yellow' }
            'low' { 'Gray' }
        }
        Write-Host "  [$($_.suggestedPriority.ToUpper())] $($_.title)" -ForegroundColor $color
        if ($_.factors.Count -gt 0) {
            Write-Host "    Factors: $($_.factors -join ', ')" -ForegroundColor DarkGray
        }
    }
}

if (-not $DryRun) {
    Write-Host ""
    Write-Host "🚀 Ready to apply priority changes?" -ForegroundColor Yellow
    Write-Host "Run with -DryRun to preview changes first" -ForegroundColor Gray
}

return $summary
