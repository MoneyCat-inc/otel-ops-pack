# Queue Steward Production Go-Live Checklist

> Use this runbook to verify the Queue Steward pipeline before switching the production schedule. Move each completed item into a dated artifact under `artifacts/` and attach raw command output.

## How to Use
1. Create a dated copy before starting:
   ```powershell
   Copy-Item docs/QUEUE_STEWARD_GO_LIVE_CHECKLIST.md ("artifacts/go-live-{0}-queue-steward.md" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
   ```
2. Work from top to bottom, checking off each item only after capturing evidence (command output, screenshot, or log excerpt).
3. Stop immediately on any BLOCKER outcome and escalate to the release lead.

## Legend
- [ ] Pending
- [x] Done (evidence captured)
- BLOCKER Requires correction before proceeding

---

## 1. Pre-Deployment Gates

- [ ] **Change window approved and stakeholders notified**  
  Action: Confirm calendar hold and incident bridge instructions are posted in the release channel.  
  Expected: Written acknowledgement from Release Lead and On-Call SRE.

- [ ] **Clean working tree and tagged release**  
  ```powershell
  git status --short
  git describe --tags --exact-match
  ```  
  Expected: No modified or untracked files; second command prints the release tag (for example `v2025.09.29`).

- [ ] **No active automation lock**  
  ```powershell
  Test-Path .agent/LOCK
  ```  
  Expected: `False`. If `True`, abort and coordinate unlock.

- [ ] **Production environment variables present**  
  ```powershell
  Get-ChildItem Env:QUEUE_STEWARD* | Format-Table Name,Value
  ```  
  Expected: Required keys populated; no `<placeholder>` strings.

- [ ] **Config and secrets checksum recorded**  
  ```powershell
  Get-FileHash -Algorithm SHA256 config.yaml
  Get-FileHash -Algorithm SHA256 C:\queue-steward\config\appsettings.production.json
  ```  
  Expected: Hash values captured in the release notes; reruns produce identical hashes.

- [ ] **Database path healthy and backed up**  
  ```powershell
  Test-Path C:\queue-steward\data\queue.db
  Copy-Item C:\queue-steward\data\queue.db "\\$env:COMPUTERNAME\c$\backups\queue.db.$((Get-Date).ToString('yyyyMMddHHmm'))" -WhatIf
  ```  
  Expected: `Test-Path` returns `True`; dry-run copy succeeds (remove `-WhatIf` only when ready to take backup).

---

## 2. System Health Verification

- [ ] **Scheduled canary task ready**  
  ```powershell
  pwsh -File scripts/verify-queue-steward-task.ps1
  ```  
  Expected: `Task State: Ready`, `Number of Missed Runs: 0`, dashboard timestamp shows < 20 minutes ago.

- [ ] **Automation monitor clean (10 minute soak)**  
  ```powershell
  pwsh -File scripts/monitor-queue-steward-automation.ps1 -MonitorMinutes 10
  ```  
  Expected: No red lines; task stays `Ready`; missed runs count remains `0`.

- [ ] **Health log free of WARN or ERROR in last hour**  
  ```powershell
  Get-Content C:\logs\queue\health.log -Tail 200 | Select-String -Pattern 'WARN|ERROR'
  ```  
  Expected: No matches. Investigate any WARN or ERROR before proceeding.

- [ ] **Queue depth within tolerance**  
  ```powershell
  Get-Content C:\logs\queue\health.log -Tail 1
  ```  
  Expected: Latest JSON shows `queueLength < 20` and `pendingCount` near `0`.

- [ ] **Verification artifact refreshed**  
  ```powershell
  Get-Content artifacts/queue-steward-verification.txt
  ```  
  Expected: Timestamp within last 30 minutes and status `Verification PASSED`.

---

## 3. Observability Validation

- [ ] **Windows collector running with correct config**  
  ```powershell
  Get-Service otelcol-contrib | Select-Object Status,Name
  Select-String -Path C:\otel\config.yaml -Pattern 'C:/logs/queue/health.log'
  ```  
  Expected: Service `Running`; config includes queue health log path.

- [ ] **SigNoz stack healthy (Docker)**  
  ```powershell
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String 'signoz'
  ```  
  Expected: `signoz-otel-collector` exposes `14317/14318`; ClickHouse and query-service are running.

- [ ] **Emit fresh canary and verify ingestion**  
  ```powershell
  pwsh -File scripts/queue-steward-canary-automation.ps1
  ```  
  Expected: Script prints `Canary emitted` and `ClickHouse verification: PASSED`.

- [ ] **SigNoz query returns latest queue logs**  
  ```sql
  SELECT toDateTime(timestamp/1000000000) AS ts,
         resources_string['service.name'] AS service_name,
         attributes_string['log.source'] AS log_source,
         JSONExtractInt(body, 'queueLength') AS queue_length
  FROM signoz_logs.logs_v2
  WHERE attributes_string['dataset'] = 'agent_queue'
    AND ts > now() - INTERVAL 15 MINUTE
  ORDER BY ts DESC
  LIMIT 10;
  ```  
  Expected: Rows show `service_name = queue-steward`, `log_source = win-filelog`, queue length trending below 20.

