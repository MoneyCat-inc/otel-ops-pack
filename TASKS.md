# TASKS.md — OTel Observability Pipeline

## 📋 SSOT + MEMX Ops Enhancement Tasks

## 🚨 Task 1 — Alerting Integration ✅ COMPLETED

**Goal:** Pipe monitoring outputs into Slack/Teams/email for proactive notification.

**Implementation:**
- ✅ Added `scripts/notify-alert.ps1` → wrapper to send webhook payloads (Slack/Teams configurable URL)
- ✅ Extended existing monitors (`direct-production-monitor.ps1`, `robust-production-monitor.ps1`) to call notifier on threshold breach
- ✅ Environment variables: `ALERT_WEBHOOK_URL`, `ALERT_CHANNEL`
- ✅ Updated `docs/SSOT_PRODUCTION_MONITORING_GUIDE.md` with alert setup

**Acceptance Criteria Met:**
- ✅ Triggering <100% health posts JSON payload into Slack test channel
- ✅ No alerts if health ≥100%
- ✅ Docs updated with comprehensive alert setup guide

---

## 📊 Task 2 — Dashboard Integration

**Goal:** Visualize SSOT metrics live (Grafana/SigNoz).

**Steps**
- [ ] Extend monitors to emit metrics JSON to `out/ssot-metrics.json`
- [ ] Configure OTLP exporter (optional) to send metrics into SigNoz collector
- [ ] Add sample Grafana dashboard JSON (panel for Health%, Freshness, Error counts)
- [ ] Doc: `docs/SSOT_DASHBOARD_SETUP.md`

**Acceptance**
- [ ] Grafana/SigNoz dashboard shows health% trending over time
- [ ] Exporter OFF by default (privacy posture)
- [ ] Local JSON file rotates hourly

---

## 🔄 Task 3 — Auto-Remediation Hooks

**Goal:** Automatically attempt recovery when health <100%.

**Steps**
- [ ] Add `scripts/remediate.ps1` (restart agent, clear stale cache, regenerate SSOT)
- [ ] Wire `robust-production-monitor.ps1` to invoke remediation once, log outcome
- [ ] Safety: only run if `AUTO_REMEDIATE=1` env flag is set

**Acceptance**
- [ ] With `AUTO_REMEDIATE=0`: monitor logs warning only
- [ ] With `AUTO_REMEDIATE=1`: monitor runs remediation and logs success
- [ ] No infinite loops; backoff enforced

---

## 🧠 Task 4 — MEMX Alignment

**Goal:** Extend ops surface to include memory observation metrics.

**Steps**
- [ ] Update MEMX exporter (`src/engine/memx/otelExporter.ts`) to align with SSOT metric schema
- [ ] Add MEMX fields (`wasmHeapBytes`, `sabUsage%`, `p95WorkletLagMs`) into SSOT health JSON
- [ ] Update `docs/SSOT_PRODUCTION_MONITORING_GUIDE.md` with MEMX integration section

**Acceptance**
- [ ] `ssot-metrics.json` includes MEMX aggregates when MEMX flag is ON
- [ ] No data if MEMX disabled
- [ ] MEMX metrics visible in dashboard

---

## 📅 Task 5 — Quarterly Threshold Review

**Goal:** Keep alert thresholds tuned.

**Steps**
- [ ] Add `docs/SSOT_THRESHOLD_REVIEW.md` template with checklist (freshness, health%, MEMX lag)
- [ ] Schedule quarterly job in CI to output last 90d metrics and open GH issue with review checklist

**Acceptance**
- [ ] Checklist generated automatically each quarter
- [ ] GH issue tagged `ops-review`
- [ ] Team can adjust thresholds in config and commit

---

### 🛡️ Guardrails

- ≤200 LOC / ≤10 files per PR
- Feature flags/env vars for all new behaviors
- Alerting + streaming OFF by default (local-first policy)
- Playwright/PowerShell smoke tests added for each new script
- Respect `.agent/LOCK` kill-switch if background agent is running

---

## 🎯 Current Sprint: E2 Ratio Optimization & Monitoring

