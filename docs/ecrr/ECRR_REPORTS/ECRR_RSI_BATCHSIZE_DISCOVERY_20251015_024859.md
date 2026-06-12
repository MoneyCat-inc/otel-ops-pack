# ECRR — RSI BatchSize Sweep

**Agent:** Cursor{Implementer}
**Date:** 2026-01-14

---


**Agent:** Cursor{Implementer}
**Date:** 2025-12-11

---


Timestamp: 2025-10-15 02:48:59 +01:00
SampleN: 2000 | Concurrency: 8

## Results
- BatchSize=500 → 255.75 files/sec (-47.66%) 
- BatchSize=800 → 338.35 files/sec (-30.76%) 
- BatchSize=1000 → 488.64 files/sec (0%) (baseline)
- BatchSize=1200 → 459.14 files/sec (-6.04%) 
- BatchSize=1500 → 495.66 files/sec (1.44%) (best)

## Examine

<!-- Add examination details here -->

## Clean

<!-- Add cleanup/implementation details here -->

## Report

<!-- Add report/summary details here -->

## Role

<!-- Add role/next actions here -->

## Conclusion
BatchSize=1500 improves throughput by 1.44% vs baseline (1000).
