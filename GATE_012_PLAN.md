# Gate #012 - ProjectM Native .milk Renderer

**Date:** 2025-10-24 10:30 UTC  
**Authority:** BossCat OEM  
**Track:** B (ProjectM Container) - Bounded, Low-Risk  
**Status:** 🟢 **AUTHORIZED**

---

## Objective

Replace blocked Butterchurn visual path with **ProjectM native .milk renderer** while preserving:
- ✅ Audio bridge (production-ready)
- ✅ Scorebot integration (unchanged)
- ✅ Authoring scripts (reusable)
- ✅ API compatibility (`/preset`, `/snap.jpg`, `/stats`)

---

## Acceptance Criteria

Test with **3 presets** (simple, echo/zoom, bass-reactive):

1. ✅ **Blackout ≤20%** (average over 10 frames)
2. ✅ **motion_ok = true** (scorebot validation)
3. ✅ **reactivity_r ≥0.35** (with audio feeder)
4. ✅ **/preset switch ≤1.5s** (hot-reload performance)
5. ✅ **Aspect OK** (1920×1080, no DPI skew)

---

## Architecture (Minimal)

```
audio-feeder.ps1 → POST /audio → md3-audio-handler
                                       ↓ writes
                                    FIFO (/dev/shm/md3.pcm)
                                       ↓ reads
                                  ProjectM SDL
                                       ↓ renders to
                                    Xvfb :99
                                       ↓ captured by
                                  GET /snap.jpg (ffmpeg x11grab)
                                       ↓ consumed by
                                    Scorebot
```

**Containers:** 2 (pm-engine, scorebot)  
**Audio:** FIFO-based (no PulseAudio complexity)  
**Capture:** Xvfb + ffmpeg (simple, observable)

---

## Implementation Plan (2 Jobs)

### Job 1: Container Skeleton (≤200 LOC)
**Files:**
- `viz-engine-projectm/Dockerfile` - ProjectM SDL build
- `viz-engine-projectm/pm-run.sh` - Xvfb + ProjectM launcher
- `viz-engine-projectm/pm-settings.ini` - ProjectM config
- `viz-engine-projectm/server.js` - HTTP shim (/stats stub)
- `docker-compose.viz.yml` - Add pm-engine service

**Acceptance:** `/stats` returns OK, container healthy

---

### Job 2: Preset Control + Validation (≤200 LOC)
**Files:**
- `viz-engine-projectm/server.js` - Add `/preset`, `/snap.jpg`
- `scripts/pm-reload-preset.ps1` - Hot-reload script

**Acceptance:** 3 presets pass Gate #012 criteria

---

## Guardrails (ECRR + AUTO-BOTS)

### Budgets
- **Files:** ≤10 per job
- **LOC:** ≤200 per job
- **Jobs:** ≤2 total
- **Lane:** `viz` sublane (temporary)

### Process
- **Single-writer lock:** `.agent/LOCK` respected
- **B-monitor:** Verifies budgets, never writes
- **Kill-switch:** Immediate stop on breach
- **Evidence:** ECRR JSON per job

### Rollback Triggers
- Health check fails >3 retries
- Budget breach (files or LOC)
- Timeline >2h per job
- Scorebot validation fails after fixes

---

## Timeline

**Job 1:** 2-3 hours (container + skeleton)  
**Job 2:** 1-2 hours (preset + validation)  
**Total:** 3-5 hours (bounded)

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| SDL binary missing | Use system projectM if build fails |
| Xvfb flakiness | Explicit health check + restart policy |
| Audio FIFO issues | Fallback to silent mode for visual testing |
| Preset search path | Normalize to single PM_PRESET_DIR |
| Scope creep | Enforce via AUTO-BOTS lane runner |

---

## Success Metrics

**Gate #012 PASS** requires:
- ✅ 3 presets render (non-black frames)
- ✅ Scorebot validation passes
- ✅ Audio reactivity maintained
- ✅ Evidence packaged
- ✅ BOSSCAT_LOG updated

---

## Fallback Plan

If ProjectM build fails after Job 1:
1. **ECRR: Contain** - Stop work immediately
2. **Report** - Document build issues
3. **Escalate** - Request BossCat guidance
4. **Preserve** - Audio bridge + parser improvements remain AMBER+

---

**Status:** 🟢 **AUTHORIZED TO PROCEED**  
**Next:** Execute Job 1 (container skeleton)  
**Evidence:** Capture at each step

