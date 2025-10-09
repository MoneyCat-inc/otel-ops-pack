# ECRR Framework - Evidence-Based Development

**Examine → Clean → Report → Role**

Apply ECRR to every operational change in this repository so the Windows → OTel → SigNoz path stays predictable and accountable.

## Framework Overview

The ECRR framework ensures all changes are evidence-based, properly documented, and attributed to responsible agents. Based on analysis of 56 ECRR reports in this repository, the framework has achieved:

- **96% Actor Declaration Compliance**: Clear responsibility attribution
- **96% Evidence Reference Compliance**: Proper artifact documentation  
- **55% Complete Structure Compliance**: Standard 4-section format
- **43% ECRR Gate Compliance**: Formal validation sections

## Why ECRR Matters

### **Signal Flow Integrity**
- Windows Event Log, file logs, and optional browser logs must land in SigNoz via the Windows collector
- OTLP gRPC/HTTP ports 5317/5318 and SigNoz 14317/14318/8080 must stay reachable
- Canary events should appear in SigNoz within 30 seconds
- Docker Desktop, WSL2, the collector service, and SigNoz compose must stay healthy

### **Accountability & Traceability**
- Every change documented with evidence and verification steps
- Clear agent responsibility and role attribution
- Reproducible validation and testing procedures
- Versioned artifacts for audit trails

## ECRR Process Loop

### **1. Examine** 
Capture environment state and identify issues:
```powershell
pwsh -File scripts/ecrr-doctor.ps1
```
- Review warnings and system status
- Document current state and key findings
- Capture evidence (screenshots, logs, configs)

### **2. Clean**
Remove drift and enforce guardrails:
- Restart services, clear noisy logs, resolve port conflicts
- Enforce local-first, safety, idempotence, verification principles
- Clean git branches, temporary files, and process conflicts

### **3. Report**
Document all changes using the standard template:
- Use `docs/ECRR_REPORT_TEMPLATE.md` 
- Store reports under `docs/ECRR_REPORTS/`
- Include ECRR Gate validation section
- Attach all evidence and artifacts

### **4. Role**
Declare responsible agent and scope:
- **Cursor Agent**: Implementation and feature development
- **Cursor-Local**: Local environment and developer ergonomics  
- **ChatGPT Agent**: Orchestration and planning
- **Codex Agent**: CI/CD and coordination
- **BossCat**: Background maintenance and automation
- **QA Scribe**: Validation and documentation

## Integration Points

### **Canary Testing**
```powershell
pwsh -File scripts/canary-test.ps1
```
- Verify in SigNoz Logs with filter: `message contains "SigNoz test"`
- Should appear within 30 seconds of execution

### **Collector Configuration**
- `config.yaml` must keep filelog and windows_eventlog receivers enabled
- Export to `http://localhost:14317` for SigNoz ingestion
- Maintain OTLP endpoint accessibility

### **Stack Health Verification**
```powershell
pwsh -File scripts/verify-integration.ps1
```
- Doubles as the clean step when system drift occurs
- Validates end-to-end pipeline functionality

### **Agent Workflows**
- Always respect `.agent/LOCK` for coordination
- Update `.agent/status.json` when running background jobs
- Maintain agent responsibility boundaries

## ECRR Quality Standards

### **Required Elements**
- ✅ **Actor Declaration**: Clear agent responsibility
- ✅ **Evidence Attachment**: Screenshots, logs, configs, test outputs
- ✅ **ECRR Gate**: Formal validation section
- ✅ **Status Declaration**: Success/failure/completion status

### **Structural Compliance**
- ✅ **4-Section Format**: Examine → Clean → Report → Role
- ✅ **Guardrail Enforcement**: Local-first, safety, idempotence, verification
- ✅ **Artifact Documentation**: All files and changes documented
- ✅ **Reproducible Validation**: Runnable checks for every change

## Repository ECRR Status

**Total Reports**: 56 ECRR reports processed  
**Compliance Rate**: 96% actor declaration, 96% evidence reference  
**Latest Activity**: September 2025 (47 reports)  
**Framework Maturity**: Production-ready with continuous improvement

---

**ECRR Mantra**: *Examine → Clean → Report → Role - Every change must begin with evidence, remove drift, leave an artifact, and declare its actor.*

**No Report, No Merge**: Keep ECRR artifacts versioned, evidence captured, and verifications reproducible.
