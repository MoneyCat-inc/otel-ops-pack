# ECRR Remediation Plan - DOCS & VIZR Lane Rebalance

**Generated**: 2025-11-01  
**Source**: ECRR Analytics Review (318 reports)  
**Objective**: Address gaps in Clean/Role phases and rebalance lane focus

---

## Problem Statement

### Key Gaps (from `artifacts/ecrr-analytics/ecrr-metrics.json`)
- **Only 42/318 reports** document a Clean phase (13%)
- **Only 48/318 reports** capture Role handoffs (15%)
- **Remediation steps and A/B verification are getting lost** despite 92% gate success rate

### Focus Imbalance
- **COMP**: 7 reports (over-invested in performance)
- **DOCS**: 2 reports (severely under-represented)
- **AUDIO**: 3 reports
- **FLAK**: 1 report
- **VIZR/SELE**: 0 reports (no coverage)

### Process Drift
- Windows Collector confusion persists in reports
- Documentation references deprecated dual-hop architecture
- Onboarding relies on out-of-date runbooks

### Risks
- 50% noise-reduction goal remains fragile without Clean/Role follow-through
- Sub-200ms latency gains could regress without operationalized recommendations
- New team members onboard with incorrect architecture understanding

---

## Remediation Tickets

### 🎯 **Ticket 1: DOCS Lane - Architecture Documentation Cleanup**

**Lane**: DOCS  
**Priority**: HIGH  
**Effort**: M (2-3 days)  
**Owner**: [To be assigned]

**Objective**: Remove Windows Collector references and document current architecture as canonical.

**Tasks**:
- [ ] Update `README.md` (remove Windows Collector setup instructions)
- [ ] Revise `docs/runbooks/unified-telemetry-proofs.md` (direct-to-SigNoz only)
- [ ] Update architecture diagrams (remove dual-hop)
- [ ] Add `docs/architecture/WINDOWS_COLLECTOR_DEPRECATION.md` to all training materials
- [ ] Update onboarding checklist (point to current architecture)
- [ ] Audit all ECRR reports in `CHAR/ECRR/ECRR_REPORTS/` for Windows Collector mentions
- [ ] Add deprecation note to any report still referencing old architecture

**Evidence**:
- [ ] `git grep -i "windows collector"` returns only deprecation notice and archived reports
- [ ] All runbooks pass peer review for accuracy
- [ ] New team member can onboard without encountering deprecated content

**Budget**: ≤10 files, ≤200 LOC  
**ECRR**: Use `docs/ecrr/ECRR_TEMPLATE.md` (all 4 phases required)

---

### 🎯 **Ticket 2: DOCS Lane - ECRR Template Rollout**

**Lane**: DOCS  
**Priority**: HIGH  
**Effort**: S (1 day)  
**Owner**: [To be assigned]

**Objective**: Standardize 4-phase ECRR reporting to close Clean/Role gaps.

**Tasks**:
- [ ] Add `docs/ecrr/ECRR_TEMPLATE.md` to all project documentation
- [ ] Update CONTRIBUTING.md (require template for all ECRR reports)
- [ ] Create PowerShell helper: `scripts/new-ecrr-report.ps1` (auto-generates from template)
- [ ] Add pre-commit hook to validate ECRR reports contain all 4 phases
- [ ] Update Cursor rules to reference template
- [ ] Document template usage in `docs/ecrr/INDEX.md`

**Evidence**:
- [ ] New ECRR reports created after this ticket use the template
- [ ] Pre-commit hook catches incomplete reports
- [ ] Compliance rate (currently 37.7%) increases to ≥80% within 30 days

**Budget**: ≤8 files, ≤150 LOC  
**ECRR**: Use `docs/ecrr/ECRR_TEMPLATE.md` (all 4 phases required)

---

### 🎯 **Ticket 3: DOCS Lane - Monitoring Script Updates**

**Lane**: DOCS  
**Priority**: MEDIUM  
**Effort**: S (1 day)  
**Owner**: [To be assigned]

**Objective**: Remove deprecated checks from monitoring scripts.

