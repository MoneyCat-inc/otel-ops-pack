# Operations Report - Optimization Pass

**Date**: 2025-09-19  
**Optimization**: Noise reduction, resilience, and performance tuning

## Changes Applied

### 1. Noise Filtering Processors
- **filter/drop_noise**: Drops routine Windows Event Log entries (6005, 6006) and health check noise
- **transform/sanitize**: Redacts Bearer tokens, passwords, and API keys from log bodies
- **transform/enrich**: Sets consistent service.name="windows-host" and deployment.environment="local-dev"

### 2. Resilience Configuration
- **WAL Storage**: Enabled disk-backed queue at `C:\ProgramData\OTel\wal`
- **Queue Settings**: 5000 items, 4 consumers, 10m max retry time
- **Retry Policy**: 5s initial, 30s max interval

### 3. Performance Tuning
- **Memory Limiter**: 80% limit, 25% spike limit, 2s check interval
- **Batch Processing**: 1000 batch size, 2000 max size, 1s timeout
- **Pipeline Order**: memory_limiter → filters → transforms → batch → exporters

### 4. Storage Cleanup
- Docker system prune completed
- SigNoz volumes identified and preserved
- WAL directory created

## Verification

### Canary Test
```powershell
# Emit test log
$id=[guid]::NewGuid().ToString()
Add-Content -Path "C:\logs\app.json" -Value "{`"timestamp`":`"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`",`"level`":`"INFO`",`"message`":`"windows-canary id=$id`",`"service`":`"test`"}"
```

### SigNoz Verification
- **Logs Query**: `log.body contains "windows-canary"`
- **Service Filter**: `service.name = "windows-host"`
- **Environment Filter**: `deployment.environment = "local-dev"`

## Expected Results
- **Ingest Reduction**: 20-50% noise reduction from filtering
- **Zero Silent Loss**: WAL ensures no data loss during outages
- **Canary Latency**: <60s from emit to visible in SigNoz
- **Memory Usage**: Stable at 80% limit with 25% spike tolerance

## Next Actions
1. Monitor ingest volume reduction over 24h
2. Verify WAL directory size stays reasonable
3. Set up alerts for queue pressure >80%
4. Consider adding SpanMetrics connector for RED metrics

## Files Modified
- `C:\otel\config.yaml` - Main collector configuration
- `C:\ProgramData\OTel\wal\` - WAL storage directory
- `C:\logs\` - Test log directory

## Rollback
```powershell
# Restore from backup
Copy-Item C:\otel\backup\collector_*.yaml C:\otel\config.yaml -Force
Restart-Service -Name "otelcol-contrib"
```
