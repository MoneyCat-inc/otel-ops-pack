# ECRR Processing Benchmark (20251007-021702)

- Synthetic reports: 300
- Iterations per scenario: 3
- Synthetic tag: benchmark-load-20251007-021702
- Faulty percentage target: 0.15
- Source script: scripts/process-all-ecrr-reports.ps1

| Scenario | Runs | Avg (ms) | Min (ms) | Max (ms) | Avg Issues |
| --- | ---: | ---: | ---: | ---: | ---: |
| auto-parallel | 3 | 1099.01 | 1051.18 | 1192.45 | 0 |
| max-1 | 3 | 1075.71 | 968.83 | 1273.15 | 0 |
| max-12 | 3 | 1014.62 | 968.45 | 1040 | 0 |
| max-16 | 3 | 992.49 | 939.21 | 1026.33 | 0 |
| max-2 | 3 | 988.68 | 939.88 | 1062.33 | 0 |
| max-4 | 3 | 988.88 | 899.45 | 1096.2 | 0 |
| max-6 | 3 | 994.7 | 984.85 | 1007 | 0 |
| max-8 | 3 | 1000.29 | 951.27 | 1042.71 | 0 |

Results JSON: artifacts\benchmarks\process-all-ecrr-reports\20251007-021702\benchmark-results.json

Summary JSON: artifacts\benchmarks\process-all-ecrr-reports\20251007-021702\benchmark-summary.json
