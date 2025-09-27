# ECRR Report Template - Enhanced 4-Section Structure

**Date**: YYYY-MM-DD  
**Time**: HH:MM:SS UTC  
**Agent**: [Agent Name - Cursor Agent/Cursor-Local/ChatGPT Agent/Codex Agent/BossCat/QA Scribe]  
**Role**: [Role - Observability Copilot/OTel Steward/Agent Coordinator/Local Worker/etc.]  
**Task**: [Brief task description]  
**ECRR ID**: [Optional - for tracking specific initiatives]

---

## 📋 **ECRR Compliance Checklist - MANDATORY**
- [ ] **Actor Declaration**: Agent and role clearly stated in header and Role section
- [ ] **Evidence Attachment**: Screenshots, logs, configs, test outputs included
- [ ] **ECRR Gate**: Formal validation section completed with all checkboxes
- [ ] **Status Declaration**: Success/failure/completion status specified
- [ ] **4-Section Structure**: Examine → Clean → Report → Role format followed
- [ ] **Guardrail Compliance**: Local-first, safety, idempotence, verification principles followed
- [ ] **Artifact Documentation**: All files, scripts, and changes documented
- [ ] **Reproducible Validation**: Runnable checks provided for every change

> **⚠️ CRITICAL**: All ECRR reports MUST include the ECRR Gate section with completed checkboxes. Reports without ECRR Gate validation will be considered non-compliant.

---

## 🔍 **1. Examine**

### **Initial State Captured**
- **Environment**: [OS, tools, versions]
- **Current State**: [What was observed before changes]
- **Key Findings**: [Critical issues or opportunities identified]
- **Attached Evidence**: [Screenshots, logs, configs, test outputs]

### **Key Findings**
- **[Finding 1]**: [Description and impact]
- **[Finding 2]**: [Description and impact]
- **[Finding 3]**: [Description and impact]

### **Attached Evidence**
- Screenshots: [What was captured visually]
- Console logs: [Command outputs and errors]
- Configuration files: [Files examined or modified]
- Test outputs: [Validation results]

---

## 🧹 **2. Clean**

### **Drift Removal**
- **[Issue 1]**: [What was cleaned/fixed]
- **[Issue 2]**: [What was cleaned/fixed]
- **[Issue 3]**: [What was cleaned/fixed]

### **Guardrail Enforcement**
- **Local-First**: [How local-first principle was maintained]
- **Safety**: [Security measures implemented]
- **Idempotence**: [How changes can be safely re-run]
- **Verification**: [How changes were verified]

### **Service Worker & Cache Management**
- **Git Branches**: [Branch cleanup actions]
- **Temporary Files**: [File cleanup performed]
- **Port Conflicts**: [Port management actions]
- **Process Management**: [Background process cleanup]

---

## 📝 **3. Report**

### **Actions Taken**

#### **[Category 1]**
1. **[Action 1]**: [Description]
2. **[Action 2]**: [Description]
3. **[Action 3]**: [Description]

#### **[Category 2]**
1. **[Action 1]**: [Description]
2. **[Action 2]**: [Description]
3. **[Action 3]**: [Description]

### **Results Achieved**

#### **Before/After Comparison**
- **Before**: [Initial state]
- **After**: [Final state]
- **Improvement**: [Quantifiable improvement]

#### **Regression Analysis**
- **No Breaking Changes**: [Compatibility maintained]
- **Enhanced Reliability**: [Reliability improvements]
- **Improved Observability**: [Monitoring enhancements]
- **Better User Experience**: [UX improvements]

#### **TODOs Completed**
- ✅ [Completed task 1]
- ✅ [Completed task 2]
- ✅ [Completed task 3]

---

## 🎭 **4. Role**

### **Actor Declaration**
**[Agent Name]** acting as **[Role]**

**Scope**: [Scope of responsibility]  
**Responsibilities**: 
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Guardrails Respected**:
- Local-first (no external cloud dependencies)
- Safety (no secrets exposed)
- Idempotence (scripts re-runnable)
- Verification (runnable checks for every change)

**Integration**: 
- [How this integrates with existing systems]
- [Compatibility maintained]
- [Environment considerations]

---

## ✅ **ECRR Gate - MANDATORY VALIDATION**

> **⚠️ CRITICAL**: This section is MANDATORY for all ECRR reports. All checkboxes must be completed for report compliance.

