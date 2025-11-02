# Milkdrop Visual Engine - Quick Start

**Authority:** BossCat OEM - Cat Nap Control Room  
**Status:** Foundation Complete - Ready for Testing

---

## [Overview]

Containerized Milkdrop (Butterchurn WebGL) visual engine with:
- **Fast preset switching** (blend in <=2.5s)
- **Hot-reload from Cursor** (instant authoring loop)
- **Automated quality scoring** (aspect, motion, beat sync)
- **ECRR integration** (artifacts, rollback on FAIL)

## [Documentation Updates]

1. **GPU Container Setup**: Detailed instructions on setting up the GPU container for optimal performance.
2. **Troubleshooting Runbook**: A comprehensive guide for common issues encountered with the viz-engine → [vizr-troubleshooting.md](docs/runbooks/vizr-troubleshooting.md)
3. **VirtualGL Deployment**: Steps for deploying VirtualGL and its rendering pipeline.
4. **ECRR Report**: Current state of the visualizer documented for compliance.
5. **Architecture Diagram**: Visual representation of telemetry flow for better understanding → [architecture-diagram.md](docs/ecrr/architecture-diagram.md)

---

## [Quick Start]

### 1. Build and Start Containers

```powershell
# Build images
docker-compose -f docker-compose.viz.yml build

# Start stack
docker-compose -f docker-compose.viz.yml up -d

# Check status
docker-compose -f docker-compose.viz.yml ps
```

### 2. Test Control API

```powershell
# Load a preset
curl -X POST http://localhost:7001/preset `
  -H "Content-Type: application/json" `
  -d '{"name":"sample_basic","body":"...milk content...","blend":2.5}'

# Get stats
curl http://localhost:7001/stats

# Capture snapshot
curl http://localhost:7001/snap.jpg -o frame.jpg
```

### 3. Hot-Reload from Cursor

```powershell
# Edit preset file
code viz-engine-butterchurn/presets/sample_basic.milk

# Reload with blend
pwsh scripts/reload-preset.ps1 `
  -PresetFile viz-engine-butterchurn/presets/sample_basic.milk `
  -Blend 2.5
```

### 4. Check Quality Metrics

```powershell
# Get scorebot metrics
curl http://localhost:7010/metrics

# Validate current state (ECRR gate)
curl -X POST http://localhost:7010/validate
```

---

## [Structure]

```
viz-engine-butterchurn/
+-- Dockerfile                    # Container build
+-- package.json                  # Dependencies
+-- src/
|   +-- server.js                 # Control API server
|   +-- renderer.html             # WebGL renderer (DPI-aware)
|   +-- health-check.js           # Health endpoint
+-- presets/
    +-- sample_basic.milk         # Sample preset

scorebot/
+-- Dockerfile                    # Container build
+-- requirements.txt              # Python deps
+-- src/
    +-- server.py                 # Metrics server
    +-- health_check.py           # Health endpoint

scripts/
+-- reload-preset.ps1             # Hot-reload script (ECRR)

docs/
+-- MILKDROP_PRESET_AUTHORING.md  # Codex authoring guide
```

---

## [Control API]

### viz-engine (port 7001)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/preset` | POST | Load preset with blend |
| `/size` | POST | Update dimensions (DPI-aware) |
| `/snap.jpg` | GET | Capture current frame |
| `/stats` | GET | FPS, frame time, memory |
| `/` | GET | Service status |
| `/events` | WebSocket | Real-time events |

### scorebot (port 7010)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/score` | GET | Current quality score (0-100) |
| `/metrics` | GET | Detailed metrics |
| `/validate` | POST | ECRR validation (PASS/FAIL) |
| `/history` | GET | Metrics history (last 60 samples) |
| `/` | GET | Service status |

---

## [Quality Checks - Scorebot]

| Check | Threshold | Fail Condition |
|-------|-----------|----------------|
| **Aspect Ratio** | <=5% deviation | Skewed canvas |
| **Blackout** | >=95% black pixels | Static black frame |
| **Motion Energy** | >=0.01 optical flow | Frozen visual |
| **Luma Balance** | 0-255 mean | Over/under exposed |
| **Chroma Balance** | 0-255 mean | Color clipping |

**FAIL actions:**
1. Log incident to `artifacts/viz-engine/`
2. Trigger rollback to last-known-good preset
3. Update `BOSSCAT_LOG.md`

---

## [Preset Authoring]

See: `docs/MILKDROP_PRESET_AUTHORING.md`

**Basic template:**

```milk
[preset00]
/* preset init */
decay = 0.98; gamma = 2.0;

/* per_frame */
time = time + 0.0167;
beat = (bass + mid + treb) * 0.33;
zoom = 1.0 + 0.03*beat;
rot = 0.02*sin(time*0.31);

/* per_pixel */
zoom = zoom + rad * 0.08 * sin(time*0.9);
```

---

## [ECRR Integration]

Every preset change:
1. **Examine** - Capture current FPS, motion, aspect
2. **Clean** - Load preset with blend
3. **Report** - Scorebot emits metrics -> artifact
4. **Role** - If FAIL, rollback to last-known-good

**Artifacts:** `artifacts/viz-engine/preset-reload-*.json`

---

## [Troubleshooting]

### Container not starting
```powershell
# Check logs
docker-compose -f docker-compose.viz.yml logs viz-engine
docker-compose -f docker-compose.viz.yml logs scorebot

# Rebuild
docker-compose -f docker-compose.viz.yml build --no-cache
```

### Firefox aspect skew
- **Fixed in renderer.html** with DPI-aware sizing
- Canvas drawing buffer = CSS size * devicePixelRatio
- `visualizer.setRendererSize(canvas.width, canvas.height)` before render

### Preset not loading
```powershell
# Check engine status
curl http://localhost:7001/

# Try simple test
curl -X POST http://localhost:7001/preset `
  -H "Content-Type: application/json" `
  -d '{"name":"test","body":"/* test */","blend":0}'
```

---

## [References]

- **Milkdrop Authoring:** [Geisswerks Guide](https://www.geisswerks.com/milkdrop/milkdrop_preset_authoring.html)
- **Butterchurn API:** [GitHub](https://github.com/jberg/butterchurn)
- **projectM:** [GitHub](https://github.com/projectM-visualizer/projectm)
- **WebGL Canvas Sizing:** [WebGL Fundamentals](https://webglfundamentals.org/webgl/lessons/webgl-resizing-the-canvas.html)

---

## [Next Steps]

1. [DONE] Test end-to-end: Cursor edit -> reload -> scorebot -> metrics
2. Create preset library (starter pack of 10-20 curated visuals)
3. Add WebRTC gateway for live streaming (optional)
4. Create projectM container (native .milk alternative)
5. Integrate with SigNoz observability (OTel traces)

---

**Status:** [READY] FOUNDATION COMPLETE - READY FOR TESTING

**BossCat Mission:** Fast iterate -> score -> refine visual loop  
**Authority:** BossCat OEM -> Cursor{Implementer}  
**ECRR:** Examine -> Clean -> Report -> Role [PASS]

**Cat Nap Control Room - Visual Authoring Loop ACTIVE**

