# GLEW/GLAD Inventory - PR #942 Migration

**Date:** 2026-01-23  
**Purpose:** Inventory of GLEW/GLAD usage before PR #942 migration

## Search Results

### GLEW Usage
- **Result:** No GLEW usage found in codebase
- Searched for: `glew`, `GL/glew.h`, `glewInit`
- **Status:** ✅ No GLEW dependencies

### GLAD Usage  
- **Result:** No GLAD usage found in application code
- Searched for: `glad`
- **Status:** ⚠️ Note: projectM (after PR #942) will vendor GLAD internally

### GL Proc Loading
- **Result:** Resolver now implemented for GLX/SDL/EGL
- Implemented in: `gl_proc_resolver.cpp/hpp`
- **Status:** ✅ Resolver available for new projectM API

### Build Files
- **CMakeLists.txt:** Added for native integration build
- **Dockerfile:** Builds projectM from source and fetches PR #942
  - Uses: `cmake` with `-DENABLE_SDL_UI=ON`
  - No explicit GLEW/GLAD dependencies in app build

## Current Architecture

### ProjectM Usage Pattern
- **Current runtime:** Spawns `projectMSDL` as separate process
- **Location:** `server.js` line 217
- **Command:** `spawn('projectMSDL', [...])`
- **Library Integration:** Available via `projectm_renderer.cpp/hpp` (not yet wired into server)

### C++ Components
- `audio-injector.cpp/hpp` - Audio buffer management (no GL/OpenGL)
- `projectm-injector.cpp/hpp` - Interface for projectM audio feed (no actual library calls)
- `pm-audio-bridge.cpp` - FIFO monitor (no GL/OpenGL)
- `audio-integration-test.cpp` - Test harness (no actual projectM library)

## Migration Requirements

### 1. Library Integration
- ✅ New C++ component links against libprojectM (`projectm_renderer.cpp/hpp`)
- ✅ GL context creation/management implemented (GLX)
- ✅ GL proc resolver implemented (GLX/SDL/EGL)
- ✅ `projectm_create_with_opengl_load_proc()` wired

### 2. Build System Updates
- ✅ Added CMakeLists.txt for native components
- ✅ Dockerfile builds PR #942 and native integration
- ✅ Context ordering enforced before projectM init

### 3. Platform Support
- **Current:** Linux/Xvfb (headless X server)
- **GL Backend:** GLX (via Xvfb +extension GLX)
- **Resolver:** Should use `glXGetProcAddressARB`

## Next Steps

1. ✅ Inventory complete
2. ✅ Library integration component created
3. ✅ GL proc resolver implemented
4. ✅ Build system updated
5. ✅ Smoke test added
6. ⏳ Build + runtime validation (gl-diagnostics + projectm-smoke-test)
