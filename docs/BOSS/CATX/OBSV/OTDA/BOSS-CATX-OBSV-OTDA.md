# BOSS-CATX-OBSV-OTDA

**Tetragram**: `BOSS-CATX-OBSV-OTDA`  
**NATO**: BRAVO–OSCAR–SIERRA–SIERRA / CHARLIE–ALFA–TANGO–XRAY / OSCAR–BRAVO–SIERRA–VICTOR / OSCAR–TANGO–DELTA–ALFA  
**Authority**: BossCat OEM Directive 012  
**Created**: 2025-10-13 00:55:00 +01:00

---

## Purpose

<!-- markdownlint-disable-next-line MD013 -->
ICF/RSI panel added to status dashboard. Surfaces Iterative Convergence Framework metrics and Rhetorical Style Integrity signals for executive visibility.

---

## Components

### Status Page Integration

**File**: `docs/status.html`  
**Section**: ICF/RSI panel with 4 metrics  
**Design**: CSP-compliant, accessible, design-system aligned

**Metrics Displayed**:

1. **Convergence Rate (7d)**: Percentage of successful iterations (ICF doctrine)
2. **RSI Warnings (7d)**: Count of style drift warnings
3. **LII**: Linguistic Individuality Index (lexical diversity)
4. **ΔPerplexity**: Function-word ratio deviation from baseline

### JavaScript Module

**File**: `docs/assets/icf-rsi-panel.js`  
**LOC**: 63 code lines  
**Features**:

- Fetches metrics from multiple candidate locations
- Graceful degradation if no data available
- Semantic color coding for warnings (green/yellow/red)
- CSP-compliant (no inline JavaScript)

### RSI Extractor Enhancement

**File**: `scripts/rsi-extract.mjs`  
**Added**: ICF fields to metrics output  
**Fields**: `convergence_rate_7d`, `warnings_7d`, `delta_perplexity`, `lii`

### CI Publishing

**File**: `.github/workflows/bosscat-gate-verify.yml`  
**Step**: Publish RSI metrics for status UI (main branch only)  
**Output**: `docs/artifacts/rsi/metrics.json`

---

## Source of Truth

**Metrics JSON**: `artifacts/rsi/metrics.json` (primary)  
**Mirror**: `docs/artifacts/rsi/metrics.json` (for status page access)  
**Evidence**: ECRR packet links from panel

---

## Narration Register

**Style**: Neutral Instructor register maintained throughout  
**Alignment**: ICF doctrine (learn and converge each cycle)  
**Framework**: ECRR (evidence → contain → rollback → report)

---

## Budget Compliance

**Lane**: DOCS (documentation and status UI)  
**LOC**: ~100 total (63 JS + 30 HTML + 10 CI)  
**Files**: 4 modified/created  
**Budget**: ≤200 LOC ✅

---

## Rollback

**If issues arise**:

```bash
# Remove panel from status page
git checkout HEAD~1 -- docs/status.html docs/assets/icf-rsi-panel.js

# Remove CI publishing step
git checkout HEAD~1 -- .github/workflows/bosscat-gate-verify.yml

# Commit rollback
git commit -m "rollback(directive-012): remove ICF/RSI panel"
```

**Recovery Time**: <5 minutes  
**Impact**: Cosmetic only (no operational impact)

---

## Future Enhancements

**Phase 2** (When full ICF tracking implemented):

- Replace placeholder `convergence_rate_7d` with actual ECRR trend calculation
- Add convergence index over time (rolling 30-day window)
- Link to detailed ICF reports

**Phase 3** (Advanced RSI):

- WARN sentinel thresholds (kσ deviation alerts)
- RSI trend visualization (sparklines)
- Correlation with code quality metrics

---

**Seal**: 🐾 BossCat OEM  
**Directive**: 012 (BOSS-CATX-OBSV-OTDA)  
**Date**: 2025-10-13 00:55:00 +01:00  
**Status**: Operational

