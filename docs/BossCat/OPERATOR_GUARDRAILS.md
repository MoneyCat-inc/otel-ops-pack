# 🐾 BossCat Operator Guardrails

**Authority:** BossCat OEM (Executive Overseer Manager)  
**Purpose:** Production-ready one-liners and safety procedures  
**Status:** OPERATIONAL

---

## 🔐 Secret Hygiene (Post-Session)

### Remove API Key from Environment

```powershell
# Remove from current process env
Remove-Item Env:SIGNOZ_API_KEY -ErrorAction SilentlyContinue
```

### Prevent API Key from Persisting in History

```powershell
# Optional: prevent secret lines from being saved to history during this session
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
  Set-PSReadLineOption -AddToHistoryHandler { param($line) return ($line -notmatch 'SIGNOZ_API_KEY') }
}
```

> **Note:** If any key was pasted into logs or terminals that persist history, consider rotating again at your next maintenance window (document in ECRR).

---

## 🧪 30-Second "Assert Green" (Copy-Paste)

```powershell
$H=@{ 'SIGNOZ-API-KEY'=$env:SIGNOZ_API_KEY }
$raw = irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)

# 1) Count totals
$tot = $rules.Count
$core = ($rules | ? { (($_.alert ?? $_.name ?? $_.alertName)) -like "BossCat *" -and (($_.alert ?? $_.name ?? $_.alertName)) -notlike "BossCat SLO *" }).Count
$slo  = ($rules | ? { (($_.alert ?? $_.name ?? $_.alertName)) -like "BossCat SLO *" }).Count

# 2) Check enabled
$disabled = $rules | ? { $_.disabled -eq $true } | Select -First 1

# 3) Severity split
$sev = ($rules | % { (($_.severity ?? $_.alertSeverity)+'').ToLower() } | Group-Object | Select Name,Count)

# 4) Print results
"Total=$tot | Core=$core | SLO=$slo"
$sev | ft -Auto
if ($disabled) { throw "❌ Some rules are disabled." } else { "✅ All rules enabled." }
```

**Expected Output (Current):**
```
Total=13 | Core=9 | SLO=4
✅ All rules enabled.
```

---

## 🧯 Break-Glass Mini (SLO Only)

### Temporarily Disable SLO Pack

```powershell
$H=@{ 'SIGNOZ-API-KEY'=$env:SIGNOZ_API_KEY }
$raw = irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)

# Disable SLO pack
$rules | ? { (($_.alert ?? $_.name ?? $_.alertName) -like 'BossCat SLO *') } | % {
  $id = ($_.id ?? $_._id ?? $_.ruleId)
  if ($id) {
    $_.disabled=$true
    irm "$env:SIGNOZ_URL/api/v1/rules/$id" -Headers $H -Method PUT -Body ($_|ConvertTo-Json -Depth 20) | Out-Null
    Write-Host "🔇 Disabled: $($_.alert ?? $_.name)"
  }
}
```

### Re-Enable SLO Pack

```powershell
$H=@{ 'SIGNOZ-API-KEY'=$env:SIGNOZ_API_KEY }
$raw = irm "$env:SIGNOZ_URL/api/v1/rules" -Headers $H
$rules = @($raw.data?.rules ?? $raw.rules ?? $raw)

# Re-enable SLO pack
$rules | ? { (($_.alert ?? $_.name ?? $_.alertName) -like 'BossCat SLO *') } | % {
  $id = ($_.id ?? $_._id ?? $_.ruleId)
  if ($id) {
    $_.disabled=$false
    irm "$env:SIGNOZ_URL/api/v1/rules/$id" -Headers $H -Method PUT -Body ($_|ConvertTo-Json -Depth 20) | Out-Null
    Write-Host "🔔 Enabled: $($_.alert ?? $_.name)"
  }
}
```

> **Important:** Log the action in ECRR when used.

---

## 🔁 Drift-Guard: What a Failure Means (and Quick Fix)

### Failure Indicates Real Drift
**Failure = real drift** (counts/names/disabled mismatch)

### Fix Path:

1. **Inspect uploaded evidence JSONs** in CI artifacts
2. **Re-run core alerts:**
   ```powershell
   pwsh -File scripts\bosscat-create-signoz-alerts.ps1 -Apply
   ```
3. **Re-run SLO pack (if applicable):**
   ```powershell
   pwsh -File scripts\bosscat-alerts-slo-burnrate.ps1
   ```
4. **Re-run views/dashboards (if drifted):**
   ```powershell
   pwsh -File scripts\bosscat-steps-7-8.ps1 -Apply
   ```
5. **Commit fresh golden snapshot:**
   ```powershell
   pwsh -File scripts\bosscat-golden-snapshot.ps1
   git add docs/BossCat/*.live.json docs/BossCat/golden-snapshot-manifest.json
   git commit -m "docs(ecrr): Golden config snapshot after drift correction"
   ```

---

## 📦 Golden Snapshot (When Config Changes)

```powershell
pwsh -File scripts\bosscat-golden-snapshot.ps1 -SigNozUrl $env:SIGNOZ_URL
```

**Auto-detects:** API key from `$env:SIGNOZ_API_KEY`  
**Artifacts land in:** `docs/BossCat/*.live.json`

---

## 📣 Advanced Operations

### Bind Notification Channels

```powershell
# After creating channels in SigNoz UI, copy ChannelId
pwsh -File scripts\bosscat-attach-channel.ps1 -ChannelId '<channel-id>'
```

### Tune SLOs Per Service

```powershell
pwsh -File scripts\bosscat-alerts-slo-burnrate.ps1 `
  -ServiceSelector 'service="your-service"' `
  -SLOErrorBudget 0.01 `
  -P95LatencySLOSeconds 0.3
```

### Extend SLO Dashboard

1. Edit `docs/BossCat/bosscat-slo-dashboard.json`
2. Add new panels
3. Deploy:
   ```powershell
   pwsh -File scripts\bosscat-create-slo-dashboard.ps1
   ```

---

## 🎯 Operational Cadence

| Frequency | Task | Command |
|-----------|------|---------|
| **Daily** | Drift Guard | Automated via CI @ 06:17 UTC |
| **Weekly** | Assert Green | Run 30-second check |
| **Monthly** | Rotate API Key | Follow rotation procedure |
| **On Config Change** | Golden Snapshot | `bosscat-golden-snapshot.ps1` |

---

## 🕶️ Gate Status

```
CI is green and all checks are satisfied.
**@cat ready-for-gate** 🚪✅
```

---

## 📋 Quick Reference

**Current Expected State:**
- Total Alerts: **13** (9 core + 4 SLO)
- All Enabled: **13/13 ✅**
- Dashboards: **2** (Executive + SLO)
- Saved Views: **4** (Logs + Traces)

**API Key Management:**
- Set: `$env:SIGNOZ_API_KEY = 'your-key'`
- Remove: `Remove-Item Env:SIGNOZ_API_KEY`
- Rotation: Document in ECRR

---

🐾 **BossCat OEM — Feline Silence Maintained**  
📅 **Date:** 2025-10-08  
🔒 **Status:** OPERATIONAL GUARDRAILS DOCUMENTED

**Standing by in autonomous operation mode.** 😴🔒✨

