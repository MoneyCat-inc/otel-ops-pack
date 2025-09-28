# Operations Team Notification

## 🚨 Windows OTel Collector Configuration Fixed

### What Changed
- **Service Identity**: Updated `config.yaml:45` from `windows-gpu-metrics` to `windows-logs`
- **Validation Workflow**: Documented proper config validation commands
- **Documentation**: Added operator guides for safe config changes

### Impact
- Windows Event Logs now appear under correct service identity in SigNoz
- Config validation now possible before restarts
- Reduced risk of misconfigurations

### Action Required

#### 1. Immediate Verification
- **SigNoz Check**: Filter `resource.service.name = "windows-logs"` to confirm new events
- **Service Status**: Verify `Get-Service -Name otelcol-contrib` shows Running

#### 2. Adopt New Validation Workflow
**Before ANY config changes:**
```powershell
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'
```

**After config changes:**
```powershell
& 'C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe' validate --config 'C:\otel\config.yaml'
Restart-Service -Name otelcol-contrib
Get-Service -Name otelcol-contrib
```

#### 3. Documentation Review
- **Validation Guide**: `docs/CONFIG_VALIDATION_GUIDE.md`
- **Fix Summary**: `docs/WINDOWS_OTEL_FIX_SUMMARY.md`
- **SigNoz Verification**: `docs/SIGNOZ_VERIFICATION_GUIDE.md`

### Next Steps
1. **Today**: Verify SigNoz shows `windows-logs` service identity
2. **This Week**: Set up monitoring alerts for ingestion gaps
3. **Ongoing**: Use validation workflow for all config changes

### Contact
- **Issues**: Check Windows Event Log for otelcol-contrib errors
- **Questions**: Reference documentation in `docs/` directory
- **Emergency**: Revert to previous config if validation fails

---
*Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
*Status: Ready for team verification*