### T-2025-01-27-001: E2 Ratio Sweep Analysis
**Priority**: High | **Estimate**: 3-4 hours | **Owner**: Cursor-Local

**Goal**: Systematic E2 ratio optimization through batch timeout/size permutations (50-500ms agent, 2-10s gateway) with latency waterfall analysis.

**Acceptance Criteria**:
- [ ] Test 9 timeout combinations: agent (50ms, 200ms, 500ms) × gateway (2s, 5s, 10s)
- [ ] Capture p50/p95/p99 latency waterfalls for each combination
- [ ] Measure queue utilization, batch efficiency, and data loss rates
- [ ] Identify optimal configuration with evidence-based recommendations
- [ ] Create baseline performance profile for future comparisons

**Implementation Plan**:
1. **Examine**: Current batch processor settings in `config.yaml`
2. **Clean**: Backup config, prepare test environment, clear metrics
3. **Report**: Create `docs/ECRR_REPORTS/2025-01-27-e2-ratio-sweep.md`
4. **Role**: Cursor-Local (Observability Copilot)

**Exact YAML Edits Required**:

**File**: `config.yaml`
```yaml
# Current batch processor (find and replace)
processors:
  batch:
    timeout: 200ms  # Will be varied: 50ms, 200ms, 500ms
    send_batch_size: 1024
    send_batch_max_size: 2048

# Add to exporters section
exporters:
  otlp/signoz:
    endpoint: http://localhost:14317
    timeout: 2s  # Will be varied: 2s, 5s, 10s
    retry_on_failure:
      enabled: true
      initial_interval: 5s
      max_interval: 30s
      max_elapsed_time: 300s
```

**Files to Modify**:
- `config.yaml` (batch processor + exporter timeout settings)
- `scripts/e2-ratio-sweep.ps1` (enhanced test script)
- `docs/ECRR_REPORTS/2025-01-27-e2-ratio-sweep.md` (comprehensive results)

**Test Matrix**:
| Agent Timeout | Gateway Timeout | Test ID |
|---------------|-----------------|---------|
| 50ms          | 2s              | E2-001  |
| 50ms          | 5s              | E2-002  |
| 50ms          | 10s             | E2-003  |
| 200ms         | 2s              | E2-004  |
| 200ms         | 5s              | E2-005  |
| 200ms         | 10s             | E2-006  |
| 500ms         | 2s              | E2-007  |
| 500ms         | 5s              | E2-008  |
| 500ms         | 10s             | E2-009  |

**Verification Commands**:
```powershell
# Run complete E2 ratio sweep
pwsh -File scripts/e2-ratio-sweep.ps1 -TestAllCombinations

# Verify specific combination
pwsh -File scripts/e2-ratio-sweep.ps1 -AgentTimeout 200ms -GatewayTimeout 5s

# Check results
Get-Content artifacts/e2-ratio-sweep-results.json | ConvertFrom-Json
```

**Success Metrics**:
- p95 latency < 2s for optimal configuration
- Queue utilization < 70% under normal load
- Zero data loss across all test combinations
- Batch efficiency > 80% (sent_spans / queued_spans)

---

### T-2025-01-27-002: SigNoz Dashboard Panel for Queue Pressure
**Priority**: High | **Estimate**: 1-2 hours | **Owner**: Cursor-Local

**Goal**: Add a SigNoz dashboard panel showing `otelcol_exporter_queue_size / capacity` to monitor spool pressure at a glance.

**Acceptance Criteria**:
- [ ] Create dashboard panel showing queue utilization percentage
- [ ] Panel shows real-time queue size vs capacity
- [ ] Panel includes trend line for last 24 hours
- [ ] Panel triggers visual warning when utilization >80%
- [ ] Dashboard config exported to `artifacts/signoz-dashboard-config.json`

**Implementation Plan**:
1. **Examine**: Current SigNoz dashboard structure
2. **Clean**: Prepare dashboard configuration
3. **Report**: Document panel creation process
4. **Role**: Cursor-Local (Observability Copilot)

**Files to Modify**:
- `artifacts/signoz-dashboard-config.json` (dashboard config)
- `docs/QUERY_RECIPES.md` (queue pressure queries)
- `MONITORING_SETUP_GUIDE.md` (import instructions)

