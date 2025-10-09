# ECRR Processing Benchmark (20251006-094523)

- Synthetic reports: 800
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-094523
- Faulty percentage target: 0.2
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1142.64 | 1086.6 | 1198.67 | 0 |
| max-14681216 | 2 | 1194.18 | 1169.46 | 1218.9 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094523\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-094523\benchmark-summary.json
