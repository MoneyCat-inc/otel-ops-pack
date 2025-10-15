# ECRR — RSI BatchSize Sweep

Timestamp: 2025-10-15 02:48:59 +01:00
SampleN: 2000 | Concurrency: 8

## Results
- BatchSize=500 → 255.75 files/sec (-47.66%) 
- BatchSize=800 → 338.35 files/sec (-30.76%) 
- BatchSize=1000 → 488.64 files/sec (0%) (baseline)
- BatchSize=1200 → 459.14 files/sec (-6.04%) 
- BatchSize=1500 → 495.66 files/sec (1.44%) (best)

## Conclusion
BatchSize=1500 improves throughput by 1.44% vs baseline (1000).