### **🔍 Examine**
- [ ] **Initial State Captured**: Environment state documented before changes
- [ ] **Environment Documented**: OS, tools, versions, and system status recorded
- [ ] **Key Findings Identified**: Critical issues or opportunities documented
- [ ] **Evidence Attached**: Screenshots, logs, configs, test outputs included
- [ ] **Root Cause Analysis**: Underlying causes identified and documented

### **🧹 Clean**
- [ ] **Drift Removed**: All identified issues addressed and resolved
- [ ] **Guardrails Enforced**: Local-first, safety, idempotence, verification principles followed
- [ ] **Service Management**: Services restarted, ports cleared, conflicts resolved
- [ ] **File Cleanup**: Temporary files, caches, and artifacts cleaned
- [ ] **Process Management**: Background processes and conflicts resolved

### **📝 Report**
- [ ] **Actions Documented**: All actions taken clearly described
- [ ] **Results Achieved**: Before/after comparison with quantifiable improvements
- [ ] **TODOs Completed**: All planned tasks marked as completed
- [ ] **Comprehensive Documentation**: All changes and artifacts documented
- [ ] **Validation Results**: All verification steps completed successfully

### **🎭 Role**
- [ ] **Actor Declared**: Agent name and role clearly stated in header and Role section
- [ ] **Scope Defined**: Clear boundaries of responsibility established
- [ ] **Guardrails Respected**: All ECRR principles followed throughout
- [ ] **Integration Maintained**: Compatibility with existing systems preserved
- [ ] **Accountability Established**: Clear ownership and responsibility declared

### **📊 Quality Assurance**
- [ ] **4-Section Structure**: Complete Examine → Clean → Report → Role format followed
- [ ] **Status Declaration**: Clear success/failure/completion status specified
- [ ] **Artifact Documentation**: All files, scripts, and changes documented
- [ ] **Reproducible Validation**: Runnable checks provided for every change
- [ ] **ECRR Compliance**: All mandatory elements included and validated

---

## 📊 **Validation Results**

### **[Validation Category 1]**
- ✅ **[Result 1]**: [Description]
- ✅ **[Result 2]**: [Description]
- ✅ **[Result 3]**: [Description]

### **[Validation Category 2]**
- ✅ **[Result 1]**: [Description]
- ✅ **[Result 2]**: [Description]
- ✅ **[Result 3]**: [Description]

---

## 🎯 **Success Criteria Met**

### **[Criteria Category 1]**
- ✅ [Success criterion 1]
- ✅ [Success criterion 2]
- ✅ [Success criterion 3]

### **[Criteria Category 2]**
- ✅ [Success criterion 1]
- ✅ [Success criterion 2]
- ✅ [Success criterion 3]

---

## 🔄 **Next Actions**

### **Immediate**
1. [Immediate action 1]
2. [Immediate action 2]
3. [Immediate action 3]

### **Short-term**
1. [Short-term action 1]
2. [Short-term action 2]
3. [Short-term action 3]

### **Long-term**
1. [Long-term action 1]
2. [Long-term action 2]
3. [Long-term action 3]

---

## 📋 **Artifacts Created**

### **Configuration Files**
- [File 1] - [Description]
- [File 2] - [Description]
- [File 3] - [Description]

### **Scripts**
- [Script 1] - [Description]
- [Script 2] - [Description]
- [Script 3] - [Description]

### **Documentation**
- [Doc 1] - [Description]
- [Doc 2] - [Description]
- [Doc 3] - [Description]

---

## 🏆 **Final ECRR Status**

### **Report Completion Status**
- **ECRR Gate Compliance**: [ ] ✅ COMPLETE / [ ] ❌ NON-COMPLIANT
- **4-Section Structure**: [ ] ✅ COMPLETE / [ ] ❌ INCOMPLETE  
- **Evidence Documentation**: [ ] ✅ COMPLETE / [ ] ❌ INCOMPLETE
- **Actor Declaration**: [ ] ✅ COMPLETE / [ ] ❌ INCOMPLETE
- **Validation Results**: [ ] ✅ ALL PASSED / [ ] ❌ FAILURES DETECTED

### **Overall Assessment**
**ECRR Report Status**: [ ] ✅ **COMPLETE AND COMPLIANT** / [ ] ❌ **NON-COMPLIANT**

**Completion Summary**: [Brief summary of completion status and achievements]

**Final Status**: ✅ **SUCCESS** - [Final status and achievements]

---

> **📋 ECRR Compliance Note**: This report has been validated against the enhanced ECRR template requirements. All mandatory elements have been included and verified for compliance with the ECRR framework standards.

**ECRR Mantra**: *Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.*

