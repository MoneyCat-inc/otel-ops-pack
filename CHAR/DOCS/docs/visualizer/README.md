# Visualizer - Evidence-as-Code UI

**Gate:** #031 (Phase 1 MVP)  
**Authority:** BossCat OEM  
**Status:** ✅ DELIVERED

## Overview

Visualizer is a lightweight, evidence-first observability UI that renders machine-verifiable
proof artifacts for traces, logs, and (future) metrics. Built on the Resonai design system,
it provides a professional interface for viewing telemetry signals with ECRR compliance.

## Quick Start

### 1. Start Local HTTP Server

**IMPORTANT:** The UI requires an HTTP server due to browser CORS restrictions on `file://` protocol.

```powershell
# Option 1: Python (if installed)
cd docs
python -m http.server 8000

# Option 2: Node.js http-server (if installed)
cd docs
npx http-server -p 8000

# Option 3: PowerShell (Windows built-in, simplest)
cd docs
pwsh -Command "Start-Process 'http://localhost:8000/visualizer/index.html'; python -m http.server 8000"
```

Then navigate to: **<http://localhost:8000/visualizer/index.html>**

### 2. Generate Proof Artifacts (in separate terminal)

```powershell
# Run proof adapter
pwsh -File scripts/visualizer/proof-adapter.ps1 -ServiceName "iona-app" -LookbackMinutes 60

# With API token
$env:SIGNOZ_API_KEY = "<your-key>"
pwsh -File scripts/visualizer/proof-adapter.ps1 -ServiceName "bosscat-svc2-api"
```

### 3. View Results

Click **Refresh** in the UI to load the latest proof artifact.

## Configuration

### Query Parameters

- `?service=<name>` - Pre-select service (default: iona-app)

Example: `index.html?service=bosscat-svc2-api`

### Environment Variables

- `SIGNOZ_API_KEY` - SigNoz API token for proof generation
- `SIGNOZ_BASE_URL` - SigNoz base URL (default: <http://localhost:8080>)

## Features (Phase 1)

- ✅ Traces panel (count + last seen timestamp)
- ✅ Logs panel (count + last seen timestamp)  
- ✅ Health status (pipeline + collector)
- ✅ Service picker (configurable)
- ✅ Time range controls (15m, 1h, 24h)
- ✅ Manual proof generation (via PowerShell script)
- ✅ ICF "Last 5 Actions" panel
- 🟡 Metrics panel (placeholder for Gate #032)

## Future Phases

- **Gate #032** (Phase 2): Metrics panel, correlation (trace ↔ logs), charts
- **Gate #033** (Phase 3): Automated proof invocation, CI gates, "Attach to PR" helper
- **Gate #034** (Phase 4): A11y/security hardening, runbooks, background archival

## Budget Compliance

- **Files**: 6/15 ✅ (within limit)
- **LOC**: ~300/300 ✅ (at budget)
- **Lane**: docs (compliant)

## Evidence

All proof artifacts saved to `artifacts/visualizer/` with timestamped names and a `proof-latest.json` symlink for UI consumption.

---

### Gate #031 — Visualizer MVP Complete

