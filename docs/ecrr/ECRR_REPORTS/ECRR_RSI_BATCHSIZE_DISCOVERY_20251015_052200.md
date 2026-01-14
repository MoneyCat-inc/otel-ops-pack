# ECRR — RSI BatchSize Sweep

**Agent:** Cursor{Implementer}
**Date:** 2026-01-14

---


**Agent:** Cursor{Implementer}
**Date:** 2025-12-11

---


Timestamp: 2025-10-15 05:22:00 +01:00
SampleN: 2000 | Concurrency: 8

## Results
- BatchSize=500 → 254.23 files/sec (-46.83%) 
- BatchSize=800 → 331.13 files/sec (-30.74%) 
- BatchSize=1000 → 478.13 files/sec (0%) (baseline)
- BatchSize=1200 → 487.33 files/sec (1.92%) (best)
- BatchSize=1500 → 472.81 files/sec (-1.11%) 

## Examine

<!-- Add examination details here -->

## Clean

<!-- Add cleanup/implementation details here -->

## Report

<!-- Add report/summary details here -->

## Role

<!-- Add role/next actions here -->

## Conclusion
BatchSize=1200 improves throughput by 1.92% vs baseline (1000).
