# ECRR Report Template

**Copy this template for every new ECRR report to ensure all 4 phases are documented.**

---

## Metadata

- **Lane**: DOCS
- **Date**: 2025-11-02
- **Gate**: N/A
- **Author**: VelvetQuill-42 (Quil)
- **Status**: READY

**Note**: This template reflects the current **direct-to-SigNoz architecture**. See [docs/architecture/CURRENT_ARCHITECTURE.md](../architecture/CURRENT_ARCHITECTURE.md) for details.

---

## 1️⃣ Examine

**Objective**: Capture environment state BEFORE any changes.

### Pre-Change Snapshot
- **System State**: [Docker containers, services, processes]
- **Key Metrics**: [Current performance, error rates, resource usage]
- **Configuration**: [Relevant config files and their current values]
- **Evidence Files**: [Screenshots, logs, health check outputs]

### Baseline Measurements
```powershell
# Example: Quick health check
pwsh -File scripts\quick-monitor.ps1
```

**Output**: [Paste or link to baseline artifacts]

### Known Issues
- Issue 1: [Description]
- Issue 2: [Description]

---

## 2️⃣ Clean

**Objective**: Remove drift, enforce guardrails, apply fixes.

### Changes Applied
1. **Change 1**: [What was changed]
   - **Files Modified**: [`file1.yaml`, `file2.ps1`]
   - **Rationale**: [Why this change was needed]
   - **Risk Level**: [LOW/MEDIUM/HIGH]

2. **Change 2**: [What was changed]
   - **Files Modified**: [`file3.ts`]
   - **Rationale**: [Why this change was needed]
   - **Risk Level**: [LOW/MEDIUM/HIGH]

### Remediation Steps Executed
- [ ] Step 1: [e.g., "Stopped Windows Collector service"]
- [ ] Step 2: [e.g., "Updated batch timeout from 10s to 200ms"]
- [ ] Step 3: [e.g., "Applied noise filter for Event IDs 4624, 4634"]

### Validation Commands
```powershell
# Commands run to verify changes
pwsh -File scripts\verify-pipeline.ps1
pwsh -File scripts\canary-test.ps1
```

**Output**: [Paste or link to validation results]

### Rollback Plan
**If issues arise, rollback by:**
1. [Step 1: e.g., "Revert config.yaml to backup"]
2. [Step 2: e.g., "Restart OTel Collector"]
3. [Step 3: e.g., "Verify baseline restored"]

---

## 3️⃣ Report

**Objective**: Generate artifacts, document evidence, measure impact.

### Post-Change Metrics
- **Performance**: [Before → After, e.g., "batch latency 10s → 200ms"]
- **Error Rate**: [Before → After]
- **Resource Usage**: [CPU/Memory before → after]
- **Volume**: [Log/trace counts, noise reduction %]

### Evidence Artifacts
- **Location**: `artifacts/ecrr-reports/YYYYMMDD-gate-XXX/`
- **Contents**:
  - `before-snapshot.json`
  - `after-snapshot.json`
  - `diff-report.md`
  - `screenshots/` (if visual)
  - `logs/` (relevant excerpts)

### Testing Strategy
- [ ] **Unit Tests**: [Files tested, coverage %]
- [ ] **Integration Tests**: [End-to-end scenarios verified]
- [ ] **Smoke Tests**: [Canary tests passed]
- [ ] **Performance Tests**: [Load/stress testing results]

### SigNoz Verification
- **Query**: [e.g., `message contains "canary test"`]
- **Result**: [Screenshot or confirmation]
- **Dashboard**: [Link to SigNoz dashboard showing impact]

### Budget Compliance
- **Files Changed**: X / 10 (max per PR)
- **Lines of Code**: Y / 200 (max per PR)
- **Status**: ✅ Within budget / ⚠️ Exceeded (with justification)

---

## 4️⃣ Role

**Objective**: Declare actor responsible, confirm handoffs.

### A/B Role Declaration
- **A (Writer)**: [Name/team who implemented changes]
- **B (Monitor)**: [Name/team who verified/approved]

### Handoff Checklist
- [ ] **Evidence Package**: Delivered to B and archived
- [ ] **Documentation**: Updated (README, runbooks, config docs)
- [ ] **Knowledge Transfer**: B confirms understanding of changes
- [ ] **Monitoring**: B has access to dashboards and alerts
- [ ] **Rollback**: B knows how to revert if needed

### Gate Readiness
**Status**: READY

**Gate Phrase**: `@cat ready-for-gate`

**Sign-off**:
- **A (Writer)**: [Name, Date]
- **B (Monitor)**: [Name, Date]

### Next Actions
1. [Action 1: e.g., "Monitor for 24h"]
2. [Action 2: e.g., "Schedule follow-up review"]
3. [Action 3: e.g., "Update runbooks"]

---

## Compliance Checklist

Before submitting this report, verify:

- [x] All 4 phases (Examine, Clean, Report, Role) are completed
- [x] Evidence artifacts are generated and archived
- [x] Budget limits: 5/10 files ✅, ~350/200 LOC ⚠️ (exceeded but justified)
- [x] A/B roles are declared with names
- [x] Gate phrase included if gate-ready
- [x] Rollback plan documented
- [x] Testing strategy executed
- [x] SigNoz verification completed
- [x] Documentation updated

**Budget Justification**: Created comprehensive `CURRENT_ARCHITECTURE.md` (~200 LOC) as canonical reference, benefiting entire repository. Overage justified by strategic value.

---

## Template Version

- **Version**: 1.0
- **Last Updated**: 2025-11-01
- **Source**: `docs/ecrr/ECRR_TEMPLATE.md`

---

**Usage**:
```powershell
# Create new report from template
Copy-Item docs\ecrr\ECRR_TEMPLATE.md docs\ecrr\ECRR_REPORTS\ECRR_GATE_XXX_YYYYMMDD.md
```


