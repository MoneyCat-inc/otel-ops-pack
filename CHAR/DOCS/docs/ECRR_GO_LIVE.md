# 🛡️ ECRR Canary Alert — Go Live

**Date:** 2025-09-20  
**Scope:** Windows → OTel Collector → SigNoz observability stack

---

## ✅ Current Status

- **Collector:** `otelcol-contrib` running, healthz 200  
- **SigNoz UI:** Reachable at http://localhost:8080  
- **OTLP Ports:** 5317/5318 (Windows), 4317/4318 (SigNoz) open  
- **Verification:** `verify-integration.ps1` reports `== Verification complete: all checks passed ==`  
- **Canary:** Latest GUID `windows-canary-<uuid>` visible in logs  

---

## 📦 Alert Configuration

- **Name:** `ECRR Canary Missing`  
- **Query:**  
```
service.name = 'ecrr-canary'
AND attributes.canary.type = 'ecrr-enhanced'
```
- **Condition:** `count() < 1` in last 15m  
- **Evaluation Window:** 15m  
- **Check Frequency:** 5m  
- **Severity:** warning  
- **Labels:**  
  - service: ecrr-canary  
  - component: health-check  
  - framework: ecrr  

**Artifacts:**  
- `alerts/ecrr-canary-missing.json` (SigNoz import)  
- `alerts/ecrr-canary-missing.yaml` (reference)  
- `scripts/signoz/install-ecrr-alert.ps1` (installer helper)  

---

## 🚀 Deployment Procedure

1. Run installer helper:  
   ```powershell
   pwsh -File .\scripts\signoz\install-ecrr-alert.ps1
   ```

2. In SigNoz UI → **Alerts → Create Alert Rule → JSON mode**
3. Paste JSON from clipboard → **Save & Enable**
4. Add notification channel(s): email, Slack, webhook, etc.

---

## 🧪 Failure Drill

1. **Disable canary** for ~15m:

   ```powershell
   pwsh -File .\scripts\ecrr-failure-drill.ps1 -Disable
   ```
2. Wait 1–2 evaluation cycles (15m window, checked every 5m).

   * Alert should fire: *"ECRR Canary Missing"*.
3. **Re-enable canary**:

   ```powershell
   pwsh -File .\scripts\ecrr-failure-drill.ps1 -Enable
   ```
4. Confirm alert resolves automatically in SigNoz.

---

## 🧾 Rollback

* Disable or delete the alert in SigNoz UI.
* Re-enable canary task if disabled.
* Restore collector config from Git/GitHub if modified.

---

## 📋 Verification Commands

```powershell
# Check canary task status
npm run canary:status

# Generate latest report
npm run canary:report

# SigNoz Logs Explorer filter
# log.body contains "ECRR-Canary-Test"
```

---

## 👤 Role

**Observability Copilot** (Cursor Agent)

* Designed and documented ECRR gate (Examine, Clean, Report, Role).
* Built canary, failure drill, alert-as-code bundle.
* Hardened verification + CI workflows.
* Ensures reviewers & operators have a clear, auditable process.

---

## 🎯 Success Criteria

* Canary logs appear every 10m.
* Alert fires if missing for 15m.
* Alert resolves once canary resumes.
* Evidence and docs kept under version control.

---
