# SigNoz ECRR Compliance Dashboard Import Guide
# Manual steps to import and configure the ECRR compliance dashboard

Write-Host "📊 SigNoz ECRR Compliance Dashboard Import Guide" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "🎯 Dashboard Overview:" -ForegroundColor Green
Write-Host "This dashboard provides comprehensive monitoring of ECRR compliance trends" -ForegroundColor White
Write-Host "and threshold breaches using the ecrr_compliance dataset from SigNoz logs." -ForegroundColor White

Write-Host ""
Write-Host "📋 Manual Import Steps:" -ForegroundColor Yellow
Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "2. Navigate to Dashboards → Import" -ForegroundColor White
Write-Host "3. Upload the file: artifacts/signoz-ecrr-compliance-dashboard.json" -ForegroundColor White
Write-Host "4. Configure data source if needed" -ForegroundColor White
Write-Host "5. Save the dashboard" -ForegroundColor White

Write-Host ""
Write-Host "🔍 Dashboard Panels:" -ForegroundColor Cyan
Write-Host "• Compliance Rate Overview - Current compliance percentage with color thresholds" -ForegroundColor White
Write-Host "• Compliance Rate Trend - Time series chart showing compliance over time" -ForegroundColor White
Write-Host "• Threshold Breaches - Count of compliance rate drops below 80%" -ForegroundColor White
Write-Host "• Trend Direction - Shows if compliance is improving, declining, or stable" -ForegroundColor White
Write-Host "• Reports Status - Number of passed vs failed reports" -ForegroundColor White
Write-Host "• Compliance Timeline - Historical view with threshold line" -ForegroundColor White
Write-Host "• Trend Analysis - Table showing trend details and recommendations" -ForegroundColor White

Write-Host ""
Write-Host "📊 Key SigNoz Queries:" -ForegroundColor Cyan
Write-Host "Compliance Rate:" -ForegroundColor White
Write-Host '  {dataset="ecrr_compliance"} | json | unwrap compliance_rate' -ForegroundColor Gray
Write-Host ""
Write-Host "Trend Analysis:" -ForegroundColor White
Write-Host '  {dataset="ecrr_compliance"} | json | unwrap trend_percentage' -ForegroundColor Gray
Write-Host ""
Write-Host "Threshold Breaches:" -ForegroundColor White
Write-Host '  {dataset="ecrr_compliance"} | json | compliance_rate < 80' -ForegroundColor Gray
Write-Host ""
Write-Host "Recent Compliance Events:" -ForegroundColor White
Write-Host '  {dataset="ecrr_compliance"} | json | event="compliance_trend_calculated"' -ForegroundColor Gray

Write-Host ""
Write-Host "🎨 Color Thresholds:" -ForegroundColor Cyan
Write-Host "• Red: Compliance rate < 60%" -ForegroundColor Red
Write-Host "• Yellow: Compliance rate 60-79%" -ForegroundColor Yellow
Write-Host "• Green: Compliance rate ≥ 80%" -ForegroundColor Green

Write-Host ""
Write-Host "📈 Trend Indicators:" -ForegroundColor Cyan
Write-Host "• Improving: Trend percentage > +2%" -ForegroundColor Green
Write-Host "• Declining: Trend percentage < -2%" -ForegroundColor Red
Write-Host "• Stable: Trend percentage between -2% and +2%" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔧 Configuration Notes:" -ForegroundColor Cyan
Write-Host "• Dashboard refreshes every 30 seconds" -ForegroundColor White
Write-Host "• Time range defaults to last 1 hour" -ForegroundColor White
Write-Host "• All panels use the ecrr_compliance dataset" -ForegroundColor White
Write-Host "• JSON parsing extracts compliance metrics from log body" -ForegroundColor White

Write-Host ""
Write-Host "🚀 Testing the Dashboard:" -ForegroundColor Cyan
Write-Host "1. Run compliance monitoring: pwsh -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport" -ForegroundColor White
Write-Host "2. Check logs are created: Get-Content C:/logs/ecrr/compliance-trends.log -Tail 1" -ForegroundColor White
Write-Host "3. Verify SigNoz ingestion: Check SigNoz Logs with filter log.file.path contains 'C:/logs/ecrr/compliance-trends.log'" -ForegroundColor White
Write-Host "4. View dashboard: Refresh dashboard to see new data points" -ForegroundColor White

Write-Host ""
Write-Host "✅ Dashboard Ready for Import!" -ForegroundColor Green
Write-Host "Configuration file: artifacts/signoz-ecrr-compliance-dashboard.json" -ForegroundColor White
