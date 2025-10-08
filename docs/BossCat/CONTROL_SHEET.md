# 🐾 BossCat Control Sheet — Final Execution Sequences

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Purpose:** Production-ready execution sequences with preflight checks  
**Status:** ARMED & READY 🔒✨

---

## 🔐 1) API Key Rotation — Execute & Seal (HIGH PRIORITY)

### GitHub Secret Update

```bash
# GitHub secret (requires gh auth)
NEW_KEY='<paste-new-key>'
echo -n "$NEW_KEY" | gh secret set WYZWOZ_SIGNOZ
```

### Local Environment + Re-Verification

```powershell
# Local env for this session
$env:SIGNOZ_URL     = 'http://localhost:8080'
$env:SIGNOZ_API_KEY = '<paste-new-key>'  # quoted

# Re-apply & verify (hands-free)
pwsh -File scripts\bosscat-create-signoz-alerts.ps1 -SigNozUrl $env:SIGNOZ_URL -Apply -ApiKey $env:SIGNOZ_API_KEY
pwsh -File scripts\bosscat-verify-signoz-completion.ps1 -SigNozUrl $env:SIGNOZ_URL -ApiKey $env:SIGNOZ_API_KEY
```

### Post-Rotation

> **Action:** Revoke the **old** key in SigNoz UI  
> **ECRR line:**
> ```
> 2025-10-08: SigNoz API key rotated; GitHub secret WYZWOZ_SIGNOZ updated; old key revoked; verify passed.
> ```

---

## 🔥 2) Deploy SLO Alerts — Preflight → Apply → Accept

### Preflight (Verify Metrics Exist)

```powershell
$env:SIGNOZ_URL='http://localhost:8080'; $H=@{ 'SIGNOZ-API-KEY'=$env:SIGNOZ_API_KEY }
# Quick metadata sniff: look for candidate metric names
# (Expect to see names like http_server_request_duration_seconds_count/_bucket)
```

> **If your metric names differ**, update in `bosscat-alerts-slo-burnrate.ps1`:
> - `$reqMetric` (per‑request counter)
> - `$bucketMetric` (latency histogram buckets)
> - `$errSelector` (how you mark 5xx)

### Apply SLO Pack

```powershell
pwsh -File scripts\bosscat-alerts-slo-burnrate.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY `
  -ServiceSelector 'service="frontend"' `
  -SLOErrorBudget 0.01 `
  -P95LatencySLOSeconds 0.3
