# Gate #025 Track C: ICF Cycle Retrospective Analyzer
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Parse evidence logs and generate learning insights

param(
    [int]$LastNCycles = 5,
    [string]$EvidenceDir = "artifacts/perf"
)

$ErrorActionPreference = "Continue"

Write-Host "=== ICF Cycle Retrospective Analyzer ===" -ForegroundColor Cyan
Write-Host ""

# Find recent evidence files
$evidenceFiles = Get-ChildItem -Path $EvidenceDir -Filter "*.json" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First $LastNCycles

if (-not $evidenceFiles) {
    Write-Host "[WARN] No evidence files found in $EvidenceDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Analyzing $($evidenceFiles.Count) recent cycles..." -ForegroundColor White
Write-Host ""

# Parse and analyze
$cycles = @()
$improvements = @()
$regressions = @()

foreach ($file in $evidenceFiles) {
    try {
        $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $cycles += @{
            file = $file.Name
            timestamp = $file.LastWriteTime
            gate = $data.gate
            track = $data.track
            verdict = $data.verdict
            data = $data
        }
    } catch {
        Write-Host "  [SKIP] Could not parse $($file.Name)" -ForegroundColor Gray
    }
}

# Generate retrospective
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cycle Retrospective (Last $LastNCycles)" -ForegroundColor White
Write-Host ""

foreach ($c in $cycles) {
    Write-Host "$(($c.timestamp).ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
    Write-Host "  Gate #$($c.gate) $($c.track): $($c.verdict)" -ForegroundColor White
    
    # Extract key metrics
    if ($c.data.improvements) {
        foreach ($key in $c.data.improvements.PSObject.Properties.Name) {
            $value = $c.data.improvements.$key
            if ($value -is [int] -or $value -is [double]) {
                if ($value -lt 0) {
                    Write-Host "    -> Improved $key by $([Math]::Abs($value))" -ForegroundColor Green
                    $improvements += "$($c.gate)/$($c.track): $key $value"
                } elseif ($value -gt 0) {
                    Write-Host "    -> Regressed $key by $value" -ForegroundColor Yellow
                    $regressions += "$($c.gate)/$($c.track): $key +$value"
                }
            }
        }
    }
    
    if ($c.data.reasoning) {
        Write-Host "    Lesson: $($c.data.reasoning.Substring(0, [Math]::Min(80, $c.data.reasoning.Length)))..." -ForegroundColor Cyan
    }
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Convergence Index" -ForegroundColor White
Write-Host ""
Write-Host "Last 5 Improvements:" -ForegroundColor Green
if ($improvements.Count -eq 0) {
    Write-Host "  (None detected)" -ForegroundColor Gray
} else {
    $improvements | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

Write-Host ""
Write-Host "Recent Regressions:" -ForegroundColor Yellow
if ($regressions.Count -eq 0) {
    Write-Host "  (None detected)" -ForegroundColor Gray
} else {
    $regressions | Select-Object -First 3 | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
}

# Convergence Index (thresholds met / total)
$totalCycles = $cycles.Count
$passCycles = ($cycles | Where-Object { $_.verdict -in @("PASS", "GREEN") }).Count
$convergenceIndex = if ($totalCycles -gt 0) { $passCycles / $totalCycles } else { 0 }

Write-Host ""
Write-Host "Convergence Index: $($convergenceIndex.ToString('P0')) ($passCycles/$totalCycles cycles met thresholds)" -ForegroundColor $(if ($convergenceIndex -ge 0.8) { 'Green' } elseif ($convergenceIndex -ge 0.6) { 'Yellow' } else { 'Red' })
Write-Host ""

# Output structured data
return @{
    cycles_analyzed = $totalCycles
    improvements_found = $improvements.Count
    regressions_found = $regressions.Count
    convergence_index = $convergenceIndex
    recent_improvements = $improvements | Select-Object -First 5
}

