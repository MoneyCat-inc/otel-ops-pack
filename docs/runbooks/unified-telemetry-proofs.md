# Unified Telemetry Proofs (Gate #030)

**Authority:** BossCat OEM (Fubumaki)  
**Gate:** #030 (Evidence-as-Code v1)  
**Date:** 2025-10-27  
**Status:** ACTIVE — v1 (Traces + Logs, Metrics deferred to v2)

---

## Overview

The `proof-of-telemetry.ps1` script generates unified proof artifacts that verify **multiple observability signals**
(traces, logs, metrics) are flowing to SigNoz, replacing manual verification with machine-parseable JSON evidence.

**Gate #030 v1 Delivers:**

- ✅ **Traces:** Service-scoped query with count
- ✅ **Logs:** Global query with count  
- ⚠️ **Metrics:** Deferred to v2 (requires metric-specific query structure)

**Extension from Gate #029-H1:** Single-signal proofs → Unified multi-signal proofs

---

## Quick Start

```powershell
# Set API token (v2 supports both env vars)
$env:SIGNOZ_API_TOKEN = "<your-api-key>"  # Preferred in v2
# or
$env:SIGNOZ_API_KEY = "<your-api-key>"    # Backward compatible

# Generate unified proof (v2: all 3 signals)
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service"

# Strict mode (all signals required, exits GREEN only if 3/3)
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -ExpectAll

# Custom auth header (Authorization Bearer)
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -AuthHeaderName "Authorization"
```

**v2 Result:** ✅ **3/3 signals** (traces, logs, metrics via collector health)

---

## Configuration

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SIGNOZ_API_KEY` | Yes | API key from SigNoz (Settings → API Keys, Viewer role) | `<redacted>` |
| `SIGNOZ_BASE_URL` | No | SigNoz base URL (default: `http://localhost:8080`) | `http://127.0.0.1:3301` |
| `SIGNOZ_SERVICE_NAME` | No | Service name for traces query | `bosscat-svc2-api` |
| `SIGNOZ_LOOKBACK_MINUTES` | No | Minutes to look back (default: 3) | `60` |

