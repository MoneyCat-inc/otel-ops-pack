# E2 Ratio Sweep Analysis - ECRR Report
**Date**: 2025-09-27 07:02:36
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- Current batch processor: 500ms timeout
- Current exporter: 127.0.0.1:14317 (gRPC)
- Test matrix: 9 combinations (3 agent × 3 gateway timeouts)

## Clean
- Backup original config.yaml
- Test each combination systematically
- Restore config after each test

## Report
- Results: 0 tests completed
- Artifacts: artifacts/e2-ratio-sweep-results.json
- Metrics: CPU, memory, span rate, latency

## Role
Cursor-Local: Observability Copilot - E2 ratio optimization analysis
