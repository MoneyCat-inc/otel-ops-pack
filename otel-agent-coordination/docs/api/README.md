# API Reference

## TelemetryCoordinator

Core coordination class for agent communication through telemetry.

### Methods

- `check_task_complete(task_name, agent_id=None)` - Check if a task has been completed
- `emit_task_complete(task_name, agent_id, attributes=None)` - Emit a task completion event

## BossCatGate

Evidence-based quality gate for agent workflows.

### Methods

- `from_yaml(filepath)` - Load gate configuration from YAML
- `evaluate(task_id, coordinator)` - Evaluate gate requirements

## GateResult

Result of gate evaluation.

### Attributes

- `status` - GREEN, AMBER, or RED
- `passed` - Boolean indicating if gate passed
- `evidence` - List of evidence found
- `missing_requirements` - List of missing requirements

## Coming Soon

Full API documentation with examples.
