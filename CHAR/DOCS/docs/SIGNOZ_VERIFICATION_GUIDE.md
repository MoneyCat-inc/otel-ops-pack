# SigNoz Verification & Monitoring Setup

## 🔍 Immediate Verification Steps

### 1. SigNoz UI Verification
1. **Open SigNoz**: http://localhost:8080
2. **Navigate to Logs**
3. **Add filter**: `resource.service.name = "windows-logs"`
4. **Expected results**:
   - Recent Windows Application logs
   - Recent Windows System logs  
   - File logs from C:/logs/ directory
   - All tagged with correct service identity

### 2. Verification Queries
```sql
-- Check for recent Windows logs with new service name
resource.service.name = "windows-logs"

-- Verify log volume (should show steady stream)
resource.service.name = "windows-logs" | rate(1m)

-- Check for any errors in Windows logs
resource.service.name = "windows-logs" AND severity = "ERROR"
```

## 📊 Monitoring Setup (Next Steps)

### 1. Dashboard Panel
**Title**: Windows Logs Volume
**Query**: `resource.service.name = "windows-logs"`
**Visualization**: Time series showing log count per minute
**Alert threshold**: < 10 logs/minute for 5 minutes

### 2. Alert Configuration
```json
{
  "name": "Windows Logs Ingestion Gap",
  "condition": "rate(resource.service.name = 'windows-logs') < 0.1 for 5m",
  "severity": "warning",
  "message": "Windows logs ingestion rate below threshold"
}
```

### 3. Service Health Check
```sql
-- Monitor collector health via log presence
resource.service.name = "windows-logs" AND message contains "otelcol-contrib"
```

## 🚨 Operations Team Handoff

### Validation Workflow (Mandatory)
```powershell
# Before ANY config changes:
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'

# After config changes:
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'
Restart-Service -Name otelcol-contrib
Get-Service -Name otelcol-contrib
```

### Documentation References
- **Validation Guide**: `docs/CONFIG_VALIDATION_GUIDE.md`
- **Fix Summary**: `docs/WINDOWS_OTEL_FIX_SUMMARY.md`
- **Service Naming**: Use semantic names (windows-logs, application-logs, gpu-metrics)

## ✅ Success Criteria

### Immediate (Today)
- [ ] SigNoz shows logs with `resource.service.name = "windows-logs"`
- [ ] Operations team has validation guide
- [ ] No collector errors in Windows Event Log

### Short-term (This Week)  
- [ ] Dashboard panel for Windows logs volume
- [ ] Alert for ingestion gaps configured
- [ ] Team trained on validation workflow

### Long-term (This Month)
- [ ] Automated health checks for windows-logs service
- [ ] Integration with existing monitoring stack
- [ ] Documentation updated in runbooks

---
*Status: Ready for SigNoz verification and monitoring setup*
