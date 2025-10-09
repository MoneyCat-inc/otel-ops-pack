# BossCat OEM - P95 Latency SLI Calculator
# Computes p95 ingest latency from trend CSV for SLO tracking

<#
.SYNOPSIS
  Calculates p95 ingest latency from verification trend CSV.

.DESCRIPTION
  Reads gate_verification_trend.csv and computes:
  - P95 ingest latency (target: < 5000ms)
  - Success rate
  - API verification rate
  - Pinpoint mode usage

  Returns:
  - Exit 0: p95 under threshold
  - Exit 1: p95 exceeds threshold
  - Exit 2: No data or file not found

.PARAMETER CsvPath
  Path to trend CSV file (default: out/gate_verification_trend.csv)

.PARAMETER Window
  Number of most recent samples to analyze (default: 200)

.EXAMPLE
  pwsh -File scripts\calc-p95-latency.ps1
  
.EXAMPLE
  pwsh -File scripts\calc-p95-latency.ps1 -Window 100
#>

param(
  [string]$CsvPath = "out\gate_verification_trend.csv",
  [int]$Window = 200  # Last N samples
)

Write-Host "🐾 BossCat OEM - P95 Latency SLI Calculator" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray

# Check if CSV exists
if (-not (Test-Path $CsvPath)) {
  Write-Error "Trend CSV not found at: $CsvPath"
  Write-Host "   Run verification first: pwsh -File scripts\verify-pipeline.ps1" -ForegroundColor Yellow
  exit 2
}

# Read CSV and get last N samples
Write-Host "[sli] Reading trend data from: $CsvPath" -ForegroundColor Cyan
$allRows = Import-Csv $CsvPath
$rows = $allRows | Select-Object -Last $Window
$actualCount = $rows.Count

Write-Host "[sli] Analyzing $actualCount samples (window: $Window)" -ForegroundColor Gray
Write-Host ""

# --- Calculate p95 ingest latency ---
$latencyValues = $rows | 
  Where-Object { $_.ingest_latency_ms -match '^\d+$' } | 
  ForEach-Object { [int]$_.ingest_latency_ms }

if ($latencyValues.Count -eq 0) {
  Write-Warning "No latency data found in trend CSV"
  Write-Host "   This is expected if no successful forensic runs yet" -ForegroundColor Yellow
  Write-Host "   Run verification with API key set to generate latency data" -ForegroundColor Yellow
  exit 2
}

$sorted = $latencyValues | Sort-Object
$p95Index = [math]::Max(0, [math]::Ceiling(0.95 * $sorted.Count) - 1)
$p95 = $sorted[$p95Index]
$p50 = $sorted[[math]::Floor($sorted.Count * 0.50)]
$p99 = $sorted[[math]::Min($sorted.Count - 1, [math]::Ceiling(0.99 * $sorted.Count) - 1)]
$min = $sorted[0]
$max = $sorted[-1]
$avg = [math]::Round(($sorted | Measure-Object -Average).Average, 0)

Write-Host "📊 Ingest Latency Metrics:" -ForegroundColor Cyan
Write-Host "   Samples with latency: $($latencyValues.Count)/$actualCount" -ForegroundColor White
Write-Host "   Min: $min ms" -ForegroundColor White
Write-Host "   Avg: $avg ms" -ForegroundColor White
Write-Host "   P50 (median): $p50 ms" -ForegroundColor White
Write-Host "   P95: $p95 ms $(if ($p95 -lt 5000) { '✅' } else { '❌' })" -ForegroundColor $(if ($p95 -lt 5000) { 'Green' } else { 'Red' })
Write-Host "   P99: $p99 ms" -ForegroundColor White
Write-Host "   Max: $max ms" -ForegroundColor White
Write-Host "   Target: < 5000 ms" -ForegroundColor Gray

# --- Calculate success rates ---
Write-Host ""
Write-Host "📈 Success Rates:" -ForegroundColor Cyan

$okCount = ($rows | Where-Object outcome -eq "OK").Count
$warnCount = ($rows | Where-Object outcome -eq "WARN").Count
$failCount = ($rows | Where-Object outcome -eq "FAIL").Count
$successRate = [math]::Round(($okCount / $actualCount) * 100, 2)

Write-Host "   OK: $okCount/$actualCount ($successRate%)" -ForegroundColor Green
Write-Host "   WARN: $warnCount/$actualCount" -ForegroundColor Yellow
Write-Host "   FAIL: $failCount/$actualCount" -ForegroundColor Red

# --- Calculate API verification rate ---
$apiConfirmed = ($rows | Where-Object api_confirmed -eq "True").Count
$apiRate = [math]::Round(($apiConfirmed / $actualCount) * 100, 2)

Write-Host ""
Write-Host "🔍 Verification Quality:" -ForegroundColor Cyan
Write-Host "   API Confirmed: $apiConfirmed/$actualCount ($apiRate%)" -ForegroundColor White

# --- Calculate verification mode distribution ---
$pinpointCount = ($rows | Where-Object verification_mode -eq "pinpoint").Count
$standardCount = ($rows | Where-Object verification_mode -eq "standard").Count
$pinpointRate = if ($actualCount -gt 0) { [math]::Round(($pinpointCount / $actualCount) * 100, 2) } else { 0 }

Write-Host "   Pinpoint Mode: $pinpointCount/$actualCount ($pinpointRate%)" -ForegroundColor White
Write-Host "   Standard Mode: $standardCount/$actualCount" -ForegroundColor White

# --- SLO Assessment ---
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host "🎯 SLO Assessment:" -ForegroundColor Cyan

$sloPass = $true
$sloIssues = @()

# Check p95 latency target
if ($p95 -ge 5000) {
  $sloPass = $false
  $sloIssues += "P95 latency ($p95 ms) exceeds target (5000ms)"
  Write-Host "   ❌ P95 Latency SLO: BREACH ($p95 ms)" -ForegroundColor Red
} else {
  Write-Host "   ✅ P95 Latency SLO: PASS ($p95 ms < 5000ms)" -ForegroundColor Green
}

# Check success rate target (99%)
if ($successRate -lt 99.0) {
  $sloPass = $false
  $sloIssues += "Success rate ($successRate%) below target (99%)"
  Write-Host "   ⚠️  Success Rate SLO: WARNING ($successRate% < 99%)" -ForegroundColor Yellow
} else {
  Write-Host "   ✅ Success Rate SLO: PASS ($successRate%)" -ForegroundColor Green
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

# --- Output machine-readable SLI ---
Write-Host ""
Write-Host "📋 Machine-Readable Output:" -ForegroundColor Cyan
Write-Host "p95_ingest_latency_ms=$p95"
Write-Host "success_rate_pct=$successRate"
Write-Host "api_verification_rate_pct=$apiRate"
Write-Host "pinpoint_mode_rate_pct=$pinpointRate"
Write-Host "slo_pass=$sloPass"

# --- Exit code ---
if (-not $sloPass) {
  Write-Host ""
  Write-Host "⚠️  SLO breach detected:" -ForegroundColor Yellow
  foreach ($issue in $sloIssues) {
    Write-Host "   - $issue" -ForegroundColor Yellow
  }
  exit 1
} else {
  Write-Host ""
  Write-Host "✅ All SLO targets met" -ForegroundColor Green
  exit 0
}

