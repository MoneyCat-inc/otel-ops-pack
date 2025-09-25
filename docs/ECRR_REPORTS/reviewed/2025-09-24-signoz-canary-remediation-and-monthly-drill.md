# ECRR — SigNoz Canary Remediation Webhook Wrapper & Monthly Failure Drill (2025-09-24)

## Examine

- Environment: Windows 11, `otelcol-contrib` service using `C:/otel/config.yaml`, SigNoz UI `http://localhost:8080`, OTLP gRPC `14317`, HTTP `14318` (SigNoz), Windows collector `5317/5318`.
- Existing canary monitor artifacts at `C:/otel/artifacts/signoz-canary-monitor-latest.json`.
- Scheduled Tasks present:
  - `SigNozCanaryRemediation` → `pwsh -NoLogo -File C:\otel\scripts\monitor-signoz-canary-remediate-wrapper.ps1` (Enabled)
  - `SigNozCanaryMonthlyDrill` → `pwsh -NoLogo -File C:\otel\scripts\signoz-canary-failure-drill.ps1` (Monthly, 02:00)

## Clean

- Added wrapper `scripts/monitor-signoz-canary-remediate-wrapper.ps1` to load webhook from `C:/otel/config/signoz-canary-webhook.txt` and export `SIGNOZ_CANARY_WEBHOOK_URL`.
- Hardened wrapper parsing: ignores comments/blank lines; accepts only `http(s)` or `smtp` schemes.
- Enhanced remediation `scripts/monitor-signoz-canary-remediate.ps1`:
  - Sends HTTP webhook JSON if `http(s)` URL.
  - Sends email via `System.Net.Mail` if `smtp://host:port/path` URL (with optional env overrides `SIGNOZ_CANARY_SMTP_TO/_FROM/_SUBJECT`).
- Confirmed monthly drill script `scripts/signoz-canary-failure-drill.ps1` stops service, marks report critical, emits Application events `5001` → remediation `5101` → completion `5200`, restarts if needed, and logs to `artifacts/signoz-canary-failure-drill-<ts>.json`.

## Report

- Evidence:
  - Remediation wrapper dry-run output:
    - `[INFO] Remediation status: healthy`
    - `Log written to C:\otel\artifacts\signoz-canary-remediation-<timestamp>.json`
  - Task queries show correct bindings and schedule:
    - `SigNozCanaryRemediation` → wrapper
    - `SigNozCanaryMonthlyDrill` → next run `1.10.25 02:00`
- Files touched:
  - `scripts/monitor-signoz-canary-remediate-wrapper.ps1` (new + parsing hardening)
  - `config/signoz-canary-webhook.sample.txt` (sample format)
  - `scripts/monitor-signoz-canary-remediate.ps1` (SMTP + robust URL handling)
  - `scripts/signoz-canary-failure-drill.ps1` (present; verified behavior)

## Role

- Actor: Cursor Agent — Observability Copilot
- Change type: Local ops automation; no external dependencies added.

## Verification Steps

1. Place webhook (first non-comment line):
   - HTTP/Teams: `https://...`
   - SMTP: `smtp://localhost:2525/ops@example.com`
2. Dry run remediation:
   - `pwsh -NoLogo -File scripts/monitor-signoz-canary-remediate-wrapper.ps1 -DryRun`
3. Check scheduled tasks:
   - `schtasks /Query /TN SigNozCanaryRemediation /V /FO LIST`
   - `schtasks /Query /TN SigNozCanaryMonthlyDrill /V /FO LIST`
4. SigNoz Logs (post-drill): filter source=`SigNozCanaryMonitor` message contains `Monthly canary failure drill` and event.id in `[5001,5101,5200]`.

## Outcome

- Webhook export is guaranteed before remediation; secrets stored out-of-repo.
- Monthly drill scheduled at 02:00 with automatic evidence artifacts and Application events.
- Remediation can notify via HTTP or SMTP.

## Follow-ups

- Insert real webhook into `config/signoz-canary-webhook.txt` (keep untracked).
- Adjust `-RemediationWaitSeconds` or schedule timing if production overlap is a concern.

