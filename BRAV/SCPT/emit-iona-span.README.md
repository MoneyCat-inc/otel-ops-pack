# IONA Synthetic Span Emitter

**File**: `BRAV/SCPT/emit-iona-span.ts`  
**Purpose**: Emit synthetic OTLP spans via HTTP for IONA gate verification  
**Protocol**: HTTP/protobuf  
**Part of**: IONA-GATE-002 - BossCat Gating Framework

---

## Usage

### Quick Test
```bash
pnpm emit
```

### With Custom Configuration
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT='http://127.0.0.1:5321'
export OTEL_SERVICE_NAME='iona-app'
pnpm emit
```

### PowerShell (Windows)
```powershell
$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'http://127.0.0.1:5321'
$env:OTEL_SERVICE_NAME = 'iona-app'
pnpm emit
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://127.0.0.1:5321` | OTLP HTTP endpoint (auto-appends `/v1/traces`) |
| `OTEL_SERVICE_NAME` | `iona-app` | Service name for resource attributes |

---

## Spans Emitted

### 1. `iona.boot` (parent)
- **Kind**: INTERNAL
- **Purpose**: Represents application boot sequence
- **Attributes**: Standard service attributes

### 2. `iona.synthetic` (child)
- **Kind**: INTERNAL  
- **Purpose**: Verification span for gate testing
- **Attributes**: Standard service attributes
- **Parent**: `iona.boot`

---

## Verification

### Check Emitter Works
```bash
pnpm emit
# Should exit with code 0 and no errors
```

### Verify in SigNoz
1. Open: `http://localhost:8080`
2. Navigate: **Traces → Explorer**
3. Filter: `service.name = "iona-app"`
4. Look for: `iona.boot` and `iona.synthetic` spans

---

## Implementation Details

### Why Native ESM (.mjs)?
- Avoids tsx/TypeScript transpiler ESM interop issues
- Direct Node.js execution (`node` not `tsx`)
- Reliable module resolution

### Why `resourceFromAttributes()`?
- Factory function avoids `Resource` constructor issues
- Namespace import (`import * as resources`) bypasses ESM bugs
- Recommended approach per OTel SDK docs

### Why NodeSDK?
- Proper span processor registration
- Handles exporter lifecycle automatically
- Designed for Node.js backend applications

---

## Troubleshooting

### ECONNREFUSED Error
```
Error: connect ECONNREFUSED 127.0.0.1:5321
```

**Solution**: Start SigNoz collector
```bash
docker-compose up -d
# Wait ~30 seconds for services to initialize
```

### Spans Not Visible in SigNoz
1. Check endpoint is reachable:
   ```bash
   curl http://127.0.0.1:5321
   ```

2. Verify SigNoz health:
   ```bash
   curl http://localhost:8080/api/v1/health
   ```

3. Check service name filter in SigNoz UI

### Module Import Errors
- Ensure using `.mjs` extension (not `.ts` or `.js`)
- Verify `@opentelemetry/sdk-node` is installed:
  ```bash
  pnpm list @opentelemetry/sdk-node
  ```

---

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Emit synthetic spans
  env:
    OTEL_EXPORTER_OTLP_ENDPOINT: http://127.0.0.1:5321
    OTEL_SERVICE_NAME: iona-app
  run: pnpm emit
```

### Docker Compose Integration
```yaml
environment:
  - OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:5321
  - OTEL_SERVICE_NAME=iona-app
```

---

## Related Files

- `scripts/verify-iona-gate.ps1` - Gate verification script (calls this emitter)
- `docs/BossCat/IONA_ECRR_REPORT.md` - ECRR documentation
- `package.json` - Contains `emit` script definition

---

## References

- [OpenTelemetry Node.js SDK](https://github.com/open-telemetry/opentelemetry-js)
- [OTLP HTTP Exporter](https://www.npmjs.com/package/@opentelemetry/exporter-trace-otlp-http)
- [SigNoz Documentation](https://signoz.io/docs/)

---

**Last Updated**: 2025-10-07  
**Maintainer**: BossCat OEM / Cursor Implementer  
**Status**: ✅ Production Ready

