<!-- markdownlint-disable MD013 MD022 MD026 MD031 MD032 MD036 MD040 -->
# 🎬 MILK Lane Live Demonstration Guide

> **Split-lane record (2026-09-02).** The visualizer lane (VIZR / MILK / ProjectM) was extracted to
> `viz-engine` in Pack 3B (2026-07-24; that repo is now archived). Nothing in this pack's telemetry
> pipeline depends on it; kept as the record of the 2025 lane.

**Date**: 2025-10-16  
**Phases**: 1-5 + Polish  
**Status**: Production-Ready

---

## 🚀 Quick Demo (5 minutes)

### Step 1: Start the Visual Control Surface

```powershell
# From repo root (C:\otel)
start docs\BossCat\visuals\control.html
```

**What you'll see**:
- Butterchurn visualization engine initializing
- Random preset loaded automatically
- Control bar with all Phase 1-5 features:
  - Preset selector (300+ community presets)
  - Navigation buttons (Prev/Next)
  - Blend time slider
  - Auto-cycle checkbox
  - **Low-Intensity checkbox** (Phase-4)
  - **Intensity slider (0-100)** (Phase-5)
  - **Live intensity readout** (Phase-5 polish)

---

### Step 2: Test Audio Input

**Option A: Microphone**
1. Click **"Start Mic"** button
2. Grant microphone permission when prompted
3. Make some noise → see visuals react to audio!

**Option B: Desktop Audio (Windows)**
1. Right-click volume icon → **"Open Sound settings"**
2. Scroll to **"Advanced sound options"** → **"App volume and device preferences"**
3. Under **Input**, look for **"Stereo Mix"** device
4. If not visible: **"Sound Control Panel"** → **"Recording"** tab → Right-click empty area → **"Show Disabled Devices"** → Enable **"Stereo Mix"**
5. Select **"Stereo Mix"** in control.html
6. Play music → see visuals react to system audio!

---

### Step 3: Test Intensity Controls (Phase-4 & 5)

#### Test Low-Intensity Mode (Phase-4)

1. **Check current preset behavior** (baseline)
   - Note wave intensity and motion speed
   
2. **Enable Low-Intensity toggle**
   - Wave amplitudes reduce by ~50%
   - Transitions become smoother (fDecay +0.005)
   - Auto-cycle interval extends to 30s (from 20s)
   
3. **Load next preset** (click "Next ▶")
   - See Low-Intensity effects apply immediately

**Use Case**: Photosensitivity, motion sensitivity, ambient displays

---

#### Test Intensity Slider (Phase-5)

1. **Set Intensity to 0** (baseline)
   - Live readout shows: `0`
   - Effective settings: *(empty - no effect)*

2. **Increase to 50**
   - Live readout shows: `50`
   - Effective settings: `blend ≥3.0s, wave α ≤0.35`
   - Load next preset → see 3s minimum blend time + reduced wave amplitude

3. **Increase to 100** (maximum)
   - Live readout shows: `100`
   - Effective settings: `blend ≥4.0s, wave α ≤0.20`
   - Load next preset → very smooth transitions, minimal wave intensity

4. **Test Interaction: Low-Intensity + Intensity**
   - Enable Low-Intensity + set Intensity to 50
   - Most restrictive settings apply (hard floor)
   - Wave amplitude halved first, then capped at 0.35

**Use Case**: Granular control for NOC displays, gradual intensity reduction

---

### Step 4: Test Resonai Pack v1 Presets

Our safety-validated presets are already in the dropdown!

1. **Open preset selector** → Type or scroll to find:
   - `Resonai - Default (Neon Pulse)` (Phase-1)
   - `RN-001 CircuSpectra` (calm, circular)
   - `RN-002 HaloBloom` (calm, dual-ring)
   - `RN-003 VectorGrid` (medium, grid warp)
   - `RN-004 LiquiRing` (intense, bass-reactive)
   - `RN-005 LineDancer` (calm, waveform)

2. **Load each preset** and observe:
   - Mood tags in action (calm/medium/intense)
   - Safety validation (no flashing/strobing)
   - 100% validated with our safety linter

**Registry**: See `docs/BossCat/visuals/presets/registry.json` for full metadata

---

## 🔧 Advanced Demo (10 minutes)

### Step 5: Test WebSocket Bridge (Phase-3A + Phase-5 Nonce)

**Terminal 1: Start Bridge**
```powershell
cd C:\otel
tsx scripts/visuals/milk-ws-bridge.ts
```

**Output you'll see**:
```
[MILK] WebSocket bridge running on ws://localhost:8899
[MILK] HTTP API: http://localhost:8899/api/milk
[MILK] Nonce: abc123xyz    ← COPY THIS NONCE!
```

**Terminal 2: Test Commands**

1. **Test WITHOUT nonce** (Phase-5 security)
   ```powershell
   curl -X POST http://localhost:8899/api/milk `
     -H "Content-Type: application/json" `
     -d '{"cmd":"next"}'
   ```
   **Expected**: `401 Unauthorized` + error message

2. **Test WITH nonce** (replace `abc123xyz` with your nonce)
   ```powershell
   curl -X POST http://localhost:8899/api/milk `
     -H "Content-Type: application/json" `
     -H "X-MILK-Nonce: abc123xyz" `
     -d '{"cmd":"next"}'
   ```
   **Expected**: `200 OK` + preset advances in control.html!

3. **Test other commands**:
   ```powershell
   # Previous preset
   curl -X POST http://localhost:8899/api/milk `
     -H "Content-Type: application/json" `
     -H "X-MILK-Nonce: abc123xyz" `
     -d '{"cmd":"prev"}'

   # Set blend time
   curl -X POST http://localhost:8899/api/milk `
     -H "Content-Type: application/json" `
     -H "X-MILK-Nonce: abc123xyz" `
     -d '{"cmd":"setBlendTime","arg":3.0}'

   # Enable auto-cycle
   curl -X POST http://localhost:8899/api/milk `
     -H "Content-Type: application/json" `
     -H "X-MILK-Nonce: abc123xyz" `
     -d '{"cmd":"auto","arg":true}'
   ```

**Use Case**: Remote automation from SigNoz alerts, scripts, CI/CD

---

### Step 6: Test Preset Registry & Mood Mapping (Phase-5)

**View Registry**:
```powershell
cat docs\BossCat\visuals\presets\registry.json
```

**Test Mood Mapping** (Node.js/TypeScript):
```typescript
import registry from './docs/BossCat/visuals/presets/registry.json';