**Tasks**:
- [ ] Update `scripts/quick-monitor.ps1` (remove Windows Collector check OR mark as expected STOPPED)
- [ ] Update `scripts/monitor-optimized-pipeline.ps1` (remove Windows Collector metrics)
- [ ] Update `scripts/verify-pipeline.ps1` (validate Docker collectors only)
- [ ] Add comment blocks explaining deprecation for future maintainers
- [ ] Update script help text and examples

**Evidence**:
- [ ] Scripts no longer report Windows Collector as unexpected state
- [ ] Help text accurately describes current architecture
- [ ] No confusion in team channel about "Windows Collector STOPPED" warnings

**Budget**: ≤5 files, ≤100 LOC  
**ECRR**: Use `docs/ecrr/ECRR_TEMPLATE.md` (all 4 phases required)

---

### 🎯 **Ticket 4: VIZR Lane - Visualization Documentation**

**Lane**: VIZR  
**Priority**: MEDIUM  
**Effort**: M (2 days)  
**Owner**: [To be assigned]

**Objective**: Document visualizer components and workflows (currently 0 ECRR reports).

**Tasks**:
- [ ] Document ProjectM GPU container setup and configuration
- [ ] Create runbook for `viz-engine-projectm-gpu` troubleshooting
- [ ] Document VirtualGL setup and rendering pipeline
- [ ] Add ECRR report for recent viz-engine changes
- [ ] Create architecture diagram for visualizer telemetry flow
- [ ] Document preset management and iteration workflow

**Evidence**:
- [ ] `docs/vizr/` directory created with comprehensive docs
- [ ] Runbook enables new team members to debug viz issues independently
- [ ] At least 1 ECRR report in VIZR lane documenting current state

**Budget**: ≤10 files, ≤200 LOC  
**ECRR**: Use `docs/ecrr/ECRR_TEMPLATE.md` (all 4 phases required)

---

### 🎯 **Ticket 5: VIZR Lane - Audio Pipeline Documentation**

**Lane**: VIZR (or AUDIO)  
**Priority**: LOW  
**Effort**: M (2 days)  
**Owner**: [To be assigned]

**Objective**: Document audio capture and loopback configuration.

**Tasks**:
- [ ] Document audio loopback setup for visualizer
- [ ] Create troubleshooting guide for audio issues
- [ ] Document audio threading and synchronization
- [ ] Add ECRR report for audio pipeline health
- [ ] Document performance tuning for audio processing

**Evidence**:
- [ ] `docs/audio/` directory created with comprehensive docs
- [ ] Audio issues can be debugged without tribal knowledge
- [ ] At least 1 ECRR report in AUDIO lane documenting current state

**Budget**: ≤10 files, ≤200 LOC  
**ECRR**: Use `docs/ecrr/ECRR_TEMPLATE.md` (all 4 phases required)

---

### 🎯 **Ticket 6: COMP Lane - Archive Deprecated Configs**

**Lane**: COMP  
**Priority**: LOW  
**Effort**: XS (1 hour)  
**Owner**: [To be assigned]

**Objective**: Move deprecated Windows Collector files to archive.

**Tasks**:
- [ ] Create `archive/deprecated/windows-collector/` directory
- [ ] Move `windows/otelcol/otelcol-contrib-config.yaml` to archive
- [ ] Move `windows/otelcol/otelcol-contrib.exe` to archive (if present)
- [ ] Update `.gitignore` to prevent accidental re-addition
- [ ] Update REPOSITORY_STRUCTURE.md to document archive location

**Evidence**:
- [ ] `windows/otelcol/` directory no longer exists
- [ ] Archive contains timestamped backup for compliance
- [ ] No confusion about which config file is canonical

**Budget**: ≤3 files, ≤50 LOC  
**ECRR**: Use `docs/ecrr/ECRR_TEMPLATE.md` (all 4 phases required)

---

## Implementation Schedule

### Week 1 (High Priority)
- **Day 1-2**: Ticket 1 (Architecture Documentation Cleanup)
- **Day 3**: Ticket 2 (ECRR Template Rollout)
- **Day 4**: Ticket 3 (Monitoring Script Updates)
- **Day 5**: Review and merge all high-priority tickets

### Week 2 (Medium Priority)
- **Day 1-2**: Ticket 4 (VIZR Documentation)
- **Day 3-4**: Ticket 5 (Audio Pipeline Documentation)
- **Day 5**: Review and merge medium-priority tickets

