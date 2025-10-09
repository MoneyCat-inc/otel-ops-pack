# scripts/agent/ - codex-local Local Workflow Custodian

This directory contains the core scripts and utilities for the codex-local Local Workflow Custodian agent, which maintains the local development environment and enforces workflow standards.

## Core Scripts

### setup-local.ps1
Bootstrap the local development environment and initialize agent configuration.

**Usage**: `pnpm setup-local`

**Features**:
- Initialize `.agent/` directory structure
- Create default configuration files
- Verify runtime dependencies (Node.js, PNPM)
- Check PowerShell execution policy
- Update agent status

### doctor.ps1
Comprehensive health diagnostic sweep of the local development setup.

**Usage**: `pnpm agent:doctor [-Detailed] [-Fix]`

**Features**:
- Runtime version validation
- Agent state file integrity checks
- Security policy compliance scanning
- Accessibility audit execution
- Development environment health verification
- Guardrail compliance checking

### watchdog.ps1
Background maintenance daemon that processes micro-tasks and enforces guardrails.

**Usage**: `pnpm agent:start [-Detached] [-MaxCycles <n>] [-CycleIntervalSeconds <n>]`

**Features**:
- Cyclical processing with configurable intervals
- Micro-task queue processing (max 2 tasks per cycle)
- Lock file compliance checking
- Continuous guardrail enforcement
- Status monitoring and reporting
- Graceful error handling

## Utility Scripts

### health-gate.ps1
Integrated health validation for agent startup integration.

**Features**:
- Local environment doctor check
- OTel wiring verification
- Status updates
- Job queue management

### update-status.ps1
Shared status updater for agent health tracking.

**Usage**: `pwsh -File scripts/agent/update-status.ps1 -section <env|otel|analytics> -ok <true|false> -detail "message"`

**Features**:
- Updates `.agent/status.json` with section-specific health information
- Maintains timestamp tracking
- Provides status summary display

### runner.ps1
Task runner for executing specific micro-task types.

**Usage**: `pwsh -File scripts/agent/runner.ps1 -TaskType <type> [-TaskData <hashtable>]`

**Supported Task Types**:
- `flaky-test-quarantine` - Identify and quarantine flaky tests
- `ssot-refresh` - Update Single Source of Truth files
- `selector-hygiene` - Add test IDs and ARIA labels
- `cleanup-artifacts` - Remove old log and temporary files

### enforce-guardrails.ps1
Comprehensive guardrail enforcement for security, accessibility, and code quality.

**Usage**: `pwsh -File scripts/agent/enforce-guardrails.ps1 [-Fix] [-ReportOnly] [-FilePatterns <patterns>]`

**Guardrails Enforced**:
- No inline styles (`style="..."` attributes)
- No `dangerouslySetInnerHTML` usage
- CSP compliance (no inline scripts/event handlers)
- ARIA accessibility compliance
- Security vulnerability detection

## Configuration

The agent behavior is controlled by `.agent/config.json`:

```json
{
  "agent_name": "codex-local",
  "role": "Local Workflow Custodian",
  "guardrails": {
    "enforce_no_inline_styles": true,
    "enforce_csp_strict": true,
    "enforce_cross_origin_isolation": true,
    "enforce_aria_compliance": true
  },
  "watchdog": {
    "cycle_interval_seconds": 300,
    "max_tasks_per_cycle": 2,
    "lock_check_interval_seconds": 30
  }
}
```

## Safety Features

### Lock File Mechanism
Create `.agent/LOCK` to pause all agent operations:
```powershell
New-Item -ItemType File -Path ".agent/LOCK"
```

Remove to resume:
```powershell
Remove-Item ".agent/LOCK"
```

### Idempotent Operations
All scripts are designed to be safe to run multiple times without side effects.

### Error Handling
Comprehensive error handling with detailed logging and graceful degradation.

## Integration

### PNPM Scripts
The agent integrates with the project's PNPM scripts:
- `pnpm setup-local` - Environment bootstrap
- `pnpm agent:doctor` - Health diagnostics
- `pnpm agent:start` - Background watchdog

### Status Tracking
Agent status is maintained in `.agent/status.json` and can be monitored programmatically.

### Logging
All operations are logged to:
- `TASKS.md` - Human-readable activity log
- `.agent/status.json` - Machine-readable status
- `DECISIONS.md` - Decision rationale

## Troubleshooting

### Common Issues

**Agent locked**: Remove `.agent/LOCK` file to resume operations.

**Health check failures**: Run `pnpm agent:doctor -Detailed` for comprehensive diagnostics.

**Guardrail violations**: Run `pnpm agent:doctor` to identify issues, then `enforce-guardrails.ps1 -Fix` to attempt automatic fixes.

**Watchdog not starting**: Check PowerShell execution policy and ensure all dependencies are installed.

### Debug Mode

Run any script with `-Verbose` for detailed output:
```powershell
pwsh -File scripts/agent/doctor.ps1 -Verbose
```

## Development

When modifying agent scripts:

1. Maintain backward compatibility with existing configurations
2. Add comprehensive error handling
3. Update documentation and logging
4. Test with both `-Fix` and `-ReportOnly` modes
5. Ensure scripts remain idempotent

## ECRR Compliance

All agent operations follow the ECRR (Examine → Clean → Report → Role) methodology:

- **Examine**: Capture environment state before changes
- **Clean**: Remove drift and enforce guardrails  
- **Report**: Generate artifacts and evidence
- **Role**: Declare the actor responsible

This ensures all changes are traceable, reversible, and well-documented.
