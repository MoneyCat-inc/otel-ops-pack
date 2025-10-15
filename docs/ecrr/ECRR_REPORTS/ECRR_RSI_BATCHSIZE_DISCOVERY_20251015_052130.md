# ECRR — RSI BatchSize Sweep

Timestamp: 2025-10-15 05:21:30 +01:00
SampleN: 2000 | Concurrency: 8

## Results
- BatchSize=500 → 229.57 files/sec (-50.55%) 
- BatchSize=800 → 317.26 files/sec (-31.66%) 
- BatchSize=1000 → 464.25 files/sec (0%) (baseline)
- BatchSize=1200 → 492.13 files/sec (6.01%) (best)
- BatchSize=1500 → 482.04 files/sec (3.83%) 

## Conclusion
BatchSize=1200 improves throughput by 6.01% vs baseline (1000).
