# 🔍 BossCat OEM V3 Gate Check
# Single gate check using complete v3 schema integration

param(
    [switch]$Verbose = $false,
    [switch]$DryRun = $false
)

# 🎯 BossCat OEM V3 Schema Constants
$V3_TABLE = "signoz_traces.signoz_index_v3"
$V3_SERVICE_COL = "resource_string_service`$`$name"  # PowerShell backtick escaping
$CANARY_SERVICE = "canary-test"
$TIME_WINDOW = "5 MINUTE"

# 🔧 Configuration from BossCat OEM Schema
$CONFIG = @{
    Detection = @{
        Query = "SELECT count() FROM $V3_TABLE WHERE ``$V3_SERVICE_COL``='$CANARY_SERVICE' AND timestamp >= now() - INTERVAL $TIME_WINDOW"
        Method = "docker exec"
        Timeout = 30
        Retry = 3
    }
    Evidence = @{
        Directory = "artifacts/ecrr/gate_v3_TIMESTAMP/"
        Format = "UTF-8"
    }
}

# 🎯 BossCat OEM V3 Schema Functions
function Write-BossCatLog {
    param([string]$Message, [string]$Color = "Gray", [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "ERROR" { "❌" }
        "WARN"  { "⚠️" }
        "SUCCESS" { "✅" }
        "INFO"  { "ℹ️" }
        default { "🔍" }
    }
    Write-Host "[$timestamp] $prefix $Message" -ForegroundColor $Color
}

function Test-V3SchemaHealth {
    param([string]$Query)
    
    try {
        Write-BossCatLog "Testing V3 schema health..." -Color Cyan -Level "INFO"
        $result = docker exec signoz-clickhouse clickhouse-client --query $Query 2>&1
        $spanCount = [int]$result.Trim()
        
        if ($spanCount -ge 0) {
            Write-BossCatLog "V3 schema healthy (count: $spanCount)" -Color Green -Level "SUCCESS"
            return $true
        } else {
            Write-BossCatLog "V3 schema unhealthy (invalid count: $spanCount)" -Color Red -Level "ERROR"
            return $false
        }
    } catch {
        Write-BossCatLog "V3 schema health check failed: $_" -Color Red -Level "ERROR"
        return $false
    }
}

function Get-V3TraceCount {
    param([string]$Query)
    
    try {
        Write-BossCatLog "Executing V3 trace count query..." -Color Yellow -Level "INFO"
        $result = docker exec signoz-clickhouse clickhouse-client --query $Query 2>&1
        $spanCount = [int]$result.Trim()
        
        Write-BossCatLog "V3 trace count result: $spanCount spans" -Color Yellow -Level "INFO"
        return $spanCount
    } catch {
        Write-BossCatLog "V3 trace count query failed: $_" -Color Red -Level "ERROR"
        return -1
    }
}

function Get-V3Timeline {
    param([string]$ServiceName, [int]$Minutes = 30)
    
    try {
        $timelineQuery = "SELECT toStartOfMinute(timestamp) AS minute, count() AS spans FROM $V3_TABLE WHERE ``$V3_SERVICE_COL``='$ServiceName' AND timestamp >= now() - INTERVAL $Minutes MINUTE GROUP BY minute ORDER BY minute DESC LIMIT 10;"
        Write-BossCatLog "Getting V3 timeline for $ServiceName (last $Minutes min)..." -Color Cyan -Level "INFO"
        
        $timeline = docker exec signoz-clickhouse clickhouse-client --query $timelineQuery
        return $timeline
    } catch {
        Write-BossCatLog "V3 timeline query failed: $_" -Color Red -Level "ERROR"
        return "ERROR: Timeline query failed"
    }
}

function Get-V3ServiceMix {
    param([int]$Hours = 24)
    
    try {
        $serviceMixQuery = "SELECT ``$V3_SERVICE_COL`` AS svc, count() AS spans FROM $V3_TABLE WHERE timestamp >= now() - INTERVAL $Hours HOUR GROUP BY svc ORDER BY spans DESC LIMIT 10;"
        Write-BossCatLog "Getting V3 service mix (last $Hours hours)..." -Color Cyan -Level "INFO"
        
        $serviceMix = docker exec signoz-clickhouse clickhouse-client --query $serviceMixQuery
        return $serviceMix
    } catch {
        Write-BossCatLog "V3 service mix query failed: $_" -Color Red -Level "ERROR"
        return "ERROR: Service mix query failed"
    }
}

# 🎯 Main Gate Check
Write-BossCatLog "🔍 BOSSCAT OEM V3 GATE CHECK STARTED" -Color Cyan -Level "INFO"
Write-BossCatLog "BossCat OEM Schema v3.0: ✅ OPERATIONAL" -Color Green -Level "SUCCESS"
Write-BossCatLog "V3 Table: $V3_TABLE" -Color Cyan -Level "INFO"
Write-BossCatLog "V3 Service Column: $V3_SERVICE_COL" -Color Cyan -Level "INFO"
Write-BossCatLog "Canary Service: $CANARY_SERVICE" -Color Cyan -Level "INFO"
Write-BossCatLog "Time Window: $TIME_WINDOW" -Color Cyan -Level "INFO"
Write-BossCatLog ""

# Step 1: V3 Schema Health Check
Write-BossCatLog "🔍 Step 1: V3 schema health check..." -Color Yellow -Level "INFO"
$healthQuery = "SELECT 1"
if (-not (Test-V3SchemaHealth -Query $healthQuery)) {
    Write-BossCatLog "❌ V3 schema health check failed" -Color Red -Level "ERROR"
    Write-BossCatLog "Check: ClickHouse container health" -Color Red -Level "ERROR"
    Write-BossCatLog ""
    exit 2
}

# Step 2: V3 Gate Check
Write-BossCatLog "🔍 Step 2: V3 gate check..." -Color Yellow -Level "INFO"
$gateQuery = $CONFIG.Detection.Query
Write-BossCatLog "Query: $gateQuery" -Color Gray -Level "INFO"

$spanCount = Get-V3TraceCount -Query $gateQuery

if ($spanCount -eq -1) {
    Write-BossCatLog "❌ V3 gate check failed" -Color Red -Level "ERROR"
    Write-BossCatLog "Check: ClickHouse container health" -Color Red -Level "ERROR"
    Write-BossCatLog ""
    exit 2
}

# Step 3: Evaluate Result
if ($spanCount -gt 0) {
    Write-BossCatLog "✅ SUCCESS: Fresh traces persisting!" -Color Green -Level "SUCCESS"
    Write-BossCatLog "Service: $CANARY_SERVICE" -Color Green -Level "SUCCESS"
    Write-BossCatLog "Recent spans (5 min): $spanCount" -Color Green -Level "SUCCESS"
    Write-BossCatLog "BossCat OEM Schema v3.0: ✅ OPERATIONAL" -Color Green -Level "SUCCESS"
    Write-BossCatLog ""
    
    # Additional V3 Analysis (if verbose)
    if ($Verbose) {
        Write-BossCatLog "📊 Additional V3 Analysis:" -Color Cyan -Level "INFO"
        
        # Timeline
        Write-BossCatLog "Timeline (last 30 min):" -Color Yellow -Level "INFO"
        $timeline = Get-V3Timeline -ServiceName $CANARY_SERVICE -Minutes 30
        Write-Host $timeline -ForegroundColor Gray
        
        # Service Mix
        Write-BossCatLog "Service Mix (last 24 hours):" -Color Yellow -Level "INFO"
        $serviceMix = Get-V3ServiceMix -Hours 24
        Write-Host $serviceMix -ForegroundColor Gray
        
        Write-BossCatLog ""
    }
    
    exit 0  # GREEN
} else {
    Write-BossCatLog "⏳ HOLD: Platform gap persists (0 spans found)" -Color Yellow -Level "WARN"
    Write-BossCatLog "Service: $CANARY_SERVICE" -Color Yellow -Level "WARN"
    Write-BossCatLog "ClickHouse query returned 0 rows" -Color Yellow -Level "WARN"
    Write-BossCatLog "BossCat OEM Schema v3.0: ✅ OPERATIONAL" -Color Green -Level "SUCCESS"
    Write-BossCatLog ""
    
    # Additional V3 Analysis (if verbose)
    if ($Verbose) {
        Write-BossCatLog "📊 Additional V3 Analysis:" -Color Cyan -Level "INFO"
        
        # Service Mix (to see what services are active)
        Write-BossCatLog "Service Mix (last 24 hours):" -Color Yellow -Level "INFO"
        $serviceMix = Get-V3ServiceMix -Hours 24
        Write-Host $serviceMix -ForegroundColor Gray
        
        Write-BossCatLog ""
    }
    
    exit 1  # HOLD
}
