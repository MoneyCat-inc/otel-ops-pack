# ECRR Template Quick Reference Card

## 🚀 **5-Step Template Cloning Workflow**

### **1️⃣ Copy Template**
```powershell
Copy-Item -Path 'docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md' -Destination 'docs/ECRR_REPORTS/your-new-report.md'
```

### **2️⃣ Update Content**
- Change Date, Actor, Task, Status at the top
- Fill Examine, Clean, Report, Role sections
- **Preserve required patterns** (see below)

### **3️⃣ Validate Compliance**
```powershell
pwsh -NoLogo -File scripts/lint-ecrr-compliance.ps1
```

### **4️⃣ Check Score**
```powershell
$report = Get-Content 'artifacts/ecrr-compliance-report.json' -Raw | ConvertFrom-Json
$yourReport = $report.Reports | Where-Object { $_.File -like "*your-report*" }
$yourReport | Select-Object File, Score, Total, Issues
```
**Target**: Score: 12/12, Issues: []

### **5️⃣ Document Completion**
Add FINISHED entry to `TASKS.md`

---

## 🛡️ **Required Patterns (Exact Match)**

### **Guardrail Compliance**
```markdown
Local-First: [description]
Safety: [description]
Idempotence: [description]
Verification: [description]
```

### **Evidence Attachments**
```markdown
Screenshots: [description]
Console logs: [description]
Configuration files: [description]
Test outputs: [description]
```

### **Required Sections**
- `## 📋 **Artifacts Created` or `### **Artifacts Created`
- `## ✅ **Validation Results Summary`
- `Validation Results` or `Runnable checks`

---

## 📋 **Compliance Checklist**

### **Structure (3/3)**
- [ ] 4-Section Structure: `## 🔍 **1. Examine`, `## 🧹 **2. Clean`, `## 📝 **3. Report`, `## 🎭 **4. Role`
- [ ] ECRR Gate: `## ✅ **ECRR Gate`
- [ ] Status Declaration: `**Status**:`

### **Content (5/5)**
- [ ] Actor Declaration: `**Actor**:` or `**Agent**:`
- [ ] Guardrail Compliance: Exact patterns with colons
- [ ] Evidence Attachment: Exact patterns with colons
- [ ] Artifact Documentation: Required section headings
- [ ] Reproducible Validation: Required patterns

### **Quality (4/4)**
- [ ] Root Cause Analysis: `Root Cause Analysis` or `Key Findings`
- [ ] Before/After Comparison: `Before/After Comparison`, `Before:`, `After:`
- [ ] Validation Results: `Validation Results` or `All verification steps`
- [ ] Next Actions: `Next Actions`, `Immediate`, `Short-term`, `Long-term`

---

## 🚨 **Common Issues & Quick Fixes**

| Issue | Quick Fix |
|-------|-----------|
| Missing Guardrail_Compliance | Add exact patterns with colons |
| Missing Evidence_Attachment | Add exact patterns with colons |
| Missing Artifact_Documentation | Add `## 📋 **Artifacts Created` |
| Missing Validation_Results | Add `## ✅ **Validation Results Summary` |
| Score < 12 | Check compliance report for specific failures |

---

## 🛠️ **Tools & Resources**

### **Primary Tools**
- **Template**: `docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md`
- **Lint**: `scripts/lint-ecrr-compliance.ps1`
- **Validate**: `scripts/validate-ecrr-compliance.ps1`

### **Reference Docs**
- **Training Guide**: `docs/ECRR_TEAM_TRAINING_GUIDE.md`
- **Template Guide**: `docs/ECRR_TEMPLATE_GUIDE.md`
- **Quick Reference**: `docs/ECRR_QUICK_REFERENCE.md`

### **CI/CD**
- **Workflow**: `.github/workflows/ecrr-compliance.yml`
- **Threshold**: 80% overall compliance
- **Artifacts**: `artifacts/ecrr-compliance-report.json`

---

## 📞 **Getting Help**

1. **Check Documentation**: Reference guides first
2. **Team Chat**: Ask questions in team channels
3. **Code Review**: Request review of ECRR reports
4. **Perfect Template**: Use as reference for patterns

---

## 🎯 **Success Criteria**

- **Perfect Compliance**: 12/12 score
- **All Patterns**: Required patterns present
- **CI Pass**: 80%+ overall compliance
- **Documentation**: Completion entry in TASKS.md

---

**Keep this card handy for quick reference!**

