# ECRR Processing Benchmark (20251006-085941)

- Synthetic reports: 150
- Iterations per scenario: 1
- Synthetic tag: benchmark-load-20251006-085941
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) |
| --- | ---: | ---: | ---: | ---: |
| auto-parallel | 1 | 1009.74 | 1009.74 | 1009.74 |
| max-1 | 1 | 1033.41 | 1033.41 | 1033.41 |
| max-4 | 1 | 979.12 | 979.12 | 979.12 |
| max-8 | 1 | 983.4 | 983.4 | 983.4 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-085941\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-085941\benchmark-summary.json
