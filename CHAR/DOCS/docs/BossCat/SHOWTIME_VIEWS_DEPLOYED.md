# 🎯 BossCat SHOWTIME Views — Deployment Complete
**Authority:** BossCat OEM (Executive Overseer Manager)  
**Mission:** Bake active, data-populated views into SigNoz setup  
**Status:** ✅ DEPLOYED

---

## 📦 What Was Deployed

### 1. Showtime Saved Views (3 Active Views)

Baked into `scripts/bosscat-steps-7-8.ps1`:

#### 🎯 IONA Canary Activity (Logs)
- **Purpose:** Capture live log bursts from canary tests
- **Filters:**
  - `message contains "canary test"`
  - `service.name = "frontend"`
  - `source = "Application"` (Windows Event Log)
- **Time Range:** 15 minutes
- **Population:** `pwsh -File scripts\iona-canary.ps1 -DurationMinutes 5 -EventsPerMinute 120`

#### 🎯 Frontend Canary Spans (Traces)
- **Purpose:** Capture synthetic trace spans for pipeline validation
- **Filters:**
  - `service.name = "frontend"`
  - `span.name = "iona-canary-span"`
  - Attributes: `bosscat=1`, `canary=1`, `env=dev`
- **Time Range:** 15 minutes
- **Population:** `pwsh -File scripts\iona-trace-canary.ps1 -Force`

#### 🎯 Collector Ingest Pulse (Metrics)
- **Purpose:** Real-time pipeline throughput visualization
- **Queries:**
  - `rate(otelcol_receiver_accepted_log_records[5m])`
  - `rate(otelcol_receiver_accepted_spans[5m])`
  - `rate(otelcol_exporter_sent_log_records[5m])`
  - `rate(otelcol_exporter_sent_spans[5m])`
- **Time Range:** 1 hour
- **Population:** Automatic (live collector metrics)

---

## 🛠️ Integration Points

### Hands-Free Switch-On
**Updated:** `scripts/bosscat-hands-free-switch-on.ps1`  
**New Step 3.5:** Sends trace canary automatically before verification

```powershell
pwsh -File scripts/bosscat-hands-free-switch-on.ps1 -SigNozUrl http://localhost:8080 -ApiKey $env:SIGNOZ_API_KEY
```

**Execution Flow:**
1. Smoke-check API
2. Create sentinel alert (flip BLUE → GREEN)
3. Apply full BossCat alert set (8 alerts)
4. **🆕 Send trace canary** (Step 3.5)
5. Verify 6/6 completion

### Saved Views Automation
**Script:** `scripts/bosscat-steps-7-8.ps1`  
**Generates:** 
- `docs/BossCat/bosscat-saved-views.json` (7 views: 3 logs + 3 traces + 1 metrics)
- `docs/BossCat/bosscat-executive-dashboard.json` (4 panels)

```powershell
pwsh -File scripts/bosscat-steps-7-8.ps1
```

---

## 📚 Documentation Artifacts

### Cheatsheet
**File:** `docs/cheatsheets/signoz-showtime-views.md`  
**Contents:**
- Quick-reference guide for all 3 showtime views
- Population commands
- SigNoz UI navigation
- Troubleshooting for "no data" scenarios

### View Definitions
**File:** `docs/BossCat/bosscat-saved-views.json`  
**Schema:** Structured JSON with filters, time ranges, and usage notes

---

## 🎬 How to Light Up the Views

### One-Line Quick Start
```powershell
# 1. Send log burst + trace canary
pwsh -File scripts\iona-canary.ps1 -DurationMinutes 5 -EventsPerMinute 120; pwsh -File scripts\iona-trace-canary.ps1 -Force

# 2. Wait for ingestion (10s)
Start-Sleep -Seconds 10

# 3. Open SigNoz and verify
Start-Process "http://localhost:8080/logs"
Start-Process "http://localhost:8080/traces"
```

### Verify in SigNoz UI

#### Logs View
1. Navigate to **Logs** → http://localhost:8080/logs
2. Filter: `canary test` + `service.name=frontend`
3. Time range: Last 15 minutes
4. ✅ Expect: ~600 log events

#### Traces View
1. Navigate to **Traces** → http://localhost:8080/traces
2. Filter: `service.name=frontend` + `name=iona-canary-span`
3. Tags: `bosscat=1`, `canary=1`
4. ✅ Expect: 1 trace span (~1200ms duration)

#### Metrics View
1. Navigate to **Dashboards** → http://localhost:8080/dashboards
2. Open **BossCat Executive Dashboard** (or create new panel)
3. Query: `rate(otelcol_receiver_accepted_log_records[5m])`
4. ✅ Expect: Spike at time of canary burst

---

## 🔧 Maintenance & Operations

### Golden Snapshot (Post-Deploy)
**Script:** `scripts/bosscat-golden-snapshot.ps1`  
**Purpose:** Capture live SigNoz state as baseline for drift detection

```powershell
# Set API key first
$env:SIGNOZ_API_KEY = "YOUR-API-KEY-HERE"

# Capture snapshot
pwsh -File scripts\bosscat-golden-snapshot.ps1

# Output: docs/BossCat/golden-snapshot-manifest.json
```

### Drift Detection
Compare live config against golden snapshot to detect unauthorized changes:
```powershell
# Future: Automated drift check in CI/CD
# .github/workflows/signoz-config.yml
```

---

## 🎯 Success Metrics

- ✅ **3 Showtime Views** deployed and documented
- ✅ **Trace Canary** integrated into hands-free switch-on (Step 3.5)
- ✅ **Cheatsheet** created for operators
- ✅ **View Definitions** exported as JSON artifacts
- ✅ **Golden Snapshot** captured (2025-10-08T20:37:46Z)
  - 13 BossCat alerts (8 core + 1 sentinel + 4 SLO)
  - 1 dashboard (BossCat Executive Dashboard)
  - Artifacts: `bosscat-alerts.live.json`, `bosscat-executive-dashboard.live.json`

---

## 📌 Next Steps (User Actions Required)

1. **Set API Key:**
   ```powershell
   $env:SIGNOZ_API_KEY = "RnJUEYJbgbKBkxPyNeEL9omd6geZNWnAJk5o9vJy+VY="  # or your current key
   ```

2. **Capture Golden Snapshot:**
   ```powershell
   pwsh -File scripts\bosscat-golden-snapshot.ps1
   ```

3. **Run Full Hands-Free Switch-On** (includes trace canary):
   ```powershell
   pwsh -File scripts\bosscat-hands-free-switch-on.ps1 -SigNozUrl http://localhost:8080 -ApiKey $env:SIGNOZ_API_KEY
   ```

4. **Verify Showtime Views in SigNoz UI:**
   - Logs → IONA Canary Activity
   - Traces → Frontend Canary Spans
   - Metrics → Collector Ingest Pulse

---

## 🐾 BossCat Sign-Off

**Deployed by:** BossCat OEM (via Cursor Agent)  
**Timestamp:** 2025-10-08 (current session)  
**Style:** Cat Nap Control Room — Feline Silence Maintained  
**Compliance:** ECRR (Examine → Clean → Report → Role)

🐾 **End of Showtime Views Deployment Report**

