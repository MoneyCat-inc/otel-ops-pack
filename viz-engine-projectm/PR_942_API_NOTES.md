# PR #942 API Integration Notes

**Date:** 2026-01-23  
**Purpose:** Notes on integrating projectM PR #942 API

## Verified API Signature (PR #942)

The PR #942 headers define the resolver-aware creation API as follows:

```c
// projectM-4/core.h
projectm_handle projectm_create_with_opengl_load_proc(
    void* (*load_proc)(const char* name, void* user_data),
    void* user_data
);
```

### Updated Files (Post-Verification):

1. **`projectm_renderer.cpp`** (line ~100)
   - Uses `projectm_create_with_opengl_load_proc(resolver, nullptr)`
   - Configures window size and loads preset file

2. **`gl_proc_resolver.hpp`** (line ~12)
   - `projectm_gl_load_proc_t` updated to accept `void* user_data`

3. **`projectm_renderer.hpp`** (forward declarations)
   - Includes `projectM-4/projectM.h` directly
   - Uses `projectm_handle` from projectM headers

## Integration Checklist

- [x] Verify exact `projectm_create_with_opengl_load_proc()` signature
- [x] Verify `projectm_gl_load_proc_t` typedef
- [x] Update `projectm_renderer.cpp` with actual API call
- [x] Update includes to use actual projectM headers
- [ ] Test compilation against PR #942 branch
- [x] Verify GL context ordering (context current before projectM creation)
- [ ] Test smoke test passes

## Current Implementation Status

✅ GL proc resolver implemented (GLX path)  
✅ GL context creation/management implemented  
✅ Context ordering enforced (context current before projectM creation)  
✅ projectM API integration (signature verified)  
✅ Build system updates (header path adjusted)  

## Next Steps

1. Build libprojectM from PR #942 (see Dockerfile update)
2. Run `gl-diagnostics` to confirm GL resolver is active
3. Run `projectm-smoke-test` with a valid preset file or URL
