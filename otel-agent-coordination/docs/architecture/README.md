# Architecture Overview

## Core Concepts

### Stigmergic Coordination

Agents coordinate by leaving "traces" in the environment (telemetry) that other agents observe and react to.

Instead of:
```
Agent A --message--> Agent B
```

We have:
```
Agent A --telemetry--> Backend <--query-- Agent B
```

## Components

1. **TelemetryCoordinator**: Core coordination layer
2. **BossCat Gates**: Evidence-based quality checkpoints
3. **OpenTelemetry**: Standard telemetry protocol
4. **Backend**: SigNoz, Jaeger, or compatible

## Benefits

- **Audit Trail**: Built-in by default
- **Debugging**: Query historical execution
- **Self-Improvement**: Agents analyze own history
- **Simplicity**: No message bus complexity

## Coming Soon

Detailed architecture diagrams and implementation guide.
