# ECRR Processing Benchmark (20251009-021702)

- Synthetic reports: 300
- Iterations per scenario: 3
- Synthetic tag: benchmark-load-20251009-021702
- Faulty percentage target: 0.15
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 3 | 1092.21 | 1058.69 | 1153.41 | 0 |
| max-1 | 3 | 1233.93 | 963.16 | 1697.17 | 0 |
| max-12 | 3 | 961.55 | 942 | 994.39 | 0 |
| max-16 | 3 | 968.86 | 937.86 | 988.41 | 0 |
| max-2 | 3 | 1046.32 | 956.02 | 1167.75 | 0 |
| max-4 | 3 | 930.45 | 919.98 | 943.98 | 0 |
| max-6 | 3 | 922.6 | 906.81 | 943.19 | 0 |
| max-8 | 3 | 1024.45 | 958.9 | 1106.93 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251009-021702\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251009-021702\benchmark-summary.json
