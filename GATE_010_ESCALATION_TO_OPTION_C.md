# Gate #010 - Escalation to Option C

**Date:** 2025-10-24 07:37 UTC  
**Authority:** BossCat OEM Decision Required  
**Status:** 🔴 OPTIONS A+B EXHAUSTED

---

## Summary

Both Option A (schema fix) and Option B (library presets) **fail with identical error**: `Unexpected token 'return'` when Butterchurn attempts to compile preset equations via `new Function()`.

This indicates a **fundamental incompatibility** between:
- Butterchurn 2.6.7 CDN minified build
- Headless Chromium environment  
- Our preset loading mechanism via `page.evaluate()`

---

## Test Results

### Option A: Schema Fix
- **Status:** ❌ FAIL
- **Implementation:** Added `normalizePreset()` with arrays/equation consolidation
- **Result:** Schema validation passed (`shapes=0 waves=0`), but equation compilation failed
- **Error:** `Unexpected token 'return'` in `new Function(<anonymous>)`

### Option B: Library Presets
- **Status:** ❌ FAIL  
- **Test:** Loaded `"Flexi - infused with the spiral"` from Butterchurn's own library
- **Result:** **Identical error** as custom presets
- **Conclusion:** NOT a parser issue - Butterchurn itself is failing

---

## Audio Bridge Status

✅ **OPERATIONAL & MEETING GATE #010 REQUIREMENTS**

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| reactivity_r | 0.44 | ≥0.35 | ✅ PASS |
| audio_samples | 500+ | >0 | ✅ PASS |
| score | 2.58 | >0 | ✅ PASS |

**Conclusion:** The audio injection architecture is **production-ready**. Only visual rendering is blocked.

---

## Root Cause Hypothesis

1. **Butterchurn 2.6.7 minified build incompatibility** with headless Chrome
   - Possible minification artifacts
   - Missing polyfills for Node.js `Function` constructor
   
2. **Preset loading via `page.evaluate()` serialization issue**
   - JSON serialization may be corrupting equation strings
   - Butterchurn might expect presets loaded synchronously within browser context

3. **Missing initialization step**
   - Butterchurn may require audio stream to be active before preset loading
   - Some initialization sequence we're missing

---

## Attempts Made (Comprehensive)

1. ✅ Fixed CDN 404 errors (switched to 2.6.7 stable)
2. ✅ Fixed `.default` export handling
3. ✅ Fixed HTTP renderer serving
4. ✅ Implemented `normalizePreset()` with array guarantees
5. ✅ Added equation consolidation
6. ✅ Tested simple per_frame only presets
7. ✅ Tested complex per_pixel presets
8. ✅ Tested library presets (Butterchurn's own collection)
9. ✅ Verified audio injection working (reactivity = 0.44)

**ALL visual attempts:** ❌ Same `Unexpected token 'return'` error

---

## Option C: ProjectM Container

### Advantages
- **Native `.milk` support** (no parser needed)
- **Proven stability** (9,700+ curated presets)
- **Desktop-grade rendering** (OpenGL/EGL)
- **Audio bridge architecture unchanged** (can reuse existing code)

### Implementation Path
1. Create `viz-engine-projectm/` directory
2. Dockerfile: Debian + libprojectM + PulseAudio/ALSA
3. Simple REST API wrapper (matches existing `/preset`, `/snap.jpg`, etc.)
4. Audio injection via PulseAudio virtual sink or direct PCM feed
5. OpenGL readback → JPEG for `/snap.jpg`
6. Scorebot remains unchanged

### Timeline
- **Setup:** 2 hours (Dockerfile + API wrapper)
- **Audio integration:** 1 hour (adapt existing audio-handler.js logic)
- **Testing:** 1 hour (verify visual output + reactivity)
- **Total:** ~4 hours

### Risk
- **Low:** ProjectM is mature, well-documented, and used in production VJ software
- **Mitigation:** Can run both containers side-by-side for A/B comparison

---

## Recommendation

**➤ Escalate to Option C (ProjectM container)**

**Rationale:**
1. Options A+B failed with **identical symptoms** → not a parser issue
2. Audio bridge is **validated and working** → can be preserved
3. Continuing to debug Butterchurn minified code = **high time investment, uncertain outcome**
4. ProjectM = **native .milk support** → eliminates entire class of parsing issues
5. **ECRR-compliant:** Small, surgical swap (one container), evidence-driven

**Alternative (if time-constrained):**
- Document Butterchurn issue as **AMBER** gate limitation
- Ship audio bridge as standalone service
- Defer visual rendering to future gate
- **Partial GREEN:** Audio reactivity requirements MET

---

## Decision Required

**BossCat:** Do we:
1. **A)** Proceed to Option C (ProjectM container, ~4h)
2. **B)** Ship audio bridge standalone, defer visuals (document AMBER)
3. **C)** Deep-dive Butterchurn debugging (unminified source, unknown timeline)

**Awaiting directive.**

---

**Evidence:**
- `GATE_010_STATUS_PARTIAL_SUCCESS.md`
- Docker logs: repeated `Unexpected token 'return'` errors
- Test results: reactivity_r = 0.44 (PASS), blackout = true (FAIL)

