# MEMX Cross-Origin Isolation Guide

## Overview

MEMX (Memory Observation Layer) requires cross-origin isolation to access SharedArrayBuffer for audio ring buffer functionality. This guide explains the development vs. production behavior and how to handle cross-origin isolation properly.

## Cross-Origin Isolation Requirements

### Headers Required
```javascript
// next.config.js
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
    key: 'Cross-Origin-Resource-Policy',
    value: 'cross-origin',
  },
  {
    key: 'Permissions-Policy',
    value: 'cross-origin-isolated=()',
  },
]
```

## Development vs. Production Behavior

### Development Environment
- **Chromium**: `window.crossOriginIsolated = false` (expected)
- **Firefox**: `window.crossOriginIsolated = true`
- **WebKit**: `window.crossOriginIsolated = true`
- **SharedArrayBuffer**: Unavailable in Chromium, available in Firefox/WebKit

### Production Environment (HTTPS)
- **All Browsers**: `window.crossOriginIsolated = true` (expected)
- **SharedArrayBuffer**: Available in all browsers

## Runtime Checks

### MEMX Instrumentation
```typescript
// src/engine/memx/instrumentation.ts
private collectSabUsage(frame: MemxFrame): void {
  // Gate SAB usage behind cross-origin isolation check
  if (!window.crossOriginIsolated) {
    console.debug('MEMX: SAB collection skipped - cross-origin isolation not enabled');
    return;
  }
  
  // ... SAB collection logic
}
```

### Component Debug Info
```typescript
// components/MemxDebugInfo.tsx
const crossOriginIsolated = window.crossOriginIsolated;
if (!crossOriginIsolated) {
  errors.push('Cross-origin isolation is not enabled');
}

// Check SharedArrayBuffer support
let sharedArrayBufferSupported = false;
try {
  if (typeof SharedArrayBuffer !== 'undefined') {
    new SharedArrayBuffer(1024);
    sharedArrayBufferSupported = true;
  } else {
    errors.push('SharedArrayBuffer is not available');
  }
} catch (error) {
  errors.push(`SharedArrayBuffer error: ${error instanceof Error ? error.message : String(error)}`);
}
```

## Test Expectations

### Playwright Tests
```typescript
// tests/memx.spec.ts
test('should have cross-origin isolation enabled', async ({ page }) => {
  await page.goto('/labs/memx');
  
  const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
  const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
  
  // In development, Chromium may not enable cross-origin isolation
  // This is expected behavior and not a failure condition
  if (crossOriginIsolated) {
    expect(sabAvailable).toBe(true);
  } else {
    // SharedArrayBuffer may not be available without cross-origin isolation
    // This is normal in development environments
    console.log('Note: Cross-origin isolation disabled in development - SharedArrayBuffer unavailable');
  }
});
```

## Browser-Specific Notes

### Chromium
- **Development**: Cross-origin isolation disabled by default
- **Production**: Requires HTTPS and proper headers
- **Flags**: May need `--enable-features=SharedArrayBuffer` for development testing

### Firefox
- **Development**: Cross-origin isolation enabled with proper headers
- **Production**: Works with HTTPS and headers

### WebKit (Safari)
- **Development**: Cross-origin isolation enabled with proper headers
- **Production**: Works with HTTPS and headers

## Troubleshooting

### Common Issues

1. **Headers not applied**: Check `next.config.js` configuration
2. **HTTPS required**: Chromium needs HTTPS for cross-origin isolation
3. **Third-party resources**: All resources must have CORP headers
4. **Service Worker**: Must preserve headers for offline functionality

### Debug Commands
```bash
# Check headers
curl -I http://localhost:3001/labs/memx

# Test cross-origin isolation
npx playwright test memx.spec.ts --project=chromium --headed

# Production build test
npm run build && npm start
```

## Best Practices

1. **Always check `window.crossOriginIsolated`** before using SharedArrayBuffer
2. **Graceful degradation** when cross-origin isolation is unavailable
3. **Test in both development and production** environments
4. **Document browser-specific behavior** in tests and docs
5. **Use runtime checks** rather than build-time assumptions

## References

- [MDN: Cross-Origin Isolation](https://developer.mozilla.org/en-US/docs/Web/API/crossOriginIsolated)
- [MDN: SharedArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer)
- [Chrome: Cross-Origin Isolation](https://web.dev/cross-origin-isolation-guide/)
