# ECRR Workshop Execution Script

## 🎯 **Workshop Execution Overview**

This script provides step-by-step execution instructions for conducting ECRR template cloning workflow workshops.

## ⏱️ **Workshop Duration**: 60 minutes

---

## 📋 **Pre-Workshop Setup**

### **Environment Preparation**
```powershell
# Verify PowerShell environment
$PSVersionTable.PSVersion

# Verify repository access
git status

# Verify ECRR tools
Test-Path "scripts/lint-ecrr-compliance.ps1"
Test-Path "docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md"

# Create workshop directory
New-Item -ItemType Directory -Path "workshop" -Force
```

### **Materials Check**
- [ ] **Workshop Script**: `docs/ECRR_WORKSHOP_SCRIPT.md`
- [ ] **Training Guide**: `docs/ECRR_TEAM_TRAINING_GUIDE.md`
- [ ] **Quick Reference**: `docs/ECRR_QUICK_REFERENCE_CARD.md`
- [ ] **Perfect Template**: `docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md`
- [ ] **Lint Script**: `scripts/lint-ecrr-compliance.ps1`

---

## 🚀 **Workshop Execution**

### **Part 1: Introduction (15 minutes)**

#### **1.1 Welcome and Overview (5 minutes)**
```markdown
Welcome to the ECRR Template Cloning Workshop!

Today we'll learn:
- ECRR framework and compliance requirements
- 5-step template cloning workflow
- Automated compliance validation
- CI/CD integration

Materials:
- Workshop script
- Training guide
- Quick reference card
- Hands-on exercises
```

#### **1.2 ECRR Framework Overview (10 minutes)**
```markdown
ECRR (Emergency Change Review Report) Framework:

Purpose: Document and validate changes systematically
Framework: Examine → Clean → Report → Role
Compliance: 12 requirements across Structure, Content, Quality

Structure (3/3):
- 4-Section Structure
- ECRR Gate
- Status Declaration

Content (5/5):
- Actor Declaration
- Guardrail Compliance
- Evidence Attachment
- Artifact Documentation
- Reproducible Validation

Quality (4/4):
- Root Cause Analysis
- Before/After Comparison
- Validation Results
- Next Actions
```

### **Part 2: Hands-on Practice (30 minutes)**

#### **2.1 Step 1: Copy Template (5 minutes)**
```powershell
# Copy the perfect compliance template
Copy-Item -Path 'docs/ECRR_REPORTS/2025-09-29-rollout-merge-consolidated.md' -Destination 'docs/ECRR_REPORTS/workshop-example-ecrr.md'

# Verify copy
Test-Path 'docs/ECRR_REPORTS/workshop-example-ecrr.md'
```

**Exercise**: Each participant copies the template

#### **2.2 Step 2: Update Content (15 minutes)**

**Sample Task**: "Implement automated testing for ECRR compliance"

**Required Changes**:
```markdown
# ECRR Report: Automated ECRR Compliance Testing Implementation

**Date**: 2025-01-27  
**Actor**: [Participant Name] - Development Team Member  
**Task**: Implement automated testing for ECRR compliance validation  
**Status**: ✅ **AUTOMATED TESTING IMPLEMENTATION IN PROGRESS**
```

**Section Updates**:
- **Examine**: Current testing state, manual validation process
- **Clean**: Implement automated testing scripts and validation
- **Report**: Testing results, automation improvements
- **Role**: Development team, QA team, CI/CD pipeline

**Critical**: Preserve required patterns:
```markdown
Local-First: All testing focuses on local development environment
Safety: No secrets exposed, all test configurations documented
Idempotence: All testing scripts and processes are re-runnable
Verification: Every test includes validation and reporting

Screenshots: Test execution screenshots, compliance validation results
Console logs: Test execution logs, validation output
Configuration files: Test configuration files, validation scripts
Test outputs: Test results, compliance reports, validation artifacts
```

**Exercise**: Participants update their reports with sample content

#### **2.3 Step 3: Validate Compliance (5 minutes)**
```powershell
# Run compliance validation
pwsh -NoLogo -File scripts/lint-ecrr-compliance.ps1 -Verbose | Select-String "workshop-example-ecrr.md" -Context 3

# Check detailed results
$report = Get-Content 'artifacts/ecrr-compliance-report.json' -Raw | ConvertFrom-Json
$workshopReport = $report.Reports | Where-Object { $_.File -like "*workshop-example*" }
$workshopReport | Select-Object File, Score, Total, Issues
```

**Exercise**: Participants validate their reports and check scores

#### **2.4 Step 4: Check Score (3 minutes)**
**Target**: Score: 12/12, Issues: []

**If Score < 12**:
1. Identify missing requirements
2. Add required patterns
3. Re-run validation
4. Verify score improvement

**Exercise**: Participants troubleshoot and improve their scores

#### **2.5 Step 5: Document Completion (2 minutes)**
```markdown
# Add to TASKS.md
`FINISHED` 2025-01-27 [time] – Automated ECRR Compliance Testing Implementation
- Implemented automated testing scripts for ECRR compliance validation
- Created comprehensive test suite with validation and reporting
- Achieved perfect compliance score: 12/12 (100%)
- Ready for integration with CI/CD pipeline
```

