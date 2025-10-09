# ECRR Processing Benchmark (20251006-092811)

- Synthetic reports: 400
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-092811
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) |
| --- | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1196.72 | 1107.27 | 1286.17 |
| max-1 | 2 | 1119.44 | 1108.35 | 1130.53 |
| max-4 | 2 | 1072.26 | 1039.69 | 1104.83 |
| max-8 | 2 | 1093.75 | 1052.71 | 1134.79 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-092811\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-092811\benchmark-summary.json
