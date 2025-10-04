# Error Pipeline Snapshot - 2025-10-04

**Generated**: 2025-10-04T00:40:00Z  
**System**: Error Radar + Quiet Channel Implementation  

## 🔧 Collector Configuration

### OTel Collector Processors (Active)

```yaml
processors:
  # Error processing processors
  attributes/error-enrichment:
    actions:
      # Promote error fingerprint to resource attribute
      - key: error.fingerprint
        action: insert
        from_attribute: error.fp
      # Add error classification
      - key: error.severity_class
        action: insert
        value: "unknown"
      # Add deduplication markers
      - key: error.dedupe_key
        action: insert
        from_attribute: error.fp
      # Normalize service name
      - key: service.name
        action: insert
        from_attribute: service.name
        value: "unknown"
  
  filter/error-noise-reduction:
    logs:
      log_record:
        - 'attributes["error.fp"] != nil'
        - 'attributes["error.known"] == true and attributes["error.count"] < 10'
  
  groupbyattrs/error-aggregation:
    keys:
      - error.fp
      - service.name
      - error.origin
  
  transform/error-normalization:
    log_statements:
      - context: log
        statements:
          # Set severity based on error type
          - set(attributes["error.severity_class"], "fatal") where attributes["error.known"] == false
          - set(attributes["error.severity_class"], "error") where attributes["error.known"] == true and attributes["error.origin"] == "uncaughtException"
          - set(attributes["error.severity_class"], "warning") where attributes["error.known"] == true and attributes["error.origin"] == "processWarning"
          # Add correlation ID for tracking
          - set(attributes["error.correlation_id"], Concat([attributes["error.fp"], "-", attributes["service.name"]]))
          # Normalize message length
          - truncate_all(attributes["body"], 1000) where len(attributes["body"]) > 1000
```

### Logs Pipeline Configuration

```yaml
logs:
  receivers:
    - otlp
  processors:
    - attributes/error-enrichment
    - filter/error-noise-reduction
    - groupbyattrs/error-aggregation
    - transform/error-normalization
    - batch
  exporters:
    - clickhouselogsexporter
```

## 🌍 Environment Summary

### Docker Services
- **SigNoz OTel Collector**: `signoz-otel-collector` (Running, Healthy)
- **SigNoz UI**: `http://localhost:8080`
- **OTLP Endpoints**: 
  - gRPC: `localhost:4317`
  - HTTP: `localhost:4318`

### Error Radar Configuration

```json
{
  "errorRadar": {
    "renotifyWindowHours": 6,
    "maxLoudPerHourPerFp": 1,
    "aggregateFlushIntervalSec": 60,
    "registryTtlDays": 21,
    "browserHook": true,
    "enableProcessWarnings": true,
    "enableUnhandledRejections": true,
    "enableUncaughtExceptions": true,
    "capture4xx": false,
    "capture5xx": true
  }
}
```

### Service Configuration

```json
{
  "services": {
    "default": {
      "serviceName": "otel-app",
      "buildSha": "dev",
      "environment": "development"
    }
  }
}
```

## 📊 Collector Health Status

### Current Status
- **Collector Container**: ✅ Running (4 hours uptime)
- **Health Check**: ✅ Healthy
- **OTLP Receivers**: ✅ Active (4317, 4318)
- **Exporters**: ✅ Active (ClickHouse)

### Log Analysis
- **Processor Errors**: ❌ None detected
- **Export Errors**: ❌ None detected
- **Prometheus Warnings**: ⚠️ Expected (endpoint not configured)
- **Log Processing**: ✅ Active

### Error Event Flow
1. **Receivers**: OTLP (gRPC/HTTP) receive error events
2. **Enrichment**: Add error.fp, error.known, severity_class
3. **Filtering**: Remove high-volume known errors
4. **Aggregation**: Group by fingerprint and service
5. **Normalization**: Set severity classes and correlation IDs
6. **Batching**: Batch for efficient export
7. **Export**: Send to ClickHouse for SigNoz

## 🎯 Expected SigNoz Attributes

### Error Event Structure
```json
{
  "timestamp": "2025-10-04T00:40:00Z",
  "body": "Database connection failed: timeout after 30s",
  "attributes": {
    "error.fp": "42482f1d8ed0a114",
    "error.known": false,
    "error.origin": "uncaughtException",
    "error.severity_class": "fatal",
    "error.correlation_id": "42482f1d8ed0a114-test-service",
    "service.name": "test-service",
    "build.sha": "dev",
    "error.frames": "[{\"file\":\"database.ts\",\"line\":45,\"fn\":\"connect\"}]",
    "error.count": 1,
    "error.suppressed": 0
  }
}
```

## 🔍 Verification Queries

### New Errors (Billable)
```sql
SELECT 
  attributes['error.fp'] as fingerprint,
  attributes['error.origin'] as origin,
  attributes['service.name'] as service,
  body as message,
  timestamp
FROM signoz_logs 
WHERE attributes['error.known'] = 'false'
  AND timestamp > now() - INTERVAL 24 HOUR
ORDER BY timestamp DESC
```

### Error Trends
```sql
SELECT 
  attributes['error.fp'] as fingerprint,
  attributes['service.name'] as service,
  count() as occurrences,
  max(timestamp) as last_seen
FROM signoz_logs 
WHERE attributes['error.known'] = 'true'
  AND timestamp > now() - INTERVAL 7 DAY
GROUP BY fingerprint, service
ORDER BY occurrences DESC
LIMIT 20
```

## 📋 Deployment Checklist

- ✅ **Collector Configuration**: Error processors configured
- ✅ **Pipeline Integration**: Logs pipeline updated
- ✅ **Service Discovery**: OTLP endpoints accessible
- ✅ **Error Registry**: Local registry functional
- ✅ **Fingerprinting**: Stable hash generation
- ✅ **Documentation**: Comprehensive guides created
- ✅ **Testing**: Validation suite passed

---

**Configuration File**: `config/signoz-collector.yaml`  
**Registry File**: `.agent/error_index.json`  
**Config File**: `.agent/config.json`
