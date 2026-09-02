# SigNoz API-Signed Telemetry Proofs

**Authority:** BossCat OEM (Fubumaki)  
**Gate:** #029-H1 (Hygiene Patch)  
**Date:** 2025-10-27  
**Status:** ACTIVE

---

## Overview

The `health-check-otlp.ps1` script can query SigNoz API to verify telemetry landed,
generating machine-verifiable proof artifacts. This replaces screenshot-based evidence
with API-signed, timestamped JSON proofs.

**Benefits:**

- **Machine-verifiable:** JSON artifacts can be parsed and validated in CI/CD
- **Timestamped:** Proof includes exact timeframe queried
- **Auditable:** Query endpoint and parameters included in proof
- **Automated:** No manual screenshot capture required

---

## Configuration

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SIGNOZ_API_KEY` | Yes | API key from SigNoz Settings → API Keys (Viewer role) | `<redacted>` |
| `SIGNOZ_BASE_URL` | No | SigNoz base URL (default: `http://localhost:8080`) | `http://localhost:8080` or `https://<tenant>.signoz.io` |
| `SIGNOZ_SERVICE_NAME` | No | Service name to query | `bosscat-svc2-api` |
| `SIGNOZ_LOOKBACK_MINUTES` | No | Minutes to look back (default: 3) | `5` |

---

## Create API Key

### Self-Hosted SigNoz

1. Open SigNoz UI → **Settings** → **API Keys**
2. Click **Create New API Key**
3. Name: `proof-generation` (or descriptive name)
4. Role: **Viewer** (least privilege for queries)
5. Click **Create**
6. **Copy the key immediately** (shown only once)
7. Store securely in environment or secrets manager

### SigNoz Cloud

1. Open your SigNoz Cloud dashboard
2. Navigate to **Settings** → **API Keys**
3. Follow same steps as self-hosted
4. Use your tenant URL (e.g., `https://<tenant>.signoz.io`)

**Security Note:** Never commit API keys to git. Use environment variables or secrets managers.

---

## Usage

### Local Testing (Interactive)

```powershell
# Set environment variables
$env:SIGNOZ_API_KEY = "<your-api-key>"
$env:SIGNOZ_BASE_URL = "http://localhost:8080"
$env:SIGNOZ_SERVICE_NAME = "bosscat-svc2-api"

# Run with API proof enabled
pwsh -File .\scripts\windows\health-check-otlp.ps1 -UseApiProof -LookbackMinutes 3 -ExpectAtLeast 1
```

**Expected Output:**

```text
[OK] SigNoz traces present for 'bosscat-svc2-api': 15 ≥ 1
Proof: artifacts/proofs/proof-traces-bosscat-svc2-api-20251027-154500.json
```

### Local Testing (Without API Proof)

The script remains backward-compatible. Run without `-UseApiProof` for traditional verification:

```powershell
pwsh -File .\scripts\windows\health-check-otlp.ps1 -ServiceName "bosscat-svc2-api"
```

### CI/CD Integration (GitHub Actions)

```yaml
name: Verify Telemetry in SigNoz

on:
  workflow_dispatch:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  verify-telemetry:
    runs-on: windows-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Verify telemetry landed in SigNoz
        shell: pwsh
        env:
          SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}
          SIGNOZ_BASE_URL: ${{ vars.SIGNOZ_BASE_URL }}
          SIGNOZ_SERVICE_NAME: bosscat-svc2-api
        run: |
          ./scripts/windows/health-check-otlp.ps1 -UseApiProof -LookbackMinutes 3 -ExpectAtLeast 1
      
      - name: Upload proof artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: signoz-proof
          path: artifacts/proofs/*.json
          retention-days: 30
```

**Setup:**

1. Add `SIGNOZ_API_KEY` to repository secrets (**Settings** → **Secrets and variables** → **Actions**)
2. Add `SIGNOZ_BASE_URL` to repository variables (e.g., `http://localhost:8080`)
3. Workflow will fail if telemetry verification fails (exit code 21)

---

## Output

### Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `0` | **GREEN** | Telemetry verified, proof generated |
| `1` | **AMBER** | Collector working but traces not in SigNoz |
| `2` | **RED** | Collector not listening or SigNoz query failed |
| `21` | **RED** | Configuration error (missing API key, service name) |

### Proof Artifacts

JSON files generated in `artifacts/proofs/` with naming pattern: `proof-traces-<service-name>-<timestamp>.json`

**Example proof file:**

```json
{
  "probe": "signoz-traces",
  "service": "bosscat-svc2-api",
  "timeframe": "3 min",
  "startMs": 1730047200000,
  "endMs": 1730047380000,
  "count": 15,
  "endpoint": "http://localhost:8080/api/v5/query_range",
  "timestamp": "20251027-154500",
  "verification_type": "api-signed",
  "api_version": "v5"
}
```

**Fields:**

