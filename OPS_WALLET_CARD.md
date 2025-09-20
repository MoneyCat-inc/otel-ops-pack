# Ops Wallet Card - 60-Second Daily

## 🚀 Quick Status Check
```powershell
# Service status, path, health, metrics lines
Get-Service otelcol-contrib | Select-Object Status, Name
Get-WmiObject -Class Win32_Service -Filter "Name='otelcol-contrib'" | Select-Object PathName
.\green-sheet.ps1
```

## 🔍 Canary Check
```powershell
# Deterministic delta +1, exit 0
.\canary-check-min.ps1
```

## 🔧 Change Window (Safe)
```powershell
# Create candidate config
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# Edit candidate config
notepad C:\otel\config.candidate.yaml
# Apply safely
.\safe-apply-config.ps1
# Create audit pack
.\make-audit-pack.ps1
```

## 🧪 Resilience Rehearsal (During Window)
```powershell
# Chaos engineering drill
.\chaos-drill.ps1 -OutageSeconds 90
```

## 🔄 Auto-Restart Proof (Admin)
```powershell
# Verify auto-restart configuration
.\auto-restart-verify.ps1
```

## 🚨 Fast Rollback
```powershell
# Revert to last known good config
Copy-Item C:\otel\config.bak.*.yaml C:\otel\config.yaml -Force
Restart-Service otelcol-contrib
.\canary-check-min.ps1
```

## 📊 Service Recovery Policy (Prod Defaults)
```powershell
# Configure service failure actions
sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1
```

## 📋 CAB Record Checklist
- [ ] Latest `audit-pack_YYYYMMDD_HHMMSS.zip` + matching `.sha256.txt`
- [ ] Release tag or commit ID recorded (`git rev-parse HEAD`)
- [ ] Screenshot of `sc qfailure` output
- [ ] Service `PathName` verification
- [ ] Canary delta output confirmation (`canary-check-min.ps1`)

## 🔄 Periodic Maintenance
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.
- **Monthly:** `repo-clean-inventory.ps1` (dry-run) → confirm no drift
- **Quarterly:** `chaos-drill.ps1` (maintenance window) → verify resilience
