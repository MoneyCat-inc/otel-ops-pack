# GLAD Symbol Conflict Prevention - PR #942 Migration

**Date:** 2026-01-23  
**Purpose:** Strategy for preventing GLAD symbol conflicts after PR #942

## Problem Statement

After PR #942, projectM vendors GLAD statically. If this application also links GLAD, we risk:
- Duplicate symbol definitions at link time
- Runtime symbol interposition conflicts
- Undefined behavior from conflicting GL function pointers

## Current Status

✅ **No GLAD in application code** - Inventory shows zero GLAD usage  
✅ **projectM will vendor GLAD** - After PR #942, projectM includes GLAD internally

## Strategy: No Action Required (Current State)

Since the application does **not** currently link GLAD, we follow **Strategy A** from the instructions:

### Strategy A: Remove GLAD from the app (Preferred)

**Status:** ✅ Already compliant

- Application code does not use GLAD
- Application uses platform-specific GL proc loading (GLX/SDL/EGL)
- No GLAD symbols in application binaries
- projectM's vendored GLAD is isolated within libprojectM

## Verification Steps

### Build-Time Verification

After building with PR #942 projectM, verify no conflicts:

```bash
# Check for GLAD symbols in application binary
nm -C --defined-only /usr/local/bin/projectm-smoke-test | grep -i glad

# Expected: No output (no GLAD symbols in app)

# Check projectM library for GLAD symbols (should be present)
nm -C --defined-only /usr/local/lib/libprojectM.so | grep -i glad | head -5

# Expected: GLAD symbols present (vendored in projectM)
```

### Link-Time Verification

If linking fails with duplicate symbol errors, investigate:

```bash
# Check what brings in GLAD
ldd /usr/local/bin/projectm-smoke-test | grep -i glad

# Expected: No GLAD libraries linked directly
```

### Runtime Verification

Monitor for runtime issues:
- GL function pointer mismatches
- Unexpected GL errors
- Rendering artifacts

## Future Considerations

### If Application Needs GLAD Later

If the application later needs GLAD for its own rendering:

1. **Option 1 (Preferred):** Use platform-specific proc loading
   - Continue using GLX/SDL/EGL directly
   - No GLAD dependency needed

2. **Option 2:** Rename/prefix application's GLAD
   - Regenerate GLAD with custom prefix (e.g., `app_glad_*`)
   - Prevents symbol collision with projectM's GLAD

3. **Option 3:** Shared library isolation
   - Build projectM as shared library
   - Ensure symbol visibility is controlled
   - Less reliable than Option 1 or 2

## Implementation Notes

- ✅ GL proc resolver uses platform APIs (GLX/SDL/EGL) directly
- ✅ No GLAD dependency in application build
- ✅ projectM's GLAD is internal to libprojectM
- ✅ Symbol namespace separation maintained

## Acceptance Criteria

- [x] No GLAD in application code (verified by inventory)
- [x] GL proc resolver uses platform APIs (not GLAD)
- [x] Build system does not link GLAD
- [ ] Verify no duplicate symbols after PR #942 build (pending PR merge)
- [ ] Smoke test passes without symbol conflicts (pending PR merge)

## Conclusion

**No action required** - Application is already compliant with Strategy A. The GL proc resolver uses platform-specific APIs (GLX), avoiding any GLAD dependency. projectM's vendored GLAD will be isolated within libprojectM, preventing conflicts.
