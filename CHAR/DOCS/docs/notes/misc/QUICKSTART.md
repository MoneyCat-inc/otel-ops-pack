# 🐾 BossCat OEM - Quick Start

## Get forensic-grade verification running in 5 minutes

---

## Prerequisites (One-Time Setup)

### 1. Install Python Dependencies

```powershell
pip install opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
```

### 2. Create SigNoz API Key

```powershell
# Open SigNoz UI
Start-Process http://localhost:8080/settings/api-keys

# Click "Create New Key" → Name: "gate-verification" → Copy the key
```

### 3. Set API Key

```powershell
# Permanent (Machine level)
[Environment]::SetEnvironmentVariable("SIGNOZ_API_KEY", "your-api-key-here", "Machine")

# Temporary (current session only)
$env:SIGNOZ_API_KEY = "your-api-key-here"

# Verify
$env:SIGNOZ_API_KEY
```

### 4. Restart PowerShell (if using Machine level)

```powershell
exit  # Open new PowerShell window
```

---

## Run Verification

```powershell
# One command - full forensic verification
pwsh -File scripts\verify-pipeline.ps1
```

**Expected Output:**

```text
✓ Captured TRACE_ID: a1b2c3d4...
✓ Canary sent successfully
✓ Canary confirmed in collector logs
PINPOINT ✓ Span confirmed via SigNoz API
📊 Ingest latency: 1250 ms
✅ VERIFICATION OK — pipeline healthy
📦 Evidence pack ready for audit
```

---

## View Results

```powershell
# Latest verification
cat out\gate_verification.json | ConvertFrom-Json | Format-List

# Trend (last 20 runs)
Get-Content out\gate_verification_trend.csv -Tail 20

# Latest evidence pack
dir out\evidence-*.zip | sort LastWriteTime -desc | select -first 1
```

---

## Optional: Webhook Notifications

```powershell
# Set webhook URL (Slack/Teams/Discord)
[Environment]::SetEnvironmentVariable("BOSSCAT_WEBHOOK_URL", "https://hooks.slack.com/...", "Machine")

# Next verification will send notifications automatically
```

---

## Documentation

- **Full Guide:** `docs/POLISH_PACK_COMPLETE.md`
- **API Setup:** `docs/API_VERIFICATION_GUIDE.md`
- **Forensic Features:** `docs/FORENSIC_GRADE_COMPLETE.md`
- **Operator Guide:** `docs/OPERATOR_QUICKSTART.md`

---

🐾 **BossCat OEM** | Ready in 5 minutes

