---
name: BossCat ECRR Task
about: Create an ECRR-compliant agent task following BossCat governance
title: "[ECRR] "
labels: ''
assignees: ''

---

## 🎯 BossCat ECRR Task Assignment

**Task ID**: ECRR-YYYYMMDD-XXXXXXXX
**Agent Role**: [Investigator/Gap-Closer/QA Scribe/IONA]
**Authorization**: BossCat OEM Approved ✅

---

### 📋 ECRR Framework Application

**Examine**: What needs to be verified or investigated?
- [ ] Environment state capture
- [ ] Baseline metrics collection  
- [ ] SigNoz dashboard snapshot
- [ ] Log analysis for anomalies

**Clean**: What fixes or improvements are required?
- [ ] Configuration updates
- [ ] Documentation patches
- [ ] Code implementations
- [ ] Test validation

**Report**: What artifacts must be generated?
- [ ] ECRR report in docs/ecrr/ECRR_REPORTS/
- [ ] SigNoz dashboard export
- [ ] Evidence collection artifacts
- [ ] Compliance verification

**Role**: Who will execute and maintain?
- [ ] Primary agent assigned
- [ ] Backup agent identified
- [ ] BossCat oversight confirmed
- [ ] Timeline established

---

### 🔍 Task Details

**Priority**: [Critical/High/Medium/Low]  
**Category**: [Infrastructure/Monitoring/Security/Compliance/Documentation]

**Description**:
<!-- Detailed description of the task -->

**Success Criteria**:
- [ ] Criteria 1
- [ ] Criteria 2  
- [ ] Criteria 3

**Dependencies**:
- [ ] Dependency 1
- [ ] Dependency 2

---

### 📊 SigNoz Integration

**Dashboard References**:
- Primary: dashboard-url-here
- Backup: ackup-dashboard-url-here

**Key Metrics to Monitor**:
- Metric 1: Expected threshold alue
- Metric 2: Expected threshold alue

**Log Queries**:
`
dataset = 
esonai_analytics AND message contains 	ask-relevance
`

---

### 🎯 Evidence Collection

**Required Artifacts**:
- [ ] Pre-task state snapshot
- [ ] Implementation evidence  
- [ ] Post-task verification
- [ ] ECRR compliance report

**Export Commands**:
`ash
# Before starting
scripts/nights/dashboard-export.ps1

# After completion  
pnpm run export:signoz:playwright
scripts/update-docs-index.ps1
`

---

### ✅ BossCat Approval Checkpoints

- [ ] Agent capability assessment complete
- [ ] Resource allocation confirmed
- [ ] Timeline realistic and achievable
- [ ] Exit criteria clearly defined
- [ ] BossCat oversight scheduled

---

### 📅 Timeline

**Target Start**: YYYY-MM-DD
**Estimated Duration**: X hours/days
**Checkpoint Reviews**: Daily/Weekly/Upon-completion
**Deadline**: YYYY-MM-DD

---

🐾 **Task authorized by BossCat OEM. All agents must maintain ECRR discipline throughout execution.**
