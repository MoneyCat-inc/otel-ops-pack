# Rollback Plan (Template)

- Service/Component: {name}
- Current Release: <tag/commit>
- Last Known Good: <tag/commit>
- Switch Mechanism: <feature flag / traffic split / deployment rollback>

## Steps

1. Halt promotions; notify stakeholders.
2. Capture evidence links (gate JSON, ECRR MD, perf report).
3. Flip switch to last-known-good (or `git revert`/deployment rollback).
4. Validate health checks (collector, perf smoke, error rate).
5. File ECRR incident note; attach logs and diffs.
6. Resume standard deploys after BossCat approval.

## Verification

- OTLP smoke: pass
- Perf gate: within thresholds
- Status page snippet updated

Owner: {name} • Reviewed by: BossCat OEM
