# ECRR Processing Benchmark (20251006-094049)

- Synthetic reports: 800
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-094049
- Faulty percentage target: 0.2
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1149.73 | 1073.92 | 1225.54 | 0 |
| max-1 | 2 | 1174.39 | 1148.04 | 1200.74 | 0 |
| max-4 | 2 | 1106.6 | 1083.77 | 1129.43 | 0 |
| max-8 | 2 | 1328.42 | 1312.95 | 1343.88 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094049\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094049\benchmark-summary.json
