# OTel + Resonai Integration Status

## ✅ Completed Setup

### 1. Git Submodule Integration
- ✅ Resonai added as submodule under `third_party/resonai`
- ✅ `otel-integration` branch created for OTel-specific development
- ✅ Submodule configured with quality-of-life settings
- ✅ Marked as vendored code in `.gitattributes`

### 2. OTel Collector Configuration
- ✅ Created `collector/otel-local.yaml` with:
  - HTTP OTLP receiver on port 14318
  - gRPC OTLP receiver on port 14317
  - Windows Event Log collection (Application, System)
  - File log collection from `C:\logs\**\*.log`
  - OTLP exporter to SigNoz on port 4317

### 3. Verification Scripts
- ✅ Created `verify-integration.ps1` for health checks
- ✅ Created `setup-resonai-env.ps1` for environment setup
- ✅ Fired test canaries (Event Log, OTLP HTTP, file logs)

## 🚀 Current Status

### Services Running
- **OTel Collector**: Running with `otelcol-contrib --config collector\otel-local.yaml`
- **Resonai Dev Server**: Running with `pnpm dev` (should be on port 3000)
- **SigNoz**: Should be accessible at `http://localhost:8080`

### Ports Expected
- `14317` - OTel gRPC receiver
- `14318` - OTel HTTP receiver  
- `3000` - Resonai dev server
- `8080` - SigNoz UI
- `4317` - SigNoz OTLP receiver

## 🔧 Next Steps

### 1. Verify Services
```powershell
# Check if services are running
.\verify-integration.ps1

# Check specific ports
netstat -an | findstr "14317\|14318\|3000\|8080"
```

### 2. Access Applications
- **Resonai**: Open `http://localhost:3000` in Firefox (HTTPS recommended for mic)
- **SigNoz**: Open `http://localhost:8080` to view logs/metrics
- **Browser Console**: Check `window.crossOriginIsolated` (should be true)

### 3. Environment Variables for Resonai
Since `.env.local` creation was blocked, set these manually or via script:

```powershell
# In Resonai directory
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/json"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:14318"
$env:OTEL_SERVICE_NAME = "resonai-local"
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=dev"
```

### 4. Test Integration
1. Open Resonai in browser
2. Grant microphone permissions
3. Check SigNoz for `resonai-local` service logs
4. Look for audio processing metrics

## 📊 Expected SigNoz Data

### Logs to Look For
- Service: `resonai-local`
- Source: `canary-app` (from test canaries)
- Windows Event Log entries with source `OTelCanary`
- File logs from `C:\logs\canary.log`

### Queries to Try
```
# All logs from Resonai
service.name = "resonai-local"

# Test canaries
message contains "canary"

# Windows Event Logs
log.source = "windows_event_log"
```

## 🛠️ Troubleshooting

### If Services Not Running
```powershell
# Restart collector
otelcol-contrib --config collector\otel-local.yaml

# Restart Resonai
cd third_party\resonai
pnpm dev
```

### If Ports Not Listening
```powershell
# Check what's using ports
netstat -ano | findstr "14317\|14318\|3000"

# Kill processes if needed
taskkill /PID <PID> /F
```

### If SigNoz Not Accessible
- Check if SigNoz is running in WSL2/Docker
- Verify port 8080 is not blocked
- Check SigNoz logs for errors

## 📝 Follow-up Tasks Available

1. **Tiny OTLP exporter** for Resonai (traces/logs) with local-first & redaction
2. **SigNoz dashboard JSON** for TTV p50/p90, Mic grant %, Activation %, error rates
3. **Playwright smoke test** that spins Resonai and asserts OTLP canaries
4. **COOP/COEP headers** for Resonai dev server (Firefox AudioWorklet support)
5. **Firefox mic optimization** validation script

## 🎯 Success Criteria

- ✅ Resonai accessible at `http://localhost:3000`
- ✅ SigNoz accessible at `http://localhost:8080`
- ✅ OTel collector receiving signals on ports 14317/14318
- ✅ Test canaries visible in SigNoz logs
- ✅ `window.crossOriginIsolated` returns true in browser console
- ✅ Microphone permissions granted and audio processing working

---

**Integration Status**: 🟡 **In Progress** - Services started, verification needed
**Next Action**: Run `.\verify-integration.ps1` and check browser access



