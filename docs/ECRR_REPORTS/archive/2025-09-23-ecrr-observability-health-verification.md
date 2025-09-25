## ECRR Report — Windows → OTel → SigNoz Health Verification (2025-09-23)

### Examine (facts before/while changes)
- Windows OTel Collector service: `otelcol-contrib` RUNNING
- SigNoz containers healthy: `signoz`, `signoz-otel-collector`, `signoz-clickhouse`
- OTLP ports (Windows): 5317 (gRPC), 5318 (HTTP) listening
- SigNoz OTLP mapped ports: 14317/14318
- Health port 13134 listening

Evidence
- Service status snapshot: `sc query otelcol-contrib` → STATE: 4 RUNNING
- Docker status (abridged): `signoz-otel-collector` exposing `4317/4318` and `14317/14318`

### Clean (drift removed / guardrails enforced)
- Enabled Service Control (SC) recovery for auto-restart on crash:
  - `sc.exe failure otelcol-contrib reset= 60 actions= restart/5000/restart/5000/restart/5000`
  - `sc.exe failureflag otelcol-contrib 1`
- Confirmed health_check extension wiring in `C:\otel\config.yaml`:
  - `extensions.health_check.endpoint: 0.0.0.0:13134`
  - `extensions.health_check.path: /healthz`
- Restarted collector to apply/confirm configuration

### Report (artifacts and verification)
Artifacts
- Script added: `C:\otel\auto-restart-verify.ps1` (simulates crash, validates recovery, emits canary)

Verification Results
- Auto-restart test: PASSED
  - Old PID → Killed → Service recovered with new PID; ports 5317/5318 listening
- Canary ingestion: PASSED
  - `.uild canary` helpers: `canary-test.ps1`, `verify-pipeline.ps1` show recent matching rows
  - SigNoz Logs filters:
    - `message contains "canary test"`
    - or `log.file.path contains "C:/logs/app.json"`
- Health endpoint: PASSED
  - `Invoke-WebRequest http://localhost:13134/healthz` → HTTP 200 OK
  - Body (abridged): `{ "status": "Server available", "uptime": "..." }`

### Role (actor)
- Actor: Cursor Agent — Observability Copilot
- Scope: Local Windows 11 host, Windows OTel Collector, local SigNoz stack

### Acceptance Criteria (met)
- Command success without manual edits: yes
- Signal visible in SigNoz (logs/traces) with provided filters: yes
- Minimal, reversible changes: yes (SC recovery settings; script addition)
- Verification evidence recorded: yes (this report + script + config confirmation)

### Next Actions
- Optional: tighten noise filters in `config.yaml` (`filter/drop_noise`, `attributes/redact`) and restart
- Import the baseline health-canary alert in SigNoz UI using `signoz-health-canary-alert.json`
- Keep `canary-monitor.ps1` running for live heartbeat

### Quick Commands (reference)
```powershell
# Health endpoint
Invoke-WebRequest -UseBasicParsing http://localhost:13134/healthz

# Auto-restart verification (scripted)
pwsh -ExecutionPolicy Bypass -NoProfile -File C:\otel\auto-restart-verify.ps1

# Canary and pipeline verify
pwsh -NoProfile -File C:\otel\canary-test.ps1
pwsh -NoProfile -File C:\otel\verify-pipeline.ps1
```


---
## Work Session (Active)

* Session ID: session-20250923-214837
* Started: 2025-09-23 21:48:37
* Owner: system-architect
* Priority: medium

Next Steps:
- Complete the ECRR methodology (Examine -> Clean -> Report -> Role)
- Capture progress notes as the session evolves
- Gather evidence artifacts before resolution

*ECRR or it didn't happen.*

---
## Resolution Summary

* Completed: 2025-09-23 21:48:38
* Outcome: Report processed and archived
* Notes: Completed via batch processing

*Report archived by scripts/ecrr-manage.ps1.*

