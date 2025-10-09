# ECRR Processing Benchmark (20251006-092901)

- Synthetic reports: 800
- Iterations per scenario: 2
- Synthetic tag: benchmark-load-20251006-092901
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) |
| --- | ---: | ---: | ---: | ---: |
| auto-parallel | 2 | 1092.94 | 1015.13 | 1170.76 |
| max-1 | 2 | 1018.01 | 961.45 | 1074.57 |
| max-4 | 2 | 1017.6 | 991.49 | 1043.71 |
| max-8 | 2 | 1051.39 | 1041.56 | 1061.22 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-092901\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251006-092901\benchmark-summary.json
