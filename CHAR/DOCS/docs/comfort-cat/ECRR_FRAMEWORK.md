# 🔄 ECRR Framework

## Examine → Clean → Report → Role

**Authority:** BossCat OEM  
**Last Updated:** 2025-10-20  
**Status:** ACTIVE

---

## 🎯 Purpose

The **ECRR Framework** is the foundational methodology for all operations in the
Cat Nap Control Room observability pipeline. It ensures accountability,
traceability, and evidence-based decision-making.

---

## 📋 The Four Phases

### 1️⃣ EXAMINE

**Objective:** Capture the current state before any changes

**Activities:**

- Gather baseline data and metrics
- Run diagnostic tools and health checks
- Document current configuration
- Identify issues and gaps
- Collect evidence of current state

**Commands:**

```powershell
# Quick health check
pwsh -File scripts/legacy/quick-status.ps1
# OR (if using BRAV scripts):
# pwsh -File BRAV\SCPT\quick-monitor.ps1

# Full pipeline verification (gate script with exit codes 0/1/2)
pwsh -File BRAV\SCPT\verify-pipeline.ps1

# Operator linear check after collector restart (no gate exit codes)
pwsh -File scripts/legacy/operator-pipeline-check.ps1

# Service status
sc query otelcol-contrib
curl -s http://localhost:8080/api/v1/health
docker ps
```

**Artifacts:**

- Diagnostic output JSON
- Service status logs
- Environment configuration snapshot
- Issue inventory

**Duration:** 5-15 minutes

---

### 2️⃣ CLEAN

**Objective:** Remediate issues and enforce standards

**Activities:**

- Fix wiring and connectivity issues
- Restore services to operational state
- Apply configuration standards
- Enforce guardrails and policies
- Validate remediation actions

**Commands:**

```powershell
# Restart services
Start-Service otelcol-contrib
docker compose restart   # root docker-compose.yml is the canonical stack

# Verify endpoints
Test-NetConnection -ComputerName localhost -Port 5320
Test-NetConnection -ComputerName localhost -Port 5321

# Run canary test
pwsh -File canary-test.ps1
```

**Artifacts:**

- Remediation action log
- Service restart evidence
- Configuration changes (Git diff)
- Validation test results

**Duration:** 10-30 minutes

---

### 3️⃣ REPORT

**Objective:** Generate evidence and documentation

**Activities:**

- Create ECRR report with all four phases documented
- Update status dashboards
- Export monitoring data
- Archive artifacts to Git
- Generate executive summary

**Commands:**

```powershell
# Generate monitoring report (if monitoring script available)
# Check for monitoring scripts in scripts/ or BRAV/SCPT/

# Update the status page (manual; there is no pnpm roadmap:update script)
pwsh -File scripts/update-status-dashboard.ps1

# Verify status
# Open docs/status.html in browser
```

**Artifacts:**

- ECRR report (Markdown)
- Gate status dashboard update
- Monitoring data exports
- Evidence archive (committed to Git)

**Duration:** 10-20 minutes

---

### 4️⃣ ROLE

**Objective:** Assign ownership and define next steps

**Activities:**

- Assign task ownership (PM, Agent, Verifier, Stakeholder, Operator)
- Define acceptance criteria
- Set validation thresholds
- Schedule reviews (Daily, Weekly, Monthly, Quarterly)
- Plan next ECRR cycle

**Ownership Matrix:**

| Role | Responsibility | Acceptance Criteria |
| ------ | ---------------- | --------------------- |
| **Project Manager** | Pass rates, roadmap | PR ≥95% |
| **Implication Agent** | Risk analysis | Blocked features tracked |
| **Verifier** | Gate enforcement | 100% gate compliance |
| **Stakeholder** | Deliverables | Shipped vs. planned on target |
| **Operator (You)** | Execution | ECRR cycle complete |

**Artifacts:**

- RACI matrix
- Acceptance criteria definitions
- Review schedule
- Next actions list with owners

**Duration:** 5-10 minutes

---

## 📊 ECRR Cycle Timeline

**Total Duration:** 30-75 minutes for full cycle

```text
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   EXAMINE   │───▶│    CLEAN    │───▶│   REPORT    │───▶│    ROLE     │
│   5-15 min  │    │  10-30 min  │    │  10-20 min  │    │   5-10 min  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
      ▲                                                            │
      └────────────────────────────────────────────────────────────┘
                    Next ECRR Cycle (as needed)
```

---

## 📝 ECRR Report Template

