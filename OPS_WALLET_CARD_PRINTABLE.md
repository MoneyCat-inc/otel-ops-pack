# 🚨 OTEL OPS WALLET CARD - PRINTABLE
**Version:** v1.1.0 | **Emergency:** See ON_CALL_RUNBOOK.md | **QR:** [Scan for full docs]

---

## ⚡ DAILY OPS (60 seconds)
```powershell
# Service status, path, health, metrics
Get-Service otelcol-contrib | Select-Object Status, Name
Get-WmiObject -Class Win32_Service -Filter "Name='otelcol-contrib'" | Select-Object PathName
.\green-sheet.ps1

# Canary check (expect delta +1)
.\canary-check-min.ps1
```

## 🔧 SAFE CHANGES
```powershell
# Create candidate, edit, apply safely
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# Edit candidate config
.\safe-apply-config.ps1
.\make-audit-pack.ps1
```

## 🚨 EMERGENCY PROCEDURES
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

## 🧪 RESILIENCE TESTING
```powershell
# Quarterly drill (during window)
.\chaos-drill.ps1 -OutageSeconds 90
Get-Content C:\otel\logs\chaos-drill.last.txt -Tail 200
```

## 📊 WHAT "GOOD" LOOKS LIKE
- **Green-sheet**: Running, config path includes `--config C:\otel\config.yaml`, health 200, metrics present
- **Canary**: Near-instant, always delta +1
- **Auto-restart**: Fires on real failures, logged by SCM
- **Changes**: Only via `safe-apply-config.ps1`; each CAB has `audit-pack_*.zip` + SHA256

## 🔒 SERVICE RECOVERY POLICY
```powershell
sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1
```

## 📋 CAB RECORD CHECKLIST
- [ ] Latest `audit-pack_YYYYMMDD_HHMMSS.zip` + matching `.sha256.txt`
- [ ] Release tag or commit ID recorded (`git rev-parse HEAD`)
- [ ] Screenshot of `sc qfailure` output
- [ ] Service `PathName` verification
- [ ] Canary delta output confirmation (`canary-check-min.ps1`)

## 🔄 MAINTENANCE SCHEDULE
- **Weekly**: `setup-weekly-audit.ps1` → automated evidence trail (hands-off); run `make-audit-pack.ps1` on-demand for manual capture
- **Monthly**: `repo-clean-inventory.ps1` (dry-run) → confirm no drift
- **Quarterly**: `chaos-drill.ps1` (maintenance window) → verify resilience
- **CI/CD**: `post-deploy-smoke.ps1` → pipeline gate validation

## 🆘 ESCALATION PATHS
- **L1**: Check service status, run canary, restart if needed
- **L2**: Verify config, check logs, run chaos drill
- **L3**: Deep dive with audit pack, check SCM recovery
- **L4**: Escalate to platform team with full evidence

## 📞 QUICK REFERENCE
- **Service**: `otelcol-contrib`
- **Config**: `C:\otel\config.yaml`
- **Logs**: `C:\otel\logs\`
- **Audit**: `C:\otel\audit\`
- **Health**: `http://127.0.0.1:13134/healthz`
- **Metrics**: `http://127.0.0.1:8889/metrics`

## 🔗 QR CODES & LINKS
- **Full Docs**: [Scan QR] → `README.md`
- **Rollout**: [Scan QR] → `ROLLOUT_CARD.md`
- **Runbook**: [Scan QR] → `ON_CALL_RUNBOOK.md`
- **Handoff**: [Scan QR] → `HANDOFF_CHECKLIST.md`

---

**🏁 This is the way. | v1.1.0 | PS 5.1+ | Windows 10/11+**
