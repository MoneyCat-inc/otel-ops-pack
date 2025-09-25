# ECRR Task Generation Framework - Usage Guide

**Version**: 1.0  
**Last Updated**: 2025-09-23  
**Status**: Production Ready  

## 🎯 Overview

The ECRR Task Generation Framework automatically converts ECRR (Examine → Clean → Report → Role) reports into actionable, structured tasks. This system eliminates manual task creation and ensures consistent task formatting across the observability pipeline.

## 🚀 Quick Start

### Basic Usage

```powershell
# Preview tasks without creating them (recommended first step)
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 3 -DryRun

# Generate actual tasks with auto-assignment
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 5 -AutoAssign

# View generated tasks
pwsh -File scripts/manage-tasks.ps1 -Action Status
pwsh -File scripts/manage-tasks.ps1 -Action List
```

### Advanced Usage

```powershell
# Force regeneration (skip duplicate detection)
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 2 -Force

# Custom paths
pwsh -File scripts/ecrr-task-automation.ps1 -EcrrReportPath "custom/reports" -JobsPath "custom/jobs"

# Large batch processing
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 20 -AutoAssign
```

## 📋 Parameters Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-EcrrReportPath` | String | `docs/ECRR_REPORTS` | Path to ECRR reports directory |
| `-JobsPath` | String | `jobs` | Path to jobs directory |
| `-MaxTasks` | Integer | `5` | Maximum number of tasks to generate |
| `-DryRun` | Switch | `False` | Preview mode (no tasks created) |
| `-Force` | Switch | `False` | Skip duplicate detection |
| `-AutoAssign` | Switch | `False` | Auto-assign tasks based on category |

## 🔄 Task Lifecycle

### 1. Generation Phase
- **Input**: ECRR reports from `docs/ECRR_REPORTS/`
- **Processing**: Framework analyzes reports and extracts actionable items
- **Output**: Structured task files in `jobs/pending/`

### 2. Management Phase
- **Assignment**: Tasks assigned to appropriate team members
- **Status Tracking**: Move tasks through `pending` → `in-progress` → `completed`
- **Verification**: Execute verification commands and document results

### 3. Integration Phase
- **SigNoz Queries**: Observability tasks include SigNoz verification queries
- **Documentation**: Results feed back into ECRR reports
- **Automation**: Continuous monitoring and alerting

## 🎨 Task Categories & Assignments

### Observability Tasks
- **Category**: `observability`
- **Auto-Assignment**: `observability-engineer`
- **SigNoz Queries**: Canary tests, analytics ingestion, log patterns
- **Verification**: `pwsh -File scripts/verify-wiring.ps1`

### Monitoring Tasks
- **Category**: `monitoring`
- **Auto-Assignment**: `system-admin`
- **SigNoz Queries**: Health checks, collector metrics, system performance
- **Verification**: `pwsh -File scripts/monitor-analytics-ingestion.ps1`

### Infrastructure Tasks
- **Category**: `infrastructure`
- **Auto-Assignment**: `system-admin`
- **SigNoz Queries**: Startup/shutdown metrics, process monitoring
- **Verification**: `sc query otelcol-contrib`

## 📊 Task Management Commands

### Status Overview
```powershell
# Quick status summary
pwsh -File scripts/manage-tasks.ps1 -Action Status

# Detailed task listing
pwsh -File scripts/manage-tasks.ps1 -Action List

# Summary dashboard
pwsh -File scripts/manage-tasks.ps1 -Action Summary
```

### Task Operations
```powershell
# Assign task
pwsh -File scripts/manage-tasks.ps1 -Action Assign -TaskId TASK-20250923-123456-001 -Assignee observability-engineer

# Start task (move to in-progress)
pwsh -File scripts/manage-tasks.ps1 -Action Start -TaskId TASK-20250923-123456-001

# Complete task
pwsh -File scripts/manage-tasks.ps1 -Action Complete -TaskId TASK-20250923-123456-001
```

### Filtering & Search
```powershell
# Filter by category
pwsh -File scripts/manage-tasks.ps1 -Action List -Category observability

# Filter by priority
pwsh -File scripts/manage-tasks.ps1 -Action List -Priority high

# Filter by assignee
pwsh -File scripts/manage-tasks.ps1 -Action List -Assignee observability-engineer
```

## 🔍 SigNoz Integration

