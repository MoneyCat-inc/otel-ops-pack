# 🐾 BossCat OEM - API-Based Verification Guide

**Status:** ✅ Implemented  
**Date:** 2025-10-08  
**Feature:** Explicit span confirmation via SigNoz Trace API

---

## Overview

The verification system now includes **API-based canary confirmation** in addition to log heuristics. This provides **provable verification** that spans actually landed in SigNoz.

### Architecture
```
Canary Script → OTLP/HTTP (4318) → SigNoz Collector → ClickHouse
                                         ↓
                            verify-pipeline.ps1 queries API
                                         ↓
                            POST /api/v5/query_range
                                         ↓
                            Confirms span exists ✅
```

---

## Setup

### 1. Create API Key in SigNoz

1. Open SigNoz UI: http://localhost:8080
2. Navigate to **Settings → API Keys**
3. Click **Create New Key**
4. Name: `gate-verification`
5. Copy the generated key

**Documentation:** https://signoz.io/docs/traces-management/trace-api/overview/

### 2. Set Environment Variable

```powershell
# Set for current session
$env:SIGNOZ_API_KEY = "your-api-key-here"

# Set permanently (Machine level)
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY", "your-api-key-here", "Machine")

# Set permanently (User level)
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY", "your-api-key-here", "User")

# Verify
$env:SIGNOZ_API_KEY
```

### 3. Test API Access

```powershell
# Manual test with curl
$apiKey = $env:SIGNOZ_API_KEY
$nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$startMs = $nowMs - 120000  # Last 2 minutes

$payload = @{
  start = $startMs
  end   = $nowMs
  requestType = "raw"
  compositeQuery = @{
    queries = @(@{
      type = "builder_query"
      spec = @{
        name = "A"
        signal = "traces"
        filter = @{ expression = "serviceName = 'synthetic-windows-check'" }
        selectFields = @(@{ name = "traceID" }, @{ name = "spanID" })
        limit = 1
      }
    })
  }
} | ConvertTo-Json -Depth 12

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8080/api/v5/query_range" `
  -Headers @{ "SIGNOZ-API-KEY" = $apiKey } `
  -ContentType "application/json" `
  -Body $payload
```

---

## How It Works

### Verification Flow

1. **Quick Monitor** runs (services, ports, docker)
2. **Canary Trace** sent via OTLP HTTP (port 4318)
3. **Wait Period** (60 seconds default)
4. **Log Check** (heuristic via collector logs)
5. **API Check** (explicit via SigNoz Trace API) ← **NEW**
6. **Gate Decision** (combines both confirmations)

### API Check Function

The `Invoke-SigNozApiTraceCheck` function:

```powershell
Invoke-SigNozApiTraceCheck -ServiceName "synthetic-windows-check" -LookbackSeconds 120
```

**Parameters:**
- `BaseUrl` - SigNoz base URL (default: http://localhost:8080)
- `ApiKeyEnv` - Environment variable name (default: SIGNOZ_API_KEY)
- `ServiceName` - Service to query (default: synthetic-windows-check)
- `LookbackSeconds` - Time window to search (default: 120)

**Returns:**
```powershell
@{
  ok = $true/$false
  reason = "span_found" | "no_span_found" | "missing_api_key" | "http_error"
  raw = <API response object>
}
```

### Decision Logic

```powershell
# Old: Only log-based
$span_rate_nonzero = $canaryConfirmed

