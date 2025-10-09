# SigNoz Alert Monitoring Schedule

## Weekly Alert Review Checklist

### 📅 **Recommended Schedule: Every Monday 09:00 AM**

### 🔍 **Alert Status Check**
1. Navigate to: http://localhost:8080 → Alerts → All Alerts
2. Review the following alerts:
   - **Windows Logs Canary Absence** (Critical)
   - Any other custom alerts configured

### ✅ **Expected Status**
- **Windows Logs Canary Absence**: Should show **RESOLVED** (green)
- If showing **FIRING** (red), investigate immediately

### 📊 **Additional Checks**
1. **Canary Log Generation**: Verify recent entries in Logs Explorer
   - Query: `(log.source = 'windows_event_log' AND body contains 'windows-canary') OR (log.file.path contains 'windows-canary-test.log' AND body contains 'windows-canary')`
   - Time Range: Last 24 hours
   - Expected: Regular entries every 5 minutes

2. **Scheduled Task Status**:
   ```powershell
   schtasks /query /tn 'Windows Canary Health Check' /fo list
   ```
   - Should show "Ready" status
   - Next run time should be within 5 minutes

3. **Collector Health**:
   ```powershell
   Get-NetTCPConnection -LocalPort 5317,5318 -State Listen
   Invoke-RestMethod -Uri 'http://localhost:8080/api/v1/health'
   ```

### 🚨 **If Issues Found**
1. **Alert Firing**: Check collector status and restart if needed
2. **No Canary Logs**: Run canary script manually to test
3. **Collector Down**: Restart service or run manually

### 📝 **Documentation Updates**
- Update this file if alert configurations change
- Note any recurring issues or pattern changes
- Record resolution steps for future reference

---
**Last Updated**: 2025-10-02 05:13:00  
**Next Review**: 2025-10-09 09:00:00  
**Status**: Active Monitoring ✅