### Observability Tasks
Each observability task includes SigNoz queries for verification:

```sql
-- Logs Query
message contains "canary test"
attributes.dataset = "resonai_analytics"
severity >= "ERROR"

-- Metrics Query
otelcol_*
otelcol_receiver_accepted_log_records
otelcol_exporter_sent_log_records
```

### Monitoring Tasks
Monitoring tasks include health check queries:

```sql
-- Health Metrics
otelcol_health_check_duration_seconds
otelcol_receiver_refused_log_records
otelcol_exporter_send_failed_log_records
```

### Infrastructure Tasks
Infrastructure tasks include system metrics:

```sql
-- System Metrics
process_cpu_seconds_total
process_resident_memory_bytes
windows_logical_disk_free_bytes
```

## 📁 File Structure

```
jobs/
├── pending/           # Newly generated tasks
├── in-progress/       # Tasks being worked on
├── completed/         # Finished tasks (retained for history)
├── templates/         # Task templates
└── README.md          # Task management guide

artifacts/
└── ecrr-generation-summary-YYYYMMDD-HHMMSS.md  # Generation reports
```

## 🛠️ Troubleshooting

### Common Issues

**1. No ECRR Reports Found**
```powershell
# Check ECRR reports directory
Get-ChildItem -Path "docs/ECRR_REPORTS" -File -Filter "*.md" | Measure-Object
```

**2. Tasks Not Generated**
```powershell
# Run with verbose logging
pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 1 -DryRun -Verbose
```

**3. Task Management CLI Errors**
```powershell
# Check task file format
Get-Content "jobs/pending/TASK-*.md" | Select-Object -First 10
```

### Debugging Commands

```powershell
# Validate ECRR report structure
Get-Content "docs/ECRR_REPORTS/2025-09-23-*.md" | Select-String "## Examine|## Clean|## Report|## Role"

# Check task file integrity
Get-ChildItem -Path "jobs/pending" -File | ForEach-Object { 
    Write-Host "=== $($_.Name) ==="
    Get-Content $_.FullName | Select-Object -First 5
}

# Verify SigNoz connectivity
Test-NetConnection -ComputerName localhost -Port 8080
Test-NetConnection -ComputerName localhost -Port 5318
```

## 📈 Best Practices

### 1. Regular Generation
- Run task generation **daily** or after major ECRR reports
- Use `-DryRun` first to preview changes
- Start with small batches (`-MaxTasks 3-5`)

### 2. Task Assignment
- Assign tasks immediately after generation
- Use auto-assignment (`-AutoAssign`) for standard categories
- Review unassigned tasks weekly

### 3. Verification
- Execute verification commands before marking tasks complete
- Document results in ECRR reports
- Update SigNoz dashboards with new insights

### 4. Maintenance
- Archive completed tasks monthly
- Review and update task templates quarterly
- Monitor framework performance and error rates

## 🔧 Advanced Configuration

### Custom Task Templates
Edit `jobs/templates/task-template.md` to customize task format:

```markdown
# Task: {title}

**Task ID**: {task_id}
**Created**: {created_date}
**Priority**: {priority}
**Category**: {category}
**Estimated Effort**: {effort}
**Status**: {status}
**Assigned To**: {assignee}

## Task Description
Generated from ECRR report: {source_report}

## Acceptance Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}
- [ ] {criterion_3}

## SigNoz Verification Queries
{sigNoz_queries}

## Verification Commands
{verification_commands}
```

### Integration with CI/CD
Add to your CI pipeline:

```yaml
- name: Generate ECRR Tasks
  run: |
    pwsh -File scripts/ecrr-task-automation.ps1 -MaxTasks 10 -AutoAssign
    
- name: Verify Task Generation
  run: |
    pwsh -File scripts/manage-tasks.ps1 -Action Status
```

## 📞 Support

### Getting Help
- **Documentation**: This guide and `jobs/README.md`
- **Scripts**: All scripts include comprehensive help (`-Help` parameter)
- **Logs**: Check `artifacts/` directory for generation summaries

### Reporting Issues
1. Run with `-Verbose` flag to capture detailed logs
2. Include the generation summary from `artifacts/`
3. Provide sample ECRR report that caused issues
4. Check SigNoz connectivity and collector status

---

**ECRR Task Generation Framework** - *Automate the workload, keep the paper trail.*
