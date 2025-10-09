# ECRR Reports - Consolidated Repository

**Last Updated:** 2025-10-09  
**Total Reports:** 391  
**Location:** `CHAR/ECRR/ECRR_REPORTS/`

## Overview

This directory contains all ECRR (Examine → Clean → Report → Role) reports for the Resonai [OTel] observability stack. Reports have been consolidated from multiple locations into this central repository for improved organization and compliance tracking.

## ECRR Framework

ECRR is BossCat OEM's governance methodology for all operational changes, deployments, and maintenance activities.

**The Four Phases:**
1. **Examine** - Capture environment state before changes
2. **Clean** - Remove drift and enforce guardrails
3. **Report** - Document all actions taken
4. **Role** - Declare the agent/actor responsible

## Directory Structure

```
CHAR/ECRR/ECRR_REPORTS/
├── README.md (this file)
├── ECRR_*.md (individual reports)
├── archive/ (archived historical reports)
├── parallel-agent-framework-validation-*/
└── ecrr-processing-analysis-*/
```

## Source Consolidation

Reports were consolidated from:
- `CHAR/EVID/ECRR_REPORTS/` → Moved 3 reports
- `CHAR/DOCS/docs/ECRR_REPORTS/` → Moved 387 reports
- `CHAR/ECRR/ECRR_REPORTS/` → Pre-existing 2 reports

**Total:** 391 reports (some subdirectories contain multiple files)

## Compliance

All reports should follow the 4-section structure:
- Examine → Clean → Report → Role
- Include ECRR Gate validation section
- Maintain 12/12 compliance score
- Attach evidence (screenshots, logs, configs, test outputs)

## Latest Reports

Recent reports can be found by searching for files with recent timestamps:
```powershell
Get-ChildItem -Path CHAR\ECRR\ECRR_REPORTS -File -Recurse | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 10
```

## Processing

ECRR reports can be processed for compliance metrics using:
```powershell
pwsh -File BRAV\SCPT\process-all-ecrr-reports.ps1
```

## Templates

ECRR report templates are available at:
- `.agent/ECRR_REPORT_TEMPLATE.md` - Generic template
- `CHAR/DOCS/docs/agents/*/ECRR_REPORT_TEMPLATE.md` - Agent-specific templates

## Related Documentation

- `ART_OF_ECRR.md` - Core ECRR methodology
- `BRAV/SCPT/lint-ecrr-compliance.ps1` - Compliance checker
- `BRAV/SCPT/process-all-ecrr-reports.ps1` - Metrics processor

---

**BossCat OEM**  
*Executive Overseer Manager*  
MoneyCat Inc · Resonai [OTel]

