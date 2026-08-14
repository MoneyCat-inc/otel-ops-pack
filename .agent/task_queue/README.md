# Agent Task Queue

This directory contains the task queue for the **Codex — Maintenance & Remediation Agent**.

## Directory Structure

- `pending/` - New alerts and tasks waiting for processing
- `processing/` - Tasks currently being worked on by Codex
- `completed/` - Successfully completed tasks
- `failed/` - Tasks that failed processing (for manual review)

## Task File Format

Each task file is a JSON document with the following structure:

```json
{
  "id": "unique-task-id",
  "type": "alert|maintenance|remediation",
  "priority": "critical|high|medium|low",
  "created_at": "2025-09-18T23:30:00Z",
  "source": "canary|signoz|gpu|kafka|manual",
  "title": "Brief description of the issue",
  "description": "Detailed description of the problem",
  "metrics": {
    "error_rate": 0.15,
    "latency_p95": 500,
    "memory_usage": 0.8,
    "gpu_temp": 85
  },
  "recipe": "otlp_exporter_failure|high_latency|cardinality_spike|gpu_thermal",
  "status": "pending|processing|completed|failed",
  "assigned_to": "codex",
  "validation_commands": [
    "otelcol --dry-run",
    "curl -s http://localhost:13134/",
    "powershell -File operator-pipeline-check.ps1"
  ],
  "expected_output": "Collector healthy, canary test passes",
  "rollback_commands": [
    "copy config.backup.yaml config.yaml",
    "sc restart otelcol-contrib"
  ]
}
```

## Processing Workflow

1. **Alert Detection**: Monitoring scripts generate task files in `pending/`
2. **Codex Processing**: Agent picks up tasks, moves to `processing/`
3. **Validation**: Runs validation commands, applies fixes
4. **Completion**: Moves to `completed/` or `failed/` with results

## Alert Sources

- **Canary Monitoring**: `canary-monitor.ps1` generates tasks
- **SigNoz Alerts**: Webhook integration (future)
- **GPU Monitoring**: `gpu-monitor.ps1` generates tasks
- **Manual**: Human-created tasks for maintenance


