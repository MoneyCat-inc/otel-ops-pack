## 🐾 BossCat PR Review - ECRR Checklist

### PR Type
<!-- Check all that apply -->
- [ ] **docs(ecrr)**: Documentation update
- [ ] **fix(gap)**: Bug fix or patch
- [ ] **test(canary)**: Test execution or validation
- [ ] **feat(bosscat)**: New feature or enhancement
- [ ] **chore(repo)**: Repository maintenance or restructuring

### ECRR Framework Compliance

#### 📋 Examine - What was the state before?
<!-- Describe the environment/system state before changes -->
- **Problem identified:**
- **Scope of investigation:**
- **Evidence collected:**

#### 🧹 Clean - What was fixed/changed?
<!-- Describe the changes and fixes applied -->
- **Changes made:**
- **Drift removed:**
- **Guardrails applied:**

#### 📊 Report - What artifacts were generated?
<!-- List any reports, logs, or evidence produced -->
- [ ] ECRR report generated (if applicable): `CHAR/EVID/ECRR_REPORTS/`
- [ ] Monitoring data exported (if applicable): `CHAR/EVID/artifacts/`
- [ ] Documentation updated (if applicable): `CHAR/DOCS/`
- [ ] Evidence attached or linked below

#### 👤 Role - Who is responsible?
<!-- Identify the agent/role executing this change -->
- **Agent/Role:** (e.g., BossCat OEM, Investigator, Gap-Closer, QA Scribe)
- **Reviewer:** @BossCat
- **Stakeholders:**

---

### Tetragram Structure Compliance
<!-- If this PR involves file moves or restructuring -->
- [ ] Changes follow tetragram structure (ALFA/BRAV/CHAR/DELT)
- [ ] Guardrails check passed: ✅ (GitHub Actions workflow)
- [ ] Legacy shims created for backward compatibility (if needed)
- [ ] Pathmap updated (if applicable)
- [ ] No forbidden legacy root directories introduced

**Affected planes:**
- [ ] ALFA (Application)
- [ ] BRAV (Build/Runtime/Automation/Verification)
- [ ] CHAR (Compliance/Human/Audit/Review)
- [ ] DELT (Data/Environment/Load/Test)

---

### Testing & Validation
- [ ] Manual testing completed
- [ ] Automated tests pass
- [ ] Canary tests executed: `pwsh -File BRAV/SCPT/canary-test.ps1`
- [ ] Pipeline verified: `pwsh -File BRAV/SCPT/verify-pipeline.ps1`
- [ ] SigNoz dashboard checked: http://localhost:8080

---

### Migration Checklist (if applicable)
<!-- For repository restructuring PRs -->
- [ ] Phase identified: B.1 (scripts) / B.2 (configs) / C (source) / D (docs)
- [ ] Migration script used: `BRAV/SCPT/migrate_*.sh` or `.ps1`
- [ ] Shims created for backward compatibility
- [ ] CI/CD workflows updated to use new paths
- [ ] Documentation references updated
- [ ] Plan for shim removal after 2 green cycles

---

### Gate Readiness
<!-- For final consolidation PRs -->
- [ ] All legacy directories removed
- [ ] Guardrails check: **GREEN** ✅
- [ ] Full CI/CD pipeline: **GREEN** ✅
- [ ] Evidence bundle prepared
- [ ] Ready for BossCat gate approval: **@cat ready-for-gate**

---

### Additional Context
<!-- Any other relevant information -->


---

### Pre-merge Checklist
- [ ] PR title follows ECRR format: `type(scope): description`
- [ ] All CI checks passing
- [ ] No merge conflicts
- [ ] Documentation updated (if needed)
- [ ] CODEOWNERS notified
- [ ] BossCat approval obtained

---

**Evidence Links:**
<!-- Add links to ECRR reports, dashboard snapshots, or other artifacts -->
- 
- 

---

🐾 **BossCat Charter Compliance**: This PR follows the BossCat Operating Principles:
- [x] Local-first: All artifacts stored locally
- [x] Proof-to-disk: Logs/reports generated
- [x] Deterministic: Reproducible results
- [x] Evidence-based: Backed by telemetry/data