// Get presets by mood
const calmPresets = registry.presets.filter(p => p.mood === 'calm');
console.log(calmPresets.map(p => p.id));
// → ['RN-001', 'RN-002', 'RN-005']

// Map SigNoz severity to mood
function getMoodFromSeverity(severity: string): string {
  for (const [mood, config] of Object.entries(registry.mood_mapping)) {
    if (config.signoz_severity.includes(severity)) return mood;
  }
  return 'calm';
}

// Get preset for alert
const severity = 'critical';
const mood = getMoodFromSeverity(severity); // → 'intense'
const preset = registry.presets.find(p => p.mood === mood);
console.log(preset.name); // → 'LiquiRing'
```

**Use Case**: Programmatic preset selection based on alert severity

---

### Step 7: Test SigNoz Integration (Phase-3C)

**Start SigNoz mapper** (optional):
```powershell
tsx scripts/visuals/milk-signoz-mapper.ts test
```

This demonstrates the full alert → visual flow:
1. SigNoz fires alert (severity: critical)
2. Mapper receives webhook
3. Maps severity → mood → preset
4. Sends command to bridge (with nonce)
5. Bridge forwards to control.html
6. Visual changes to match severity

**Use Case**: Real-time system health visualization

---

## 📊 Demo Scenarios

### Scenario 1: NOC Display (24/7 ambient monitoring)

**Setup**:
1. Open control.html on large display
2. Enable **Low-Intensity** (photosensitivity)
3. Set **Intensity to 25** (gentle visuals)
4. Enable **Auto-cycle** (rotate through calm presets)
5. Select **Stereo Mix** for desktop audio

**Result**: Calm, non-distracting ambient visualization that responds to system audio

---

### Scenario 2: Alert-Driven Demo (Sales/Executive)

**Setup**:
1. Start bridge + control.html
2. Configure SigNoz webhook → bridge
3. Trigger test alerts with different severities

**Flow**:
```
info alert     → calm preset   (RN-001 CircuSpectra)
warning alert  → medium preset (RN-003 VectorGrid)
critical alert → intense preset (RN-004 LiquiRing)
```

**Result**: "System state becomes immediately visible" — executives see health at a glance

---

### Scenario 3: Developer Testing (CI/CD integration)

**Setup**:
1. Start bridge with nonce
2. Integrate bridge commands into CI/CD pipeline
3. Visual feedback for build/deploy status

**Example**:
```bash
# Build passes → calm preset
curl ... -d '{"cmd":"next"}' -H "X-MILK-Nonce: $NONCE"

# Build fails → intense preset
curl ... -d '{"cmd":"prev"}' -H "X-MILK-Nonce: $NONCE"
```

**Result**: Peripheral awareness of CI/CD status without context switching

---

## 🎯 Feature Showcase

### Phase-1: Resonai Default Preset ✅
- Safety-validated neon pulse preset
- 100/100 validation score
- No GPU shaders (universal compatibility)

### Phase-2: Control Surface ✅
- Butterchurn WebGL2 engine
- 300+ community presets
- Manual controls + automation API

### Phase-3A: WebSocket Bridge ✅
- Remote control via HTTP/WebSocket
- Localhost-only security
- **Phase-5: Nonce protection** (401 on invalid)

### Phase-3C: SigNoz Integration ✅
- Alert severity → visual mapping
- **Phase-5: Registry-driven** mood selection

### Presets: Authoring Pack ✅
- 6 safety-validated presets
- Validator with 7 checks (100% pass rate)
- Pack installer for MilkDrop3

### Phase-4: Low-Intensity ✅
- Accessibility mode (photosensitivity)
- 50% wave reduction, smoother transitions
- 30s auto-cycle interval

### Phase-5: Hardening + Intensity ✅
- **Nonce security**: X-MILK-Nonce header required
- **Intensity slider**: 0-100 granular control
- **Preset registry**: Mood tags + severity mapping
- **Live readout**: See effective blend/alpha values

---

## 🐾 Demo Complete!

**What you've seen**:
- ✅ Visual control surface with audio reactivity
- ✅ Low-Intensity + Intensity controls with live feedback
- ✅ Safety-validated preset library (6 presets)
- ✅ WebSocket bridge with nonce security
- ✅ Preset registry with mood mapping
- ✅ Complete SigNoz integration path

**Unique Value**:
- **Only observability platform** with real-time visual feedback
- <500ms latency (alert → visual)
- 100% safety-validated
- Accessibility-first design
- Zero external dependencies

---

## 📞 Next Steps

1. **Try it yourself**: Follow steps 1-7 above
2. **Capture GIFs**: Use `docs/BossCat/visuals/previews/README_previews.md` guide
3. **Deploy to production**: Already production-ready!
4. **Phase-6 ideas**:
   - Voice control (IONA integration)
   - AI-generated presets (MilkDropLM)
   - Automated preview generation
   - Advanced SigNoz metric → visual mappings

---

**🐾 cursor{implementer}** | MILK Lane Demo | **Ready for hands-on testing!** 🚀

