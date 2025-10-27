# Gate #026 Track C: ICF Convergence Analyzer
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Compute Convergence Index and extract improvement actions from ECRR artifacts

param(
    [string]$OutputPath = "artifacts/icf",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #026 Track C: ICF Convergence Analyzer ===" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Read BOSSCAT_LOG
Write-Host "[1/5] Reading BOSSCAT_LOG..." -ForegroundColor Cyan
$bossCatLogPath = "docs/BossCat/BOSSCAT_LOG.md"
if (-not (Test-Path $bossCatLogPath)) {
    Write-Host "   ❌ BOSSCAT_LOG not found: $bossCatLogPath" -ForegroundColor Red
    exit 1
}

$bossCatLog = Get-Content $bossCatLogPath -Raw
$logEntries = $bossCatLog -split "`n" | Where-Object { $_ -match "^\-\s+\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z" }
Write-Host "   ✅ Found $($logEntries.Count) log entries" -ForegroundColor Green

# Analyze convergence patterns
Write-Host ""
Write-Host "[2/5] Analyzing convergence patterns..." -ForegroundColor Cyan

# Pattern 1: Retries and rework
$retryPattern = "retry|revert|redo|regression|reverted|re-run"
$retryCount = ($logEntries | Where-Object { $_ -match $retryPattern }).Count

# Pattern 2: Drift detections
$driftPattern = "drift|desync|reconciliation|mismatch|corrected"
$driftCount = ($logEntries | Where-Object { $_ -match $driftPattern }).Count

# Pattern 3: AMBER gates (partial success)
$amberPattern = "AMBER|YELLOW|WARN|partial"
$amberCount = ($logEntries | Where-Object { $_ -match $amberPattern }).Count

# Pattern 4: GREEN gates (full success)
$greenPattern = "GREEN|APPROVED|PASS|complete"
$greenCount = ($logEntries | Where-Object { $_ -match $greenPattern }).Count

# Pattern 5: Performance improvements
$perfPattern = "performance|optimization|faster|improved|baseline"
$perfCount = ($logEntries | Where-Object { $_ -match $perfPattern }).Count

Write-Host "   Retries/Rework: $retryCount" -ForegroundColor White
Write-Host "   Drift Detections: $driftCount" -ForegroundColor White
Write-Host "   AMBER Gates: $amberCount" -ForegroundColor White
Write-Host "   GREEN Gates: $greenCount" -ForegroundColor White
Write-Host "   Performance Improvements: $perfCount" -ForegroundColor White

# Compute Convergence Index
Write-Host ""
Write-Host "[3/5] Computing Convergence Index..." -ForegroundColor Cyan

# Convergence Index formula:
# CI = (GREEN_count / (GREEN_count + AMBER_count + retry_count)) * (1 - (drift_count / total_entries))
# Higher CI = better convergence (fewer retries, less drift)

$totalIssues = $retryCount + $driftCount + $amberCount
$successRate = if (($greenCount + $totalIssues) -gt 0) {
    $greenCount / ($greenCount + $totalIssues)
} else {
    1.0
}

$driftRate = if ($logEntries.Count -gt 0) {
    $driftCount / $logEntries.Count
} else {
    0.0
}

$convergenceIndex = $successRate * (1 - $driftRate)
$convergencePercent = [Math]::Round($convergenceIndex * 100, 2)

Write-Host "   Success Rate: $([Math]::Round($successRate * 100, 2))%" -ForegroundColor White
Write-Host "   Drift Rate: $([Math]::Round($driftRate * 100, 2))%" -ForegroundColor White
Write-Host "   Convergence Index: $convergencePercent%" -ForegroundColor $(if ($convergencePercent -ge 80) { 'Green' } elseif ($convergencePercent -ge 60) { 'Yellow' } else { 'Red' })

# Extract last 5 improvement actions
Write-Host ""
Write-Host "[4/5] Extracting recent improvement actions..." -ForegroundColor Cyan

# Look for entries that indicate learning/improvement
# Filter to only entries with GATE markers (most meaningful milestones)
$improvementEntries = $logEntries | Where-Object { $_ -match "\*\*\[GATE #" } | Select-Object -Last 5

$improvements = @()
foreach ($entry in $improvementEntries) {
    # Extract gate number and action
    # Pattern matches: "**[GATE #026A APPROVED GREEN]** description text — authority"
    if ($entry -match "\[GATE #([\dA-Z\+]+)\s+([^\]]+)\]\*\*\s*(.+?)\s*—") {
        $gateNum = $matches[1]
        $status = $matches[2].Trim()
        $description = $matches[3].Trim()
        
        # Limit description to first 80 chars for dashboard
        if ($description.Length -gt 80) {
            $description = $description.Substring(0, 77) + "..."
        }
        
        $improvements += [PSCustomObject]@{
            Gate = "Gate #$gateNum"
            Status = $status
            Action = $description
            Date = if ($entry -match "(\d{4}-\d{2}-\d{2})") { $matches[1] } else { "unknown" }
        }
    }
}

Write-Host "   ✅ Extracted $($improvements.Count) recent improvement actions" -ForegroundColor Green

# Generate ICF report
Write-Host ""
Write-Host "[5/5] Generating ICF report..." -ForegroundColor Cyan

$reportPath = Join-Path $OutputPath "convergence-report.json"
$report = [PSCustomObject]@{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    convergence_index = $convergenceIndex
    convergence_percent = $convergencePercent
    metrics = [PSCustomObject]@{
        total_log_entries = $logEntries.Count
        retry_count = $retryCount
        drift_count = $driftCount
        amber_gates = $amberCount
        green_gates = $greenCount
        performance_improvements = $perfCount
        success_rate = $successRate
        drift_rate = $driftRate
    }
    recent_improvements = $improvements
    assessment = if ($convergencePercent -ge 80) {
        "EXCELLENT - System converging well"
    } elseif ($convergencePercent -ge 60) {
        "GOOD - Some iteration required"
    } else {
        "NEEDS ATTENTION - High retry/drift rate"
    }
}

$report | ConvertTo-Json -Depth 10 | Set-Content $reportPath -Encoding UTF8
Write-Host "   ✅ Report saved: $reportPath" -ForegroundColor Green

# Display summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ ICF Convergence Analysis Complete" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Convergence Index: $convergencePercent%" -ForegroundColor $(if ($convergencePercent -ge 80) { 'Green' } elseif ($convergencePercent -ge 60) { 'Yellow' } else { 'Red' })
Write-Host "📈 Assessment: $($report.assessment)" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Recent Improvements:" -ForegroundColor Yellow
foreach ($imp in $improvements) {
    Write-Host "   - [$($imp.Date)] $($imp.Gate): $($imp.Action)" -ForegroundColor White
}
Write-Host ""
Write-Host "📂 Evidence: $reportPath" -ForegroundColor Gray
Write-Host ""

# Return convergence index for scripting
return $convergenceIndex

