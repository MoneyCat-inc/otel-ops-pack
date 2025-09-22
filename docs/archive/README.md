# 📦 Archive Directory

> **Purpose**: Store superseded runbooks and historical documentation

---

## 📋 **Archived Files**

### **WINDOWS_COLLECTOR_SIGNOZ_RUNBOOK.md**
- **Archived**: 2024-12-19
- **Reason**: Superseded by `docs/observability/SIGNOZ_RUNBOOK_BUNDLE.md`
- **Historical Value**: Contains specific script references and detailed troubleshooting steps
- **Key Content Preserved**: 
  - References to `schedule-canary.ps1` and `schedule-canary-simple.ps1`
  - Detailed troubleshooting procedures
  - Specific port configuration details

### **RUNBOOK_EXECUTION_SUMMARY.md**
- **Archived**: 2024-12-19
- **Reason**: Superseded by execution summary section in SigNoz Bundle
- **Historical Value**: Contains specific canary ID and execution records
- **Key Content Preserved**:
  - Canary ID: `585a44b6-055d-421a-b4b7-7b5aa9d33123`
  - Execution date: 2025-09-20
  - Specific test results and verification data

---

## 🔄 **Migration Notes**

### **What Was Consolidated**
- **Runbook Commands**: Moved to SigNoz Bundle Section 1
- **Execution Summary**: Moved to SigNoz Bundle Section 2
- **Verification Procedures**: Moved to SigNoz Bundle Section 3
- **Screenshot Guidelines**: Moved to SigNoz Bundle Section 4

### **What Was Preserved**
- **Historical Data**: Specific canary IDs and execution timestamps
- **Script References**: Links to specific PowerShell scripts
- **Detailed Troubleshooting**: Step-by-step procedures for edge cases

---

## 📚 **Current Active Documentation**

- **Primary**: [`docs/observability/SIGNOZ_RUNBOOK_BUNDLE.md`](../observability/SIGNOZ_RUNBOOK_BUNDLE.md)
- **Index**: [`docs/RUNBOOK_INDEX.md`](../RUNBOOK_INDEX.md)
- **Emergency**: [`ON_CALL_RUNBOOK.md`](../../ON_CALL_RUNBOOK.md)

---

## ⚠️ **Important Notes**

1. **Do Not Delete**: These files contain historical execution data that may be needed for audits
2. **Reference Only**: Use for historical context, not operational procedures
3. **Updates**: If new historical data is needed, add to the active SigNoz Bundle instead

---

*Archived by Observability Copilot on 2024-12-19*