- `probe`: Proof type (always `signoz-traces` for this script)
- `service`: Service name queried
- `timeframe`: Human-readable lookback period
- `startMs`/`endMs`: Unix timestamp (milliseconds) of query window
- `count`: Number of traces found
- `endpoint`: SigNoz API endpoint used
- `timestamp`: Proof generation timestamp
- `verification_type`: Authentication method (api-signed)
- `api_version`: SigNoz API version (v5)

---

## Troubleshooting

### Error: "SIGNOZ_API_KEY environment variable required"

**Cause:** API proof mode enabled but API key not set.

**Fix:**

```powershell
$env:SIGNOZ_API_KEY = "<your-api-key>"
```

### Error: "ServiceName required when using API proof"

**Cause:** `-UseApiProof` specified but no service name provided.

**Fix:** Provide via parameter or environment:

```powershell
# Option 1: Parameter
pwsh -File .\scripts\windows\health-check-otlp.ps1 -ServiceName "bosscat-svc2-api" -UseApiProof

# Option 2: Environment
$env:SIGNOZ_SERVICE_NAME = "bosscat-svc2-api"
pwsh -File .\scripts\windows\health-check-otlp.ps1 -UseApiProof
```

### HTTP 401: Unauthorized

**Cause:** Invalid or expired API key.

**Fix:**

1. Regenerate API key in SigNoz UI (Settings → API Keys)
2. Update `SIGNOZ_API_KEY` environment variable
3. Verify key has at least **Viewer** role

### HTTP 404: Endpoint not found

**Cause:** Wrong SigNoz base URL or API version mismatch.

**Fix:**

1. Verify `SIGNOZ_BASE_URL` points to correct SigNoz instance
2. Self-hosted: `http://localhost:8080` (legacy SigNoz installs used `:3301`)
3. Cloud: Use your tenant URL (e.g., `https://<tenant>.signoz.io`)
4. Ensure SigNoz version supports `/api/v5/query_range` (v0.31+)

### Proof count is 0 but service is running

**Cause:** Service might not be sending telemetry, or lookback window too short.

**Fix:**

1. Increase lookback window: `-LookbackMinutes 15`
2. Generate traffic to service before running proof
3. Verify service is instrumented and sending to correct endpoint
4. Check SigNoz UI manually to confirm traces exist

---

## API Reference

### SigNoz API Endpoint

**URL:** `POST {BASE_URL}/api/v5/query_range`

**Headers:**

- `Content-Type: application/json`
- `SIGNOZ-API-KEY: <your-api-key>`

**Payload (Trace Count):**

```json
{
  "start": 1730047200000,
  "end": 1730047380000,
  "requestType": "scalar",
  "compositeQuery": {
    "queries": [
      {
        "type": "builder_query",
        "spec": {
          "name": "A",
          "signal": "traces",
          "aggregations": [
            {"expression": "count()", "alias": "span_count"}
          ],
          "filter": {
            "expression": "serviceName = 'bosscat-svc2-api'"
          },
          "disabled": false
        }
      }
    ]
  }
}
```

**Response (Success):**

```json
{
  "data": {
    "result": {
      "A": {
        "value": 15
      }
    }
  }
}
```

**Documentation:**

- [SigNoz Trace API Overview](https://signoz.io/docs/traces-management/trace-api/overview/)
- [Trace API Payload Model](https://signoz.io/docs/traces-management/trace-api/payload-model/)

---

## Security Best Practices

1. **Least Privilege:** Use **Viewer** role API keys (read-only)
2. **Rotation:** Rotate API keys every 90 days
3. **Secrets Management:** Store in GitHub Secrets, Azure Key Vault, or similar
4. **Never Commit:** Add `*.key`, `*.secret` to `.gitignore`
5. **Audit:** Review API key usage in SigNoz logs periodically

---

## Unified proofs (Gate #030) — shipped

This runbook covers the **traces-only** proof. Gate #030 delivered the unified proof (v2: traces + logs +
metrics, 3/3 signals) — see `unified-telemetry-proofs.md`. What it added, for reference:

- **Logs:** Query `/api/v5/query_range` with `signal: "logs"`
- **Metrics:** Query `/api/v5/query_range` with `signal: "metrics"`
- **Unified Proof:** Single artifact with all three signals
- **Pass Criteria:** GREEN only if traces + logs + metrics all present

---

## Related Documentation

- [Gate #029 Implementation](../archive/gates/2025-11/GATE_029_IMPLEMENTATION_COMPLETE.md)
- [Gate #029 Approval](../archive/gate/2025-10/GATE_029_APPROVAL.md)
- [Gate #029 Hygiene Patch H1](../archive/gates/2025-11/GATE_029_HYGIENE_PATCH_H1.md)
- [Windows Collector Runbook](./windows-collector.md)

---

**Last Updated:** 2025-10-27; truth pass 2026-09-01 (SigNoz UI port 8080, Gate #030 shipped)  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** ACTIVE — Gate #029-H1 Hygiene Patch

🐾 **Machine-Verifiable Evidence for Gate Approvals**

