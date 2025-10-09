# 🐾 BossCat OEM - Acceptance Checklist

**Objective criteria for transitioning gate from HOLD → APPROVED**

---

## 🎯 Acceptance Criteria

Exit HOLD status **ONLY** when **ALL** of the following are true:

### 1. ✅ Preflight Passes
```powershell
pwsh -File scripts\preflight.ps1
# Must return: exit code 0
# Must show: ✅ Preflight OK - All prerequisites met
```

**Validates:**
- Windows collector service running
- OTLP endpoint reachable (port 4318)
- Python available with OpenTelemetry packages
- SigNoz API key configured
- Proxy configuration (if applicable)

---

### 2. ✅ Verification Passes (OK Outcome)
```powershell
pwsh -File scripts\verify-pipeline.ps1
# Must return: exit code 0
# Must show: ✅ VERIFICATION OK — pipeline healthy
```

**Check JSON:**
```powershell
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
$j.outcome     # Must be: "OK"
$j.exit_code   # Must be: 0
```

---

### 3. ✅ Forensic Features Validated
```powershell
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
$canary = $j.steps.canary_send

# All must be true:
$canary.trace_id -match '^[0-9a-f]{32}$'     # 32-char hex trace ID
$canary.canary_id -match '^\d+$'             # Numeric canary ID
$canary.log_confirmed -eq $true              # Collector logs confirmed
$canary.api_confirmed -eq $true              # SigNoz API confirmed
$canary.api_reason -eq "span_found"          # API found the span
$canary.api_mode -match "PINPOINT"           # Forensic mode active
```

**Verification:**
- [ ] `trace_id` present and valid (32-char hex)
- [ ] `api_confirmed` is true
- [ ] `log_confirmed` is true
- [ ] `api_mode` is "PINPOINT (traceID)"

---

### 4. ✅ Ingest Latency Within SLO

**Single Run:**
```powershell
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
$latency = $j.steps.canary_send.ingest_latency_ms

# Must be:
$latency -ne $null                          # Measured successfully
$latency -gt 0                              # Positive value
$latency -lt 5000                           # Under SLO target
```

**P95 (Historical):**
```powershell
pwsh -File scripts\calc-p95-latency.ps1
# Must return: exit code 0
# Must show: P95 Latency SLO: PASS (< 5000ms)
```

**Verification:**
- [ ] Current run latency measured (not null)
- [ ] Current run latency < 5000ms
- [ ] P95 latency < 5000ms (if enough history)

---

### 5. ✅ Artifacts Generated

**Evidence Pack:**
```powershell
# Must exist for current run
$latest = dir out\evidence-*.zip | sort LastWriteTime -desc | select -first 1
$age = ((Get-Date) - $latest.LastWriteTime).TotalMinutes

$age -lt 10  # Created within last 10 minutes
```

**Trend CSV:**
```powershell
# Must exist with recent entry
Test-Path out\gate_verification_trend.csv
$lastLine = Get-Content out\gate_verification_trend.csv -Tail 1
$lastLine -match (Get-Date).ToString("yyyy-MM-dd")
```

**Verification:**
- [ ] Evidence pack exists (created within 10 min)
- [ ] Trend CSV exists with recent entry

---

### 6. ✅ Schema Validation Passes
```powershell
$json = Get-Content out\gate_verification.json -Raw
$schemaValid = $json | Test-Json -SchemaFile schemas\gate_verification.schema.json

$schemaValid -eq $true  # Must pass schema validation
```

**Verification:**
- [ ] JSON conforms to schema

---

### 7. ✅ Pester Tests Pass
```powershell
Import-Module Pester -ErrorAction Stop
$result = Invoke-Pester -Path tests\GateVerification.tests.ps1 -PassThru

$result.FailedCount -eq 0  # No test failures
$result.Result -eq 'Passed'  # Overall result is Passed
```

**Verification:**
- [ ] All Pester tests pass
- [ ] Business rules enforced
- [ ] Exit code mapping validated

---

### 8. ✅ Gate Flipped with Reason
```powershell
pwsh -File scripts\set-gate-status.ps1 -Status APPROVED -Reason "Forensic-grade verification complete"

# Verify update
cat docs\ecrr\GATE_STATUS.md
# Must show: Status: APPROVED
# Must show: Reason: Forensic-grade verification complete
```

**Verification:**
- [ ] Gate status updated to APPROVED
- [ ] Reason clearly documented
- [ ] Timestamp recent

---

## 📋 Acceptance Workflow

### Step-by-Step Validation

