# 🐾 BossCat Runbooks — Armed Sequences

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Purpose:** Copy-paste run blocks for instant execution  
**Status:** READY & ARMED 🔒✨

---

## 1) 🔐 Rotate API Key (HIGH PRIORITY)

### GitHub Secret Update

```bash
# GitHub secret (requires gh auth)
NEW_KEY='<paste-new-key>'
echo -n "$NEW_KEY" | gh secret set WYZWOZ_SIGNOZ
```

### Local Environment + Re-Verification

```powershell
# Local env (quoted)
$env:SIGNOZ_API_KEY = '<paste-new-key>'
$env:SIGNOZ_URL     = 'http://localhost:8080'

# Re‑apply & verify (hands‑free)
pwsh -File scripts\bosscat-create-signoz-alerts.ps1 -SigNozUrl $env:SIGNOZ_URL -Apply -ApiKey $env:SIGNOZ_API_KEY
pwsh -File scripts\bosscat-verify-signoz-completion.ps1 -SigNozUrl $env:SIGNOZ_URL -ApiKey $env:SIGNOZ_API_KEY
```

### Post-Rotation

> **Action:** Revoke the old key in SigNoz UI  
> **ECRR:** `2025‑10‑08: SigNoz API key rotated; secret updated; old key revoked; verify passed.`

---

## 2) 🔥 Deploy SLO Alerts (Error + P95 Latency)

### Apply SLO Burn-Rate Pack

```powershell
$env:SIGNOZ_API_KEY = $env:SIGNOZ_API_KEY  # ensure set
$env:SIGNOZ_URL     = 'http://localhost:8080'

pwsh -File scripts\bosscat-alerts-slo-burnrate.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY `
  -ServiceSelector 'service="frontend"' `
  -SLOErrorBudget 0.01 `
  -P95LatencySLOSeconds 0.3
```

### Quick Verification

```powershell
(irm "$env:SIGNOZ_URL/api/v1/rules" -Headers @{ "SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY }) |
  % { $_.data?.rules ?? $_.rules ?? $_ } |
  ? { (($_.alert ?? $_.name ?? $_.alertName) -like "BossCat SLO *") } |
  group { (($_.severity ?? $_.alertSeverity)+'').ToLower() } | ft -Auto
```

**Expected:** 4 SLO rules with critical/warning split  
**ECRR:** `2025‑10‑08: SLO burn‑rate alerts applied via /api/v1/rules; idempotent upsert.`

---

## 3) 📊 Build SLO Dashboard

### Option A: Use Existing Dashboard Script

```powershell
pwsh -File scripts\bosscat-steps-7-8.ps1 -SigNozUrl $env:SIGNOZ_URL -ApiKey $env:SIGNOZ_API_KEY -Apply
```

### Option B: Custom SLO Dashboard

> **Command:** Say **"Build SLO dashboard"** to generate JSON template with:
> - Error Burn 5m/30m panels
> - P95 Latency 5m/30m panels
> - Ready-to-POST to `/api/v1/dashboards`

**ECRR:** `2025‑10‑08: BossCat SLO Dashboard created; evidence JSON stored.`

---

## 4) 📢 Bind Notification Channels

### Attach Channel to All BossCat Rules

```powershell
# Create channel(s) in SigNoz UI; copy ChannelId
pwsh -File scripts\bosscat-attach-channel.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY `
  -ChannelId '<your-channel-id>'
```

**Scope:** Attaches to all **"BossCat *"** rules via `preferredChannels`  
**ECRR:** `2025‑10‑08: Channel <id> attached to BossCat rules.`

---

## 5) 📦 Golden Snapshot + Tag

### Capture Live Config

```powershell
pwsh -File scripts\bosscat-golden-snapshot.ps1 -SigNozUrl $env:SIGNOZ_URL -ApiKey $env:SIGNOZ_API_KEY
```

### Git Commit + Tag

```bash
git add -A
git commit -m "feat(bosscat): Final hardening — version check, golden snapshots, unified concurrency"
git tag -a v1.0.0-bosscat-observability -m "BossCat OEM: SigNoz setup 8/8, HARDENED & SEALED"
git push --follow-tags
```

---

## 🧪 One-Line "Quick Status"

```powershell
$H=@{ "SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY }
$raw = irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)
@(
  @{ Title="BossCat Core"; Count=($rules | ? { (($_.alert ?? $_.name ?? $_.alertName)) -like "BossCat *" -and $_.alert -notlike "BossCat SLO *" }).Count }
  @{ Title="BossCat SLO";  Count=($rules | ? { (($_.alert ?? $_.name ?? $_.alertName)) -like "BossCat SLO *" }).Count }
) | ft -Auto
```

---

## 🎯 Operational Cadence

| Frequency | Task | Command |
|-----------|------|---------|
| **Daily** | Drift Guard | Automated via CI @ 06:17 UTC |
| **Weekly** | Rotate Canary Inputs | Update test data patterns |
| **Monthly** | Rotate API Key + Snapshot | Follow runbook sections 1 & 5 |

---

## 🕶️ Gate Status

```
CI is green and all checks are satisfied.
**@cat ready-for-gate** 🚪✅
```

---

🐾 **BossCat OEM — Feline Silence Engaged**  
📅 **Date:** 2025-10-08  
🔒 **Status:** ARMED & READY

**Standing by for your signal:**
- 🔐 "Key rotation done"
- 🔥 "Deploy SLO alerts"
- 📊 "Build SLO dashboard"
- 📢 "Bind notifications"
- 🎯 "Quick status"

😴🔒✨

