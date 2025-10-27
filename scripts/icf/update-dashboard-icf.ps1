# Gate #026 Track C: Update Dashboard with ICF Data
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Inject ICF Convergence Index into status dashboard

param(
    [string]$DashboardPath = "docs/GATE_STATUS_DASHBOARD.md",
    [string]$ICFReportPath = "artifacts/icf/convergence-report.json"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #026 Track C: Dashboard ICF Integration ===" -ForegroundColor Cyan
Write-Host ""

# Check if ICF report exists
if (-not (Test-Path $ICFReportPath)) {
    Write-Host "❌ ICF report not found: $ICFReportPath" -ForegroundColor Red
    Write-Host "   Run: .\scripts\icf\analyze-convergence.ps1" -ForegroundColor Yellow
    exit 1
}

# Read ICF report
Write-Host "[1/3] Reading ICF report..." -ForegroundColor Cyan
$icfReport = Get-Content $ICFReportPath -Raw | ConvertFrom-Json
Write-Host "   ✅ Convergence Index: $($icfReport.convergence_percent)%" -ForegroundColor Green

# Read dashboard
Write-Host ""
Write-Host "[2/3] Reading dashboard..." -ForegroundColor Cyan
if (-not (Test-Path $DashboardPath)) {
    Write-Host "   ❌ Dashboard not found: $DashboardPath" -ForegroundColor Red
    exit 1
}

$dashboard = Get-Content $DashboardPath -Raw
Write-Host "   ✅ Dashboard loaded" -ForegroundColor Green

# Generate ICF section
$icfSection = @"
## 📈 ICF Convergence Telemetry (Gate #026)

**Last Updated:** $($icfReport.timestamp)  
**Convergence Index:** $($icfReport.convergence_percent)% — *$($icfReport.assessment)*

### Metrics Snapshot
``````
Total Log Entries:         $($icfReport.metrics.total_log_entries)
GREEN Gates:               $($icfReport.metrics.green_gates)
AMBER Gates:               $($icfReport.metrics.amber_gates)
Retry/Rework Events:       $($icfReport.metrics.retry_count)
Drift Detections:          $($icfReport.metrics.drift_count)
Performance Improvements:  $($icfReport.metrics.performance_improvements)

Success Rate:              $([Math]::Round($icfReport.metrics.success_rate * 100, 2))%
Drift Rate:                $([Math]::Round($icfReport.metrics.drift_rate * 100, 2))%
``````

### Recent Improvement Actions (Last 5)
"@

# Add improvements
foreach ($imp in $icfReport.recent_improvements) {
    $icfSection += "`n- **$($imp.Date)** — $($imp.Gate): $($imp.Action)"
}

$icfSection += @"


### ICF Doctrine
The Convergence Index measures system learning and adaptation:
- **≥80%:** Excellent convergence (minimal retries, low drift)
- **60-79%:** Good convergence (acceptable iteration)
- **<60%:** Needs attention (high retry/drift rate)

**Formula:** CI = (GREEN / (GREEN + AMBER + retries)) × (1 - drift_rate)

**Evidence:** `artifacts/icf/convergence-report.json`

---

"@

# Update dashboard
Write-Host ""
Write-Host "[3/3] Updating dashboard..." -ForegroundColor Cyan

# Find insertion point (after "Current State" section, before "Gate Approvals")
$insertionMarker = "---`n`n## ✅ Gate #024 Approval"

if ($dashboard -match [regex]::Escape($insertionMarker)) {
    $dashboard = $dashboard -replace [regex]::Escape($insertionMarker), "$icfSection$insertionMarker"
    $dashboard | Set-Content $DashboardPath -Encoding UTF8
    Write-Host "   ✅ Dashboard updated with ICF section" -ForegroundColor Green
} else {
    # Fallback: append at end
    Write-Host "   ⚠️  Insertion marker not found, appending to end" -ForegroundColor Yellow
    $dashboard + "`n`n$icfSection" | Set-Content $DashboardPath -Encoding UTF8
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Dashboard ICF Integration Complete" -ForegroundColor Green
Write-Host ""
Write-Host "📂 Updated: $DashboardPath" -ForegroundColor Gray
Write-Host "📊 Convergence Index: $($icfReport.convergence_percent)%" -ForegroundColor White
Write-Host ""