```markdown
# ECRR Report: [Purpose] - [Date]

**Authority:** Cursor{Implementer} under [Delegator] delegation
**Date:** YYYY-MM-DD HH:MM:SS
**Gate:** #XXX
**Status:** [READY/PENDING/BLOCKED]

---

## 1️⃣ EXAMINE

### Environment State
- Windows Collector: [Status]
- SigNoz Health: [Status]
- OTLP Endpoints: [Status]
- Docker Services: [Status]

### Issues Identified
1. [Issue 1 description]
2. [Issue 2 description]

### Baseline Metrics
- p95 Latency: [value]
- Error Rate: [value]
- Pass Rate: [value]

---

## 2️⃣ CLEAN

### Actions Taken
1. [Action 1 with command]
2. [Action 2 with command]

### Remediation Evidence
- [Evidence 1]
- [Evidence 2]

### Validation
- [Validation check 1]: ✅/⚠️/❌
- [Validation check 2]: ✅/⚠️/❌

---

## 3️⃣ REPORT

### Artifacts Generated
- `[artifact 1 path]`
- `[artifact 2 path]`

### Dashboard Updates
- [Dashboard 1]: Updated
- [Dashboard 2]: Updated

### Evidence Archive
- Committed to: `[commit SHA]`
- Files: [count] files changed

---

## 4️⃣ ROLE

### Ownership Assignments
| Task | Owner | Acceptance Criteria | Due Date |
|------|-------|---------------------|----------|
| [Task 1] | [Owner] | [Criteria] | [Date] |

### Next Actions
1. [Action 1 with owner]
2. [Action 2 with owner]

### Review Schedule
- Daily: [What to check]
- Weekly: [What to review]
- Monthly: [What to assess]

---

## ✅ Certification

**Cursor{Implementer} Attestation:**
- [x] All ECRR phases completed
- [x] Evidence comprehensive
- [x] Artifacts committed
- [x] Status dashboards updated
- [x] Next actions defined

**BossCat OEM Review Required:** YES/NO

---

🐾 **ECRR Report Complete**
```

---

## 🎯 Success Criteria

### Per ECRR Cycle

- [ ] Baseline data collected (Examine)
- [ ] Issues resolved (Clean)
- [ ] ECRR report generated (Report)
- [ ] Ownership assigned (Role)
- [ ] Artifacts committed to Git
- [ ] Dashboard updated and verified
- [ ] BossCat approval obtained (if required)

### For Production Changes

- [ ] PR lane ≥95% pass rate
- [ ] 100% SBOM coverage
- [ ] A lean ECRR filed for the change (quantified before/after, honest verdict)
- [ ] Zero critical vulnerabilities
- [ ] Pipeline latency <200ms
- [ ] Clean-host E2E gate green (no nightly automation gates anything since 2026-08-03)

---

## 📁 Evidence Storage

### Primary Locations

- **ECRR Reports**: `CHAR/ECRR/ECRR_REPORTS/`
- **Artifacts**: `artifacts/` (temporary), `DELT/ARTF/` (permanent)
- **Dashboards**: `docs/status.html`, `docs/GATE_STATUS_DASHBOARD.md`
- **Monitoring**: `docs/observability/snapshots/`

### Naming Conventions

```text
ECRR_[PURPOSE]_[YYYYMMDD]_[HHMMSS].md
ECRR_[PURPOSE]_LATEST.md  (symlink to most recent)
```

**Examples:**

- `ECRR_GATE_READY_20251020_073000.md`
- `ECRR_P1_COMPLETE_20251011.md`
- `ECRR_CURSOR_IMPLEMENTER_20251012_085425.md`

---

## 🔄 ECRR Cadence

### Continuous (Operational)

- **Trigger**: Issue detected, change required
- **Frequency**: As needed
- **Scope**: Specific issue or component
- **Report**: Brief ECRR (1-2 pages)

### Scheduled (Maintenance)

- **Trigger**: Weekly review schedule
- **Frequency**: Weekly
- **Scope**: Full system health check
- **Report**: Comprehensive ECRR (3-5 pages)

### Gate (Milestone)

- **Trigger**: Gate readiness assessment
- **Frequency**: Per gate (every 1-2 weeks)
- **Scope**: Complete gate verification matrix
- **Report**: Executive ECRR (5-10 pages)

### Incident (Emergency)

- **Trigger**: Critical failure, security issue
- **Frequency**: Immediate
- **Scope**: Incident scope only
- **Report**: Incident ECRR (2-4 pages) + Post-mortem

---

## 🛡️ ECRR Compliance

### Mandatory ECRR Triggers

1. **All production changes** (code, config, infrastructure)
2. **Gate transitions** (readiness, approval, completion)
3. **Security incidents** (vulnerabilities, breaches, alerts)
4. **Performance degradation** (SLO breaches, latency spikes)
5. **Scheduled maintenance** (weekly health checks)

### ECRR Exemptions (Rare)

- **Trivial changes** (typo fixes, comment updates) - Document in commit message instead
- **Emergency hotfixes** (ECRR generated post-facto within 24 hours)
- **Automated changes** (CI/CD, nightly automation) - Automated ECRR generation

### Compliance Score — retired

The 2025 compliance-score engine (reports ÷ triggering events, ≥80% target) was **retired on
2026-08-03** (Roadmap Phase 0, #433): its verdict was arithmetically incapable of failing. The
current standard is one lean ECRR per change — quantified before and after, an honest verdict, the
actor declared — with no scoring apparatus (`docs/BossCat/CHARTER.md`).

---

## 📞 ECRR Support

### Questions About ECRR

- **Reference**: This document (`docs/comfort-cat/ECRR_FRAMEWORK.md`)
- **Examples**: `CHAR/ECRR/ECRR_REPORTS/` directory
- **Escalation**: BossCat OEM

### ECRR Tool Issues

- **Scripts**: Check `scripts/` or `BRAV/SCPT/` for available monitoring scripts
- **Dashboard**: `docs/status.html` (ECRR status rollup)
- **Automation**: none — ECRRs are written per change, not generated by a pipeline

### ECRR Review Requests

- **Command**: `@cat ecrr-review`
- **Authority**: BossCat OEM
- **SLA**: Review within 24 hours

---

🐾 **ECRR Framework**  
*Examine → Clean → Report → Role: The foundation of all Cat Nap Control Room operations*