```

### Acceptance (Must Show 4 SLO Rules)

```powershell
(irm "$env:SIGNOZ_URL/api/v1/rules" -Headers @{ "SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY }) |
  % { $_.data?.rules ?? $_.rules ?? $_ } |
  ? { (($_.alert ?? $_.name ?? $_.alertName) -like "BossCat SLO *") } |
  % { [pscustomobject]@{ Name=($_.alert ?? $_.name); Sev=(($_.severity ?? $_.alertSeverity)+''); Disabled=[bool]$_.disabled } } |
  ft -Auto
```

**Expected:**
- 4 entries
- Appropriate warning/critical split
- `Disabled=False`

**ECRR line:**
```
2025-10-08: SLO burn-rate alerts (error + P95 latency) applied via /api/v1/rules; idempotent upsert; verified present/enabled.
```

---

## 📊 3) Build SLO Dashboard — Two Ways

### Option A: Use Existing Dashboard Script (Fastest)

```powershell
pwsh -File scripts\bosscat-steps-7-8.ps1 -SigNozUrl $env:SIGNOZ_URL -ApiKey $env:SIGNOZ_API_KEY -Apply
```

### Option B: Custom SLO Dashboard

> **Command:** Say **"Build SLO dashboard"** to generate JSON template with:
> - Error Burn 5m/30m panels
> - P95 Latency 5m/30m panels
> - Ready-to-POST to `/api/v1/dashboards`

**ECRR line:**
```
2025-10-08: BossCat SLO Dashboard created; evidence JSON stored; panels render OK.
```

---

## 📢 4) Bind Notification Channels — Safe Attach

### Prerequisites
- Create channel(s) in SigNoz UI
- Copy ChannelId from UI

### Execute

```powershell
pwsh -File scripts\bosscat-attach-channel.ps1 `
  -SigNozUrl $env:SIGNOZ_URL `
  -ApiKey $env:SIGNOZ_API_KEY `
  -ChannelId '<your-channel-id>'
```

**Notes:**
- Scoped to `"BossCat *"` rules only
- Preserves existing channels; adds if not present

**ECRR line:**
```
2025-10-08: Attached notification channel <id> to all "BossCat *" rules (preferredChannels).
```

---

## 📦 5) Golden Snapshot + Tag

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

## 🧯 Break-Glass — Maintenance Noise Control

### Temporarily Disable All BossCat Rules

```powershell
$H=@{ "SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY }
$raw = irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)

# Disable
$rules | ? { (($_.alert ?? $_.name ?? $_.alertName) -like 'BossCat *') } | % {
  $id = ($_.id ?? $_._id ?? $_.ruleId)
  if ($id) {
    $_.disabled=$true
    irm "$env:SIGNOZ_URL/api/v1/rules/$id" -Headers $H -Method PUT -Body ($_|ConvertTo-Json -Depth 20) | Out-Null
    Write-Host "🔇 Disabled: $($_.alert ?? $_.name)"
  }
}
```

### Re-Enable All BossCat Rules

```powershell
$H=@{ "SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY }
$raw = irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)

# Re-enable
$rules | ? { (($_.alert ?? $_.name ?? $_.alertName) -like 'BossCat *') } | % {
  $id = ($_.id ?? $_._id ?? $_.ruleId)
  if ($id) {
    $_.disabled=$false
    irm "$env:SIGNOZ_URL/api/v1/rules/$id" -Headers $H -Method PUT -Body ($_|ConvertTo-Json -Depth 20) | Out-Null
    Write-Host "🔔 Enabled: $($_.alert ?? $_.name)"
  }
}
```

---

## 🧪 One-Line Quick Status

```powershell
$H=@{ "SIGNOZ-API-KEY"=$env:SIGNOZ_API_KEY }
$raw=irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules=@($raw.data?.rules ?? $raw.rules ?? $raw)
@(
  @{ Title="BossCat Core"; Count=($rules | ? { (($_.alert ?? $_.name ?? $_.alertName)) -like "BossCat *" -and (($_.alert ?? $_.name ?? $_.alertName)) -notlike "BossCat SLO *" }).Count }
  @{ Title="BossCat SLO";  Count=($rules | ? { (($_.alert ?? $_.name ?? $_.alertName)) -like "BossCat SLO *" }).Count }
) | ft -Auto
```

---

## 📋 Execution Checklist

### Before Any Deployment

- [ ] SigNoz health check passed
- [ ] API key set: `$env:SIGNOZ_API_KEY`
- [ ] SigNoz URL set: `$env:SIGNOZ_URL`
- [ ] Scripts are latest version

### After Each Deployment

- [ ] Acceptance test passed
- [ ] ECRR line appended to log
- [ ] Evidence artifacts saved
- [ ] UI verification completed

### Before Production Tag

- [ ] All alerts enabled and verified
- [ ] Golden snapshot captured
- [ ] Documentation updated
- [ ] CI/CD workflows passing

---

## 🎯 Signal Commands

**Just say:**
- 🔐 `"Key rotation done"` — After rotation complete
- 🔥 `"Deploy SLO alerts"` — Execute SLO pack
- 📊 `"Build SLO dashboard"` — Generate dashboard JSON
- 📢 `"Bind notifications"` — Attach channels
- 📦 `"Snapshot and tag"` — Final golden snapshot + v1.0.0
- 🎯 `"Quick status"` — Show current state

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

**Standing by for your signal.** 😴🔒✨