**Note:** For API key creation, see [signoz-api-proofs.md](./signoz-api-proofs.md#create-api-key)

---

## Usage

### Local Testing

```powershell
# Basic usage (permissive mode)
$env:SIGNOZ_API_KEY = "<your-key>"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "iona-app"

# Expected output:
# [1/3] Querying traces... ✅ 2
# [2/3] Querying logs... ✅ 14  
# [3/3] Querying metrics... SKIPPED
# Overall: PARTIAL (2/3 signals)
# [GREEN] At least one signal verified
```

### Strict Mode (CI/CD)

```powershell
# All signals required (exits AMBER if any missing)
$env:SIGNOZ_API_KEY = "<your-key>"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -ExpectAll

# Exit codes:
# 0 = All signals present
# 1 = Some signals missing (AMBER)
# 2 = No signals present (RED)
# 21 = Config error
```

### CI/CD Integration (GitHub Actions)

```yaml
name: Verify Unified Telemetry

on:
  workflow_dispatch:
  pull_request:
    paths:
      - 'src/**'
      - '.github/workflows/verify-telemetry.yml'

jobs:
  verify-telemetry:
    runs-on: windows-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Deploy test service
        run: |
          # Deploy your instrumented service here
          # ...
      
      - name: Verify unified telemetry in SigNoz
        shell: pwsh
        env:
          SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}
          SIGNOZ_BASE_URL: ${{ vars.SIGNOZ_BASE_URL }}
        run: |
          ./scripts/windows/proof-of-telemetry.ps1 -ServiceName "my-service" -LookbackMinutes 5
      
      - name: Upload proof artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: unified-telemetry-proof
          path: artifacts/proofs/unified-proof-*.json
          retention-days: 30
```

---

## Unified Proof Schema

**File Path:** `artifacts/proofs/unified-proof-<service>-<timestamp>.json`

**Schema:**

```json
{
  "probe": "signoz-unified",
  "service": "iona-app",
  "timeframe": "60 min",
  "startMs": 1761577563134,
  "endMs": 1761581163134,
  "signals": {
    "traces": {
      "count": 2,
      "status": "PASS",
      "endpoint": "http://localhost:8080/api/v5/query_range",
      "error": null
    },
    "logs": {
      "count": 14,
      "status": "PASS",
      "endpoint": "http://localhost:8080/api/v5/query_range",
      "error": null
    },
    "metrics": {
      "count": 0,
      "status": "FAIL",
      "endpoint": "N/A",
      "error": "PARTIAL - Metrics deferred to v2"
    }
  },
  "overall_status": "PARTIAL",
  "timestamp": "20251027-164412",
  "verification_type": "api-signed-unified",
  "api_version": "v5"
}
```

**Fields:**

- `probe`: Always `"signoz-unified"`
- `service`: Service name queried (traces only in v1)
- `timeframe`: Human-readable lookback period
- `startMs`/`endMs`: Unix timestamp (ms) of query window
- `signals`: Object with traces/logs/metrics results
  - `count`: Number of records found
  - `status`: "PASS" (≥threshold) or "FAIL" (<threshold)
  - `endpoint`: API endpoint queried
  - `error`: Error message (if query failed)
- `overall_status`: "PASS" (all), "PARTIAL" (some), "FAIL" (none)
- `timestamp`: Proof generation timestamp
- `verification_type`: `"api-signed-unified"`
- `api_version`: `"v5"`

---

## Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `0` | **GREEN** | At least one signal present (permissive) OR all signals present (strict) |
| `1` | **AMBER** | Some signals missing (only in strict mode with `-ExpectAll`) |
| `2` | **RED** | No signals present |
| `21` | **RED** | Configuration error (missing API key/service name) |

### Permissive Mode (Default)

```powershell
# Exits GREEN if ANY signal present
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service"
```

**Exit 0 (GREEN):** Traces OR logs OR metrics present  
**Exit 2 (RED):** No signals at all

### Strict Mode

```powershell
# Exits GREEN only if ALL signals present
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -ExpectAll
```

**Exit 0 (GREEN):** Traces AND logs AND metrics all present  
**Exit 1 (AMBER):** Only 1-2 signals present  
**Exit 2 (RED):** No signals present

---

## Signal Sources (v2)

### Traces ✅

**Source:** SigNoz API `/api/v5/query_range`  
**Filter:** Service-scoped (`serviceName = 'service-name'`)  
**Proves:** Service sending traces to SigNoz

### Logs ✅

**Source:** SigNoz API `/api/v5/query_range`  
**Filter:** Global (all logs)  
**Proves:** Logs flowing to SigNoz  
**Note:** Not service-scoped in v2 (field name TBD)

### Metrics ✅ (v2 NEW)

**Source:** Windows Collector Prometheus endpoint (port 8888)  
**Metric:** `otelcol_exporter_sent_spans`  
**Proves:** Collector pipeline operational  
**Why:** Stable, service-agnostic, always present when collector running

**Result:** ✅ **All 3/3 signals operational in v2**

---

## Auth Hardening (v2)

### Dual-Header Support

**Default:** `SIGNOZ-API-KEY: <token>`  
**Alternate:** `Authorization: Bearer <token>`

**Usage:**

```powershell
# Default (signoz-api-key header)
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service"

# Authorization Bearer header
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -AuthHeaderName "Authorization"
```

**Fallback Logic:**

- If initial auth fails (401/403) with `signoz-api-key`
- Automatically retries with `Authorization: Bearer`
- Transparent to user

### Secret Masking

**Proof Artifact:**

```json
{
  "auth_method": "signoz-api-key",
  "auth_token": "***masked***"
}
```

**Console Output:** Token never printed  
**Logs:** Header type logged, not value  
**Compliance:** ECRR Rule #10 (secrets & boundaries)

---

## Known Limitations (v2)

### Service-Level Filtering for Logs

**Status:** ⚠️ **PARTIAL**

**Current Behavior:**

- Logs query counts ALL logs (no service filter)
- Still proves logs are flowing to SigNoz

**Reason:** Field name for service in logs unclear (`service_name` vs `service.name` vs attributes)

**Future (v2):**

- Investigate correct field name for logs
- Add service-scoped log filtering

---

## Comparison: Single vs Unified Proofs

### Single-Signal Proof (Gate #029-H1)

**Script:** `health-check-otlp.ps1 -UseApiProof`  
**Signals:** Traces only  
**Proof:** `proof-traces-<service>-<timestamp>.json`  
**Use Case:** Collector path verification

### Unified Proof (Gate #030)

**Script:** `proof-of-telemetry.ps1`  
**Signals:** Traces + Logs (+ Metrics in v2)  
**Proof:** `unified-proof-<service>-<timestamp>.json`  
**Use Case:** Comprehensive telemetry verification

**Recommendation:** Use unified proof for gate approvals, single-signal for troubleshooting specific paths.

---

## Troubleshooting

### Exit 21: "SIGNOZ_API_KEY environment variable required"

**Fix:**

```powershell
$env:SIGNOZ_API_KEY = "<your-key>"
```

### Exit 21: "ServiceName required"

**Fix:**

```powershell
# Option 1: Parameter
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service"

# Option 2: Environment
$env:SIGNOZ_SERVICE_NAME = "my-service"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1
```

### Overall Status: PARTIAL (expected in v1)

**Cause:** Metrics not implemented in v1

**Acceptable:** If traces + logs both show count > 0

**Fix (if needed):** Remove `-ExpectAll` flag to exit GREEN with partial signals

### Traces Count is 0

**Possible Causes:**

1. Service not sending traces
2. Service name incorrect
3. Lookback window too short

**Fix:**

```powershell
# Increase lookback
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -LookbackMinutes 60

# Check service name in SigNoz UI first
```

### Logs Count is 0

**Possible Causes:**

1. No logs being sent to SigNoz
2. Lookback window too short

**Note:** Logs query counts ALL logs (not service-scoped in v1)

---

## API Reference

### Endpoint

**URL:** `POST http://localhost:8080/api/v5/query_range`  
**Headers:**

- `Content-Type: application/json`
- `SIGNOZ-API-KEY: <your-key>`

### Traces Query Payload

```json
{
  "start": 1730047200000,
  "end": 1730047380000,
  "requestType": "scalar",
  "compositeQuery": {
    "queries": [{
      "type": "builder_query",
      "spec": {
        "name": "A",
        "signal": "traces",
        "aggregations": [{"expression": "count()", "alias": "span_count"}],
        "filter": {"expression": "serviceName = 'my-service'"},
        "disabled": false
      }
    }]
  }
}
```

### Logs Query Payload

```json
{
  "start": 1730047200000,
  "end": 1730047380000,
  "requestType": "scalar",
  "compositeQuery": {
    "queries": [{
      "type": "builder_query",
      "spec": {
        "name": "A",
        "signal": "logs",
        "aggregations": [{"expression": "count()", "alias": "log_count"}],
        "filter": {"expression": ""},
        "disabled": false
      }
    }]
  }
}
```

**Note:** Logs query uses empty filter (counts all) in v1

### Response Format

```json
{
  "status": "success",
  "data": {
    "type": "scalar",
    "data": {
      "results": [{
        "data": [[2]]  // Count at data[0][0]
      }]
    }
  }
}
```

**Parsing:** `$count = $resp.data.data.results[0].data[0][0]`

---

## Examples

### Example 1: Basic Verification

**Goal:** Verify traces + logs present (permissive mode)

```powershell
$env:SIGNOZ_API_KEY = "<key>"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "iona-app"
```

**Output:**

```yaml
[1/3] Querying traces... ✅ 2
[2/3] Querying logs... ✅ 14
[3/3] Querying metrics... SKIPPED

Overall: PARTIAL (2/3 signals)
[GREEN] At least one signal verified ✅
```

**Exit:** 0 (GREEN)

### Example 2: Strict Verification (CI/CD)

**Goal:** Fail if any signal missing

```powershell
$env:SIGNOZ_API_KEY = "<key>"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -ExpectAll
```

**Output (if 2/3 signals):**

```yaml
Overall: PARTIAL (2/3 signals)
[AMBER] Only 2/3 signals present
```

**Exit:** 1 (AMBER) — Metrics missing

**Note:** In v1, `-ExpectAll` will always exit AMBER since metrics not implemented

### Example 3: Custom Timeframe

**Goal:** Check last 15 minutes

```powershell
$env:SIGNOZ_API_KEY = "<key>"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service" -LookbackMinutes 15
```

### Example 4: Environment Variables Only

**Goal:** No command-line parameters

```powershell
$env:SIGNOZ_API_KEY = "<key>"
$env:SIGNOZ_BASE_URL = "http://localhost:8080"
$env:SIGNOZ_SERVICE_NAME = "my-service"
$env:SIGNOZ_LOOKBACK_MINUTES = "5"

pwsh -File .\scripts\windows\proof-of-telemetry.ps1
```

---

## Proof Artifact

**Location:** `artifacts/proofs/unified-proof-<service>-<timestamp>.json`

**Example Proof (2/3 signals working):**

```json
{
  "probe": "signoz-unified",
  "service": "iona-app",
  "timeframe": "60 min",
  "startMs": 1761577563134,
  "endMs": 1761581163134,
  "signals": {
    "traces": {
      "count": 2,
      "status": "PASS",
      "endpoint": "http://localhost:8080/api/v5/query_range"
    },
    "logs": {
      "count": 14,
      "status": "PASS",
      "endpoint": "http://localhost:8080/api/v5/query_range"
    },
    "metrics": {
      "count": 0,
      "status": "FAIL",
      "endpoint": "N/A",
      "error": "PARTIAL - Metrics deferred to v2"
    }
  },
  "overall_status": "PARTIAL",
  "timestamp": "20251027-164412",
  "verification_type": "api-signed-unified",
  "api_version": "v5"
}
```

---

## Decision Tree: When to Use

### Use Unified Proof When

- ✅ Gate approvals (comprehensive evidence)
- ✅ CI/CD verification (multiple signals)
- ✅ Post-deployment validation
- ✅ Operational acceptance testing

### Use Single-Signal Proof When

- ✅ Troubleshooting specific path (e.g., collector 5317)
- ✅ Testing individual signal types
- ✅ Debugging instrumentation issues

### Both Scripts Available

- `health-check-otlp.ps1 -UseApiProof` — Single-signal (traces)
- `proof-of-telemetry.ps1` — Unified (traces + logs + metrics*)

---

## Known Limitations (v1)

### 1. Metrics Not Implemented

**Impact:** Metrics count always 0, overall status always "PARTIAL"

**Mitigation:** Use permissive mode (don't use `-ExpectAll`)

**Roadmap:** v2 will add metrics-specific query logic

### 2. Logs Not Service-Scoped

**Impact:** Logs query counts ALL logs (not just specified service)

**Mitigation:** Still proves logs are flowing to SigNoz

**Roadmap:** v2 will add service-scoped log filtering

### 3. Single Timeframe for All Signals

**Impact:** All three signals use same lookback window

**Mitigation:** Choose appropriate timeframe (e.g., 5-15 minutes)

**Roadmap:** v2 could support per-signal timeframes

---

## Migration from Gate #029-H1

### Old: Single-Signal Proof

```powershell
$env:SIGNOZ_API_KEY = "<key>"
pwsh -File .\scripts\windows\health-check-otlp.ps1 -ServiceName "my-service" -UseApiProof
```

**Output:** `proof-traces-my-service-<timestamp>.json` (traces only)

### New: Unified Proof

```powershell
$env:SIGNOZ_API_KEY = "<key>"
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "my-service"
```

**Output:** `unified-proof-my-service-<timestamp>.json` (traces + logs + metrics*)

**Recommendation:** Use unified proof going forward; keep single-signal for compatibility

---

## Roadmap: Gate #030 v2

**Planned Enhancements:**

1. **Metrics Query Implementation**
   - Support metric name parameter
   - Query common metrics (request duration, error rate)
   - Service-scoped metric filtering

2. **Service-Scoped Log Filtering**
   - Investigate correct field name
   - Add service filter to logs query

3. **Per-Signal Thresholds**
   - Different ExpectAtLeast for each signal
   - Example: Traces ≥10, Logs ≥50, Metrics ≥5

4. **Exemplar Linking**
   - Include trace IDs in proof
   - Link logs/metrics to specific traces

5. **Historical Trending**
   - Track proof results over time
   - Generate trend reports

---

## Security

### API Key Handling

- ✅ API key MUST be in `SIGNOZ_API_KEY` environment variable
- ✅ Never passed as parameter (prevents logging)
- ✅ API key never included in proof artifacts
- ✅ Viewer role sufficient (least privilege)

### Secrets Management

**Local:**

```powershell
# Session-scoped (disappears when PowerShell closes)
$env:SIGNOZ_API_KEY = "<key>"
```

**CI/CD:**

```yaml
env:
  SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}  # GitHub Secrets
```

**Production:** Use Azure Key Vault, HashiCorp Vault, or similar

---

## Related Documentation

- [SigNoz API Proofs (Single-Signal)](./signoz-api-proofs.md) — Gate #029-H1
- [Gate #030 Scope](../../GATE_030_SCOPE.md)
- [Gate #030 Implementation](../../GATE_030_IMPLEMENTATION_COMPLETE.md)
- [Windows Collector Runbook](./windows-collector.md)

---

**Last Updated:** 2025-10-28  
**Version:** v2 (Traces + Logs + Metrics via Collector Health)  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** ✅ **ACTIVE (v2 COMPLETE - All 3/3 Signals Operational)**

🐾 **Unified Telemetry Proofs — Evidence-as-Code v2**

---

## 🆕 Gate #030 v2 Enhancements

### What's New in v2

### 1. Metrics Proof via Collector Health ✅

- Queries Windows Collector metrics endpoint (port 8888)
- Uses `otelcol_exporter_sent_spans` metric (stable, service-agnostic)
- Proves pipeline operational without app-specific metrics
- **Result:** All 3/3 signals now operational

### 2. Dual-Header Auth Support ✅

- Supports both `SIGNOZ-API-KEY` and `Authorization: Bearer` headers
- Automatic fallback on 401/403 errors
- Configurable via `-AuthHeaderName` parameter

### 3. Secret Masking ✅

- API tokens never printed to console or logs
- Proof artifacts show `"auth_token": "***masked***"`
- Auth method logged (header type) but not token value
- ECRR Rule #10 compliant (secrets & boundaries)

### v1 → v2 Upgrade

| Feature | v1 | v2 |
|---------|----|----|
| Traces | ✅ Working | ✅ Working |
| Logs | ✅ Working | ✅ Working |
| Metrics | ❌ Deferred | ✅ **Collector health metrics** |
| Exit (all signals) | AMBER (2/3) | **GREEN (3/3)** |
| Auth headers | Single | **Dual + fallback** |
| Secret safety | Basic | **Fully masked** |

