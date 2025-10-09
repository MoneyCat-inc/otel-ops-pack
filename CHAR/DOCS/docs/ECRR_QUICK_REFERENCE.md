# ECRR Quick Reference - Perfect Compliance Workflow

## 🎯 **Template Reference**

**Perfect Compliance Report**: `docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md`  
**Score**: **12/12 (100%)**  
**Guide**: `docs/ECRR_TEMPLATE_GUIDE.md`

---

## ⚡ **Quick Start Workflow**

### **Step 1: Copy Template Structure**
```bash
# Copy the perfect compliance template
cp docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md docs/ECRR_REPORTS/your-new-report.md
```

### **Step 2: Update Content (Keep Required Patterns)**
- ✅ **Actor Declaration**: `**Actor**:` or `**Agent**:`
- ✅ **Status Declaration**: `**Status**:`
- ✅ **Four ECRR Sections**: Examine → Clean → Report → Role
- ✅ **ECRR Gate**: `## ✅ **ECRR Gate`

### **Step 3: Add Required Patterns (Exact Match)**
```markdown
# Guardrail Compliance (exact patterns with colons)
Local-First: [your description]
Safety: [your description]
Idempotence: [your description]
Verification: [your description]

# Evidence Attachments (exact patterns with colons)
Screenshots: [your description]
Console logs: [your description]
Configuration files: [your description]
Test outputs: [your description]
```

### **Step 4: Include Required Sections**
- ✅ **Artifacts Created**: `## 📋 **Artifacts Created` or `### **Artifacts Created`
- ✅ **Validation Results**: Include `Validation Results` or `All verification steps`
- ✅ **Next Actions**: Include `Next Actions`, `Immediate`, `Short-term`, or `Long-term`
- ✅ **Before/After**: Include `Before/After Comparison`, `Before:`, or `After:`

### **Step 5: Validate Compliance**
```powershell
# Run compliance validator
pwsh -NoLogo -File scripts/validate-ecrr-compliance.ps1

# Check your specific report score
$report = Get-Content 'artifacts/ecrr-compliance-report.json' -Raw | ConvertFrom-Json
$entry = $report.Reports | Where-Object { $_.File -like '*your-report-name*' }
$entry | ConvertTo-Json -Depth 6
```

### **Step 6: Confirm Perfect Score**
- ✅ **Target**: Score = 12, Issues = []
- ✅ **Structure**: 3/3 (100%)
- ✅ **Content**: 5/5 (100%)
- ✅ **Quality**: 4/4 (100%)

---

## 🔍 **Pattern Testing Commands**

### **Test Guardrail Patterns**
```powershell
$content = Get-Content "your-report.md" -Raw
$patterns = @("Local-First:", "Safety:", "Idempotence:", "Verification:")
foreach ($pattern in $patterns) { 
    if ($content -match [regex]::Escape($pattern)) { 
        Write-Host "✅ Found: $pattern" 
    } else { 
        Write-Host "❌ Missing: $pattern" 
    } 
}
```

### **Test Evidence Patterns**
```powershell
$patterns = @("Screenshots:", "Console logs:", "Configuration files:", "Test outputs:")
foreach ($pattern in $patterns) { 
    if ($content -match [regex]::Escape($pattern)) { 
        Write-Host "✅ Found: $pattern" 
    } else { 
        Write-Host "❌ Missing: $pattern" 
    } 
}
```

---

## 📋 **Checklist for 100% Compliance**

### **Structure (3/3)**
- [ ] `## 🔍 **1. Examine`
- [ ] `## 🧹 **2. Clean`
- [ ] `## 📝 **3. Report`
- [ ] `## 🎭 **4. Role`
- [ ] `## ✅ **ECRR Gate`
- [ ] `**Status**:`

### **Content (5/5)**
- [ ] `**Actor**:` or `**Agent**:`
- [ ] `Local-First:` (exact pattern)
- [ ] `Safety:` (exact pattern)
- [ ] `Idempotence:` (exact pattern)
- [ ] `Verification:` (exact pattern)
- [ ] `Screenshots:` (exact pattern)
- [ ] `Console logs:` (exact pattern)
- [ ] `Configuration files:` (exact pattern)
- [ ] `Test outputs:` (exact pattern)
- [ ] `## 📋 **Artifacts Created` or `### **Artifacts Created`
- [ ] `Validation Results` or `Runnable checks`

### **Quality (4/4)**
- [ ] `Root Cause Analysis` or `Key Findings`
- [ ] `Before/After Comparison`, `Before:`, or `After:`
- [ ] `Validation Results` or `All verification steps`
- [ ] `Next Actions`, `Immediate`, `Short-term`, or `Long-term`

---

## 🚀 **Success Metrics**

**Perfect Compliance**: 12/12 (100%)  
**Issues**: 0  
**Validator Exit Code**: 2 (expected for low overall repo compliance)

**Repository Impact**:
- **Total Reports**: 140
- **Perfect Compliance**: 1 (template)
- **Overall Compliance**: 2.04%

---

## 📝 **Documentation Update**

After achieving perfect compliance:
```markdown
# Add to TASKS.md
`FINISHED` YYYY-MM-DD HH:MM:SS – [Your Task Name] ECRR Report
- [Brief description of what was accomplished]
- Achieved perfect compliance score: 12/12 (100%) with 0 issues
- [Any other relevant details]
```

---

## 🎯 **Next Steps Options**

1. **Replicate Template**: Use this workflow for the next pending ECRR report
2. **Automate Linting**: Create a pre-commit hook that fails reports missing required patterns
3. **Batch Update**: Apply template patterns to existing reports to improve overall compliance
4. **Training**: Share this quick reference with team members creating ECRR reports

---

**Quick Reference Created**: 2025-01-27  
**Template Status**: ✅ **PERFECT COMPLIANCE (12/12)**  
**Ready for Use**: ✅ **YES**

