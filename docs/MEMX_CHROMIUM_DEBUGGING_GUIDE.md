# MEMX Chromium Debugging Guide

## Overview

This guide addresses Chromium-specific issues with MEMX (Memory Observation Layer) and provides debugging strategies for cross-origin isolation and SharedArrayBuffer support.

## Known Issues

### 1. Cross-Origin Isolation Failures
**Symptoms:**
- `window.crossOriginIsolated` returns `false` in Chromium
- SharedArrayBuffer is undefined
- MEMX tests fail in Chromium but pass in Firefox/WebKit

**Root Cause:**
Chromium has stricter requirements for cross-origin isolation headers compared to Firefox and Safari.

### 2. SharedArrayBuffer Unavailability
**Symptoms:**
- `typeof SharedArrayBuffer === 'undefined'`
- Audio processing fails
- Memory monitoring unavailable

**Root Cause:**
SharedArrayBuffer requires cross-origin isolation to be properly configured.

## Solutions

### 1. Enhanced Next.js Configuration

Use `next.config.chromium-fix.js` for Chromium compatibility:

```javascript
// Key headers for Chromium
headers: [
  {
    key: 'Cross-Origin-Embedder-Policy',
    value: 'require-corp',
  },
  {
    key: 'Cross-Origin-Opener-Policy',
    value: 'same-origin',
  },
  {
    key: 'Permissions-Policy',
    value: 'cross-origin-isolated=()',
  },
]
```

### 2. Browser Compatibility Detection

The `MemxDebugInfo` component provides real-time browser compatibility status:

- ✅ **Green indicators**: Feature supported
- ❌ **Red indicators**: Feature not supported
- ⚠️ **Yellow warnings**: Chromium-specific issues detected

### 3. Enhanced Testing Strategy

#### Debug Tests
Run Chromium-specific debug tests:
```bash
npx playwright test --config=playwright.chromium.config.ts tests/memx-chromium-debug.spec.ts
```

#### Enhanced Tests
Run comprehensive MEMX tests:
```bash
npx playwright test tests/memx-enhanced.spec.ts
```

## Debugging Steps

### Step 1: Check Cross-Origin Isolation
```javascript
// In browser console
console.log('Cross-origin isolated:', window.crossOriginIsolated);
console.log('SharedArrayBuffer available:', typeof SharedArrayBuffer !== 'undefined');
```

### Step 2: Verify Headers
```bash
# Check response headers
curl -I http://localhost:3000/labs/memx
```

Look for:
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Opener-Policy: same-origin`
- `Permissions-Policy: cross-origin-isolated=()`

### Step 3: Test SharedArrayBuffer Creation
```javascript
// In browser console
try {
  const sab = new SharedArrayBuffer(1024);
  console.log('SharedArrayBuffer created successfully');
} catch (error) {
  console.error('SharedArrayBuffer creation failed:', error);
}
```

## Test Results Analysis

### Firefox/WebKit (✅ Working)
- Cross-origin isolation: Enabled
- SharedArrayBuffer: Available
- MEMX functionality: Fully operational

### Chromium (❌ Issues)
- Cross-origin isolation: Disabled (needs header fixes)
- SharedArrayBuffer: Unavailable
- MEMX functionality: Limited

## Chromium-Specific Workarounds

### 1. Development Mode
For development, use Chromium with specific flags:
```bash
# Launch Chrome with cross-origin isolation
google-chrome --disable-web-security --enable-shared-array-buffer --cross-origin-isolated
```

### 2. Alternative Testing
Use Firefox or Safari for MEMX testing when Chromium issues persist.

### 3. Fallback Implementation
Implement graceful degradation when SharedArrayBuffer is unavailable:

```javascript
if (typeof SharedArrayBuffer !== 'undefined') {
  // Use SharedArrayBuffer for high-performance audio processing
  const audioBuffer = new SharedArrayBuffer(4096);
} else {
  // Fallback to regular ArrayBuffer
  const audioBuffer = new ArrayBuffer(4096);
}
```

## Monitoring and Alerts

### Browser Compatibility Alerts
The system automatically detects and reports:
- Cross-origin isolation status
- SharedArrayBuffer availability
- Browser-specific issues

### Performance Monitoring
Track MEMX performance across browsers:
- Audio processing latency
- Memory usage patterns
- Frame rate stability

## Next Steps

1. **Apply Chromium fixes** to production configuration
2. **Monitor browser compatibility** in real-time
3. **Implement fallback strategies** for unsupported browsers
4. **Update CI/CD pipelines** to test all browser combinations

## Troubleshooting Commands

```bash
# Run Chromium debug tests
npx playwright test --config=playwright.chromium.config.ts tests/memx-chromium-debug.spec.ts

# Check MEMX page in Chromium
npx playwright test --config=playwright.chromium.config.ts --project=chromium-debug tests/memx.spec.ts

# Verify headers
curl -I http://localhost:3000/labs/memx | grep -i "cross-origin\|permissions"

# Check browser compatibility
open http://localhost:3000/labs/memx
# Open browser console and run:
# console.log('Cross-origin isolated:', window.crossOriginIsolated);
# console.log('SharedArrayBuffer available:', typeof SharedArrayBuffer !== 'undefined');
```

## References

- [MDN: Cross-Origin Isolation](https://developer.mozilla.org/en-US/docs/Web/API/Window/crossOriginIsolated)
- [MDN: SharedArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer)
- [Chrome Security: Cross-Origin Isolation](https://web.dev/cross-origin-isolation-guide/)
- [Next.js: Headers Configuration](https://nextjs.org/docs/advanced-features/security-headers)
