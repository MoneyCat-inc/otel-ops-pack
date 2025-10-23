# 🟢 Gate Advancement Script — Evidence-Based GREEN Flip
# Executes when platform fix lands: verify traces → package evidence → flip GREEN
# BossCat ECRR compliant: single-writer, lane-locked, budgets enforced

Write-Host ""
Write-Host "🟢 GATE ADVANCEMENT - TRACE VERIFICATION" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

# 1) Send canary trace
Write-Host "📤 Step 1: Sending canary trace..." -ForegroundColor Cyan
pwsh -File .\send-canary-trace-direct.ps1
Write-Host ""

# 2) Prove traces exist (5-min window)
Write-Host "🔍 Step 2: Querying ClickHouse for traces..." -ForegroundColor Cyan
$query = @"
SELECT count()
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE
"@

[int]$count = docker exec signoz-clickhouse clickhouse-client --query "$query"
Write-Host "   Traces found (last 5 min): $count" -ForegroundColor Yellow
Write-Host ""

# 3) Package evidence + ECRR
Write-Host "📦 Step 3: Packaging evidence..." -ForegroundColor Cyan
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$dir = "artifacts\ecrr\gate"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

# Save trace count
$count | Out-File "$dir\trace_count_$ts.txt" -Encoding utf8
Write-Host "   ✅ Saved: $dir\trace_count_$ts.txt" -ForegroundColor Green

# Get timeline (last 30 min)
$timelineQuery = @"
SELECT toStartOfMinute(timestamp) AS minute, count() AS c
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 30 MINUTE
GROUP BY minute
ORDER BY minute DESC
LIMIT 10
"@

$timeline = docker exec signoz-clickhouse clickhouse-client --query "$timelineQuery"
$timeline | Out-File "$dir\trace_timeline_$ts.txt" -Encoding utf8
Write-Host "   ✅ Saved: $dir\trace_timeline_$ts.txt" -ForegroundColor Green

# Save service name assertion
"canary-test" | Out-File "$dir\service_name_$ts.txt" -Encoding utf8
Write-Host "   ✅ Saved: $dir\service_name_$ts.txt" -ForegroundColor Green

# 4) Emit ECRR JSON artifact
Write-Host ""
Write-Host "📋 Step 4: Creating ECRR artifact..." -ForegroundColor Cyan

if ($count -ge 1) {
    $ecrr = @{
        t = (Get-Date).ToUniversalTime().ToString("o")
        who = "Cursor{Implementer}"
        type = "report"
        lane = "gate"
        msg = "Traces persisted for service.name=canary-test"
        artifacts = @(
            "artifacts/ecrr/gate/trace_count_$ts.txt",
            "artifacts/ecrr/gate/trace_timeline_$ts.txt",
            "artifacts/ecrr/gate/service_name_$ts.txt"
        )
        result = "GREEN"
        evidence = @{
            service_name = "canary-test"
            span_count = $count
            window = "5 minutes"
            query_method = "docker exec"
            table = "span_attributes"
            timestamp = $ts
        }
    } | ConvertTo-Json -Depth 4
    
    $ecrr | Out-File "$dir\ECRR_TRACE_PROOF_$ts.json" -Encoding utf8
    Write-Host "   ✅ ECRR artifact created: ECRR_TRACE_PROOF_$ts.json" -ForegroundColor Green
    Write-Host ""
    
    # Success message
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "✅ GATE ADVANCEMENT: READY FOR GREEN" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "Evidence Package:" -ForegroundColor Yellow
    Write-Host "  - Trace count: $count spans" -ForegroundColor White
    Write-Host "  - Service: canary-test" -ForegroundColor White
    Write-Host "  - Window: 5 minutes" -ForegroundColor White
    Write-Host "  - Method: docker exec (validated)" -ForegroundColor White
    Write-Host ""
    Write-Host "Artifacts:" -ForegroundColor Yellow
    Write-Host "  - $dir\trace_count_$ts.txt" -ForegroundColor White
    Write-Host "  - $dir\trace_timeline_$ts.txt" -ForegroundColor White
    Write-Host "  - $dir\service_name_$ts.txt" -ForegroundColor White
    Write-Host "  - $dir\ECRR_TRACE_PROOF_$ts.json" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review evidence artifacts" -ForegroundColor White
    Write-Host "  2. Commit artifacts to repository" -ForegroundColor White
    Write-Host "  3. Post @cat ready-for-gate with bundle" -ForegroundColor White
    Write-Host "  4. Update BOSSCAT_LOG.md with gate entry" -ForegroundColor White
    Write-Host ""
    Write-Host "Gate Verdict: 🟠 WARN → 🟢 GREEN" -ForegroundColor Green
    Write-Host ""
    
    exit 0  # GREEN
} else {
    Write-Host "   ⏳ No ECRR artifact created (count = 0)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "⏳ GATE ADVANCEMENT: HOLDING AT WARN" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Platform Gap:" -ForegroundColor Yellow
    Write-Host "  - Traces found: 0 spans" -ForegroundColor White
    Write-Host "  - Service searched: canary-test" -ForegroundColor White
    Write-Host "  - Window: 5 minutes" -ForegroundColor White
    Write-Host ""
    Write-Host "Status:" -ForegroundColor Yellow
    Write-Host "  - SigNoz exporter→ClickHouse gap still present" -ForegroundColor White
    Write-Host "  - Continue monitoring (2-min polling)" -ForegroundColor White
    Write-Host "  - Gate remains: 🟠 WARN" -ForegroundColor White
    Write-Host ""
    
    exit 1  # HOLD
}

