# Gate #011 Track A - Findings

**Date:** 2025-10-24 08:55 UTC  
**Track:** A (Butterchurn Scaffolding)  
**Status:** ❌ BLOCKED - Root cause deeper than expected

---

## Implementation Completed

### ✅ Parser Enhancements (milk-parser.js)
1. **sanitizeEel()** - Strips 'return', 'function' keywords from equations
2. **ensureVizScaffold()** - Adds minimal wave/shape stubs (prevents undefined.length)
3. **normalizePreset()** - Enhanced with EEL sanitization

### ✅ Server Safe Mode (server.js)
1. **safe=1 default** - Forces normalization on all presets
2. **Try/catch with ECRR fallback** - Loads blank preset on failure
3. **Enhanced logging** - Tracks array counts

**LOC Added:** ~110 (within ≤200 budget)  
**Files Changed:** 2 (within ≤10 budget)

---

## Test Results

### Test 1: Custom .milk with Bass Warp
**Preset:**
```
[preset00]
fDecay=0.93
fVideoEchoZoom=1.6
bAdditiveWaves=1
per_frame_1=zoom = 1.0 + 0.08*bass;
per_pixel_1=ang = ang + 0.02*bass*rad;
```

**Parser Output:**
- ✅ `.milk parsed successfully`
- ✅ `preset arrays: shapes=1 waves=1 safe=1`
- ✅ Arrays guaranteed (scaffolding working)

**Load Result:**
- ❌ `Preset load failed`
- ❌ `Unexpected token 'return'` (STILL OCCURRING)
- ❌ Fallback blank preset loaded (ECRR: Contain)

**Visual Output:**
- ❌ Blackout: 99.88%
- ❌ Motion: 0
- ❌ Frame size: 18495 bytes (baseline black)

---

## Root Cause Analysis

### Finding
**The 'return' error persists AFTER sanitizeEel() strips all 'return' keywords from equations.**

This indicates the error originates from:
1. **Butterchurn's internal code** (not our equations)
2. **Minified library artifact** (syntax error in butterchurn.min.js itself)
3. **Equation compilation context** (our equations trigger a broken code path)

### Evidence
- Our equations are sanitized (confirmed in logs)
- Arrays are guaranteed (shapes=1, waves=1)
- **Both** custom .milk AND library presets fail identically
- Error location: `new Function(<anonymous>)` inside butterchurn.min.js

### Hypothesis
Butterchurn 2.6.7 minified build may have:
- Broken code path for certain preset structures
- Missing polyfills in headless Chrome
- Incompatibility with our serialization via `page.evaluate()`

---

## Track A Verdict

❌ **BLOCKED** - Surgical fix insufficient

**Attempts Made:**
1. ✅ Schema normalization
2. ✅ Array scaffolding  
3. ✅ EEL sanitization
4. ✅ Safe mode with fallback
5. ❌ All still fail with same error

**Conclusion:** Root cause is **not** in our parser or preset structure. Issue is in Butterchurn library itself or environment incompatibility.

---

## ECRR Execution

✅ **Examine:** Tested Track A fixes thoroughly  
✅ **Contain:** Fallback preset loads on failure  
❌ **Clean:** Cannot resolve without deeper investigation  
✅ **Report:** Findings documented here

**Recommendation:** Escalate per BossCat two-track strategy

---

## Next Steps

### Option 1: Track B (ProjectM Bounded)
- Resume ProjectM container work
- Resolve SDL binary installation
- Timeline: 3-5 hours
- Risk: Medium (build complexity)

### Option 2: Butterchurn Deep Dive
- Switch to unminified Butterchurn source
- Debug equation compilation path
- Timeline: Uncertain (2-8 hours)
- Risk: High (minified internals)

### Option 3: Alternative Engine
- Evaluate other WebGL visualizers
- Timeline: Unknown
- Risk: High (new codebase)

---

## BossCat Decision Required

Track A surgical fix **attempted but insufficient**. Root cause requires one of:
1. ProjectM container completion (Track B)
2. Deep Butterchurn debugging (uncertain timeline)
3. Alternative approach

**Awaiting directive.**

---

**Files Changed:** 2 (milk-parser.js, server.js)  
**LOC Added:** ~110  
**Budget:** ✅ Within limits  
**ECRR:** ✅ Executed (rollback ready)

