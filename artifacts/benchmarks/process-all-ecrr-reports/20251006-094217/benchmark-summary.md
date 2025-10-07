# ECRR Processing Benchmark (20251006-094217)

- Synthetic reports: 800
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-094217
- Faulty percentage target: 0.2
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1286.14 | 1220.85 | 1351.42 | 0 |
| max-1 | 2 | 1180.03 | 1155.47 | 1204.59 | 0 |
| max-4 | 2 | 1058.65 | 1031.51 | 1085.79 | 0 |
| max-8 | 2 | 1137.2 | 1115.14 | 1159.27 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094217\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094217\benchmark-summary.json
