# BossCat Gates

Evidence-based quality gates for AI agents.

## Concept

Instead of trusting agent self-reports, gates require **evidence** from telemetry:

- ✅ Passing tests (telemetry span exists)
- ✅ Security scan (zero critical vulnerabilities)
- ✅ Code review (review completion span)

## Gate Configuration

See [config/gates/](../../config/gates/) for examples.

## Using Gates

```python
from otel_ops_pack import BossCatGate

gate = BossCatGate.from_yaml("config/gates/code_quality_gate.yaml")
result = gate.evaluate(task_id="task-123", coordinator=coordinator)

if result.passed:
    deploy()
else:
    print(f"Gate failed: {result.missing_requirements}")
```

## Coming Soon

- Pre-built gate templates
- Gate visualization
- Integration examples
