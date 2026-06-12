# ECRR — RSI Sweep Statistical Analysis

**Agent:** Cursor{Implementer}
**Date:** 2026-01-14

---


**Agent:** Cursor{Implementer}
**Date:** 2025-12-11

---


**Timestamp**: 2025-10-15 05:22:43 +01:00
**Tag Pattern**: `repeat-*-bs*`
**Samples per BatchSize**: 3
**Confidence Level**: 95%

---

## Summary Statistics

| BatchSize | Median (files/sec) | Mean | StdDev | CV% | 95% CI |
|-----------|-------------------|------|--------|-----|--------|
| 500 | **255.82** | 246.54 | ±14.72 | 5.97% | [209.98, 283.1] |
| 800 | **331.13** | 324.14 | ±6.94 | 2.14% | [306.91, 341.37] |
| 1000 **(baseline)** | **478.13** | 465.75 | ±11.71 | 2.51% | [436.66, 494.83] |
| 1200 **(best)** | **492.13** | 486.28 | ±6.43 | 1.32% | [470.3, 502.27] |
| 1500 | **482.04** | 476.82 | ±4.73 | 0.99% | [465.07, 488.58] |

_CV = Coefficient of Variation (lower is more consistent)_

---

## Detailed Analysis

### BatchSize=500

- **N**: 3 samples
- **Median**: 255.82 files/sec (robust central tendency)
- **Mean**: 246.54 files/sec
- **StdDev**: ±14.72 files/sec
- **CV**: 5.97% (variability)
- **95% CI**: [209.98, 283.1] (±36.56)
- **Raw values**: 229.57, 254.23, 255.82

**vs Baseline (1000)**:
- Median Δ: **-46.5%**
- Mean Δ: -47.07%
- Statistical significance: **Significant** (CIs do not overlap)

### BatchSize=800

- **N**: 3 samples
- **Median**: 331.13 files/sec (robust central tendency)
- **Mean**: 324.14 files/sec
- **StdDev**: ±6.94 files/sec
- **CV**: 2.14% (variability)
- **95% CI**: [306.91, 341.37] (±17.23)
- **Raw values**: 317.26, 331.13, 324.04

**vs Baseline (1000)**:
- Median Δ: **-30.74%**
- Mean Δ: -30.4%
- Statistical significance: **Significant** (CIs do not overlap)

### BatchSize=1000

- **N**: 3 samples
- **Median**: 478.13 files/sec (robust central tendency)
- **Mean**: 465.75 files/sec
- **StdDev**: ±11.71 files/sec
- **CV**: 2.51% (variability)
- **95% CI**: [436.66, 494.83] (±29.08)
- **Raw values**: 464.25, 478.13, 454.86

### BatchSize=1200

- **N**: 3 samples
- **Median**: 492.13 files/sec (robust central tendency)
- **Mean**: 486.28 files/sec
- **StdDev**: ±6.43 files/sec
- **CV**: 1.32% (variability)
- **95% CI**: [470.3, 502.27] (±15.98)
- **Raw values**: 492.13, 487.33, 479.39

**vs Baseline (1000)**:
- Median Δ: **2.93%**
- Mean Δ: 4.41%
- Statistical significance: **NOT significant** (CIs overlap)

### BatchSize=1500

- **N**: 3 samples
- **Median**: 482.04 files/sec (robust central tendency)
- **Mean**: 476.82 files/sec
- **StdDev**: ±4.73 files/sec
- **CV**: 0.99% (variability)
- **95% CI**: [465.07, 488.58] (±11.75)
- **Raw values**: 482.04, 472.81, 475.62

**vs Baseline (1000)**:
- Median Δ: **0.82%**
- Mean Δ: 2.38%
- Statistical significance: **NOT significant** (CIs overlap)

---

## Clean

<!-- Add cleanup/implementation details here -->

## Examine

<!-- Add examination details here -->

## Report

<!-- Add report/summary details here -->

## Role

<!-- Add role/next actions here -->

## Conclusion

**Best configuration**: BatchSize=1200
- Median improvement: **2.93%** vs baseline
- Consistency: CV=1.32% (vs baseline CV=2.51%)
- **Recommendation**: ⚠️ **Keep BatchSize=1000** (improvement not statistically significant)
- Confidence intervals overlap, indicating difference may be due to variance

---

## Interpretation Guide

- **Median**: Central value, robust to outliers (preferred over mean)
- **StdDev**: Spread of values (lower is more consistent)
- **CV%**: Normalized variability (< 5% is good, < 2% is excellent)
- **95% CI**: Range where true value likely lies
- **CI Overlap**: If CIs overlap, difference may not be real (within variance)

