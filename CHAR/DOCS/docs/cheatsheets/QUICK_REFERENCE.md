# 🚀 Quick Reference Guide - OTel Observability Kit

## 🔒 **Cross-Origin Isolation**
```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```
**Workaround**: Use `coi-serviceworker` if Service Worker strips headers

## 🎤 **Low-Latency Audio**
```typescript
getUserMedia({ audio: { 
  echoCancellation: false,    // ❌ Disable
  noiseSuppression: false,    // ❌ Disable  
  autoGainControl: false      // ❌ Disable
}})
```
**Target**: < 20ms end-to-end with `AudioContext({ latencyHint: 0 })`

## 🎵 **Pitch Tracking**
- **Primary**: CREPE-tiny (ONNX/WASM)
- **Fallback**: YIN algorithm
- **Smoothing**: Median filter (5-frame) + Kalman
**Workaround**: Auto-fallback to YIN on low-end mobile

## 📊 **Practice Flow JSON**
```json
{ "id": "glide", "type": "drill", "title": "Pitch Glide", 
  "metrics": ["timeInTargetPct"], "successThreshold": { "timeInTargetPct": 0.7 } }
```
**Storage**: IndexedDB local-first, 60 FPS metrics computation

## 📈 **Analytics A/B Tests**
- **E1**: Signup timing (lesson-first vs signup-first)
- **E2**: Permission primer vs native
**Events**: `screen_view`, `permission_requested`, `mic_session_start/end`, `activation`
**Delivery**: `sendBeacon` with ring buffer to prevent data loss

## 🔊 **Loudness Guardrails**
- **Heuristic**: ≥ 5s @ 0.8 RMS = strain
- **Calibration**: Device-specific thresholds
- **Bluetooth**: 20% sensitivity reduction
**Never push volume** - always provide cooldown prompts

## ⚙️ **Background Workers**
- **Budgets**: ≤ 2 jobs/pass, ≤ 10 files, ≤ 200 LOC
- **Kill Switch**: `.agent/LOCK` → stops immediately
- **Bootstrap**: `pnpm agent:doctor` if `agent:start` fails

## ♿ **UI & A11y**
- **Never**: Inline styles, `dangerouslySetInnerHTML`
- **Always**: ARIA live regions, proper labels, keyboard nav
- **Colors**: WCAG AA contrast ratios
- **Motion**: Respect `prefers-reduced-motion`

## 📉 **SigNoz Dashboard**
- **Data Source**: LOGS (not Prometheus!)
- **Query**: `body contains "agent_queue" | json | unwrap fieldName`
- **Time Range**: "Last 24 hours" or "Last 7 days"
**Test First**: Go to Logs → Explorer before creating panels

## 🔍 **SigNoz Queries**
```sql
-- Queue data
body contains "agent_queue"

-- Recent activity  
timestamp > now() - 15m

-- Service logs
service.name = "windows-host"
```

## 🚨 **Emergency Fixes**

### **Dashboard Shows No Panels**
1. Check time range (expand to 24h+)
2. Verify LOGS data source (not Prometheus)
3. Test query in Logs Explorer first

### **Audio Latency Too High**
1. Disable all DSP in getUserMedia
2. Use `latencyHint: 0` in AudioContext
3. Monitor `audioCtx.baseLatency`

### **Cross-Origin Fails**
1. Check COOP/COEP headers in Network tab
2. Use `coi-serviceworker` as fallback
3. Configure CDN CORS headers

### **Worker Fails to Start**
1. Run `pnpm agent:doctor`
2. Check `.agent/LOCK` file
3. Verify PATH configuration

## 📋 **Testing Checklist**
- [ ] No inline styles used
- [ ] ARIA labels on all interactive elements
- [ ] Keyboard navigation works
- [ ] Color contrast meets WCAG AA
- [ ] SigNoz uses LOGS data source
- [ ] Audio DSP disabled
- [ ] Worker budgets enforced
- [ ] Kill switch functional

## 🎯 **Quick Commands**
```bash
# SigNoz health
curl http://localhost:8080/api/v1/health

# Check worker status
cat .agent/status.json

# Test audio
pwsh -File scripts/test-audio-latency.ps1

# Verify dashboard
pwsh -File scripts/verify-dashboard-import.ps1
```

---
**📂 Full Details**: `docs/cheatsheets/`  
**🚨 Rule**: Check cheat sheets FIRST before implementing solutions!
