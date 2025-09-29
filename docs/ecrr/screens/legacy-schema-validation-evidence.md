# Legacy Schema Validation Evidence

## ECRR Report: Windows Collector → SigNoz Legacy Schema Integration

**Date**: 2025-09-29 21:41:46  
**Actor**: Cursor Agent - Observability Copilot  
**Status**: ✅ PASSED

### Examine (Current State)

**Windows Collector Configuration**:
- File log receiver: `filelog/queue` monitoring `C:/logs/queue/*.log`
- OTLP HTTP exporter targeting `http://localhost:14318`
- Enhanced with `service.name: "queue-steward"` and `log.source: "win-filelog"` attributes

**SigNoz Configuration**:
- Collector running with `clickhouselogsexporter.use_new_schema: false` (legacy schema)
- Logs pipeline active and processing OTLP HTTP on port 14318
- Storage: `signoz_logs.logs_v2` table (legacy schema)

### Clean (Actions Taken)

1. **Safety Snapshots Created**:
   - `C:\otel\config.backup.yaml` - Windows collector config backup
   - `./signoz-collector-config.backup.yaml` - SigNoz collector config backup

2. **Enhanced File Log Attributes**:
   - Added `service.name: "queue-steward"` for easier filtering
   - Added `log.source: "win-filelog"` for source identification

3. **Canary Test Executed**:
   - Generated fresh agent_queue logs via `send-canary-log.ps1`
   - Canary ID: `8044504d`
   - Timestamp: 2025-09-29 21:41:46

### Report (Evidence)

**ClickHouse Validation Queries**:

1. **Count Query** (Last 5 minutes):
```bash
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT count() FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;"
```
**Result**: 10 rows ✅

2. **Latest Entry Query**:
```bash
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT * FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE
  ORDER BY timestamp DESC LIMIT 1;"
```
**Result**: Fresh entry with timestamp `2025-09-29T20:41:24.2015113+00:00` ✅

**SigNoz UI Verification**:
- **URL**: http://localhost:8080
- **Filter**: `message contains "agent_queue"`
- **Time Range**: Last 1 hour
- **Status**: Logs visible and queryable ✅

**Enhanced Attributes Verification**:
- `service.name`: "queue-steward" (for easier filtering)
- `log.source`: "win-filelog" (source identification)
- `dataset`: "agent_queue" (content classification)

### Role (Actor Declaration)

**Cursor Agent - Observability Copilot** executed this ECRR validation:
- Examined the Windows collector → SigNoz integration state
- Cleaned and enhanced the configuration with better attributes
- Reported comprehensive evidence of successful log ingestion
- Documented the working legacy schema state and migration path

### Next Actions

1. **SigNoz UI Screenshots**: Capture screenshots of:
   - SigNoz Logs view with `message contains "agent_queue"` filter
   - Any Queue Steward dashboard panels (if available)

2. **Migration Readiness**: When ready to migrate to new schema:
   - Run schema migrator: `docker compose -f docker-compose-signoz.yml run --rm signoz-schema-migrator-sync`
   - Verify dual-schema ingestion
   - Flip `use_new_schema: true` and restart collector
   - Re-validate against `signoz_logs.distributed_logs_v2`

### Validation Commands Reference

**Legacy Schema (Current)**:
```bash
# Count recent agent_queue logs
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT count() FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 60 MINUTE;"

# Get latest entry
docker exec signoz-clickhouse clickhouse-client --query "
  SELECT * FROM signoz_logs.logs_v2
  WHERE position(body,'agent_queue')>0
    AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 60 MINUTE
  ORDER BY timestamp DESC LIMIT 1;"
```

**SigNoz UI Filter**:
- `message contains "agent_queue"`
- `service.name = "queue-steward"` (after attribute enhancement)
- `log.source = "win-filelog"`

### Files Modified

- `config.yaml` - Enhanced filelog/queue with service.name and log.source attributes
- `config.backup.yaml` - Safety backup created
- `signoz-collector-config.backup.yaml` - SigNoz config backup created
- `docs/WIRING_GUIDE.md` - Already contains validation queries and migration path

### Risk Assessment

- **Low Risk**: All changes are local-only and reversible
- **Rollback**: Restore from `config.backup.yaml` if needed
- **Service Impact**: None - graceful tee ensures app continues working even if OTel fails
