# DECISIONS.md - codex-local Local Workflow Custodian Decision Log

This file documents the rationale behind significant decisions made by the codex-local Local Workflow Custodian agent.

## 2025-01-27 - Initial Implementation Decisions

### Agent Configuration Structure
**Decision**: Enhanced existing `.agent/config.json` with codex-local specific settings
**Rationale**: The repository already had a well-structured agent system, so we extended it rather than replacing it. This maintains compatibility with existing workflows while adding the required Local Workflow Custodian capabilities.

**Key additions**:
- `role: "Local Workflow Custodian"` - Clear identity declaration
- Enhanced capabilities array with environment_setup, health_diagnostics, guardrail_enforcement
- Guardrails configuration section with enforcement thresholds
- Watchdog configuration with cycle intervals and task limits

### PNPM Script Integration
**Decision**: Added three core scripts to package.json: setup-local, agent:doctor, agent:start
**Rationale**: Following the existing pattern of PowerShell script integration in package.json. This provides familiar entry points for developers while maintaining the Windows/PowerShell focus of the project.

**Scripts created**:
- `setup-local` → `scripts/agent/setup-local.ps1` - Environment bootstrap
- `agent:doctor` → `scripts/agent/doctor.ps1` - Health diagnostics
- `agent:start` → `scripts/agent/watchdog.ps1` - Background watchdog

### Lock File Mechanism
**Decision**: Implemented `.agent/LOCK` kill-switch as a simple file presence check
**Rationale**: Simple, reliable emergency brake mechanism. File presence/absence is atomic and doesn't require complex state management. All scripts check for lock before proceeding with any operations.

**Implementation**: All three core scripts check for `.agent/LOCK` at startup and exit immediately if found, updating status to "paused:lock".

### Guardrail Enforcement Strategy
**Decision**: Implemented comprehensive scanning for inline styles, CSP violations, and A11y issues
**Rationale**: These are the most common security and accessibility violations that can be automatically detected and reported. The agent focuses on detection and reporting rather than automatic fixing to avoid breaking working code.

**Guardrails enforced**:
- No inline styles (`style="..."` attributes)
- No `dangerouslySetInnerHTML` usage
- CSP configuration presence validation
- ARIA accessibility compliance (alt text, labels, roles)
- Runtime version compliance (Node.js >= 18.0.0)

### Background Watchdog Design
**Decision**: Implemented cyclical processing with configurable intervals and task limits
**Rationale**: Background maintenance should be non-intrusive but reliable. The cyclical approach allows for regular health checks while processing queued tasks without overwhelming the system.

**Key features**:
- 5-minute default cycle interval (configurable)
- Maximum 2 tasks per cycle (configurable)
- Lock file checking every 30 seconds
- Comprehensive logging and status updates
- Graceful error handling and recovery

### Logging and Documentation Strategy
**Decision**: Dual logging approach with structured JSON and human-readable markdown
**Rationale**: Machine-readable logs enable programmatic monitoring and integration, while human-readable logs provide transparency for developers. This follows the ECRR (Examine → Clean → Report → Role) methodology.

**Logging components**:
- `.agent/status.json` - Machine-readable status tracking
- `.agent/state.json` - Agent state persistence
- `.agent/agent_queue.json` - Task queue management
- `TASKS.md` - Human-readable activity log
- `DECISIONS.md` - Decision rationale documentation

### Windows/PowerShell Focus
**Decision**: Maintained PowerShell script implementation with Windows-specific optimizations
**Rationale**: The existing codebase is Windows-focused with PowerShell integration. Maintaining this approach ensures consistency and leverages existing Windows-specific features like service management.

**Windows-specific features**:
- OTel Collector service status checking
- PowerShell execution policy validation
- Windows path handling (`C:\` vs `/` paths)
- Service management integration

### Safety and Idempotence
**Decision**: All operations are designed to be safe and idempotent
**Rationale**: Local development environments need to be stable and predictable. Scripts should be safe to run multiple times without causing issues.

**Safety measures**:
- Read-only operations by default
- Configuration file backup before modifications
- Graceful error handling with detailed logging
- Non-destructive guardrail enforcement (reporting vs. automatic fixing)

## Future Considerations

### Integration with Existing Agent System
The implementation leverages the existing agent infrastructure while adding Local Workflow Custodian capabilities. Future enhancements could include:
- Integration with existing task queue system
- Enhanced reporting to existing dashboard infrastructure
- Coordination with other agents in the system

### Guardrail Expansion
Current guardrails focus on the most common issues. Future iterations could include:
- Dependency vulnerability scanning
- Code quality metrics enforcement
- Performance regression detection
- Security header validation

### Cross-Platform Support
While currently Windows-focused, the architecture could be extended to support:
- Linux/macOS compatibility
- WSL2 integration
- Docker container environments
- CI/CD pipeline integration
