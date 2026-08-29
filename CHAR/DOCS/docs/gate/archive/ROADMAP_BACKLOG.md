# Roadmap Backlog - Visual Rendering

**Updated:** 2025-10-24  
**Authority:** BossCat OEM

---

## 🎯 Backlog Items

### 1. ProjectM SDL Runtime Resolution
**ID:** VIZ-001  
**Type:** Technical Investigation  
**Priority:** Medium  
**Status:** Queued  
**Estimate:** 3-5 hours

**Description:**
Resolve ProjectM SDL binary installation/execution issue preventing visual rendering in containerized environment.

**Context:**
- libprojectM compiles successfully
- SDL frontend build flags set correctly
- Expected binaries (projectMSDL, projectM-sdl) not found after install
- Issue persisted across 3 attempts (Gate #012 attempts 1, 2a, 2b)

**Investigation Areas:**
1. CMake build logs - verify SDL frontend actually builds
2. Installation paths - check where binaries are placed
3. System package - try `apt install projectm` as alternative
4. Alternative frontends - try PulseAudio frontend instead of SDL
5. Python bindings - investigate pyprojectM as wrapper
6. Pre-built images - search Docker Hub for working ProjectM containers

**Success Criteria:**
- ProjectM process launches and renders
- /snap.jpg returns non-black frames (>50KB)
- Visual output validated by scorebot
- Integration with existing audio bridge (reactivity ≥0.35)

**Dependencies:** None (standalone)

**Risks:**
- Build system complexity
- Undocumented runtime requirements
- May require alternative approach

---

### 2. Butterchurn Deep-Dive (Alternative)
**ID:** VIZ-002  
**Type:** Technical Investigation  
**Priority:** Low  
**Status:** Queued  
**Estimate:** 5-8 hours

**Description:**
Investigate Butterchurn minified library equation compiler error using unminified source.

**Context:**
- Minified Butterchurn 2.6.7 throws "Unexpected token 'return'" in headless Chrome
- Error in internal `new Function()` during equation compilation
- Parser sanitization (sanitizeEel) doesn't resolve issue
- Array scaffolding (ensureVizScaffold) doesn't resolve issue

**Investigation Areas:**
1. Switch to unminified Butterchurn source
2. Debug equation compilation path
3. Identify missing polyfills for headless Chrome
4. Test with different Butterchurn versions
5. Investigate preset serialization via page.evaluate()

**Success Criteria:**
- Presets load without errors
- Visual output (non-black frames)
- Scorebot validation passes

**Dependencies:** VIZ-001 (if ProjectM succeeds, this becomes optional)

---

### 3. Alternative Visualization Engine
**ID:** VIZ-003  
**Type:** Research & Prototype  
**Priority:** Low  
**Status:** Backlog  
**Estimate:** 8-12 hours

**Description:**
Evaluate and prototype alternative WebGL-based visualization engines.

**Candidates:**
- Three.js + custom shaders
- p5.js with audio reactivity
- Custom WebGL implementation
- Other Milkdrop-compatible engines

**Success Criteria:**
- Audio-reactive visuals
- Preset authoring capability
- Performance: 30+ fps
- Integration with existing audio bridge

---

## 📊 Priority Matrix

| Item | Priority | Estimate | Risk | Value |
|------|----------|----------|------|-------|
| VIZ-001 (ProjectM) | Medium | 3-5h | Medium | High (native .milk) |
| VIZ-002 (Butterchurn) | Low | 5-8h | High | Medium (WebGL) |
| VIZ-003 (Alternative) | Low | 8-12h | High | Unknown |

**Recommendation:** Start with VIZ-001 (ProjectM) when resources available

---

## 🚀 How to Resume

### Pre-Work
1. Review `GATE_012_BLOCKER_REPORT.md`
2. Read `GATE_012_CLOSURE_DEFERRED.md`
3. Check staged code in `viz-engine-projectm/`

### Investigation Steps
1. Examine CMake build output for SDL frontend
2. Search for binaries in build artifacts
3. Test system package as alternative
4. Document findings

### Success Path
1. Resolve binary location/execution
2. Verify visual output
3. Integrate with audio bridge
4. Run scorebot validation
5. Document and certify

---

**Status:** Backlog items queued for future work  
**Current Focus:** AMBER deployment (audio bridge)

