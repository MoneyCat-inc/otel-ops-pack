# IONA Supervisor Specification v1.1

## Overview

The IONA Supervisor provides a safe, budget-controlled pattern for spawning, monitoring, and terminating AI agents within the Resonai observability pipeline. It enforces guardrails, manages resource budgets, and maintains auditable execution trails.

## Architecture

### Components

- **Supervisor**: Single entry point for agent lifecycle management
- **Runner**: Background worker that executes queued agents
- **Existing Agents**: ChatGPT, Cursor, Codex agents that integrate with the supervisor
- **Storage**: JSON-based ticket system with artifact outputs

### Storage Structure

```
.agent/
├── agent_queue.json          # Active ticket queue
├── state.json               # Runner state and statistics
├── config.json              # Budget limits and safety settings
└── LOCK                     # Kill-switch file (pauses all execution)

artifacts/agents/
├── <ticket-id>/
│   ├── output.json          # Agent execution results
│   ├── logs.txt             # Execution logs
│   └── metadata.json        # Ticket metadata and timing
```

## Type Definitions

### Agent Modes

```typescript
type IONAMode = 'Companion' | 'Archivist' | 'Cipher' | 'MarketAnalyst' | 'Care';
```

- **Companion**: Conversational assistance with humor gating
- **Archivist**: Documentation and knowledge management
- **Cipher**: Security analysis and compliance checking
- **MarketAnalyst**: Business intelligence and metrics analysis
- **Care**: Health monitoring and maintenance tasks

### Agent Specification

```typescript
interface AgentSpec {
  mode: IONAMode;
  goal: string;
  inputs?: Record<string, unknown>;
  guardrails: {
    browsing: boolean;        // Default: false, requires explicit consent
    maxTokens: number;        // Token budget per execution
    humorGating: boolean;     // Enable humor only for safe contexts
  };
  budgets: {
    maxJobs: number;          // Maximum concurrent jobs
    maxFiles?: number;        // File operation limit
    maxLines?: number;        // Code analysis limit
    ttlMs: number;           // Time-to-live in milliseconds
    maxAttempts: number;      // Retry attempts before failure
    backoffMs: number;       // Backoff delay between retries
  };
}
```

### Ticket Schema

```typescript
interface Ticket {
  id: string;                 // UUID v4
  status: 'queued' | 'running' | 'succeeded' | 'failed' | 'terminated';
  startedAt?: number;         // Unix timestamp
  deadline: number;          // Unix timestamp
  attempts: number;          // Current attempt count
  outputs?: unknown;         // Agent execution results
  logs?: string[];           // Execution log entries
  metadata: {
    mode: IONAMode;
    goal: string;
    guardrails: AgentSpec['guardrails'];
    budgets: AgentSpec['budgets'];
    createdAt: number;
    updatedAt: number;
  };
}
```

## API Surface

### Supervisor Commands

#### `spawn(spec: AgentSpec): Ticket`

Validates agent specification against system budgets, assigns unique ID and deadline, writes to queue, returns ticket stub.

**Validation Rules:**
- Check `.agent/config.json` global limits
- Verify mode-specific guardrails
- Ensure browsing consent if enabled
- Validate token budgets against available capacity

**Returns:** Ticket with `status: 'queued'` and assigned `id`

#### `awaitResult(id: string, options: { timeoutMs: number }): { status: string, outputs?: unknown }`

Polls ticket status and output artifacts until completion, timeout, or termination.

**Polling Strategy:**
- Check `.agent/agent_queue.json` for status updates
- Read `.artifacts/agents/<id>/output.json` for results
- Respect `timeoutMs` parameter
- Return termination reason on failure

**Returns:** Status and outputs (if available)

#### `terminate(id: string, reason: string): boolean`

Marks ticket as terminated, signals runner to stop execution, appends reason to logs.

**Actions:**
- Update ticket status to `'terminated'`
- Write termination reason to logs
- Signal runner process (if running)
- Persist state update

**Returns:** `true` if termination successful, `false` if ticket not found

## Runner Responsibilities

### Execution Loop

1. **Lock Check**: Skip execution if `.agent/LOCK` exists
2. **Queue Processing**: Read `.agent/agent_queue.json` for queued tickets
3. **Budget Enforcement**: Verify job limits, file caps, line limits
4. **Agent Spawning**: Launch appropriate agent based on mode
5. **Monitoring**: Track execution progress and resource usage
6. **Completion**: Write outputs to artifacts, update ticket status
7. **Cleanup**: Remove expired tickets, update statistics

### Budget Enforcement

- **Max Jobs**: Limit concurrent agent executions
- **File Limits**: Cap file operations per agent
- **Line Limits**: Restrict code analysis scope
- **TTL**: Auto-terminate expired tickets
- **Backoff**: Implement retry delays for failed attempts

### Safety Controls

- **No Merges**: Agents produce artifacts only, never modify main codebase
- **Artifact Generation**: Create reports, dashboards, monitoring data
- **PR Drafts**: Optional PR creation for review (never auto-merge)
- **State Updates**: Maintain `.agent/state.json` with execution statistics

## Safety & Guardrails

### Ask → Notify → Act Cadence

1. **Ask**: Supervisor validates request and creates ticket
2. **Notify**: System logs ticket creation with budgets and constraints
3. **Act**: Runner executes within defined guardrails

### Browsing Controls

