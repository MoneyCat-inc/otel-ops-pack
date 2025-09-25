# ECRR Report — SigNoz Canary Proof & Scheduled Monitor

Date: 2025-09-24  
Agent: Cursor Agent — Observability Copilot  
Role: Implementor (OTel Wiring & Monitoring Steward)  
Session: Prove Windows → SigNoz canary ingestion; add scheduled-friendly monitor; silence noisy profile hook

---

## 1. Examine

Initial State
- Environment: Windows 11, PowerShell 7, WSL2 + Docker Desktop, local SigNoz
- Containers: signoz-otel-collector healthy, exposing 14317/14318
- Service: otelcol-contrib → STATE: 4 RUNNING
- ClickHouse: reachable in signoz-clickhouse

Evidence
- ClickHouse query returned canary row:
  - SELECT timestamp, body FROM signoz_logs.distributed_logs_v2 WHERE body LIKE '%SigNoz wiring canary%' ORDER BY timestamp DESC LIMIT 1 FORMAT Vertical
  - Body includes: {"message":"SigNoz wiring canary sent …","eventId":1001,"source":"SigNozTestSource"}

---

## 2. Clean

- Silenced .venv\Scripts\Activate.ps1 auto-activation in Microsoft.PowerShell_profile.ps1 (backup created)
- Retained local-first, no secrets; idempotent scripts; verifiable queries

---

## 3. Report

Actions
- Emitted Windows Event + file canary and proved ingestion in ClickHouse
- Enhanced scripts/monitor-signoz-canary.ps1 with -EmitCanary, JSON artifacts, clear exit codes, and signoz-canary-monitor-latest.json
- Documented Task Scheduler setup (every 10 minutes)

Results
- Monitor run: "Canary ingestion healthy" with recent counts; artifacts written under artifacts/
- Shell startup cleaned (no more .venv activation errors after restart)

---

## 4. Role

Actor: Cursor Agent — Observability Copilot (Implementor)
- Scope: OTel wiring verification and local monitoring automation
- Guardrails: Local-first, Safety, Idempotence, Verification — all respected
- Integration: Compatible with existing SigNoz/WIRING docs and scripts

---

## 5. Validation

- ClickHouse: latest canary row present and correct
- Script: exit code 0 (healthy), artifacts: artifacts/signoz-canary-monitor-*.json

---

## 6. Next Actions

- Schedule monitor-signoz-canary.ps1 every 10 minutes (omit -EmitCanary to reduce noise)
- Optionally route non-zero exit codes to alert-escalation-manager.ps1
- Add dashboard panel for canary freshness (last 15m)

---

Artifacts
- Script: scripts/monitor-signoz-canary.ps1
- Reports: artifacts/signoz-canary-monitor-latest.json, timestamped JSONs

Status: SUCCESS — Canary verified, monitor ready for scheduling, profile noise fixed
