# ECRR Processing Benchmark (20251008-021702)

- Synthetic reports: 300
- Iterations per scenario: 3
- Synthetic tag: benchmark-load-20251008-021702
- Faulty percentage target: 0.15
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 3 | 1142.26 | 1113.81 | 1159.33 | 0 |
| max-1 | 3 | 1189.38 | 1029.33 | 1347.2 | 0 |
| max-12 | 3 | 1126.88 | 1086.95 | 1154.08 | 0 |
| max-16 | 3 | 1131.45 | 1038.04 | 1266.56 | 0 |
| max-2 | 3 | 1019.12 | 982.44 | 1061.31 | 0 |
| max-4 | 3 | 1035.3 | 996.87 | 1062.19 | 0 |
| max-6 | 3 | 1082.2 | 988.23 | 1222.48 | 0 |
| max-8 | 3 | 1091.84 | 1064.01 | 1106.65 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251008-021702\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251008-021702\benchmark-summary.json
