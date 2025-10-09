# IONA Errors and Anomalies Ledger

Last Updated: 2025-10-09

## Current Anomalies

- None blocking. Previous issues have been remediated:
  - SigNoz UI/API reachable on `http://localhost:8080`.
  - OTLP ports open: 14317 (gRPC), 14318 (HTTP).
  - Windows Collector `otelcol-contrib` Running.
  - Guardrails PASS; ephemeral dirs untracked: `gpu-buffers/`, `sidecars/`.
  - Spinner shim available at `BRAV/SCPT/progress-indicators.ps1`.

## Suggested Remediations

- Keep `gpu-buffers/` and `sidecars/` ephemeral/untracked.
- Use `start-signoz.ps1` for clean startup sequence when needed.

## Provenance

- Source: Local BossCat verification run.
- Evidence: `CHAR/EVID/gate-verify.json`, `CHAR/EVID/ECRR_REPORTS/ECRR_GATE_VERIFY_2025-10-09.md`.
