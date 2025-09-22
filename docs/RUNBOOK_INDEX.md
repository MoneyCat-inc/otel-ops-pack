# Runbook Index

[![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](reports/ECRR_REPORT.md)
[![ECRR Project Report](https://img.shields.io/badge/ECRR%20Project%20Report-available-7c5cff?style=flat-square)](../docs/ECRR_PROJECT_REPORT.md)
[![CI](https://github.com/fubumaki/otel-ops-pack/actions/workflows/ci.yml/badge.svg)](https://github.com/fubumaki/otel-ops-pack/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/fubumaki/otel-ops-pack/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/fubumaki/otel-ops-pack/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/fubumaki/otel-ops-pack/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/fubumaki/otel-ops-pack/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/fubumaki/otel-ops-pack/branch/main/graph/badge.svg)](https://codecov.io/gh/fubumaki/otel-ops-pack)

> Last Updated: 2024-12-19 | Version: 1.0

This index provides quick access to operational runbooks and supporting documentation for the Windows Collector -> SigNoz observability pipeline.

---

## Primary Runbooks

### SigNoz Operations Bundle (RECOMMENDED)
- File: [docs/observability/SIGNOZ_RUNBOOK_BUNDLE.md](observability/SIGNOZ_RUNBOOK_BUNDLE.md)
- Purpose: Complete SigNoz operations guide with runbook, execution summary, verification, and screenshot specification
- Status: Production Ready
- Use When: Daily operations, troubleshooting, verification, documentation

### Emergency Response
- File: [ON_CALL_RUNBOOK.md](../ON_CALL_RUNBOOK.md)
- Purpose: Emergency troubleshooting and escalation procedures
- Status: Active
- Use When: Service down, critical issues, escalation required

---

## Legacy Runbooks (Superseded)

### Windows Collector -> SigNoz (SUPERSEDED)
- File: [WINDOWS_COLLECTOR_SIGNOZ_RUNBOOK.md](archive/WINDOWS_COLLECTOR_SIGNOZ_RUNBOOK.md)
- Status: Superseded by SigNoz Bundle
- Action: Archived in docs/archive/; review before deletion

### Execution Summary (SUPERSEDED)
- File: [RUNBOOK_EXECUTION_SUMMARY.md](archive/RUNBOOK_EXECUTION_SUMMARY.md)
- Status: Superseded by SigNoz Bundle
- Action: Archived in docs/archive/; review before deletion

---

## Quick Access

### Most Common Tasks
```powershell
# Health Check
.\health-check.ps1

# Canary Test
.\canary-test.ps1

# Full Verification
.\verify-pipeline.ps1
```

### Cross-Project Summary
- See the Resonai-wide context: [ECRR Project Report](../ECRR_PROJECT_REPORT.md) for Examine / Clean / Report / Role overview.

### Emergency Commands
```powershell
# Quick Status
.\green-sheet.ps1

# Service Restart
Restart-Service otelcol-contrib

# Port Check
netstat -an | findstr "5317\|5318\|14317\|14318"
```

---

## Runbook Status Overview

| Runbook | Status | Last Updated | Primary Use |
|---------|--------|--------------|-------------|
| SigNoz Bundle | Active | 2024-12-19 | Daily Operations |
| On-Call | Active | 2024-12-19 | Emergency Response |
| Windows Collector | Superseded | 2025-09-20 | Legacy Reference |
| Execution Summary | Superseded | 2025-09-20 | Legacy Reference |

---

## Recommended Actions

### For New Users
1. Start with SigNoz Bundle for comprehensive operations.
2. Bookmark On-Call Runbook for emergency procedures.
3. Ignore legacy runbooks unless specific historical reference is required.

### For Maintenance
1. Review legacy files in docs/archive/ for unique content each quarter.
2. Archive Audit: Confirm archived material can be removed once redundant.
3. Update links whenever runbooks are added or retired.

---

## Support & Escalation

- Primary: Observability Copilot (Cursor Agent)
- Emergency: See [On-Call Runbook](../ON_CALL_RUNBOOK.md)
- SigNoz UI: http://localhost:8080
- Service Management: `sc query otelcol-contrib`

---

## 🏷️ Project Badges

See [docs/badges.md](badges.md) for all status badges (ECRR, CI, nightly, coverage).
Use it whenever the project stage changes so the README and this index stay accurate.

---

## 🏷️ Reminder

Keep project status visible:
- Update the badge row at the top of this file when the project stage changes (for example, Beta Cohort -> Cohort-Ready -> Production Ready).
- Mirror the same badge row in the root `README.md`.

Refer to [docs/badges.md](badges.md) for ready-to-copy badge rows and visual previews.

---

This index is maintained by the Observability Copilot and updated when runbooks change.
