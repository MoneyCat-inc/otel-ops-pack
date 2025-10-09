# Resonai ↔ OTel Wiring Guide

This guide documents the integration between Resonai analytics and the local OpenTelemetry → SigNoz observability stack.

> Cross-project context: see the ECRR Project Report for the overarching Examine/Clean/Report/Role summary — [ECRR_PROJECT_REPORT.md](ECRR_PROJECT_REPORT.md)

## Purpose

The wiring forwards sanitized Resonai analytics events from `/api/events` to SigNoz via OTLP/HTTP, enabling:
- Real-time analytics monitoring in SigNoz
- Error rate tracking and alerting
- Performance metrics (TTV, activation rates)
- Debugging and troubleshooting analytics flows

## Dataflow

```mermaid
graph LR
    A[Resonai App] -->|POST /api/events| B[Next.js API Route]
    B --> C[In-Memory Ring Buffer]
    B -->|Tee| D[OTLP/HTTP Client]
    D -->|http://localhost:5318/v1/logs| E[Windows OTel Collector]
    E -->|http://localhost:14317| F[SigNoz Collector]
    F --> G[ClickHouse Storage]
    G --> H[SigNoz UI - Logs]
    
    I[MEMX Memory Monitoring] -->|OTLP/HTTP Metrics| E
    I --> J[MEMX Store]
    J --> K[Session Aggregates]
```

## Event → LogRecord Mapping

Each Resonai analytics event is converted to an OTLP LogRecord:

### Input Event Schema
```typescript
interface AnalyticsEvent {
  event: string;           // e.g., "screen_view", "permission_granted"
  session_id?: string;     // Session identifier
  variant?: string;        // A/B test variant
  ttv_ms?: number;         // Time to value (milliseconds)
  ua?: string;            // User agent
  cohort?: string;         // User cohort
  user_id?: string;        // User identifier
  props?: Record<string, any>; // Additional properties
  ts?: number;            // Timestamp
}
```

