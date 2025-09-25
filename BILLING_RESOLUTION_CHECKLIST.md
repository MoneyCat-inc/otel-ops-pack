# Billing Resolution Checklist

## Current Status
- 🚫 **BLOCKED**: GitHub Actions billing hold (run 17951058208)
- ✅ **READY**: ECRR report documented at `docs/ECRR_REPORTS/2025-09-23-sanity-ci-billing-hold.md`
- ✅ **READY**: 4 helper scripts prepared (sanity scan/clean + OTel stubs)
- ✅ **READY**: Local hygiene verified (0 flagged files)

## Immediate Actions (Once Billing Cleared)

### 1. Clear GitHub Billing Hold
- GitHub → Settings → Billing & plans
- Resolve failed payments
- Raise spending limit if needed

### 2. Rerun Sanity Workflow
```bash
gh run rerun 17951058208
gh run watch 17951058208 --exit-status
```

### 3. Trigger OTel Health Monitoring
- GitHub → Actions → OTel Health Monitoring
- Run workflow → select `docs/ecrr-refresh`

### 4. Replace Helper Script Stubs
Update these files with real implementations:
- `scripts/otel-health.ps1`
- `scripts/otel-listener-summary.ps1`

## Ready Scripts
- ✅ `scripts/sanity-scan.ps1` - BOM & smart quote detector
- ✅ `scripts/sanity-clean.ps1` - Automated sanitizer  
- ✅ `scripts/otel-health.ps1` - Stub (ready for real implementation)
- ✅ `scripts/otel-listener-summary.ps1` - Stub (ready for real implementation)

## Next Contact
Notify when billing is resolved to proceed with verification and OTel script completion.
