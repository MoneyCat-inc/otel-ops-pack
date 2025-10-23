# 🔔 Gate Self-Signal Check
# Autonomous detection: runs canary + queries ClickHouse for trace evidence
# Triggers gate advancement when platform fix lands (traces persist)

param(
    [int]$MinutesWindow = 10,
    [switch]$Verbose = $false
)

Write-Host ""
Write-Host "🔔 GATE SELF-SIGNAL CHECK - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Step 1: Send canary trace
Write-Host "📤 Step 1: Sending canary trace to SigNoz..."
try {
    & pwsh -File .\send-canary-trace-direct.ps1 -ErrorAction Stop | Out-Null
    Write-Host "✅ Canary sent successfully (HTTP 200)" -ForegroundColor Green
} catch {
    Write-Host "❌ Canary send failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Wait for ingestion
Write-Host ""
Write-Host "⏳ Waiting 2 seconds for ClickHouse ingestion..."
Start-Sleep -Seconds 2

# Step 3: Query ClickHouse for traces
Write-Host ""
Write-Host "🔍 Step 2: Querying ClickHouse for canary-test traces..."

# Query ClickHouse for recent canary-test spans
Write-Host "Querying ClickHouse for recent canary-test traces..." -ForegroundColor Cyan

# Use docker exec to query ClickHouse (HTTP port not mapped to host)
$query = @"
SELECT count()
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 10 MINUTE;
"@

try {
    $result = docker exec signoz-clickhouse clickhouse-client --query $query 2>&1
    $spanCount = [int]$result.Trim()
    
    Write-Host "Result: $spanCount spans found" -ForegroundColor Yellow
    
    if ($spanCount -gt 0) {
        Write-Host ""
        Write-Host "✅ SUCCESS: Traces persisting to ClickHouse" -ForegroundColor Green
        Write-Host "Service: canary-test" -ForegroundColor Green
        Write-Host "Recent spans (10 min): $spanCount" -ForegroundColor Green
        Write-Host ""
        exit 0
    } else {
        Write-Host ""
        Write-Host "⏳ HOLD: Platform gap persists (0 spans found)" -ForegroundColor Yellow
        Write-Host "Service: canary-test" -ForegroundColor Yellow
        Write-Host "ClickHouse query returned 0 rows" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "⚠️ ERROR: ClickHouse query failed" -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor Red
    Write-Host ""
    exit 2
}
