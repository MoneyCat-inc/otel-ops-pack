# Minor Issues Tracking - Polish Items

## Issues Identified (Non-blocking)

### 1. **PowerShell Script Formatting Issues**
**Status**: Cosmetic display problems, functionality works
**Location**: Various monitoring scripts
**Symptoms**:
- Color output formatting issues in `quick-monitor.ps1`
- Some Write-Host commands not displaying colors correctly
- Variable interpolation issues in string formatting

**Impact**: Low - scripts function correctly, just display formatting needs polish
**Priority**: Low - can be addressed during maintenance cycles

### 2. **OTLP Trace Ingestion Warning**
**Status**: Logs work fine, traces have connectivity issue
**Symptoms**:
```
[WARN] Failed to send OTLP trace: Response status code does not indicate success: 503 (Service Unavailable)
```
**Working**: OTLP log ingestion (`http://localhost:5318/v1/logs`)
**Not Working**: OTLP trace ingestion (503 errors)

**Impact**: Low - log observability is primary need, traces are secondary
**Priority**: Medium - investigate SigNoz trace receiver configuration

### 3. **Build Script Flag Issues**
**Status**: pnpm compatibility issue
**Symptoms**:
```
error: unknown option '--if-present'
```
**Location**: `scripts/setup-local.ps1` verification section

**Impact**: Low - build works fine, just verification script needs update
**Priority**: Low - update to use `--if-present` correctly or remove flag

## Recommended Actions

### Immediate (Optional)
1. SigNoz trace investigation: confirm the trace receiver configuration
2. Script polish: fix color formatting in monitoring scripts

### Future Maintenance
1. Update build verification: reconcile `--if-present` usage
2. Standardize output formatting: ensure consistent PowerShell output across scripts

## Impact Assessment

| Issue | Impact | Urgency | Effort |
|-------|--------|---------|--------|
| PowerShell formatting | Low | Low | Low |
| Trace 503 warnings | Low | Medium | Medium |
| Build script flags | Low | Low | Low |

**Overall**: All issues are cosmetic or secondary - primary functionality works perfectly