**Exercise**: Participants document their completion

### **Part 3: CI/CD Integration (10 minutes)**

#### **3.1 GitHub Actions Workflow (5 minutes)**
```yaml
# .github/workflows/ecrr-compliance.yml
name: ECRR Compliance Check
on:
  push:
    branches: [ main, develop ]
    paths: [ 'docs/ECRR_REPORTS/**' ]
  pull_request:
    branches: [ main, develop ]
    paths: [ 'docs/ECRR_REPORTS/**' ]
```

#### **3.2 Compliance Threshold (3 minutes)**
- **Pass Threshold**: 80% overall compliance
- **Fail Behavior**: CI fails if threshold not met
- **Artifact Upload**: Compliance reports uploaded for 30 days

#### **3.3 Testing CI Integration (2 minutes)**
```powershell
# Test workflow locally
pwsh -NoLogo -File scripts/lint-ecrr-compliance.ps1 -FailOnError

# Check compliance report
Get-Content 'artifacts/ecrr-compliance-report.json' | ConvertFrom-Json | Select-Object Overall_Score
```

**Exercise**: Participants test CI integration

### **Part 4: Q&A and Wrap-up (5 minutes)**

#### **4.1 Common Issues (3 minutes)**
- **Missing Patterns**: Add exact patterns with colons
- **Score Issues**: Check compliance report for specific failures
- **CI Failures**: Verify 80% threshold compliance

#### **4.2 Resources and Support (2 minutes)**
- **Training Guide**: `docs/ECRR_TEAM_TRAINING_GUIDE.md`
- **Quick Reference**: `docs/ECRR_QUICK_REFERENCE_CARD.md`
- **Template Guide**: `docs/ECRR_TEMPLATE_GUIDE.md`
- **Team Chat**: Ask questions in team channels

---

## 🎓 **Workshop Exercises**

### **Exercise 1: Template Cloning**
**Objective**: Practice the 5-step template cloning workflow
**Duration**: 15 minutes
**Deliverable**: Perfect compliance ECRR report (12/12)

**Steps**:
1. Copy perfect compliance template
2. Update metadata for sample task
3. Fill in Examine, Clean, Report, Role sections
4. Preserve required patterns
5. Validate compliance and check score

### **Exercise 2: Pattern Recognition**
**Objective**: Identify and fix compliance issues
**Duration**: 10 minutes
**Deliverable**: Improved compliance score

**Steps**:
1. Review non-compliant ECRR report
2. Identify missing patterns
3. Add required patterns
4. Re-run validation
5. Verify score improvement

### **Exercise 3: CI Integration**
**Objective**: Test CI/CD integration
**Duration**: 5 minutes
**Deliverable**: Successful CI validation

**Steps**:
1. Create test ECRR report
2. Push to test branch
3. Verify GitHub Actions workflow triggers
4. Check compliance report artifacts
5. Verify 80% threshold compliance

---

## 📊 **Workshop Success Metrics**

### **Individual Success**
- [ ] **Template Cloned**: Successfully copied and updated template
- [ ] **Perfect Compliance**: Achieved 12/12 score
- [ ] **CI Integration**: Verified CI/CD workflow functionality
- [ ] **Documentation**: Added completion entry to TASKS.md

### **Team Success**
- [ ] **Consistency**: All participants using template workflow
- [ ] **Compliance**: 100% of workshop reports achieve perfect compliance
- [ ] **Understanding**: Clear comprehension of ECRR framework
- [ ] **Integration**: Successful CI/CD integration testing

---

## 🔄 **Post-Workshop Follow-up**

### **Immediate Actions**
1. **Practice**: Create additional ECRR reports using template workflow
2. **Integration**: Use template workflow for upcoming tasks
3. **Feedback**: Provide feedback on training effectiveness
4. **Support**: Ask questions and request assistance as needed

### **Ongoing Support**
1. **Documentation**: Reference training materials as needed
2. **Team Chat**: Ask questions in team channels
3. **Code Review**: Request review of ECRR reports

---

## 📞 **Workshop Support**

### **During Workshop**
- **Instructor**: Available for questions and assistance
- **Documentation**: Reference materials available
- **Tools**: All required tools and scripts provided
- **Practice Environment**: Safe environment for hands-on practice

### **Post-Workshop**
- **Training Guide**: `docs/ECRR_TEAM_TRAINING_GUIDE.md`
- **Quick Reference**: `docs/ECRR_QUICK_REFERENCE_CARD.md`
- **Template Guide**: `docs/ECRR_TEMPLATE_GUIDE.md`

---

## 🎯 **Workshop Completion Checklist**

- [ ] **Understanding**: ECRR framework and compliance requirements
- [ ] **Practice**: Template cloning workflow (5 steps)
- [ ] **Validation**: Compliance checking and score verification
- [ ] **Integration**: CI/CD pipeline and GitHub Actions
- [ ] **Troubleshooting**: Common issues and solutions
- [ ] **Documentation**: Reference materials and resources

---

**Status**: ✅ **WORKSHOP EXECUTION SCRIPT COMPLETE**

**Next Steps**: Begin workshop sessions and monitor progress