### Week 3 (Low Priority + Validation)
- **Day 1**: Ticket 6 (Archive Deprecated Configs)
- **Day 2-5**: Validation period (monitor compliance rate, gather feedback)

---

## Success Metrics

### Primary KPIs
- **ECRR Compliance Rate**: 37.7% → ≥80% (within 30 days)
  - Track weekly via `artifacts/ecrr-analytics/ecrr-metrics.json`
  
- **Clean Phase Coverage**: 42/318 (13%) → ≥240/300 (80%)
  - Track via `scripts/extract-ecrr-metrics.ps1`
  
- **Role Phase Coverage**: 48/318 (15%) → ≥240/300 (80%)
  - Track via `scripts/extract-ecrr-metrics.ps1`

### Secondary KPIs
- **Lane Balance**: DOCS reports 2 → ≥5, VIZR reports 0 → ≥2
- **Documentation Accuracy**: Zero mentions of deprecated Windows Collector outside archive
- **Onboarding Time**: New team member onboarding reduced by 25% (via feedback)

### Gate Success (Maintain)
- **Gate Success Rate**: Keep ≥90% (currently 92%)

---

## Tracking & Reporting

### Weekly Check-ins
Run the following command to track progress:
```powershell
# Update metrics
pwsh -File scripts\extract-ecrr-metrics.ps1

# View dashboard
Start-Process artifacts\ecrr-analytics\ecrr-dashboard.html

# Check compliance trend
Get-Content artifacts\ecrr-analytics\ecrr-metrics.json | ConvertFrom-Json | Select-Object -ExpandProperty byPhase
```

### Monthly Executive Review
Use the Codex executive review to assess:
```powershell
.\codex\codex-review-openai.ps1 `
  -Since HEAD~50 `
  -Question "Review ECRR methodology compliance and lane balance progress"
```

---

## Owner Assignment

| Lane | Primary | Backup | Persona |
|------|---------|--------|---------|
| DOCS | `VelvetQuill-42` ("Quil") | Maya Singh | see `docs/personas/quil-persona.md` |
| VIZR | `LumiPulse-MkII` ("Lumi") | Alex Romero | see `docs/personas/lumi-persona.md` |

### Quil (DOCS lane)
**Responsibilities**:
- Own Tickets 1, 2, 3
- Auto-generate ECRR reports, enforce 4-phase compliance
- Track documentation metrics weekly; escalate if compliance < 80%
- Cross-link updated architecture docs across the repo

**Operating Mode**:
- Triggered via workflows (see `.github/workflows/weekly-executive-review.yml`)
- Signs messages with `– Quil 🪶`
- Human backup: Maya Singh (reviews escalations & PRs)

### Lumi (VIZR lane)
**Responsibilities**:
- Own Tickets 4, 5
- Maintain dashboards and trend CSVs
- Create/track remediation tickets when visualization/audio docs lag
- Keep VIZR lane active with current ECRR entries

**Operating Mode**:
- Triggered via trend & dashboard scripts
- Signs messages with `– Lumi ✨`
- Human backup: Alex Romero (validates visuals & audio documentation)

---

## Questions Answered

### ✅ **Q1: Should we standardize an ECRR template that enforces all four phases?**
**A1**: **YES**. Template created at `docs/ecrr/ECRR_TEMPLATE.md`. Rollout in Ticket 2.

### ✅ **Q2: Should Windows Collector guidance be formally retired?**
**A2**: **YES**. Deprecation notice created at `docs/architecture/WINDOWS_COLLECTOR_DEPRECATION.md`. Cleanup in Ticket 1.

### ✅ **Q3: Who should own a DOCS catch-up lane?**
**A3**: **Assign DOCS lane owner** (see above). This person will execute Tickets 1-3 and maintain documentation quality going forward.

---

## Next Actions

1. **Assign Owners**: Designate DOCS and VIZR lane owners
2. **Kickoff Meeting**: Review remediation plan with team
3. **Create Tickets**: Port to your issue tracker (GitHub Issues, Jira, etc.)
4. **Baseline Metrics**: Capture current state before starting
5. **Weekly Reviews**: Track compliance metrics every Friday

---

**Version**: 1.0  
**Last Updated**: 2025-11-01  
**Owner**: ECRR Audit Team  
**Status**: Ready for Implementation


