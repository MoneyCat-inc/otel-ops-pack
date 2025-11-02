# Windows Collector Deprecation Notice

**Status**: 🚫 **DEPRECATED**  
**Effective Date**: 2025-10-27  
**Superseded By**: Direct-to-SigNoz Architecture

---

## Summary

The **Windows OpenTelemetry Collector** (`otelcol-contrib` Windows service) is **officially deprecated** and should **no longer be referenced** in ECRR reports, runbooks, or architectural documentation.

### Historical Context

**Original Architecture (Deprecated)**:
```
Windows Event Logs
    ↓
Windows OTel Collector (otelcol-contrib service)
    ↓
Docker OTel Collector (forwarder)
    ↓
SigNoz
```

**Current Architecture (Active)**:
```
Windows Event Logs + File Logs
    ↓
Docker OTel Collectors (direct ingestion)
    ↓
SigNoz
```

---

## Reason for Deprecation

1. **Redundant Hop**: The Windows service added unnecessary latency (~2-5s) and complexity.
2. **Forwarding Issues**: Intermittent forwarding failures between Windows → Docker collectors.
3. **Maintenance Burden**: Dual configuration files (Windows + Docker) increased drift risk.
4. **Performance Goals**: Sub-200ms batch processing required direct pipeline (achieved with 200ms timeout).

**Decision**: Pivot to **direct-to-SigNoz** via Docker collectors only, eliminating the Windows service hop.

---

## Migration Completed

- **Date**: 2025-10-27
- **Gate**: GATE_029
- **ECRR Report**: `docs/archive/gates/2025-11/GATE_029_READY_20251027.md`

### Actions Taken
- ✅ Stopped `otelcol-contrib` Windows service
- ✅ Disabled auto-start for Windows service
- ✅ Reconfigured Docker collectors for direct ingestion
- ✅ Optimized batch processing (10s → 200ms timeout)
- ✅ Verified end-to-end telemetry flow in SigNoz
- ✅ Achieved ~50% noise reduction via filters

### Verification
```powershell
# Confirm Windows service is stopped
sc query otelcol-contrib
# Status: STOPPED (expected)

# Verify Docker collectors are active
docker ps
# Should show: signoz-otel-collector, signoz-otel-collector-metrics

# Validate telemetry in SigNoz
# Navigate to: http://localhost:8080
# Query: message contains "canary test"
# Expected: Logs appear within 200ms
```

---

## Guidance for Future ECRR Reports

### ❌ Do NOT Reference

- ~~"Windows Collector service"~~
- ~~"otelcol-contrib Windows service"~~
- ~~"Dual-hop architecture"~~
- ~~"Windows → Docker forwarding"~~
- ~~"`windows/otelcol/otelcol-contrib-config.yaml`~~ (deprecated config file)

### ✅ DO Reference

- **"Docker OTel Collectors"** (canonical)
- **"Direct-to-SigNoz architecture"**
- **"SigNoz OTLP endpoints"** (5317 gRPC, 5318 HTTP)
- **"`config.yaml`** (active Docker collector config)

---

## Configuration Files

### Deprecated (Do Not Use)
- ❌ `windows/otelcol/otelcol-contrib-config.yaml` (archived)
- ❌ `windows/otelcol/otelcol-contrib.exe` (service binary)

### Active (Use These)
- ✅ `config.yaml` (root, Docker collector config)
- ✅ `docker-compose.yaml` (SigNoz services)
- ✅ `scripts/verify-pipeline.ps1` (validation script)
- ✅ `scripts/canary-test.ps1` (test data generator)

---

## Monitoring & Health Checks

### Updated Health Check Command
```powershell
# Quick health check (updated for current architecture)
pwsh -File scripts\quick-monitor.ps1

# Expected output:
# ✅ Docker collectors running
# ✅ SigNoz API reachable
# ✅ Telemetry flowing
# ⚠️  Windows Collector: STOPPED (expected, deprecated)
```

### Updated Monitoring Script
The `quick-monitor.ps1` script **still checks** Windows Collector status for historical visibility, but the **expected state is STOPPED**. This is intentional for audit purposes.

**Recommendation**: Update the script to **remove** the Windows Collector check in a future PR (DOCS lane).

---

## Rollback (If Needed)

**If direct-to-SigNoz architecture fails**, the Windows Collector can be temporarily re-enabled:

```powershell
# Emergency rollback only
sc start otelcol-contrib
sc config otelcol-contrib start=auto

# Restore forwarding config (from backup)
Copy-Item config\backups\otelcol-contrib-config-backup.yaml windows\otelcol\otelcol-contrib-config.yaml

# Verify forwarding
pwsh -File scripts\verify-pipeline.ps1
```

**Note**: Rollback should be treated as a **temporary measure**. The direct architecture is the strategic direction.

---

## Documentation Updates Required

### High Priority (DOCS Lane)
- [ ] Update `README.md` to remove Windows Collector references
- [ ] Revise `docs/runbooks/unified-telemetry-proofs.md` (current architecture only)
- [ ] Update `scripts/quick-monitor.ps1` (remove deprecated check)
- [ ] Archive `windows/otelcol/` directory to `archive/deprecated/`

### Medium Priority
- [ ] Update all ECRR reports referencing Windows Collector (add deprecation note)
- [ ] Revise training materials / onboarding docs
- [ ] Update architecture diagrams (remove dual-hop)

### Low Priority
- [ ] Remove Windows service binary from repo (after 90-day grace period)
- [ ] Clean up archived config backups older than 6 months

---

## Owner & Contacts

- **Deprecation Decision**: ECRR Gate Review (GATE_029)
- **Technical Owner**: [Your team/role]
- **Documentation Owner**: DOCS Lane (to be assigned, see below)
- **Questions**: Refer to `docs/ecrr/INDEX.md` or raise in team channel

---

## Related Documents

- **Current Architecture**: `docs/REPOSITORY_STRUCTURE.md`
- **ECRR Framework**: `docs/comfort-cat/ECRR_FRAMEWORK.md`
- **ECRR Analytics**: `artifacts/ecrr-analytics/ecrr-dashboard.html`
- **Gate Reports**: `docs/archive/gates/2025-11/GATE_029_READY_20251027.md`

---

## Compliance

This deprecation notice follows the **ECRR Clean phase** principle: remove drift, enforce guardrails, and document the change.

**Gate Phrase**: `@cat ready-for-gate` ✅

**Sign-off**:
- **A (Writer)**: ECRR Audit (2025-11-01)
- **B (Monitor)**: [To be assigned by DOCS lane owner]

---

**Version**: 1.0  
**Last Updated**: 2025-11-01  
**Status**: Active Deprecation Notice

