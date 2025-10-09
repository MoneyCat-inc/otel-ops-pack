# Verify Hurst Exponent Drift Alert
# Checks alert status and provides monitoring guidance

param(
    [string] = "Hurst Exponent Drift Alert"
)

Write-Host "🔍 Verifying SigNoz Hurst Drift Alert: ''" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

Write-Host "
Manual Verification Steps:" -ForegroundColor Green
Write-Host "1. Open SigNoz UI: http://localhost:8080"
Write-Host "2. Navigate to Alerts"
Write-Host "3. Find the alert named ''"
Write-Host "4. Verify its status (should be 'Active' if patterns are flowing normally)"
Write-Host "5. Check the 'Logs' section in SigNoz using the query:"
Write-Host "   message contains "hurst_estimate" AND log.file.path contains "canary-pattern-results.json""
Write-Host "6. Confirm that fractal pattern logs are visible with Hurst estimates"

Write-Host "
Expected Hurst Values:" -ForegroundColor Cyan
Write-Host "  Steady Pattern: H ≈ 0.5 (random walk)"
Write-Host "  Poisson Pattern: H ≈ 0.5 (memoryless process)"
Write-Host "  Pareto Pattern: H > 0.5 (long-range dependence)"

Write-Host "
Alert Thresholds:" -ForegroundColor Yellow
Write-Host "  Drift Alert: H > 0.7 (persistent behavior)"
Write-Host "  Anti-persistent: H < 0.3 (mean-reverting behavior)"
Write-Host "  Normal Range: 0.3 ≤ H ≤ 0.7 (acceptable variation)"

Write-Host "
To test the alert:" -ForegroundColor Green
Write-Host "1. Run daily pattern drills to generate baseline data"
Write-Host "2. Monitor alert status for any drift detection"
Write-Host "3. Investigate if persistent behavior (H > 0.7) is detected"

Write-Host "
Investigation Resources:" -ForegroundColor Cyan
Write-Host "  Analysis Report: artifacts/poisson-anomaly-analysis-report.md"
Write-Host "  Investigation Results: artifacts/poisson-anomaly-investigation.json"
Write-Host "  Pattern Results: artifacts/canary-pattern-results.json"
