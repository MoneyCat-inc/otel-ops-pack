# Apply Priority Updates to Outstanding ECRR Reports
# Uses analysis from analyze-outstanding-reports.ps1 to update report priorities

param(
    [string]$AnalysisFile,
    [switch]$DryRun = $false,
    [int]$BatchSize = 20
)

if (-not $AnalysisFile) {
    $latest = Get-ChildItem "artifacts/ecrr-priority-analysis-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $AnalysisFile = $latest.FullName
        Write-Host "📋 Using latest analysis: $($latest.Name)" -ForegroundColor Cyan
    } else {
        Write-Error "No analysis file found. Run analyze-outstanding-reports.ps1 first."
        exit 1
    }
}

# Load analysis
Write-Host "⠋ Loading priority analysis..." -NoNewline -ForegroundColor Cyan
$analysis = Get-Content $AnalysisFile | ConvertFrom-Json
Write-Host "`r✅ Loaded analysis for $($analysis.totalReports) reports" -ForegroundColor Green

# Filter reports that need priority changes
$changesNeeded = $analysis.analysis | Where-Object { $_.currentPriority -ne $_.suggestedPriority }
Write-Host "📊 Priority changes needed: $($changesNeeded.Count)" -ForegroundColor Yellow

if ($changesNeeded.Count -eq 0) {
    Write-Host "✅ All reports already have correct priorities!" -ForegroundColor Green
    exit 0
}

# Group changes by priority for better visualization
$changeSummary = $changesNeeded | Group-Object suggestedPriority | Sort-Object @{Expression = {
    switch ($_.Name) {
        'critical' { 1 }
        'high' { 2 }
        'medium' { 3 }
        'low' { 4 }
    }
}}

Write-Host ""
Write-Host "🎯 Priority Update Summary:" -ForegroundColor Yellow
foreach ($group in $changeSummary) {
    $color = switch ($group.Name) {
        'critical' { 'Red' }
        'high' { 'Magenta' }
        'medium' { 'Yellow' }
        'low' { 'Gray' }
    }
    Write-Host "  $($group.Name.ToUpper()): $($group.Count) reports" -ForegroundColor $color
}

if ($DryRun) {
    Write-Host ""
    Write-Host "🔍 DRY RUN - Changes that would be applied:" -ForegroundColor Yellow
    $changesNeeded | Select-Object -First 10 | ForEach-Object {
        $color = switch ($_.suggestedPriority) {
            'critical' { 'Red' }
            'high' { 'Magenta' }
            'medium' { 'Yellow' }
            'low' { 'Gray' }
        }
        Write-Host "  [$($_.currentPriority) → $($_.suggestedPriority.ToUpper())] $($_.title)" -ForegroundColor $color
    }
    if ($changesNeeded.Count -gt 10) {
        Write-Host "  ... and $($changesNeeded.Count - 10) more" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Cyan
    exit 0
}

# Apply changes in batches
Write-Host ""
Write-Host "🚀 Applying priority updates..." -ForegroundColor Green
$processed = 0
$errors = @()

foreach ($change in $changesNeeded) {
    $processed++
    $progress = [math]::Round(($processed / $changesNeeded.Count) * 100)
    Write-Host "`r⠙ Updating priorities... $processed/$($changesNeeded.Count) ($progress%)" -NoNewline -ForegroundColor Cyan
    
    try {
        # Use ECRR management script to update priority
        $result = & "scripts/ecrr-manage.ps1" -Action Review -Report $change.report -Priority $change.suggestedPriority -Notes "Priority updated based on automated analysis" -ErrorAction Stop
        
        # Brief pause to avoid overwhelming the system
        if ($processed % $BatchSize -eq 0) {
            Start-Sleep -Milliseconds 100
        }
    } catch {
        $errors += @{
            report = $change.report
            error = $_.Exception.Message
        }
    }
}

Write-Host "`r✅ Priority updates complete! Processed $processed reports" -ForegroundColor Green

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  $($errors.Count) errors encountered:" -ForegroundColor Yellow
    $errors | ForEach-Object {
        Write-Host "  $($_.report): $($_.error)" -ForegroundColor Red
    }
}

# Generate completion report
$completionReport = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    analysisFile = $AnalysisFile
    totalReports = $analysis.totalReports
    changesAttempted = $changesNeeded.Count
    changesSuccessful = $processed - $errors.Count
    errors = $errors
    summary = @{
        critical = ($changesNeeded | Where-Object { $_.suggestedPriority -eq 'critical' }).Count
        high = ($changesNeeded | Where-Object { $_.suggestedPriority -eq 'high' }).Count
        medium = ($changesNeeded | Where-Object { $_.suggestedPriority -eq 'medium' }).Count
        low = ($changesNeeded | Where-Object { $_.suggestedPriority -eq 'low' }).Count
    }
}

$reportPath = "artifacts/ecrr-priority-updates-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$completionReport | ConvertTo-Json -Depth 10 | Set-Content $reportPath -Encoding UTF8

Write-Host ""
Write-Host "📄 Update report saved to: $reportPath" -ForegroundColor Green
Write-Host "🏁 Priority update complete!" -ForegroundColor Green

return $completionReport