**Verification**:
```powershell
# Import dashboard
pwsh -File scripts/import-dashboard.ps1

# Verify panel in SigNoz UI
# Navigate to: SigNoz UI → Dashboards → OTel Queue Pressure
```

---

### T-2025-01-27-003: Canary Alert for Windows Logs
**Priority**: Medium | **Estimate**: 1 hour | **Owner**: Cursor-Local

**Goal**: Wire a canary alert for `log.body contains "windows-canary"` absence >5 minutes to catch ingestion failures.

**Acceptance Criteria**:
- [ ] Create SigNoz alert rule for canary log absence
- [ ] Alert triggers when no canary logs for >5 minutes
- [ ] Alert includes proper notification channels
- [ ] Test alert with canary log injection and removal
- [ ] Alert config exported to `artifacts/signoz-alerts.json`

**Implementation Plan**:
1. **Examine**: Current canary log generation in `scripts/verify-canary.ps1`
2. **Clean**: Ensure consistent canary log format
3. **Report**: Document alert creation and testing
4. **Role**: Cursor-Local (Observability Copilot)

**Files to Modify**:
- `artifacts/signoz-alerts.json` (alert configuration)
- `scripts/verify-canary.ps1` (ensure consistent format)
- `SIGNOZ_ALERT_IMPORT_GUIDE.md` (import instructions)

**Verification**:
```powershell
# Test canary alert
pwsh -File scripts/test-canary-alert.ps1

# Verify alert in SigNoz UI
# Navigate to: SigNoz UI → Alerts → Windows Canary Alert
```

---

## 🔄 Workflow Status

### In Progress
- None currently

### Completed
- None yet

### Blocked
- None currently

---

### T-2025-01-27-004: Canary Log Pattern Drills
**Priority**: High | **Estimate**: 2-3 hours | **Owner**: Cursor-Local

**Goal**: Expand `windows-canary` emitter with steady/Poisson/Pareto patterns to measure fractal self-similarity and validate ingestion reliability.

**Acceptance Criteria**:
- [ ] Implement steady pattern canary (1 event/10s)
- [ ] Implement Poisson pattern canary (λ=0.1 events/s)
- [ ] Implement Pareto pattern canary (α=1.5, scale=1.0)
- [ ] Measure ingestion latency distribution for each pattern
- [ ] Validate fractal self-similarity metrics
- [ ] Create pattern comparison dashboard

**Implementation Plan**:
1. **Examine**: Current canary log generation in `scripts/verify-canary.ps1`
2. **Clean**: Enhance canary script with pattern support
3. **Report**: Document pattern analysis and fractal metrics
4. **Role**: Cursor-Local (Observability Copilot)

**Files to Modify**:
- `scripts/canary-pattern-drills.ps1` (new enhanced script)
- `artifacts/canary-pattern-results.json` (pattern analysis results)
- `docs/ECRR_REPORTS/2025-01-27-canary-pattern-analysis.md` (results)

**Pattern Definitions**:
```powershell
# Steady Pattern: 1 event every 10 seconds
# Poisson Pattern: λ=0.1 events/second (exponential inter-arrival)
# Pareto Pattern: α=1.5, scale=1.0 (heavy-tailed distribution)
```

**Verification Commands**:
```powershell
# Run all pattern drills
pwsh -File scripts/canary-pattern-drills.ps1 -Pattern All

# Test specific pattern
pwsh -File scripts/canary-pattern-drills.ps1 -Pattern Poisson -Duration 300

# Analyze results
Get-Content artifacts/canary-pattern-results.json | ConvertFrom-Json
```

---

### T-2025-01-27-005: Fractal Drift Monitors Dashboard
**Priority**: High | **Estimate**: 2 hours | **Owner**: Cursor-Local

**Goal**: Pre-build SigNoz panels for exporter queue ratio, `*_send_failed_*`, and trace time-to-use as "fractal drift" monitors.

**Acceptance Criteria**:
- [ ] Queue ratio panel (current_size / capacity)
- [ ] Send failure rate panel (failed_sends / total_sends)
- [ ] Trace time-to-use panel (p50/p95/p99)
- [ ] Fractal drift detection (variance in patterns)
- [ ] Alert thresholds configured