# New: API OR log-based (more resilient)
$span_rate_nonzero = ($canaryConfirmed -or $apiCheck.ok)
```

**Benefit:** If collector logs are unavailable/lost, API check still provides confirmation.

---

## API Endpoint Details

### POST /api/v5/query_range

**Reference:** https://signoz.io/docs/traces-management/trace-api/overview/

**Headers:**
```
SIGNOZ-API-KEY: <your-api-key>
Content-Type: application/json
```

**Payload:**
```json
{
  "start": <unix-ms-timestamp>,
  "end": <unix-ms-timestamp>,
  "requestType": "raw",
  "compositeQuery": {
    "queries": [
      {
        "type": "builder_query",
        "spec": {
          "name": "A",
          "signal": "traces",
          "filter": {
            "expression": "serviceName = 'synthetic-windows-check'"
          },
          "selectFields": [
            { "name": "traceID" },
            { "name": "spanID" },
            { "name": "spanName" },
            { "name": "timestamp" }
          ],
          "order": [
            { "key": { "name": "timestamp" }, "direction": "desc" }
          ],
          "limit": 1,
          "offset": 0,
          "disabled": false
        }
      }
    ]
  }
}
```

**Response:** JSON with trace data (if found)

---

## Verification Output

### JSON Summary (Enhanced)

```json
{
  "timestamp_utc": "2025-10-08T23:45:00Z",
  "service_name": "synthetic-windows-check",
  "gate_id": "GATE-2025-10-08-234500",
  "steps": {
    "quick_monitor": "pass",
    "canary_send": {
      "exit_code": 0,
      "log_confirmed": true,
      "api_confirmed": true,        ← NEW
      "api_reason": "span_found",   ← NEW
      "status": "pass"
    }
  },
  "gate_checks": {
    "collector_service_running": true,
    "otlp_reachable": true,
    "span_rate_nonzero": true,
    "export_drops_zero": true,
    "error_ratio_under_5pct": true
  },
  "outcome": "OK",
  "exit_code": 0
}
```

### Console Output

```
[verify] Step 2/3: canary trace
✓ Canary sent successfully
[verify] Waiting up to 60 s for ingestion...
✓ Canary confirmed in collector logs

[verify] API check (SigNoz Trace API)...
[api-check] Querying http://localhost:8080/api/v5/query_range for service 'synthetic-windows-check' (last 120 s)...
[api-check] ✓ Span confirmed via SigNoz API

✅ VERIFICATION OK — pipeline healthy
```

---

## Troubleshooting

### Missing API Key

**Symptom:**
```
WARNING: [api-check] No API key in SIGNOZ_API_KEY environment variable
ℹ️  Create API key in SigNoz: Settings → API Keys
```

**Solution:**
```powershell
# Set environment variable
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY", "your-key", "Machine")

# Restart PowerShell or reload environment
$env:SIGNOZ_API_KEY = [Environment]::GetEnvironmentVariable("SIGNOZ_API_KEY", "Machine")
```

### API Request Failed

**Symptom:**
```
WARNING: [api-check] Request failed: Connection refused
```

**Solutions:**
1. Check SigNoz is running: `docker ps --filter "name=signoz"`
2. Verify URL is correct: `http://localhost:8080`
3. Test API manually: See "Test API Access" section above
4. Check firewall/network connectivity

### No Spans Found

**Symptom:**
```
WARNING: [api-check] No spans found for service 'synthetic-windows-check' in last 120 s
```

**Solutions:**
1. Check canary script actually sent data
2. Verify OTLP endpoint is correct (4318 for HTTP)
3. Check collector logs: `docker logs signoz-otel-collector`
4. Increase lookback window in verify-pipeline.ps1
5. Manually query in SigNoz UI: **Traces → Filter by service name**

---

## Performance Considerations

### API Check Latency

- **Typical:** 50-200ms
- **Timeout:** 30 seconds
- **Impact:** Adds ~1-2 seconds to verification (including wait after canary)

### Alternatives for Ultra-Low Latency

For environments needing <100ms verification, consider:

1. **Direct ClickHouse Query** (via `clickhouse_sql`)
2. **Redis Cache** (if SigNoz supports caching layer)
3. **Skip API check** (rely on log heuristic only)

Current implementation provides good balance of reliability and speed.

---

## Manual Testing

### Quick API Test (PowerShell)

```powershell
# Test API endpoint directly
$apiKey = $env:SIGNOZ_API_KEY
$nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$startMs = $nowMs - 120000

$headers = @{ "SIGNOZ-API-KEY" = $apiKey }
$body = @{
  start = $startMs
  end = $nowMs
  requestType = "raw"
  compositeQuery = @{
    queries = @(@{
      type = "builder_query"
      spec = @{
        name = "A"
        signal = "traces"
        filter = @{ expression = "serviceName = 'synthetic-windows-check'" }
        selectFields = @(@{ name = "traceID" })
        limit = 1
      }
    })
  }
} | ConvertTo-Json -Depth 12

$response = Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8080/api/v5/query_range" `
  -Headers $headers `
  -ContentType "application/json" `
  -Body $body

