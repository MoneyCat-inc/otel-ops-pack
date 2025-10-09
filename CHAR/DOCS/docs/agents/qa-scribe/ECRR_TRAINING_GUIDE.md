# ECRR Agent Training Guide - Compliance Standards

**Date**: 2025-01-27  
**Purpose**: Standardize ECRR compliance across all agents  
**Audience**: All agents (Cursor Agent, Cursor-Local, ChatGPT Agent, Codex Agent, BossCat, QA Scribe)

## 🎯 **ECRR Framework Overview**

The ECRR (Examine → Clean → Report → Role) framework ensures all changes are evidence-based, properly documented, and attributed to responsible agents. **Every agent must follow this framework for all operational changes.**

### **ECRR Mantra**
> *Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.*

## 📋 **Mandatory ECRR Requirements**

### **1. Actor Declaration - MANDATORY**
**Requirement**: Every ECRR report MUST clearly declare the responsible agent and role.

**Format**:
```markdown
**Agent**: [Agent Name - Cursor Agent/Cursor-Local/ChatGPT Agent/Codex Agent/BossCat/QA Scribe]  
**Role**: [Role - Observability Copilot/OTel Steward/Agent Coordinator/Local Worker/etc.]
```

**Examples**:
- `**Agent**: Cursor Agent - Observability Copilot`
- `**Agent**: Cursor-Local - Local Environment Steward`
- `**Agent**: ChatGPT Agent - Orchestration Coordinator`

### **2. ECRR Gate - MANDATORY**
**Requirement**: Every ECRR report MUST include the ECRR Gate section with all checkboxes completed.

**Template**:
```markdown
## ✅ **ECRR Gate - MANDATORY VALIDATION**

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
```

### **3. 4-Section Structure - MANDATORY**
**Requirement**: Every ECRR report MUST follow the complete 4-section format.

**Structure**:
1. **🔍 1. Examine** - Capture environment state and identify issues
2. **🧹 2. Clean** - Remove drift and enforce guardrails
3. **📝 3. Report** - Document all changes and results
4. **🎭 4. Role** - Declare responsible agent and scope

### **4. Evidence Attachment - MANDATORY**
**Requirement**: Every ECRR report MUST include evidence and artifacts.

**Required Evidence**:
- Screenshots of UI changes or system states
- Console logs and command outputs
- Configuration files examined or modified
- Test outputs and validation results
- Artifact files created or updated

### **5. Status Declaration - MANDATORY**
**Requirement**: Every ECRR report MUST include clear completion status.

**Format**:
```markdown
**Status**: ✅ **SUCCESS** - [Brief description of achievements]
```
or
```markdown
**Status**: ❌ **FAILED** - [Brief description of issues and next steps]
```

## 🎭 **Agent-Specific Responsibilities**

### **Cursor Agent - Observability Copilot**
**Primary Role**: Implementation and feature development
**ECRR Focus**: Technical implementation, system integration, monitoring setup
**Typical Tasks**: 
- Implement monitoring scripts and dashboards
- Configure OTel collectors and SigNoz integration
- Set up alerting and automation
- Troubleshoot observability pipeline issues

**ECRR Requirements**:
- Always include technical implementation details in Examine section
- Document all configuration changes and service restarts in Clean section
- Provide verification commands and expected outputs in Report section
- Declare technical scope and integration points in Role section

### **Cursor-Local - Local Environment Steward**
**Primary Role**: Local environment and developer ergonomics
**ECRR Focus**: Local setup, developer workflows, environment parity
**Typical Tasks**:
- Set up local development environments
- Configure developer tools and workflows
- Maintain environment consistency
- Troubleshoot local setup issues

**ECRR Requirements**:
- Document environment state and configuration in Examine section
- Clean up local artifacts and temporary files in Clean section
- Provide setup scripts and verification steps in Report section
- Declare local environment scope in Role section

### **ChatGPT Agent - Orchestration Coordinator**
**Primary Role**: Orchestration and planning
**ECRR Focus**: Project coordination, task planning, workflow management
**Typical Tasks**:
- Plan and coordinate multi-agent workflows
- Define task requirements and success criteria
- Manage project timelines and dependencies
- Coordinate between different agents

**ECRR Requirements**:
- Document project state and requirements in Examine section
- Clean up task conflicts and dependencies in Clean section
- Provide coordination plans and timelines in Report section
- Declare coordination scope and responsibilities in Role section

### **Codex Agent - CI/CD Coordinator**
**Primary Role**: CI/CD and coordination
**ECRR Focus**: Build pipelines, deployment automation, integration testing
**Typical Tasks**:
- Set up and maintain CI/CD pipelines
- Automate deployment processes
- Coordinate integration testing
- Manage build and deployment artifacts

**ECRR Requirements**:
- Document CI/CD state and pipeline configuration in Examine section
- Clean up build artifacts and failed deployments in Clean section
- Provide pipeline configurations and deployment scripts in Report section
- Declare CI/CD scope and automation responsibilities in Role section

### **BossCat - Background Maintenance**
**Primary Role**: Background maintenance and automation
**ECRR Focus**: Automated cleanup, system maintenance, background tasks
**Typical Tasks**:
- Run automated cleanup tasks
- Perform system maintenance
- Monitor background processes
- Execute scheduled maintenance

