# OpenTelemetry Collector - Hardened Ops Package

Production-ready observability package with hardened collector configuration and day-2 operational tooling.

## 🚀 Quick Start

### Daily Ops (60 seconds)
```powershell
C:\otel\green-sheet.ps1
C:\otel\canary-check-min.ps1
```

### Safe Change
```powershell
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# edit candidate...
C:\otel\safe-apply-config.ps1
C:\otel\make-audit-pack.ps1
```

### Service Status
```powershell
# Check service status and health
.\green-sheet.ps1
```

### Canary Check
```powershell
# Run deterministic canary test
.\canary-check-min.ps1
```

## 📋 Ops Wallet Card

### ops: 60-second daily
```powershell
# Service, path, health, metrics lines
Get-Service otelcol-contrib | Select-Object Status, Name
Get-WmiObject -Class Win32_Service -Filter "Name='otelcol-contrib'" | Select-Object PathName
.\green-sheet.ps1
```

### change window (safe)
```powershell
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# edit candidate
.\safe-apply-config.ps1
.\make-audit-pack.ps1
```

### resilience rehearsal (during a window)
```powershell
.\chaos-drill.ps1 -OutageSeconds 90
```

### auto-restart proof (admin)
```powershell
.\auto-restart-verify.ps1
```

## 🔧 Core Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `canary-check-min.ps1` | Minimal canary check | Daily health verification |
| `green-sheet.ps1` | Status dashboard | Quick system overview |
| `quick-all-green.ps1` | Quick verification | Fast health check |
| `auto-restart-verify.ps1` | Auto-restart verification | Admin configuration check |
| `safe-apply-config.ps1` | Safe config application | Change management |
| `chaos-drill.ps1` | Chaos engineering | Resilience testing |
| `make-audit-pack.ps1` | Audit packaging | Compliance evidence |
| `setup-weekly-audit.ps1` | Weekly audit setup | Hands-off evidence trail |
| `post-deploy-smoke.ps1` | CI/CD smoke test | Pipeline gate validation |
| `generate-wallet-card-pdf.ps1` | PDF generation | Printable wallet card |

## 📁 Repository Structure

```
C:\otel\
├── config.yaml                    # Primary configuration
├── config-hardened-plus.yaml      # Hardened configuration
├── canary-check-min.ps1          # Minimal canary check
├── green-sheet.ps1               # Status check
├── quick-all-green.ps1           # Quick verification
├── auto-restart-verify.ps1       # Auto-restart verification
├── safe-apply-config.ps1         # Safe config application
├── chaos-drill.ps1               # Chaos engineering
├── make-audit-pack.ps1           # Audit packaging
├── setup-weekly-audit.ps1        # Weekly audit setup
├── post-deploy-smoke.ps1         # CI/CD smoke test
├── generate-wallet-card-pdf.ps1  # PDF generation
├── wallet-card.html              # Printable wallet card
├── FINALIZATION_COMPLETE.md      # Finalization documentation
├── ON_CALL_RUNBOOK.md            # On-call procedures
├── HANDOFF_CHECKLIST.md          # Handoff checklist
├── OPS_WALLET_CARD.md            # Quick reference
├── logs\                         # Operational logs
├── audit\                        # Audit packs
├── queue\                        # Queue management
├── state\                        # State files
└── baseline\                     # Baseline configurations
```

## 🔄 Maintenance Schedule

- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off)
- **Monthly:** `repo-clean-inventory.ps1` (dry-run) → confirm no drift
- **Quarterly:** `chaos-drill.ps1` (maintenance window) → verify resilience
- **CI/CD:** `post-deploy-smoke.ps1` → pipeline gate validation

## 🚨 Emergency Procedures

### Fast Rollback
```powershell
# Revert to last known good config
Copy-Item C:\otel\config.bak.*.yaml C:\otel\config.yaml -Force
Restart-Service otelcol-contrib
.\canary-check-min.ps1
```

### Service Recovery Policy
```powershell
# Configure service failure actions
sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1
```

## 📊 Release Information

- **Version:** v1.0.0
- **Release Date:** $(Get-Date -Format 'yyyy-MM-dd')
- **Artifact:** `ops-pack.zip` with SHA256 verification
- **Compatibility:** PowerShell 5.1+, Windows 10/11, Windows Server 2016+

## 🔒 Security & Compliance

- ASCII-only scripts for maximum compatibility
- Idempotent operations for safe re-runs
- Audit trail via `make-audit-pack.ps1`
- Immutable release artifacts with SHA256 verification

## 🔧 Repository Maintenance

### Clean Up Merged Branches
```bash
# prune merged branches locally
git fetch --all --prune
git branch --merged main | egrep -v "^\*|main|master|release/" | xargs -n1 git branch -d

# delete merged remote branches (review carefully)
git branch -r --merged origin/main | egrep -v "origin/(main|master|release/)" \
  | sed 's#origin/##' | xargs -n1 -I{} git push origin --delete {}

# compact history
git gc --aggressive --prune=now
```

### Repository Status
```bash
# Check repository health
git status
git log --oneline -5
gh repo view fubumaki/otel-ops-pack
```

## 📞 Support

See `ON_CALL_RUNBOOK.md` for detailed operational procedures and troubleshooting guides.
