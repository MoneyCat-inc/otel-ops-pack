# ECRR Processing Benchmark (20251006-092839)

- Synthetic reports: 600
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-092839
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) |
| --- | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1224.4 | 1214.3 | 1234.49 |
| max-1 | 2 | 1110.12 | 1072.15 | 1148.08 |
| max-4 | 2 | 1054.84 | 1022.72 | 1086.97 |
| max-8 | 2 | 1053.48 | 1013.53 | 1093.43 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-092839\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-092839\benchmark-summary.json
