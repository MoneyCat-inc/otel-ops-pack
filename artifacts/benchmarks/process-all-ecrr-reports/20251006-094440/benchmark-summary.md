# ECRR Processing Benchmark (20251006-094440)

- Synthetic reports: 800
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-094440
- Faulty percentage target: 0.2
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1113.03 | 1093.19 | 1132.86 | 0 |
| max-1 | 2 | 1157.4 | 1135.14 | 1179.65 | 0 |
| max-4 | 2 | 1065.78 | 1055.81 | 1075.75 | 0 |
| max-8 | 2 | 1362.42 | 1281.79 | 1443.05 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094440\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094440\benchmark-summary.json
