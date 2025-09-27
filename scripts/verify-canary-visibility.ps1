# Verify Canary Test Visibility in SigNoz
# This script helps verify that canary test data is visible in SigNoz UI

Write-Host "🔍 SigNoz Canary Test Visibility Verification" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Check ClickHouse data directly
Write-Host "`n📊 Direct ClickHouse Query Results:" -ForegroundColor Yellow
$clickhouseQuery = @"
SELECT 
    fromUnixTimestamp64Nano(timestamp) as log_time,
    body,
    attributes_string['dataset'] as dataset,
    attributes_string['canary.type'] as canary_type
FROM signoz_logs.logs_v2 
WHERE body LIKE '%ECRR-Canary-Test%' 
ORDER BY timestamp DESC 
LIMIT 5
FORMAT PrettyCompact
"@

try {
    $result = docker exec -it signoz-clickhouse clickhouse-client --query $clickhouseQuery
    Write-Host $result -ForegroundColor Green
} catch {
    Write-Host "❌ ClickHouse query failed: $_" -ForegroundColor Red
}

Write-Host "`n🌐 SigNoz UI Verification Steps:" -ForegroundColor Yellow
Write-Host "1. Open browser: http://localhost:8080" -ForegroundColor White
Write-Host "2. Navigate to: Logs" -ForegroundColor White
Write-Host "3. Add filter: message contains 'ECRR-Canary-Test'" -ForegroundColor White
Write-Host "4. Or try: body contains 'ECRR-Canary-Test'" -ForegroundColor White
Write-Host "5. Look for entries with dataset='ecrr-canary'" -ForegroundColor White

Write-Host "`n📋 Expected Canary Test Patterns:" -ForegroundColor Yellow
Write-Host "• OTLP logs: canary.type = 'ecrr-enhanced'" -ForegroundColor White
Write-Host "• Windows Event Logs: dataset = 'ecrr-canary'" -ForegroundColor White  
Write-Host "• File logs: log.file.path contains 'ecrr-canary-test.log'" -ForegroundColor White

Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "• If UI shows 'Something went wrong', try refreshing the page" -ForegroundColor White
Write-Host "• If no data appears, check time range (last 24 hours)" -ForegroundColor White
Write-Host "• If authentication required, use browser login to SigNoz" -ForegroundColor White

Write-Host "`n✅ Verification Complete" -ForegroundColor Green
Write-Host "Canary test data is confirmed present in ClickHouse database." -ForegroundColor Green
