# 🔍 SigNoz v3 Trace Schema Analyzer
# Understands exactly what the v3 schema is doing with traces
# Enables trace reingestion with modified attributes

param(
    [string]$ServiceName = "",
    [int]$LimitRows = 20,
    [switch]$ShowSchema = $false
)

Write-Host ""
Write-Host "🔍 SIGNOZ V3 TRACE SCHEMA ANALYZER" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# 1) Show v3 schema structure (if requested)
if ($ShowSchema) {
    Write-Host "📋 V3 SCHEMA STRUCTURE (signoz_index_v3)" -ForegroundColor Yellow
    Write-Host ""
    
    $schema = docker exec signoz-clickhouse clickhouse-client --query `
        "DESCRIBE signoz_traces.signoz_index_v3 FORMAT PrettyCompact;"
    
    Write-Host $schema
    Write-Host ""
}

# 2) Discover all service names currently in v3
Write-Host "🔎 DISCOVERING SERVICE NAMES IN V3..." -ForegroundColor Yellow
Write-Host ""

$servicesQuery = @"
SELECT ``resource_string_service`$`$name`` AS service_name,
       count() AS total_spans,
       min(timestamp) AS first_seen,
       max(timestamp) AS last_seen
FROM signoz_traces.signoz_index_v3
GROUP BY service_name
ORDER BY total_spans DESC
LIMIT $LimitRows;
"@

$services = docker exec signoz-clickhouse clickhouse-client --query $servicesQuery --format=PrettyCompact

Write-Host $services
Write-Host ""

# 3) If specific service requested, show details
if ($ServiceName -ne "") {
    Write-Host "📊 ANALYZING SERVICE: $ServiceName" -ForegroundColor Yellow
    Write-Host ""
    
    # Recent activity
    Write-Host "Recent Activity (last 30 min):" -ForegroundColor Cyan
    $recentQuery = "SELECT toStartOfMinute(timestamp) AS minute, count() AS spans FROM signoz_traces.signoz_index_v3 WHERE ``resource_string_service`$`$name``='$ServiceName' AND timestamp >= now() - INTERVAL 30 MINUTE GROUP BY minute ORDER BY minute DESC LIMIT 10;"
    $recent = docker exec signoz-clickhouse clickhouse-client --query $recentQuery --format=PrettyCompact
    Write-Host $recent
    Write-Host ""
    
    # Sample spans
    Write-Host "Sample Spans (recent):" -ForegroundColor Cyan
    $sampleQuery = "SELECT timestamp, trace_id, span_id, name, duration_nano FROM signoz_traces.signoz_index_v3 WHERE ``resource_string_service`$`$name``='$ServiceName' ORDER BY timestamp DESC LIMIT 5;"
    $samples = docker exec signoz-clickhouse clickhouse-client --query $sampleQuery --format=PrettyCompact
    Write-Host $samples
    Write-Host ""
    
    # Resource attributes
    Write-Host "Resource Attributes (sample from latest span):" -ForegroundColor Cyan
    $resourceQuery = "SELECT resources_string FROM signoz_traces.signoz_index_v3 WHERE ``resource_string_service`$`$name``='$ServiceName' ORDER BY timestamp DESC LIMIT 1;"
    $resources = docker exec signoz-clickhouse clickhouse-client --query $resourceQuery
    Write-Host $resources
    Write-Host ""
}

# 4) Show materialized vs map columns
Write-Host "🧬 V3 SCHEMA INSIGHTS" -ForegroundColor Yellow
Write-Host ""
Write-Host "Materialized Columns (optimized for queries):" -ForegroundColor Cyan
Write-Host "  - resource_string_service`$`$name     → resources_string['service.name']"
Write-Host "  - attribute_string_http`$`$route      → attributes_string['http.route']"
Write-Host "  - attribute_string_db`$`$system       → attributes_string['db.system']"
Write-Host "  - attribute_string_rpc`$`$system      → attributes_string['rpc.system']"
Write-Host ""
Write-Host "Map Columns (full attribute access):" -ForegroundColor Cyan
Write-Host "  - resources_string    → Map(String, String) of all resource attributes"
Write-Host "  - attributes_string   → Map(String, String) of all span attributes"
Write-Host "  - attributes_number   → Map(String, Float64) of numeric attributes"
Write-Host "  - attributes_bool     → Map(String, Bool) of boolean attributes"
Write-Host ""

# 5) Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ v3 uses signoz_index_v3 table (not span_attributes)"
Write-Host "✅ Service names stored in: resource_string_service`$`$name column"
Write-Host "✅ Materialized columns for fast queries (service, http, db, rpc)"
Write-Host "✅ Full attribute access via map columns (resources_string, attributes_string)"
Write-Host ""
Write-Host "USAGE:" -ForegroundColor Yellow
Write-Host "  # Show all services:"
Write-Host "    pwsh -File analyze-trace-schema.ps1"
Write-Host ""
Write-Host "  # Analyze specific service:"
Write-Host "    pwsh -File analyze-trace-schema.ps1 -ServiceName 'canary-test'"
Write-Host ""
Write-Host "  # Show full v3 schema:"
Write-Host "    pwsh -File analyze-trace-schema.ps1 -ShowSchema"
Write-Host ""