```powershell
# 1) Preflight
pwsh -File scripts\preflight.ps1
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Fix preflight issues"; exit }

# 2) Verify and flip (one command)
pwsh -File scripts\verify-and-flip.ps1
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Verification failed"; exit }

# 3) Check outcome
$j = Get-Content out\gate_verification.json | ConvertFrom-Json
if ($j.outcome -ne "OK") { Write-Host "❌ Outcome is $($j.outcome)"; exit }

# 4) Verify forensic features
$c = $j.steps.canary_send
if (-not $c.trace_id) { Write-Host "❌ No trace ID"; exit }
if (-not $c.api_confirmed) { Write-Host "❌ API not confirmed"; exit }
if ($c.api_mode -notmatch "PINPOINT") { Write-Host "❌ Not PINPOINT mode"; exit }

# 5) Check latency
if (-not $c.ingest_latency_ms) { Write-Host "❌ No latency measured"; exit }
if ($c.ingest_latency_ms -ge 5000) { Write-Host "⚠️  Latency exceeds SLO"; }

# 6) Verify artifacts
if (-not (Test-Path out\gate_verification_trend.csv)) { Write-Host "❌ No trend CSV"; exit }
$latestEvidence = dir out\evidence-*.zip -ErrorAction SilentlyContinue | sort LastWriteTime -desc | select -first 1
if (-not $latestEvidence) { Write-Host "❌ No evidence pack"; exit }

# 7) Schema validation
$json = Get-Content out\gate_verification.json -Raw
if (-not ($json | Test-Json -SchemaFile schemas\gate_verification.schema.json)) { 
  Write-Host "❌ Schema validation failed"; exit 
}

# 8) Pester tests (optional but recommended)
try {
  Import-Module Pester -ErrorAction Stop
  $result = Invoke-Pester -Path tests\GateVerification.tests.ps1 -PassThru
  if ($result.FailedCount -gt 0) { Write-Host "⚠️  $($result.FailedCount) test(s) failed"; }
} catch {
  Write-Host "ℹ️  Pester tests skipped (not installed)"
}

# 9) All checks passed
Write-Host ""
Write-Host "✅ ALL ACCEPTANCE CRITERIA MET" -ForegroundColor Green
Write-Host ""
Write-Host "Gate is APPROVED for production operations." -ForegroundColor Green
Write-Host "Current status: $(cat docs\ecrr\GATE_STATUS.md | Select-String 'Status:' | Select-Object -First 1)"
```

---

## 🎯 Objective APPROVED Criteria Summary

**All Must Be True:**

1. ✅ Preflight passes (exit 0)
2. ✅ Verification outcome = "OK" (exit 0)
3. ✅ Trace ID captured (32-char hex)
4. ✅ API confirmed = true
5. ✅ Log confirmed = true
6. ✅ API mode = "PINPOINT (traceID)"
7. ✅ Ingest latency measured and < 5000ms
8. ✅ P95 latency < 5000ms (if enough history)
9. ✅ Evidence pack generated (within 10 min)
10. ✅ Trend CSV exists with recent entry
11. ✅ Schema validation passes
12. ✅ Pester tests pass (or N/A if not installed)
13. ✅ Gate flipped to APPROVED with reason

**If ANY criterion fails:** Gate remains HOLD

---

## 📝 Acceptance Sign-Off Template

```markdown
## BossCat Acceptance Sign-Off

**Date:** YYYY-MM-DD HH:MM UTC
**Gate ID:** GATE-2025-10-08-234500
**Verifier:** <name>

### Acceptance Criteria

- [x] Preflight passes
- [x] Verification outcome = OK
- [x] Trace ID captured
- [x] API confirmed = true
- [x] Log confirmed = true
- [x] API mode = PINPOINT
- [x] Ingest latency < 5000ms
- [x] P95 latency < 5000ms
- [x] Evidence pack generated
- [x] Trend CSV updated
- [x] Schema validation passes
- [x] Pester tests pass

### Evidence

- Verification JSON: out/gate_verification.json
- Trend CSV: out/gate_verification_trend.csv
- Evidence pack: out/evidence-YYYYMMDD-HHMMSSZ.zip
- Gate status: docs/ecrr/GATE_STATUS.md

### Decision

**Status:** APPROVED ✅
**Reason:** Forensic-grade verification complete - all acceptance criteria met
**Approved By:** 🐾 BossCat OEM
**Date:** YYYY-MM-DD HH:MM UTC

Signature: _____________________
```

---

## 🔄 Nightly Validation Flow

**For CI/CD or scheduled tasks:**

```powershell
# Run preflight first
& pwsh -NoProfile -File scripts\preflight.ps1
if ($LASTEXITCODE -ne 0) { 
  Write-Host "Preflight failed - sending alert"
  # Send notification, create issue, etc.
  exit 2
}

# Run verification + flip
& pwsh -NoProfile -File scripts\verify-and-flip.ps1 -Strict

# Check acceptance criteria
# (Copy validation commands from above)

# If all pass: APPROVED is maintained
# If any fail: HOLD is triggered
```

---

🐾 **BossCat OEM** | Acceptance Criteria Defined  
**Status:** Objective criteria for HOLD → APPROVED  
**Use:** Enforce before any gate approval

**Now implementing final features...** 🎯

