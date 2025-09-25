# ECRR Lifecycle Process Guide

> Comprehensive workflow for managing ECRR reports through review, work, and archive phases.

## Overview

The ECRR lifecycle system provides structured workflow management for all ECRR reports, ensuring proper triage, assignment, tracking, and archival of work items.

## Lifecycle Phases

### 1. Review Phase
Reports start in the review phase where they are:
- **Triaged**: Assessed for priority and assignment
- **Categorized**: Classified by status (Open, Reviewed, Not Working, Resolved)
- **Assigned**: Given to appropriate team members
- **Prioritized**: Ranked by urgency and impact

### 2. Work Phase
Active reports move to the work phase where they:
- **Track Progress**: Monitor status and completion
- **Document Changes**: Record all modifications and decisions
- **Maintain Ledger**: Update working ledger with progress notes
- **Follow ECRR**: Apply Examine → Clean → Report → Role methodology

### 3. Archive Phase
Completed reports move to archive where they:
- **Document Resolution**: Record final outcomes and lessons learned
- **Maintain History**: Preserve all evidence and artifacts
- **Update Index**: Refresh status badges and categorization
- **Close Loop**: Ensure all follow-ups are addressed

## Workflow Commands

### Review Actions
```powershell
# Review a specific report
pwsh -File scripts/ecrr-manage.ps1 -Action Review -Report "report-name.md"

# Review all outstanding reports
pwsh -File scripts/ecrr-manage.ps1 -Action Review -All

# Assign report to team member
pwsh -File scripts/ecrr-manage.ps1 -Action Review -Report "report-name.md" -Assign "team-member" -Priority "high"
```

### Work Actions
```powershell
# Start working on a report
pwsh -File scripts/ecrr-manage.ps1 -Action Start -Report "report-name.md"

# Update work progress
pwsh -File scripts/ecrr-manage.ps1 -Action Update -Report "report-name.md" -Notes "Progress update"

# Add work session footer
pwsh -File scripts/ecrr-manage.ps1 -Action Footer -Report "report-name.md" -Session "session-id"
```

### Resolution Actions
```powershell
# Mark report as resolved
pwsh -File scripts/ecrr-manage.ps1 -Action Resolve -Report "report-name.md" -Resolution "completed"

# Archive completed report
pwsh -File scripts/ecrr-manage.ps1 -Action Archive -Report "report-name.md"
```

### Maintenance Actions
```powershell
# Regenerate index with current status
pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateIndex

# Update working ledger
pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateLedger

# Full system refresh
pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateAll
```

## Directory Structure

```
docs/ECRR_REPORTS/
├── INDEX.md              # Main index with status badges
├── PROCESS.md            # This workflow guide
├── ledger.json           # Machine-readable ledger data
├── working/
│   └── LEDGER.md         # Human-readable working ledger
├── reviewed/             # Reports under review
├── working/              # Active work reports
├── archive/              # Completed reports
└── *.md                  # Individual ECRR reports
```

## Status Badges

The system uses four status badges:
- **Open**: ![Open](../assets/badges/open.svg) - New or unprocessed reports
- **Reviewed**: ![Reviewed](../assets/badges/reviewed.svg) - Reports under review
- **Not Working**: ![Not Working](../assets/badges/not-working.svg) - Reports with issues
- **Resolved**: ![Resolved](../assets/badges/resolved.svg) - Completed reports

## ECRR Methodology Integration

All work follows the ECRR framework:
1. **Examine** - Capture environment state before changes
2. **Clean** - Remove drift and enforce guardrails  
3. **Report** - Generate artifacts and evidence
4. **Role** - Declare the actor responsible

## Best Practices

### Report Creation
- Use consistent naming: `YYYY-MM-DD-descriptive-name.md`
- Include ECRR sections: Examine, Clean, Report, Role
- Add status metadata in frontmatter when possible
- Document all evidence and artifacts

### Work Tracking
- Update ledger regularly with progress notes
- Use clear, actionable language in status updates
- Maintain chronological history of changes
- Include relevant file paths and command outputs

### Resolution
- Document complete resolution steps
- Record lessons learned and improvements
- Update all related documentation
- Ensure proper archival and indexing

## Automation Features

The ECRR lifecycle system provides:
- **Automatic Status Detection**: Classifies reports by filename patterns
- **Badge Management**: Updates status badges automatically
- **Ledger Synchronization**: Keeps human and machine-readable ledgers in sync
- **Index Generation**: Maintains current status overview
- **Workflow Enforcement**: Ensures proper ECRR methodology application

## Troubleshooting

### Common Issues
- **Reports not appearing**: Check filename patterns and directory placement
- **Badges not updating**: Run `RegenerateIndex` action
- **Ledger out of sync**: Run `RegenerateLedger` action
- **Missing status**: Verify report metadata and classification keywords

### Recovery Procedures
- **Corrupted ledger**: Delete `ledger.json` and run `RegenerateLedger`
- **Index issues**: Run `RegenerateIndex` to rebuild from scratch
- **Missing directories**: Recreate structure and run `RegenerateAll`

---

*ECRR Lifecycle Process Guide v1.0*  
*Last updated: $(Get-Date -Format 'yyyy-MM-dd')*