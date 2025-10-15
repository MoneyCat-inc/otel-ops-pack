# ECRR — RSI BatchSize Sweep

Timestamp: 2025-10-15 05:22:31 +01:00
SampleN: 2000 | Concurrency: 8

## Results
- BatchSize=500 → 255.82 files/sec (-43.76%) 
- BatchSize=800 → 324.04 files/sec (-28.76%) 
- BatchSize=1000 → 454.86 files/sec (0%) (baseline)
- BatchSize=1200 → 479.39 files/sec (5.39%) (best)
- BatchSize=1500 → 475.62 files/sec (4.56%) 

## Conclusion
BatchSize=1200 improves throughput by 5.39% vs baseline (1000).