**ECRR Requirements**:
- Document system state and maintenance needs in Examine section
- Perform automated cleanup and maintenance in Clean section
- Provide maintenance logs and automation scripts in Report section
- Declare maintenance scope and automation responsibilities in Role section

### **QA Scribe - Validation and Documentation**
**Primary Role**: Validation and documentation
**ECRR Focus**: Testing, validation, documentation, quality assurance
**Typical Tasks**:
- Validate system functionality
- Test new features and changes
- Document processes and procedures
- Ensure quality standards compliance

**ECRR Requirements**:
- Document testing state and validation requirements in Examine section
- Clean up test artifacts and failed validations in Clean section
- Provide test results and validation reports in Report section
- Declare testing scope and quality responsibilities in Role section

## 🔧 **ECRR Compliance Tools**

### **Template Usage**
Always use the enhanced ECRR template: `docs/ECRR_REPORT_TEMPLATE.md`

### **Compliance Monitoring**
Run compliance monitoring to check report quality:
```powershell
pwsh -File scripts/ecrr-compliance-monitor.ps1
```

### **Compliance Validation**
Use the ECRR doctor to validate environment state:
```powershell
pwsh -File scripts/ecrr-doctor.ps1
```

## 📊 **Quality Standards**

### **Compliance Thresholds**
- **ECRR Gate Compliance**: ≥80% (Critical)
- **4-Section Structure**: ≥90% (High)
- **Actor Declaration**: ≥95% (Critical)
- **Evidence Attachment**: ≥85% (High)
- **Status Declaration**: ≥75% (Medium)
- **Overall Compliance**: ≥70% (Target)

### **Quality Metrics**
The compliance monitoring script tracks:
- Total number of ECRR reports
- Compliance percentage for each requirement
- Overall compliance score
- Recommendations for improvement
- Quality trends over time

## 🚨 **Common Compliance Issues**

### **Issue 1: Missing ECRR Gate**
**Problem**: Report lacks the mandatory ECRR Gate section
**Solution**: Always include the complete ECRR Gate with all checkboxes
**Impact**: Report marked as non-compliant

### **Issue 2: Incomplete 4-Section Structure**
**Problem**: Missing one or more required sections (Examine, Clean, Report, Role)
**Solution**: Use the enhanced template to ensure all sections are included
**Impact**: Reduced compliance score

### **Issue 3: Unclear Actor Declaration**
**Problem**: Agent and role not clearly stated in header or Role section
**Solution**: Always include both agent name and specific role
**Impact**: Accountability issues

### **Issue 4: Insufficient Evidence**
**Problem**: Missing screenshots, logs, configs, or test outputs
**Solution**: Include comprehensive evidence for all changes
**Impact**: Reduced traceability

### **Issue 5: Missing Status Declaration**
**Problem**: No clear success/failure/completion status
**Solution**: Always include final status with brief description
**Impact**: Unclear completion state

## ✅ **ECRR Compliance Checklist**

Before submitting any ECRR report, verify:

- [ ] **Actor Declaration**: Agent and role clearly stated in header and Role section
- [ ] **ECRR Gate**: Complete ECRR Gate section with all checkboxes
- [ ] **4-Section Structure**: All four sections (Examine, Clean, Report, Role) included
- [ ] **Evidence Attachment**: Screenshots, logs, configs, test outputs included
- [ ] **Status Declaration**: Clear success/failure/completion status specified
- [ ] **Guardrail Compliance**: Local-first, safety, idempotence, verification principles followed
- [ ] **Artifact Documentation**: All files, scripts, and changes documented
- [ ] **Reproducible Validation**: Runnable checks provided for every change

## 🔄 **Continuous Improvement**

### **Regular Compliance Monitoring**
- Run compliance monitoring weekly: `pwsh -File scripts/ecrr-compliance-monitor.ps1`
- Review compliance trends and address issues
- Update templates and standards based on findings

### **Agent Training Updates**
- Review this guide monthly
- Update based on new compliance requirements
- Share best practices and lessons learned

### **Template Enhancements**
- Continuously improve the ECRR template
- Add new compliance requirements as needed
- Ensure template remains comprehensive and user-friendly

## 📞 **Support and Resources**

### **ECRR Framework Documentation**
- `docs/ECRR.md` - Complete framework overview
- `docs/ECRR_REPORT_TEMPLATE.md` - Enhanced template
- `docs/ECRR_REPORTS/` - Example reports and best practices

### **Compliance Tools**
- `scripts/ecrr-compliance-monitor.ps1` - Compliance monitoring
- `scripts/ecrr-doctor.ps1` - Environment validation
- `artifacts/ecrr-compliance-report.json` - Latest compliance metrics

### **Getting Help**
- Review existing ECRR reports for examples
- Use the enhanced template as a starting point
- Run compliance monitoring to identify issues
- Consult the ECRR framework documentation

---

**ECRR Mantra**: *Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.*

**Remember**: ECRR compliance is mandatory for all agents. Non-compliant reports will be flagged and must be corrected before acceptance.

**Training Status**: ✅ **COMPLETE** - All agents trained on ECRR compliance standards and requirements.
