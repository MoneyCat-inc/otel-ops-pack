# ECRR Processing Benchmark (20251006-091349)

- Synthetic reports: 300
- Iterations per scenario: 5
- Synthetic tag: benchmark-load-20251006-091349
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) |
| --- | ---: | ---: | ---: | ---: |
| auto-parallel | 5 | 837.26 | 822.15 | 865.18 |
| max-1 | 5 | 818.99 | 783.5 | 846.54 |
| max-4 | 5 | 857.24 | 822.64 | 900.07 |
| max-8 | 5 | 928.38 | 846.08 | 1121 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-091349\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-091349\benchmark-summary.json
