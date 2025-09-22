# ECRR Mantra
Examine -> Clean -> Report -> Role.

Apply ECRR to every operational change in this repository so the Windows -> OTel -> SigNoz path stays predictable.

## Why it matters
- **Signal flow**: Windows Event Log, file logs, and optional browser logs must land in SigNoz via the Windows collector.
- **Port hygiene**: Keep OTLP gRPC/HTTP ports 5317/5318 and SigNoz 14317/14318/8080 reachable.
- **Canary health**: Canary events should appear in SigNoz within 30 seconds.
- **Stack integrity**: Docker Desktop, WSL2, the collector service, and SigNoz compose must stay healthy.

## Quick loop
1. **Examine** the environment with `pwsh -File scripts/ecrr-doctor.ps1` and review warnings.
2. **Clean** by restarting services, clearing noisy logs, and resolving port conflicts.
3. **Report** using `docs/ECRR_REPORT_TEMPLATE.md` (store reports under `docs/ECRR_REPORTS`).
4. **Role**: declare which hat you wear (Observability Copilot, OTel Steward, Agent Coordinator, Local Worker) and the artifacts you touched.

## Integration points
- Canary testing: `pwsh -File scripts/canary-test.ps1` with SigNoz Logs filter `message contains "SigNoz test"`.
- Collector config: `config.yaml` must keep filelog and windows_eventlog receivers enabled and export to `http://localhost:14317`.
- Stack health: `pwsh -File scripts/verify-integration.ps1` doubles as the clean step when things drift.
- Agent workflows: always respect `.agent/LOCK` and update `.agent/status.json` when running background jobs.

Keep ECRR artifacts versioned, evidence captured, and verifications reproducible. No report, no merge.
