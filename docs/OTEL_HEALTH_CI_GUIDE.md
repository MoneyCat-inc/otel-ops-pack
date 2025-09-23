# OTel Health CI Guide

Purpose

- Validate that the Windows OpenTelemetry Collector and SigNoz endpoints are healthy via a lightweight CI workflow.
- Provide fast feedback on wiring regressions without requiring a full pipeline run.

What this workflow does

- Runs `scripts/otel-health-check.ps1` on a Windows runner.
- Confirms the SigNoz UI is reachable on `http://localhost:8080` when applicable.
- Verifies OTLP endpoints are listening/mapped correctly:
  - Windows collector: 5317 (gRPC) / 5318 (HTTP)
  - SigNoz collector (WSL/Compose): 14317 (gRPC) / 14318 (HTTP)
- Emits concise pass/fail logs suitable for PR gating.

Files

- `.github/workflows/otel-health.yml` — CI workflow invoking the checks
- `scripts/otel-health-check.ps1` — core health probe script
- `docs/OTEL_HEALTH.md` — supplemental local health notes

How to run locally (optional)

```powershell
# From repo root
pwsh -File scripts/otel-health-check.ps1
```

Expected output (summary)

- Exit code 0 on success
- Lines indicating:
  - Collector service status OK
  - OTLP/HTTP 5318 reachable on localhost
  - SigNoz collector reachable on 14317/14318 (if applicable)

Common issues & fixes

- Port conflict on 4317/4318: ensure Windows collector uses 5317/5318 and SigNoz maps to 14317/14318.
- WSL/Docker not wired: start SigNoz stack in WSL2 and expose ports.
- Network loopback blocked in CI: disable steps requiring local SigNoz if not present.

ECRR note

- Changes that touch OTel wiring must include a verification note and artifacts (logs or screenshots) in the PR.