**Implementation Plan**:
1. **Examine**: Current SigNoz dashboard structure
2. **Clean**: Create comprehensive drift monitoring dashboard
3. **Report**: Document drift detection methodology
4. **Role**: Cursor-Local (Observability Copilot)

**Files to Modify**:
- `artifacts/signoz-fractal-drift-dashboard.json` (dashboard config)
- `docs/QUERY_RECIPES.md` (drift detection queries)
- `MONITORING_SETUP_GUIDE.md` (drift monitoring guide)

**Dashboard Panels**:
- Queue Utilization Ratio (real-time + 24h trend)
- Send Failure Rate (by exporter, by error type)
- Trace Time-to-Use (p50/p95/p99 percentiles)
- Fractal Drift Detection (pattern variance analysis)

---

### T-2025-01-27-006: Alert Thresholds & Notifications
**Priority**: High | **Estimate**: 1-2 hours | **Owner**: Cursor-Local

**Goal**: Set thresholds (queue_ratio > 0.7 for 10m, p95 time-to-use > 8s) and wire to notifier.

**Acceptance Criteria**:
- [ ] Queue ratio alert: > 0.7 for 10 minutes
- [ ] Time-to-use alert: p95 > 8 seconds
- [ ] Send failure alert: > 5% failure rate
- [ ] Notification channels configured
- [ ] Alert testing completed

**Implementation Plan**:
1. **Examine**: Current alert configuration in `artifacts/signoz-alerts.json`
2. **Clean**: Add drift monitoring alerts
3. **Report**: Document alert configuration and testing
4. **Role**: Cursor-Local (Observability Copilot)

**Files to Modify**:
- `artifacts/signoz-alerts.json` (enhanced alert config)
- `scripts/test-drift-alerts.ps1` (alert testing script)
- `docs/ECRR_REPORTS/2025-01-27-drift-alerts-deployment.md` (results)

---

### T-2025-01-27-007: Agent Hygiene & File Storage
**Priority**: Medium | **Estimate**: 1 hour | **Owner**: Cursor-Local

**Goal**: Add `file_storage` directory check in `verify-integration.ps1` to prevent queue silent failures on restart.

**Acceptance Criteria**:
- [ ] File storage directory validation
- [ ] Queue persistence verification
- [ ] Restart recovery testing
- [ ] Silent failure detection

**Implementation Plan**:
1. **Examine**: Current `verify-integration.ps1` script
2. **Clean**: Add file storage validation
3. **Report**: Document hygiene improvements
4. **Role**: Cursor-Local (Observability Copilot)

**Files to Modify**:
- `scripts/verify-integration.ps1` (enhanced validation)
- `scripts/test-file-storage.ps1` (storage testing)
- `docs/ECRR_REPORTS/2025-01-27-agent-hygiene.md` (results)

---

## 📋 Future Sprint Candidates

### T-2025-01-27-008: Performance Baseline
**Priority**: Low | **Estimate**: 3 hours

**Goal**: Establish performance baselines for collector CPU, memory, and queue metrics.

### T-2025-01-27-009: Batch Size Optimization
**Priority**: Medium | **Estimate**: 2 hours

**Goal**: Optimize batch sizes for different telemetry types (traces, logs, metrics) based on E2 ratio analysis.

---

## 🎭 ECRR Compliance

All tasks must follow the **ECRR mantra**:
- **Examine** → Capture environment state before changes
- **Clean** → Remove drift, enforce guardrails
- **Report** → Save results in `docs/ECRR_REPORTS/`
- **Role** → Declare actor (Cursor-Local: Observability Copilot)

---

## 📊 Success Metrics

**E2 Ratio Optimization**:
- p95 latency < 2s for trace batches
- Queue utilization < 80% under normal load
- Zero data loss during batch timeout adjustments

**Monitoring & Alerting**:
- Queue pressure visible at a glance
- Canary alert triggers within 5 minutes of failure
- Dashboard panels load in < 3 seconds

---

*Last updated: 2025-01-27 by Cursor-Local: Observability Copilot*
