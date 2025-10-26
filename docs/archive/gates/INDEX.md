# 🗂️ Gate Archive Index

Archived gate evidence and documentation. Production code remains in active codebase.

---

## 📋 Archive Structure

```
docs/archive/gates/
├── 2025-10/
│   └── 016/          # Gate #016 - Visual Guard & Jitter Stabilization
└── INDEX.md          # This file
```

---

## 🏷️ Archived Gates

### Gate #016 — Visual Guard & Jitter Stabilization
**Status:** ✅ GREEN  
**Certified:** 2025-10-24  
**Archived:** 2025-10-26  
**Location:** `docs/archive/gates/2025-10/016/`

**Summary:** Active visual guard monitoring with frame-timing stabilization
- Active guard: 9.92 Hz monitoring cadence
- Jitter stabilizer: P95 2ms (≤8ms budget)
- Blackout detection: 0% unsafe presets
- Synthetic traces: visuals.test.run + audio.test.run

**Files Archived:** 11 documents (evidence, corrections, certifications, summaries)

**Related Code:** Retained in `viz-engine-projectm/` (brightness-guard.js, frame-timing-stabilizer.js)

---

## 📅 Archive Policy

**What Gets Archived:**
- Gate evidence documents
- Job reports and corrections
- Executive summaries and handoffs
- PR summaries and certifications
- ECRR reports (gate-specific)

**What Stays in Active Codebase:**
- Production code (implementations)
- Active scripts and tools
- Central documentation (GATE_STATUS_DASHBOARD.md, BOSSCAT_LOG.md)
- Current gate evidence (Gates in progress or recently certified)

**Archiving Timeline:**
- Gates archived after subsequent gates are GREEN
- Typically 1-2 gates lag (e.g., archive #016 when #018+ GREEN)
- Immediate archive for large evidence bundles (cleanup)

---

## 🔍 How to Access Archived Evidence

**By Gate Number:**
1. Navigate to `docs/archive/gates/YYYY-MM/###/`
2. Read `README.md` for gate summary
3. Access specific evidence files as needed

**By Date:**
- Archives organized by year-month (YYYY-MM)
- Gates sorted numerically within month directories

**Search:**
```bash
# Find specific gate
find docs/archive/gates -name "*GATE_016*"

# Search gate content
grep -r "brightness guard" docs/archive/gates/

# List all archived gates
ls docs/archive/gates/*/
```

---

## 📊 Archive Statistics

**Total Gates Archived:** 1  
**Total Files Archived:** 11  
**Earliest Archive:** 2025-10-24 (Gate #016)  
**Latest Archive:** 2025-10-26 (Gate #016)

---

**Maintained by:** Cursor{Implementer}  
**Authority:** BossCat OEM  
**Last Updated:** 2025-10-26

🐾 *Gate archive: Evidence preserved, production code active.*

