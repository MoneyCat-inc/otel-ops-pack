# OpenTelemetry Collector - Production Rollout Card

## 🚀 Golden Rollout (New Host in ~5–10 min)

**Goal:** Reproduce working setup on a fresh Windows 11 box

```powershell
# 0) Prereqs (Admin)
winget install --id OpenTelemetry.CollectorContrib -e   # or MSI if you prefer
New-Item -ItemType Directory -Force C:\otel | Out-Null

# 1) Get the ops toolkit (via git or offline zip)
git clone <repo-url> C:\otel
# or copy a release zip created with Compress-Archive into C:\otel

# 2) Install hardened config + scripts
Copy-Item -Force C:\otel\config-hardened-plus.yaml C:\otel\config.yaml

# 3) Pin service and lock in (Admin)
sc.exe stop otelcol-contrib
sc.exe config otelcol-contrib binPath= "\"C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe\" --config C:\otel\config.yaml"
sc.exe config otelcol-contrib start= auto
sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1
sc.exe start otelcol-contrib

# 4) First-time verification
C:\otel\green-sheet.ps1
C:\otel\canary-check-min.ps1     # expect delta +1
Invoke-WebRequest -Uri "http://127.0.0.1:13134/healthz" -TimeoutSec 5 | ConvertFrom-Json

# 5) (Optional) schedule local monitors
# Example: run deterministic canary every 10 minutes via Task Scheduler
$exe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$action = New-ScheduledTaskAction -Execute $exe -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\otel\canary-check-min.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName "otel_canary_10m" -Action $action -Trigger $trigger -RunLevel Highest -Force

# 6) (Optional) setup weekly auto-audit for evidence trail
C:\otel\setup-weekly-audit.ps1
```

## 🔧 Safe Change Control (Repeatable)

```powershell
# prepare candidate
Copy-Item C:\otel\config.yaml C:\otel\config.candidate.yaml -Force
# edit candidate
C:\otel\safe-apply-config.ps1           # validates, restarts, canary; auto-rollback on fail
C:\otel\make-audit-pack.ps1             # attach zip + sha256 to CAB
```

## 🧪 Quarterly Resilience Drill (During Window)

```powershell
# exporter outage simulation + recovery proof
C:\otel\chaos-drill.ps1 -OutageSeconds 90
Get-Content C:\otel\logs\chaos-drill.last.txt -Tail 200
```

## 🛡️ Branch & Release Guardrails (Once Per Repo)

* **Protect `main`**: require PRs, 1 approval, status checks (sanity workflow)
* **Protect tags**: disallow force-push; releases are immutable
* **Sign** ZIPs if your security policy requires it; always attach **SHA256**
* **.gitignore**: keep operational dirs (`logs/`, `queue/`, `backup/`, `audit/`, `state/`) and `*.last.*`, `*.zip`, `*.sha256.txt` out of git

## ⚡ Minimal Daily Ops (60 seconds)

```powershell
C:\otel\green-sheet.ps1                # service, path, health, metrics lines
C:\otel\canary-check-min.ps1           # deterministic delta +1, exit 0
```

## 🚨 "Oh No" Playbook (Fastest Paths)

* **service looks up but ingest flat:** check metrics, run canary; if still flat, `Restart-Service otelcol-contrib`
* **bad config deploy:** `Copy-Item C:\otel\config.bak.*.yaml C:\otel\config.yaml -Force; Restart-Service otelcol-contrib; C:\otel\canary-check-min.ps1`
* **prove SCM recovery:** `C:\otel\auto-restart-verify.ps1` (Admin)
* **deep evidence:** `C:\otel\make-audit-pack.ps1` (attach to incident ticket)

## 📋 Small Backlog (When You Want to Iterate)

* **AllSigned**: code-sign `C:\otel\*.ps1` and move host to `ExecutionPolicy AllSigned`
* **SigNoz API auth**: optional L3 search-side verify in canary (keep metrics-delta as the truth)
* **Weekly audit pack**: ✅ **DONE** - `setup-weekly-audit.ps1` creates hands-off evidence trail
* **Least-privilege service account**: move service off LocalSystem/LocalService with ACL'd `C:\otel`
* **CI/CD Integration**: ✅ **DONE** - `post-deploy-smoke.ps1` for pipeline gates

## ✅ What "Good" Looks Like Going Forward

* **Green-sheet** shows *Running*, config path includes `--config C:\otel\config.yaml`, health 200, metrics present
* **Canary** is near-instant, always delta +1
* **Auto-restart** fires on real failures and is logged by SCM
* **Changes** only via `safe-apply-config.ps1`; each CAB has `audit-pack_*.zip` + SHA256
* **Repo** stays lean; tasks and service always point to kept scripts

## 📊 Success Metrics

- **Deployment Time**: < 10 minutes from fresh Windows 11
- **Daily Ops Time**: < 60 seconds
- **Change Window**: < 5 minutes with auto-rollback
- **Recovery Time**: < 2 minutes for common issues
- **Audit Trail**: Complete with SHA256 verification

## 🔒 Security & Compliance

- **ASCII-only scripts** for maximum compatibility
- **Idempotent operations** for safe re-runs
- **Immutable releases** with SHA256 verification
- **Audit trail** via `make-audit-pack.ps1`
- **Self-healing runtime** with auto-restart
- **Safe-change flow** with candidate configs

---

**Version:** v1.0.0  
**Last Updated:** $(Get-Date -Format 'yyyy-MM-dd')  
**Compatibility:** PowerShell 5.1+, Windows 10/11, Windows Server 2016+
