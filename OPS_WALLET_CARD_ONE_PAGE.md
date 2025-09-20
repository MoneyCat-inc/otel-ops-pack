# Ops Wallet Card - One Page Reference

## ⚡ Daily Ops (60 seconds)
```powershell
# Service status, path, health, metrics
Get-Service otelcol-contrib | Select-Object Status, Name
Get-WmiObject -Class Win32_Service -Filter "Name='otelcol-contrib'" | Select-Object PathName
.\green-sheet.ps1

# Canary check (expect delta +1)
.\canary-check-min.ps1
```

## 🔧 Safe Changes
```powershell
# Create candidate, edit, apply safely
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# Edit candidate config
.\safe-apply-config.ps1
.\make-audit-pack.ps1
```

## 🚨 Emergency Procedures
```powershell
# Service looks up but ingest flat
Restart-Service otelcol-contrib
.\canary-check-min.ps1

# Bad config deploy (fast rollback)
Copy-Item C:\otel\config.bak.*.yaml C:\otel\config.yaml -Force
Restart-Service otelcol-contrib
.\canary-check-min.ps1

# Prove SCM recovery (Admin)
.\auto-restart-verify.ps1

# Deep evidence for incident
.\make-audit-pack.ps1
```

## 🧪 Resilience Testing
```powershell
# Quarterly drill (during window)
.\chaos-drill.ps1 -OutageSeconds 90
Get-Content C:\otel\logs\chaos-drill.last.txt -Tail 200
```

## 📊 What "Good" Looks Like
- **Green-sheet**: Running, config path includes `--config C:\otel\config.yaml`, health 200, metrics present
- **Canary**: Near-instant, always delta +1
- **Auto-restart**: Fires on real failures, logged by SCM
- **Changes**: Only via `safe-apply-config.ps1`; each CAB has `audit-pack_*.zip` + SHA256

## 🔒 Service Recovery Policy
```powershell
sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1
```

## 📋 CAB Record Checklist
- [ ] Latest `audit-pack_YYYYMMDD_HHMMSS.zip` + matching `.sha256.txt`
- [ ] Release tag or commit ID recorded (`git rev-parse HEAD`)
- [ ] Screenshot of `sc qfailure` output
- [ ] Service `PathName` verification
- [ ] Canary delta output confirmation (`canary-check-min.ps1`)

## 🔄 Maintenance Schedule
- **Weekly**: `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.
- **Monthly**: `repo-clean-inventory.ps1` (dry-run) → confirm no drift
- **Quarterly**: `chaos-drill.ps1` (maintenance window) → verify resilience

---
**Version:** v1.0.0 | **Compatibility:** PS 5.1+, Windows 10/11+ | **Emergency:** See ON_CALL_RUNBOOK.md
