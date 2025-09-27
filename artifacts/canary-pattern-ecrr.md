# Canary Pattern Drills - ECRR Report
**Date**: 2025-09-27 15:46:28
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- Pattern types: Steady (10s intervals), Poisson (λ=0.1), Pareto (α=1.5, scale=1.0)
- Duration: 30 seconds
- Log destinations: C:\logs\canary-*.log
- Fractal self-similarity analysis via Hurst exponent estimation

## Clean
- Generated structured canary logs with pattern metadata
- Calculated inter-arrival time distributions
- Measured fractal characteristics for each pattern

## Report
- Results: 1 patterns analyzed
- Total events: Microsoft.PowerShell.Commands.GenericMeasureInfo.Sum
- Artifacts: artifacts/canary-pattern-results.json
- Duration: 29.6 seconds

## Role
Cursor-Local: Observability Copilot - Canary pattern analysis and fractal drift detection