- [ ] **UI verification**  
  Path: `SigNoz > Logs > Add filter > dataset = "agent_queue" > Add filter > message contains "canary"`  
  Expected: Latest row matches canary timestamp; screenshot saved to `artifacts/`.

---

## 4. Functional Testing

- [ ] **End-to-end job processing dry run**  
  ```powershell
  Invoke-RestMethod -Method Post -Uri http://localhost:4310/api/queue/test-job -Body (@{ type = 'ping'; dryRun = $true } | ConvertTo-Json) -ContentType 'application/json'
  ```  
  Expected: HTTP 200 with `{ "status": "accepted" }`; corresponding log entry emitted with `dataset="agent_queue"`.

- [ ] **Offline isolation guard rehearsal**  
  ```powershell
  .\scripts\agent\tetragrammaton-orch.ps1 -Mode Offline -WhatIf
  ```  
  Expected: Dry run prints planned isolation steps without errors.

- [ ] **Admission control sanity check**  
  ```powershell
  Invoke-RestMethod -Method Get -Uri http://localhost:4310/api/queue/admission-status
  ```  
  Expected: JSON shows `state: "open"` (or documented maintenance window state).

- [ ] **Shadow versus canonical parity**  
  ```powershell
  Compare-Object (Get-Content C:\queue-steward\data\canonical.json | ConvertFrom-Json) \
                 (Get-Content C:\queue-steward\data\shadow.json | ConvertFrom-Json)
  ```  
  Expected: No differences reported.

---

## 5. Safety and Rollback Readiness

- [ ] **Rollback package staged**  
  ```powershell
  Test-Path C:\releases\queue-steward\rollback\package.zip
  ```  
  Expected: `True`; checksum recorded alongside current release package.

- [ ] **Service restart procedure rehearsed**  
  ```powershell
  Get-Service queue-steward
  ```  
  Expected: Service exists and reports `Running`. Document `Stop-Service queue-steward; Start-Service queue-steward` in release notes.

- [ ] **Emergency contacts reachable**  
  Action: Confirm SRE, Product, and Analytics contacts acknowledge the bridge channel.  
  Expected: Names and response windows captured in release document.

- [ ] **Documentation snapshot archived**  
  ```powershell
  Copy-Item docs/ECRR_QUALITY_DASHBOARD.md ("artifacts/ECRR_QUALITY_DASHBOARD.{0}.md" -f (Get-Date -Format 'yyyyMMddHHmm'))
  ```  
  Expected: Copy succeeds; used for rollback comparison.

---

## 6. Deployment Execution Readiness

- [ ] **Import latest dashboard config**  
  ```powershell
  pwsh -File scripts/import-queue-dashboard.ps1
  ```  
  Expected: Script reports `Dashboard import completed` with HTTP 200.

- [ ] **Monitoring alerts enabled**  
  Action: In SigNoz Alerts, ensure `Queue Steward Ingestion Stall` and `Queue Depth Spike` alerts are enabled and target the current on-call destination.  
  Expected: Alert list shows each alert with status `Enabled`.

- [ ] **Agent status JSON updated**  
  ```powershell
  pwsh -File scripts/agent/update-status.ps1 -section queue -ok $true -detail "Go-live preflight passed"
  ```  
  Expected: `.agent/status.json` reflects updated detail and timestamp.

- [ ] **Release notes final copy shared**  
  Action: Publish release summary (features, risks, rollback) in project document and release channel.  
  Expected: Link recorded in go-live artifact.

---

## 7. Go / No-Go Decision Matrix

| State | Criteria | Action |
|-------|----------|--------|
| GO | All sections checked, no WARN or ERROR in health log, SigNoz shows fresh canary, queue depth < 20 | Proceed with production switch |
| HOLD | Single WARN in log or automation timestamp > 20 minutes | Investigate, rerun Sections 2 and 3; escalate to SRE if unresolved within 15 minutes |
| NO-GO | Any service down, dataset missing in SigNoz, queue depth ≥ 50, alert pipeline disabled | Abort release, trigger rollback package, open incident |

Record final vote (`GO`, `HOLD`, or `NO-GO`) with names and time in the artifact.

---

## 8. Post-Deployment Monitoring Plan

- **0–2 hours:**
  - Run `pwsh -File scripts/monitor-queue-steward-automation.ps1 -MonitorMinutes 30` (expect no missed runs).
  - SigNoz UI → Dashboards → Queue Steward → confirm `Queue Depth` panel stays below 25.
  - Capture screenshot and attach to artifact.

- **2–24 hours:**
  - Verify `artifacts/queue-steward-daily-guardrail.txt` updated by automation (timestamp < 24 hours old).
  - Review alerts channel for noise; tune thresholds if more than three informational alerts fired.

- **After 24 hours:**
  - Schedule a short retro; append findings to `docs/SIGNOZ_ECRR_COMPLIANCE_ALERT_GUIDE.md` if new learnings.
  - Update `.agent/status.json` via `pwsh -File scripts/agent/update-status.ps1 -section queue -ok $true -detail "Post-go-live check clean"`.

---

## Evidence Checklist

Attach to release artifact:
- Command transcripts (`Start-Transcript` recommended).
- SigNoz dashboard screenshot filtered on `dataset="agent_queue"`.
- Updated `artifacts/queue-steward-verification.txt`.
- Hashes and backup confirmation.
- Final Go/No-Go decision note with approvers.
