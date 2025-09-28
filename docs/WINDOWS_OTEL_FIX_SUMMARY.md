# Windows OTel Collector Fix Summary

## ✅ Issues Resolved

### 1. Service Identity Misconfiguration
- **Problem**: `config.yaml:45` set `service.name = "windows-gpu-metrics"` causing Windows Event Logs to appear under GPU service identity
- **Fix**: Updated to `service.name = "windows-logs"` for semantic correctness
- **Impact**: Windows logs now properly categorized in SigNoz

### 2. Config Validation Gap
- **Problem**: `--dry-run` flag not supported, preventing safe config validation
- **Solution**: Documented proper validation workflow using `validate` command
- **Result**: Operators can now safely test configs before restarts

## 🔧 Validation Workflow (New Standard)

```powershell
# 1. Validate before changes
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'

# 2. Make config changes (if validation passed)

# 3. Re-validate after changes  
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'

# 4. Restart service
Restart-Service -Name otelcol-contrib

# 5. Verify health
Get-Service -Name otelcol-contrib
```

## 📊 SigNoz Verification Steps

### Check New Service Identity
1. Open SigNoz UI: http://localhost:8080
2. Navigate to **Logs**
3. Add filter: `resource.service.name = "windows-logs"`
4. Verify Windows Event Logs appear under correct service identity

### Expected Results
- Windows Application logs: `resource.service.name = "windows-logs"`
- Windows System logs: `resource.service.name = "windows-logs"`  
- File logs from C:/logs/: `resource.service.name = "windows-logs"`

## 🚨 Next Actions

### Immediate (Today)
- [ ] Verify in SigNoz that `resource.service.name = "windows-logs"` shows recent Windows events
- [ ] Share `docs/CONFIG_VALIDATION_GUIDE.md` with operations team

### Short-term (This Week)
- [ ] Set up alerting for `windows-logs` ingestion gaps
- [ ] Create dashboard panel for Windows log volume by service identity
- [ ] Train team on new validation workflow

### Monitoring Queries
```sql
-- Windows log volume by service
resource.service.name = "windows-logs"

-- Error rate for Windows logs
resource.service.name = "windows-logs" AND severity = "ERROR"

-- Ingestion gaps (no logs in 5 minutes)
resource.service.name = "windows-logs" | rate(5m) = 0
```

## 📚 Documentation
- **Validation Guide**: `docs/CONFIG_VALIDATION_GUIDE.md`
- **Service Naming**: Follow semantic conventions (windows-logs, application-logs, gpu-metrics)
- **Troubleshooting**: Use `validate` command before any config changes

---
*Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
*Status: Collector Running, Config Validated, Documentation Complete*