- **Default**: Browsing disabled for all agents
- **Consent Required**: Agents must explicitly request browsing permission
- **Audit Trail**: All browsing requests logged with justification
- **Scope Limitation**: Browsing restricted to specific domains/topics

### Humor Gating

- **Context Awareness**: Enable humor only for appropriate topics
- **Mode Restrictions**: Companion mode only when mood/topic safe
- **Content Filtering**: Prevent inappropriate or offensive content
- **Fallback Behavior**: Graceful degradation when humor disabled

### Kill-Switch

- **Lock File**: Touching `.agent/LOCK` pauses all execution
- **Graceful Shutdown**: Running agents complete current operations
- **Resume**: Removing lock file resumes normal operation
- **Status Reporting**: Clear indication of paused state

### Budget Management

- **Global Limits**: Defined in `.agent/config.json`
- **Per-Agent Limits**: Specified in agent ticket
- **Enforcement**: Supervisor refuses tickets exceeding limits
- **Monitoring**: Real-time budget tracking and alerts

### TTL & Backoff

- **Deadline Enforcement**: Runner drops tickets exceeding deadline
- **Retry Logic**: Exponential backoff for failed attempts
- **Termination Logging**: Clear reason codes for all terminations
- **Resource Cleanup**: Automatic cleanup of expired artifacts

## Operational Procedures

### Daily Operations

```powershell
# Start supervisor runner
pwsh -File scripts/agents/supervisor.ps1 -Action start-runner

# Check queue status
pwsh -File scripts/agents/supervisor.ps1 -Action status

# Emergency stop
touch .agent/LOCK

# Resume operations
rm .agent/LOCK
```

### Agent Lifecycle

```powershell
# Spawn agent
pwsh -File scripts/agents/supervisor.ps1 -Action spawn -SpecPath specs/companion.json

# Monitor execution
pwsh -File scripts/agents/supervisor.ps1 -Action await -Id <ticket-id> -TimeoutMs 30000

# Terminate if needed
pwsh -File scripts/agents/supervisor.ps1 -Action terminate -Id <ticket-id> -Reason "operator stop"
```

### Verification

```powershell
# Run smoke tests
pwsh -File scripts/agents/supervisor.ps1 -Action smoke-test

# Verify budget compliance
pwsh -File scripts/agents/supervisor.ps1 -Action verify-budgets

# Check artifact integrity
pwsh -File scripts/agents/supervisor.ps1 -Action verify-artifacts
```

## Integration Points

### ECRR Compliance

- **Examine**: Capture environment state before agent execution
- **Clean**: Remove drift and enforce guardrails
- **Report**: Generate artifacts and evidence
- **Role**: Declare responsible actor in all outputs

### SigNoz Integration

- **Metrics**: Track agent execution times, success rates, resource usage
- **Logs**: Stream agent logs to SigNoz for monitoring
- **Alerts**: Configure alerts for budget violations, failures, timeouts
- **Dashboards**: Create agent performance dashboards

### Existing Agent Integration

- **ChatGPT Agent**: Orchestrator role, plans and specifications
- **Cursor Agent**: Implementation role, UI/features under guardrails
- **Codex Agent**: Coordination role, CI/security/merges
- **Codex-Local**: Local ergonomics, environment management

## Security Considerations

### Data Protection

- **No PII**: Agents never handle personally identifiable information
- **Local-First**: No external network calls except localhost services
- **Audit Trails**: Complete execution logs for compliance
- **Access Control**: File system permissions for artifact directories

### Resource Limits

- **Memory Caps**: Prevent memory exhaustion
- **CPU Limits**: Throttle resource-intensive operations
- **File System**: Protect against runaway file operations
- **Network**: Restrict external connectivity

### Error Handling

- **Graceful Degradation**: System continues operating on agent failures
- **Error Isolation**: Failed agents don't affect other operations
- **Recovery Procedures**: Automatic cleanup and retry mechanisms
- **Alerting**: Immediate notification of critical failures

## Monitoring & Observability

### Metrics Collection

- **Execution Times**: Track agent performance
- **Success Rates**: Monitor reliability
- **Resource Usage**: CPU, memory, file operations
- **Budget Compliance**: Track limit adherence

### Logging Strategy

- **Structured Logs**: JSON format for machine parsing
- **Log Rotation**: Size-based rotation with retention
- **Correlation IDs**: Link logs across agent lifecycle
- **Severity Levels**: INFO, WARN, ERROR, CRITICAL

### Alerting Rules

- **Budget Violations**: Immediate alert on limit breaches
- **Execution Failures**: Alert on repeated failures
- **Resource Exhaustion**: Alert on high resource usage
- **Timeout Events**: Alert on execution timeouts

## Future Enhancements

### Planned Features

- **Agent Marketplace**: Repository of pre-configured agent specs
- **Dynamic Scaling**: Automatic resource allocation based on demand
- **Cross-Agent Communication**: Inter-agent messaging and coordination
- **Advanced Scheduling**: Cron-based and event-driven execution

### Integration Roadmap

- **Kubernetes**: Container-based agent execution
- **Cloud Providers**: Hybrid cloud/local execution
- **External APIs**: Integration with third-party services
- **Machine Learning**: Predictive resource allocation

---

*This specification follows the ECRR methodology: Examine (current state), Clean (remove drift), Report (documentation), Role (supervisor responsibility).*
