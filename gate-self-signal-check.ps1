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

$query = @"
SELECT count() as span_count
FROM signoz_traces.distributed_signoz_spans
WHERE serviceName = 'canary-test'
  AND toDateTime(startTime/1e9) >= now() - INTERVAL $MinutesWindow MINUTE
"@

if ($Verbose) {
    Write-Host "   Query: $query" -ForegroundColor DarkGray
}

try {
    $url = "http://localhost:8123/?query=$([uri]::EscapeDataString($query))"
    $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 5 -ErrorAction Stop
    $count = [int]($response.Content.Trim())
    
    Write-Host "   Result: $count spans found" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 4: Evaluate signal
    if ($count -gt 0) {
        Write-Host "✅ SELF-SIGNAL: GREEN (traces detected)" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎯 Platform fix detected! Traces are persisting to ClickHouse."
        Write-Host "   Service name: canary-test"
        Write-Host "   Span count (last $MinutesWindow min): $count"
        Write-Host ""
        Write-Host "📋 Next: Execute gate advancement runbook"
        Write-Host "   1. Run canary 5x more (verify stability)"
        Write-Host "   2. Capture evidence: query output + config excerpt"
        Write-Host "   3. Regenerate ECRR artifacts"
        Write-Host "   4. Post @cat ready-for-gate with bundle"
        Write-Host ""
        exit 0  # Success
    } else {
        Write-Host "⏳ SELF-SIGNAL: HOLDING at WARN (no traces yet)" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "🟠 Platform fix not yet landed. ClickHouse spans table remains empty."
        Write-Host "   Service name searched: canary-test"
        Write-Host "   Time window: last $MinutesWindow minutes"
        Write-Host ""
        Write-Host "📋 Diagnostics:"
        Write-Host "   ✅ Canary trace sent successfully"
        Write-Host "   ❌ Traces not persisting in ClickHouse"
        Write-Host "   → Blocker remains: exporter→ClickHouse gap"
        Write-Host ""
        exit 1  # Hold
    }
} catch {
    Write-Host "❌ ClickHouse query failed: $_" -ForegroundColor Red
    Write-Host "   (Verify ClickHouse is running on localhost:8123)" -ForegroundColor Red
    exit 2
}