> **Note**: This schema aligns with the `AnalyticsEvent` interface defined in [Resonai Code Map](RESONAI_CODE_MAP.md#core-contracts).

### OTLP LogRecord Output
```typescript
interface OtlpLogRecord {
  body: { stringValue: string };     // JSON stringified original event
  attributes: [
    { key: "dataset", value: { stringValue: "resonai_analytics" } },
    { key: "event", value: { stringValue: "screen_view" } },
    { key: "session_id", value: { stringValue: "session_123" } },
    { key: "variant", value: { stringValue: "test" } },
    { key: "ttv_ms", value: { intValue: 150 } },
    // ... other attributes
  ];
  severityNumber: 9;      // INFO level
  severityText: "INFO";
  timeUnixNano: string;   // Nanoseconds since epoch
  observedTimeUnixNano: string;
}
```

## OTLP/HTTP Endpoint & Ports

- **Collector Endpoint**: `http://localhost:5318/v1/logs`
- **Protocol**: OTLP/HTTP JSON
- **Content-Type**: `application/json`
- **Batch Size**: ≤50 records per request
- **Retry Policy**: 2 retries with exponential backoff (250ms, 750ms)

### Port Configuration
- **5318**: Windows OTel Collector OTLP/HTTP receiver
- **5317**: Windows OTel Collector OTLP/gRPC receiver (not used for this integration)
- **14317**: SigNoz Collector OTLP/gRPC endpoint (collector export target)
- **14318**: SigNoz Collector OTLP/HTTP endpoint (alternative export target)

## MEMX Memory Metrics

The MEMX (Memory Observation Layer) system provides real-time browser memory monitoring via OTLP metrics:

### MEMX Metrics Schema

```typescript
interface MemxMetrics {
  // Observable Gauges
  "resonai_memx_wasm_heap_bytes": number;           // WASM linear memory usage
  "resonai_memx_sab_used_bytes": number;            // SharedArrayBuffer occupancy
  "resonai_memx_sab_capacity_bytes": number;        // SharedArrayBuffer total capacity
  "resonai_memx_strain_pct": number;                // Memory strain percentage
  
  // Histogram
  "resonai_memx_worklet_ui_lag": number;            // UI-to-AudioWorklet lag (ms)
}
```

### MEMX Configuration

```typescript
interface MemxConfig {
  enabled: boolean;                    // Feature flag
  streamDefault: boolean;             // Enable OTLP streaming by default
  otlpEndpoint?: string;              // OTLP/HTTP endpoint (default: http://localhost:5318)
  exportIntervalMs: number;          // Export interval (default: 5000ms)
}
```

### Environment Variables

```bash
# Enable MEMX feature
NEXT_PUBLIC_FEATURE_MEMX=1

# Enable OTLP streaming by default
NEXT_PUBLIC_MEMX_STREAM_DEFAULT=1

# OTLP endpoint (optional, defaults to http://localhost:5318)
NEXT_PUBLIC_MEMX_OTLP_ENDPOINT=http://localhost:5318
```

### MEMX Metrics Attributes

All MEMX metrics include standard resource attributes:
- `service.name`: "resonai-frontend"
- `service.version`: "1.0.0"
- `telemetry.sdk.language`: "webjs"
- `telemetry.sdk.name`: "memx-otel"
- `component`: "memx"

Additional metric-specific attributes:
- `component`: "wasm" | "audio"
- `ring`: "worklet_io" (for SAB metrics)
- `kind`: "memory_strain" | "none" (for strain metrics)

## Verification

### Automated Verification Script
```powershell
# Run the wiring verification
pwsh -File scripts/verify-wiring.ps1
```

The script will:
1. Check OTel Collector service status
2. Verify port connectivity (5318, 8080)
3. Send a test analytics event to `/api/events`
4. Query SigNoz for the test event
5. Test MEMX metrics export (if enabled)
6. Generate artifacts: `artifacts/wiring-verify.txt` and `artifacts/wiring-api.json`

### Manual Verification Steps

1. **Send test event**:
   ```bash
   curl -X POST http://localhost:3000/api/events \
     -H "Content-Type: application/json" \
     -d '{"event":"test_event","session_id":"test-123","variant":"test"}'
   ```

2. **Check SigNoz UI**:
   - Open http://localhost:8080
   - Navigate to Logs
   - Filter: `attributes.dataset = "resonai_analytics"`
   - Look for recent entries
   - Optional: add filter `attributes.log.source = "win-filelog"` to isolate Windows queue logs (upserted by the Windows collector attributes/label_source processor)

3. **API verification** (if SIGNOZ_API_TOKEN is set):
   ```bash
   curl -X POST http://localhost:8080/api/v5/query_range \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $SIGNOZ_API_TOKEN" \
     -d '{
       "start": 1640995200000,
       "end": 1640995260000,
       "requestType": "raw",
       "compositeQuery": {
         "queries": [{
           "type": "builder_query",
           "spec": {
             "name": "A",
             "signal": "logs",
             "filter": {
               "expression": "attributes.dataset = \"resonai_analytics\""
             },
             "order": [{"key": {"name": "timestamp"}, "direction": "desc"}],
             "limit": 10
           }
         }]
       }
     }'
   ```

4. **MEMX Metrics Verification** (if MEMX is enabled):
   - Navigate to SigNoz UI → Metrics
   - Filter: `service.name = "resonai-frontend"` AND `component = "memx"`
   - Look for MEMX metrics:
     - `resonai_memx_wasm_heap_bytes`
     - `resonai_memx_sab_used_bytes`
     - `resonai_memx_sab_capacity_bytes`
     - `resonai_memx_strain_pct`
     - `resonai_memx_worklet_ui_lag`
   - Verify metrics are updating every 5 seconds (export interval)

## SigNoz Dashboard Seeds

### Key Metrics to Track

1. **Error Rate**: `count(level="ERROR") / count(*) * 100`
2. **Event Volume**: `count by (attributes.event)`
3. **TTV Percentiles**: `quantile(0.5, attributes.ttv_ms)`, `quantile(0.9, attributes.ttv_ms)`
4. **Activation Rate**: `count(attributes.event="activation") / count(attributes.event="screen_view")`
5. **MEMX Memory Strain**: `resonai_memx_strain_pct`
6. **MEMX WASM Heap**: `resonai_memx_wasm_heap_bytes`
7. **MEMX Worklet Lag**: `resonai_memx_worklet_ui_lag`

### Sample Dashboard Queries

```sql
-- Error rate over time
rate(count by (level) (level="ERROR")[5m]) / rate(count[5m])

-- Top events by volume
count by (attributes.event) (attributes.dataset="resonai_analytics")

-- TTV distribution
histogram_quantile(0.5, sum(rate(attributes.ttv_ms[5m])) by (le))

-- Session analytics
count by (attributes.session_id, attributes.event) (attributes.dataset="resonai_analytics")

-- MEMX Memory Strain over time
resonai_memx_strain_pct{service_name="resonai-frontend"}

-- MEMX WASM Heap Usage
resonai_memx_wasm_heap_bytes{service_name="resonai-frontend"}

-- MEMX Worklet Lag Percentiles
histogram_quantile(0.95, sum(rate(resonai_memx_worklet_ui_lag_bucket[5m])) by (le))

-- MEMX SAB Utilization
resonai_memx_sab_used_bytes{service_name="resonai-frontend"} / resonai_memx_sab_capacity_bytes{service_name="resonai-frontend"} * 100
   ```

### Legacy schema (logs_v2) — sanity checks

Use these ClickHouse queries to verify recent ingestion under the legacy schema. Run from the host via Docker exec or a ClickHouse client.

```bash
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT count() FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 60 MINUTE;"
```

```bash
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT * FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 60 MINUTE
  ORDER BY timestamp DESC
  LIMIT 1;"
```

Filter equivalent in SigNoz UI → Logs (Last 1 hour):

- message contains `agent_queue`
- or attributes: `service.name = queue-steward` (after adding filelog attributes)

### Current storage toggle state

- `clickhouselogsexporter.use_new_schema: false` (legacy schema active)
- Do not flip to new schema until the migrator has been run successfully and new tables show fresh rows.

### Safe migration path to new schema

1. Sync schemas:

```bash
docker compose -f docker-compose-signoz.yml run --rm signoz-schema-migrator-sync
```

2. Dual-check for last 10 minutes:

```bash
# Legacy
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT count() FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 10 MINUTE;"

# New
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT count() FROM signoz_logs.distributed_logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 10 MINUTE;"
```

3. Flip and restart SigNoz collector:

- Edit `signoz-collector-config.yaml`: set `use_new_schema: true`
- Restart: `docker compose -f docker-compose-signoz.yml restart signoz-otel-collector`

4. Re-emit canary and re-validate against `signoz_logs.distributed_logs_v2` (Last 30 minutes).

## Troubleshooting

### Common Issues

#### 1. Port Conflicts & Mismatches
**Symptom**: Connection refused on port 5318 or logs not appearing in SigNoz
**Solution**: 
- Check if another service is using port 5318: `netstat -an | findstr 5318`
- Verify OTel Collector config uses correct ports
- **CRITICAL**: Ensure application instrumentation uses remapped ports (14317/14318) not default ports (4317/4318)
- Restart otelcol-contrib service: `Restart-Service otelcol-contrib`

#### 1.1 Port Mapping Issue (FIXED 2025-09-28)
**Symptom**: "No logs yet" in SigNoz UI despite collector running
**Root Cause**: Applications configured for default ports (4317/4318) but SigNoz running on remapped ports (14317/14318)
**Solution**: Updated all instrumentation to use remapped ports:
- `http://localhost:4317` → `http://localhost:14317`
- `http://localhost:4318` → `http://localhost:14318`

#### 2. OTLP Endpoint Double-Path Error (FIXED 2025-09-28)
**Symptom**: HTTP Status Code 404, "request to http://localhost:14318/v1/logs/v1/logs"
**Root Cause**: Windows collector config had `/v1/logs` appended to endpoint, causing double path
**Solution**: Fixed `config.yaml` OTLP exporter endpoint:
```yaml
# Before (causing double path)
otlphttp:
  endpoint: http://localhost:14318/v1/logs

# After (correct)
otlphttp:
  endpoint: http://localhost:14318
```

#### 3. Missing Receivers in Collector Config
**Symptom**: Events not appearing in SigNoz
**Solution**:
- Verify `config.yaml` has OTLP HTTP receiver on port 5318
- Check logs pipeline includes the OTLP receiver
- Ensure no typos in receiver names

#### 4. CORS Issues
**Symptom**: Browser blocks requests to OTLP endpoint
**Solution**:
- OTLP forwarding happens server-side, not browser-side
- If testing from browser, use `/api/events` endpoint, not direct OTLP

#### 5. Windows Collector Service Issues (FIXED 2025-10-02)
**Symptom**: Service shows "Stopped" status or exit code 1064
**Root Cause**: Broken service registration pointing to non-existent binary path
**Solution**: 
- **Standalone Mode**: Collector runs as standalone process instead of Windows service
- Check running processes: `Get-Process -Name otelcol-contrib`
- Verify health endpoint: `Invoke-WebRequest http://127.0.0.1:13134/healthz`
- Confirm OTLP ports: `Get-NetTCPConnection -State Listen -LocalPort 5317,5318`
- **Note**: Standalone mode is normal and preferred for development environments
- **Service Cleanup**: Remove broken service: `sc delete otelcol-contrib`

#### 5. Service Down
**Symptom**: Health checks fail
**Solution**:
- Check OTel Collector service: `Get-Service otelcol-contrib`
- Check SigNoz containers: `docker ps | findstr signoz`
- Verify health endpoints:
  - Collector: `curl http://localhost:13134/healthz`
  - SigNoz UI: `curl http://localhost:8080`

#### 6. Authentication Required
**Symptom**: 401 Unauthorized from SigNoz API
**Solution**:
- Set `SIGNOZ_API_TOKEN` environment variable
- Get token from SigNoz UI → Settings → API Keys
- For local development, API may not require auth

### Debug Commands

```powershell
# Check collector service status
Get-Service otelcol-contrib

# Test port connectivity
Test-NetConnection -ComputerName localhost -Port 5318

# Check collector logs
Get-WinEvent -LogName "Application" -Source "otelcol-contrib" -MaxEvents 10

# Verify SigNoz UI
Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5

# Test analytics API
Invoke-RestMethod -Uri "http://localhost:3000/api/events" -Method POST -Body '{"event":"test"}' -ContentType "application/json"
```

### Log Locations

- **OTel Collector Logs**: Windows Event Log → Application
- **SigNoz Logs**: Docker containers (use `docker logs signoz-otel-collector`)
- **Verification Artifacts**: `artifacts/wiring-verify.txt`, `artifacts/wiring-api.json`

## Security & Privacy

### Data Redaction
The integration automatically redacts sensitive information:
- Bearer tokens: `Bearer ***`
- Passwords: `pwd=***`, `password=***`
- API keys: `api_key=***`
- Auth headers: `auth=***`
- Secrets: `secret=***`

### Local-Only Operation
- No external dependencies
- All communication stays on localhost
- No cloud services required
- Data remains on local SigNoz instance

## Performance Considerations

- **Batch Size**: Maximum 50 records per OTLP request
- **Retry Policy**: 2 retries with exponential backoff
- **Non-blocking**: OTel forwarding failures don't affect API responses
- **Memory Usage**: Ring buffer limited to 1000 events in memory
- **Rate Limiting**: 120 requests per minute per client

## Next Steps

1. **Set up Alerts**: Configure SigNoz alerts for error rate spikes
2. **Create Dashboards**: Build analytics dashboards in SigNoz UI
3. **Monitor Performance**: Track TTV and activation metrics
4. **Scale Testing**: Test under load to verify batch processing
5. **Production Migration**: Replace in-memory buffer with persistent storage

## Related Documentation

- **[Resonai Code Map](RESONAI_CODE_MAP.md)** - Complete frontend architecture, contracts, and implementation guide
- **[Query Recipes](QUERY_RECIPES.md)** - SigNoz queries for analytics insights  
- **[Monitoring Setup Guide](../MONITORING_SETUP_GUIDE.md)** - Complete monitoring and alerting configuration
- **[Agent Roles](roles/)** - Understanding the agent ecosystem that maintains this observability pipeline
- **[ECRR Project Report](ECRR_PROJECT_REPORT.md)** - Cross-project summary of Examine / Clean / Report / Role
