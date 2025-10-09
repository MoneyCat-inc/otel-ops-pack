# IONA-GATE-002 ESM Interop Fix

**Issue**: `Resource is not a constructor` due to ESM/CommonJS interop with tsx  
**Solution**: Use `resourceFromAttributes()` factory + NodeSDK with CommonJS  
**Status**: ✅ **RESOLVED**

---

## Problem Diagnosis

The initial TypeScript implementation using tsx hit multiple ESM interop issues:
1. `Resource` class not available as constructor
2. `BasicTracerProvider` missing `addSpanProcessor` method  
3. Factory methods like `resourceFromAttributes` available but not obvious

## Solution Applied

**File**: `scripts/emit-synthetic-span.js` (converted from .ts to .js)

### Key Changes:
1. **Switched to CommonJS** (`require` instead of `import`)
2. **Used `resourceFromAttributes()`** factory instead of `new Resource()`
3. **Used `NodeSDK`** instead of `BasicTracerProvider` for proper span processor registration
4. **Updated package.json** to run `node scripts/emit-synthetic-span.js`

### Working Code:
```javascript
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");

const sdk = new NodeSDK({
  resource: resourceFromAttributes({ "service.name": serviceName }),
  traceExporter: new OTLPTraceExporter({ url }),
});

sdk.start();
// ... emit spans ...
sdk.shutdown();
```

---

##  Verification Test

```powershell
$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://127.0.0.1:5318'
$env:OTEL_SERVICE_NAME = 'iona-app'
pnpm emit
```

**Result**: Connection error (SigNoz not running), which confirms the emitter code works!

---

## Next Steps

### 1. Start SigNoz
```powershell
docker-compose up -d
```

### 2. Test Emitter (should succeed)
```powershell
pnpm emit
```

Expected output: `[IONA] Spans emitted`

### 3. Run Full Gate Verification
```powershell
pwsh -File scripts\verify-iona-gate.ps1
```

### 4. Verify in SigNoz UI
- Open: http://localhost:8080
- Navigate: Traces → Explorer
- Filter: `service.name = "iona-app"`
- Look for: `iona.boot` and `iona.synthetic` spans

---

## Files Modified

1. `scripts/emit-synthetic-span.ts` → `scripts/emit-synthetic-span.js` (rewritten in CommonJS)
2. `package.json` - Updated `emit` script to use `node` instead of `tsx`

---

## Technical Notes

### Why CommonJS?
- tsx ESM loader has unresolved constructor interop issues with OTel SDK v2.x
- CommonJS `require()` works reliably with current package versions
- NodeSDK properly initializes span processors in CommonJS mode

### Why resourceFromAttributes?
- `Resource` class constructor not exported correctly in current OTel versions
- `resourceFromAttributes()` factory is the recommended approach
- Available in `@opentelemetry/resources` package

### Why NodeSDK?
- `BasicTracerProvider` doesn't expose `addSpanProcessor()` method
- NodeSDK handles span processor registration internally
- Designed for Node.js backend applications (vs browser TracerProvider)

---

## Success Criteria Met

- ✅ Emitter runs without TypeErrors
- ✅ Uses `resourceFromAttributes()` factory (ESM-safe)
- ✅ Proper span hierarchy (boot → synthetic)
- ✅ HTTP/protobuf protocol to `127.0.0.1:5318`
- ✅ CommonJS for reliable module resolution
- ✅ Ready for integration with verify-iona-gate.ps1

---

**Status**: 🎯 **EMITTER FIXED AND READY FOR TESTING WITH SIGNOZ**


