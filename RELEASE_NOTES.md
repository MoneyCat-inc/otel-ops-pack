# Release Notes

## v1.2.2 – ASCII config fix (2025-09-18)

### Changes
- **fix:** convert config.yaml to ASCII for PS 5.1 compatibility
- **ci:** add sanity workflow with ASCII checks
- **docs:** add PR template, CODEOWNERS, .gitignore
- **docs:** update README with daily ops quick-start

### Verification
- ✅ Verified with safe-apply-config.ps1 (canary delta +1)
- ✅ Mini burn-in test: 3/3 successful canary runs
- ✅ ASCII guard function confirms pure ASCII encoding
- ✅ Service running with correct configuration

### Evidence
- **Audit Pack:** `audit-pack_20250918_003856.zip`
- **SHA256:** `EB1743A4B4A7FE313ED24247C225C69602F64A8517B328C9C35A3559B1A01A68`
- **Safe-Apply Log:** Validation OK, Canary PASS after apply
- **Service PathName:** `--config C:\otel\config.yaml`
- **Canary Evidence:** delta +1 (106→107) confirmed

### Breaking Changes
None.

### Migration Notes
None required. This is a configuration encoding fix with no functional changes.

---

## v1.2.1 – Initial hardened ops package (2025-09-17)

### Changes
- **feat:** initial hardened OpenTelemetry Collector configuration
- **feat:** comprehensive operational tooling suite
- **feat:** audit and compliance evidence generation
- **feat:** safe configuration change management

### Features
- Production-ready collector configuration
- Day-2 operational scripts
- Audit trail and evidence generation
- Safe change management with rollback
- Comprehensive documentation and runbooks

### Breaking Changes
None (initial release).

### Migration Notes
N/A (initial release).