$response | ConvertTo-Json -Depth 10
```

### Test Full Verification

```powershell
# With API key set
pwsh -File scripts\verify-pipeline.ps1

# Check output
cat out\gate_verification.json | ConvertFrom-Json | Format-List

# Should show:
#   api_confirmed: True
#   api_reason: span_found
```

---

## OTLP Endpoint Reference

### HTTP vs gRPC

**Current Implementation:** HTTP/Protobuf on port **4318**

```powershell
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318"
```

**Alternative:** gRPC on port **4317**

```powershell
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4317"
```

**Windows Compatibility:** HTTP/Protobuf (4318) avoids `grpcio` native dependency issues on Windows. This is the recommended approach for Windows environments.

**Reference:** https://signoz.io/docs/instrumentation/opentelemetry-fastapi/

---

## CI/CD Integration

### GitHub Actions

API key should be stored as a secret:

```yaml
env:
  SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}

steps:
  - name: Run verification
    run: pwsh -File scripts/verify-pipeline.ps1
```

**Setup:**
1. GitHub Repo → Settings → Secrets and variables → Actions
2. New repository secret: `SIGNOZ_API_KEY`
3. Paste your API key value

### Local CI/CD

For Jenkins, Azure Pipelines, etc.:

```powershell
# Set in build environment
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY", $env:SECRET_SIGNOZ_KEY, "Process")

# Run verification
pwsh -File scripts\verify-pipeline.ps1
```

---

## Security Considerations

### API Key Protection

- ✅ Store in environment variables (not in code)
- ✅ Use Machine/User scope (not hardcoded)
- ✅ Rotate keys regularly
- ✅ Use GitHub Secrets for CI/CD
- ✅ Never commit keys to repository

### Network Security

- API endpoint is local by default (localhost:8080)
- For remote SigNoz, use HTTPS and proper authentication
- Consider VPN/firewall rules for production environments

---

## Benefits of API-Based Verification

### 1. Provable Confirmation
- ✅ Explicit span exists in SigNoz database
- ✅ Not reliant on log parsing heuristics
- ✅ Direct query to source of truth

### 2. Resilience
- ✅ Works even if collector logs are lost/rotated
- ✅ Combines with log check (dual verification)
- ✅ Fallback if one method fails

### 3. Audit Compliance
- ✅ Uses documented SigNoz API
- ✅ Provides traceable API requests
- ✅ JSON output includes API confirmation status

### 4. Metrics Collection
- ✅ Can measure ingestion latency
- ✅ Can track API response times
- ✅ Foundation for SLO tracking

---

## Future Enhancements

### ClickHouse Direct Query

For ultra-low latency (<100ms):

```powershell
# Query ClickHouse directly via clickhouse_sql
# Requires ClickHouse client setup
# Bypasses SigNoz API layer
```

### Latency Measurement

Add span ingestion latency tracking:

```powershell
$sendTime = Get-Date
# ... send canary ...
$spanFoundTime = <query API for span timestamp>
$latency = ($spanFoundTime - $sendTime).TotalMilliseconds
```

### Error Rate Calculation

Query API for error spans:

```json
{
  "filter": {
    "expression": "serviceName = 'X' AND status != 'OK'"
  }
}
```

---

## References

- **SigNoz Trace API:** https://signoz.io/docs/traces-management/trace-api/overview/
- **OpenTelemetry OTLP:** https://signoz.io/docs/instrumentation/opentelemetry-fastapi/
- **BossCat Gate Framework:** `docs/AGENTS.md`
- **Verification Script:** `scripts/verify-pipeline.ps1`

---

🐾 **BossCat OEM** | API-Based Verification  
**Status:** Production Ready  
**Last Updated:** 2025-10-08

