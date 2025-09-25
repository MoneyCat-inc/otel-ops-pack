# ECRR Task Management System

This directory contains the automated task generation and lifecycle management system for the OTel observability workspace. The scripts analyse ECRR reports, create actionable tasks, and keep their status organised under `jobs/`.

## Directory Structure

```
jobs/
  pending/       # Newly generated tasks
  in-progress/   # Tasks actively being worked
  completed/     # Finished tasks retained for history
  templates/     # Task templates and documentation helpers
  README.md      # This guide
```

## Task Lifecycle

1. **Generate**: Tasks are created from ECRR reports with `scripts/ecrr-task-automation.ps1`
2. **Review**: Inspect new entries under `jobs/pending` and adjust priority/assignee
3. **Execute**: Move tasks to `in-progress` when work starts and capture evidence
4. **Complete**: When acceptance criteria are met, move the task to `completed`

## Categories, Priority, Effort

- **Categories**: observability, infrastructure, automation, monitoring, development, maintenance
- **Priority**: low, medium, high, critical (derived from report language)
- **Estimated Effort**: XS, S, M, L, XL (rough hour buckets)

## Generate Tasks

```powershell
# Dry run to preview up to 3 tasks (currently shows parser blocker info)
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 3 -DryRun

# Generate and auto-assign owners based on category (stub mode)
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 5 -AutoAssign

# Force regeneration even if older tasks exist for those reports (stub mode)
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 2 -Force
```

Simple wrapper (backwards compatibility):

```powershell
pwsh -File scripts/simple-task-generator.ps1 -MaxTasks 3
```

**Note**: The task generator is currently in stub mode due to PowerShell parser issues with template building. See the detailed blocker documentation in the script output for workaround options.

## Manage Tasks

```powershell
# List every task with metadata
pwsh -File scripts/manage-tasks.ps1 -Action List

# List only high priority observability work
pwsh -File scripts/manage-tasks.ps1 -Action List -Priority high -Category observability

# Update assignment and move through statuses
pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId TASK-20250923-123456-001 -Assignee observability-engineer
pwsh -File scripts/manage-tasks.ps1 -Action Start -TaskId TASK-20250923-123456-001
pwsh -File scripts/manage-tasks.ps1 -Action Complete -TaskId TASK-20250923-123456-001

# Status and summary views
pwsh -File scripts/manage-tasks.ps1 -Action Status
pwsh -File scripts/manage-tasks.ps1 -Action Summary
```

Simple wrapper:

```powershell
pwsh -File scripts/simple-task-manager.ps1 -Action Status
```

## Automation Features

- **Duplicate detection**: Existing tasks referencing the same ECRR report are skipped (unless `-Force` is used) - *planned*
- **Command extraction**: Inline commands from reports appear in the generated task under *Verification Commands* - *planned*
- **Next actions**: Bullet lists, TODOs, and "Next Steps" blocks become numbered actions in the task - *planned*
- **Success metrics**: Category-specific metrics prompt consistent verification and documentation - *planned*
- **Summary report**: Each generation run produces `jobs/automation-report-YYYYMMDD-HHMMSS.md` listing the new tasks - *planned*

**Current Status**: Task generation is in stub mode with comprehensive diagnostic output. The framework validates paths, reads ECRR reports, and provides detailed documentation of the PowerShell parser blocker that prevents full implementation. The task management CLI is fully functional for managing existing tasks.

## Best Practices

- Run the generator after filing or updating ECRR reports.
- Review new tasks before assigning to ensure priority matches current reality.
- Keep `jobs/pending` small; archive completed work promptly.
- Record verification evidence back in the originating ECRR report and relevant dashboards.

## Related Scripts

- `scripts/verify-wiring.ps1` – end-to-end wiring check for the OTLP/SigNoz path
- `scripts/monitor-analytics-ingestion.ps1` – live ingestion monitor for analytics events
- `scripts/ci-verify.ps1` – CI smoke test bundle when tasks touch code or pipelines
- `scripts/manage-tasks.ps1` – comprehensive task management CLI
- `scripts/simple-task-manager.ps1` – lightweight wrapper for common operations
- `scripts/simple-task-generator.ps1` – lightweight wrapper for task generation

---

*ECRR Task Management System — automate the workload, keep the paper trail.*
