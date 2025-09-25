# Monitoring Quick Reference Card
**Observability Pipeline - Post-Implementation**

## 🔍 Daily Health Checks

### Parser Error Monitoring
```powershell
# Check current parser error count (last hour)
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.logs_v2 WHERE timestamp >= toUnixTimestamp64Nano(now64(9) - toIntervalHour(1)) AND severity_text = 'ERROR' AND body LIKE '%json_parser%'"

# Review monitoring log
Get-Content "artifacts/parser-error-watch.log" -Tail 20
```

### Dataset Coverage Validation
```powershell
# Check missing datasets (last 2 minutes)
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.logs_v2 WHERE timestamp >= toUnixTimestamp64Nano(now64(9) - toIntervalMinute(2)) AND NOT mapContains(attributes_string,'dataset')"

# Run 24h validation
pwsh -File scripts/validate-dataset-coverage-24h.ps1
```

### System Health
```powershell
# Collector service status
sc query otelcol-contrib | Select-String "STATE"

# Scheduled task status
Get-ScheduledTask -TaskName "OTel-Parser-Error-Monitor" | Select-Object State, LastRunTime, NextRunTime
```

## 📋 Expected Results

- **Parser Errors**: Should be `0`
- **Missing Datasets**: Should be `0` 
- **Collector State**: Should be `4  RUNNING`
- **Scheduled Task**: Should be `Ready`

## 🚨 Troubleshooting

### If Parser Errors > 0
1. Check `artifacts/parser-error-watch.log` for sample error bodies
2. Review log file formats in `C:/logs/`
3. Verify `config.yaml:30-45` router configuration

### If Missing Datasets > 0
1. Run `scripts/validate-dataset-coverage-24h.ps1`
2. Review `config.yaml:122-132` transform rules
3. Add regex patterns for new log sources

### If Monitoring Stops
1. Check Task Scheduler for `OTel-Parser-Error-Monitor`
2. Verify PowerShell execution policy
3. Check Windows Event Log for task errors

## 📁 Key Files

- **Configuration**: `config.yaml` (lines 30-133)
- **Monitoring Script**: `scripts/monitor-parser-errors.ps1`
- **Validation Script**: `scripts/validate-dataset-coverage-24h.ps1`
- **DMA Evaluation**: `scripts/evaluate-dma-protection.ps1`
- **Monitoring Log**: `artifacts/parser-error-watch.log`
- **Status Reports**: `docs/status/`

## 🎯 Success Criteria

✅ Zero parser errors sustained  
✅ Complete dataset coverage maintained  
✅ Monitoring automation runs without intervention  
✅ All documentation properly recorded  

---

**Last Updated**: 2025-09-23 22:40:00  
**Status**: Implementation Complete
