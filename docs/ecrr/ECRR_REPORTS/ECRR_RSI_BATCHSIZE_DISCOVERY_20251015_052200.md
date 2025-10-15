# ECRR — RSI BatchSize Sweep

Timestamp: 2025-10-15 05:22:00 +01:00
SampleN: 2000 | Concurrency: 8

## Results
- BatchSize=500 → 254.23 files/sec (-46.83%) 
- BatchSize=800 → 331.13 files/sec (-30.74%) 
- BatchSize=1000 → 478.13 files/sec (0%) (baseline)
- BatchSize=1200 → 487.33 files/sec (1.92%) (best)
- BatchSize=1500 → 472.81 files/sec (-1.11%) 

## Conclusion
BatchSize=1200 improves throughput by 1.92% vs baseline (1000).
