# Basic Coordination Example

This example demonstrates two agents coordinating through telemetry without explicit message passing.

## How It Works

1. **Agent A** performs work and emits completion telemetry
2. **Agent B** polls telemetry backend waiting for Agent A's completion
3. Once detected, Agent B proceeds with its work
4. No direct communication between agents

## Running

```bash
# Ensure SigNoz or compatible backend is running
python examples/basic_coordination/basic_example.py
```

## Key Concepts

- **Stigmergic Coordination**: Agents coordinate by observing telemetry traces
- **Polling Pattern**: Simple polling for task completion
- **Zero Message Passing**: No direct agent-to-agent communication
