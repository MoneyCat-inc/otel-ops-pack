# cursor{implementer} Setup Prompt – IONA Gate Finalization & Diagnostic Shell
MoneyCat Inc - Resonai [OTel] - otel-ops-pack  
Date: 2025-10-07  
Authority: BossCat OEM (Executive Overseer Manager)  
Actor: cursor{implementer}

---

## Mission Snapshot
- Finalize IONA's BossCat gate activation by validating the workflow, synthetic span generator, and verification suite end to end.
- Build and ship the `/diagnostics` telemetry shell so operators can inspect metrics, traces, logs, and trigger synthetic spans in real time.
- Operate under the ECRR mantra (Examine -> Clean -> Report -> Role). Every action leaves evidence in `artifacts/` and documentation in `docs/`.

## Latest Gate Status (2025-10-07 06:10 UTC)
| Area | Status | Evidence / Notes |
| --- | --- | --- |
| Telemetry wiring | Complete | `app/layout.tsx` renders `TelemetryInit`; browser spans flow via `lib/telemetry/iona-telemetry.ts`. |
| Synthetic span generator | Passing locally | `python synthetic/send_iona_boot_span.py` returned success at 2025-10-07 06:45 UTC. Collector endpoint: `http://localhost:5317`. |
| BossCat workflow | In repository | `.github/workflows/iona-gate-verify.yml` responds to push/PR; helper `scripts/move-iona-workflow.ps1` repairs paths if needed. |
| Verification script | Ready to execute | `scripts/verify-iona-gate.ps1` covers dependency checks, span emission, Playwright run, artifact validation. Dev server required. |
| Diagnostics shell | Not started | No `app/diagnostics/` route or components exist yet. |
| Test telemetry | Mixed | `docs/status/tests.json` shows 14/15 passing; docker security scan still failing (48 vulnerabilities). Capture rationale in ECRR notes. |
| Observability health | Needs confirmation | `docs/status/kpis.json` marks SigNoz as `unhealthy: ok`; rerun health checks after diagnostics work. |
| Documentation | Baseline shipped | `docs/BossCat/IONA_*` reports exist; they need updates once verification reruns and diagnostics land. |

## Immediate Priorities
1. Run the IONA gate verification locally, capture every artifact, and refresh supporting documentation.
2. Implement the diagnostics telemetry shell (route, components, API routes, Playwright coverage).
3. Regenerate ECRR evidence for both the gate run and diagnostics deliverables.
4. Package the work into BossCat-compliant commits and request approval with `@cat ready-for-gate`.

## Reference Map
- Core app: `app/`, `lib/`, `components/`.
- Telemetry helpers: `lib/telemetry/iona-telemetry.ts`, `lib/observability/signoz.ts`.
- Automation: `scripts/verify-iona-gate.ps1`, `scripts/move-iona-workflow.ps1`, `scripts/send_synthetic_otel_simple.py`.
- Playwright assets: `scripts/iona-snapshot.spec.ts`, `tests/helpers/signoz.ts`.
- Status dashboards: `docs/status/*.json`, `docs/IONA_ERRORS.md`.
- Evidence sinks: `artifacts/`, `docs/ecrr/ECRR_REPORTS/`, `docs/observability/snapshots/`.

---

## Phase 1 – Gate Finalization

### 1. Environment readiness
- Confirm Node 22.x, pnpm 9.x, and Python 3.11+.
- `pnpm install`
- `npx playwright install --with-deps chromium`
- `python -m pip install --upgrade opentelemetry-sdk opentelemetry-exporter-otlp-proto-grpc`

### 2. Workflow sanity checks
- Ensure `.github/workflows/iona-gate-verify.yml` matches the expected trigger paths and artifact uploads.
- Remove any legacy `workflows/iona-gate-verify.yml` files (helper script can do this).
- Verify `scripts/verify-iona-gate.ps1` references the `.github/workflows/` location.

### 3. Synthetic span verification
- Run `python synthetic/send_iona_boot_span.py`.
- Success output: `[iona-boot] [OK] Span emitted successfully`.
- If errors appear, reinstall OTLP exporters or update `OTEL_EXPORTER_OTLP_ENDPOINT`.

### 4. Full gate run
- Terminal 1: `pnpm dev` (wait for `http://localhost:3000/api/health` to return 200).
- Terminal 2: `pwsh -File scripts/verify-iona-gate.ps1`.
  - Expected: dependency checks, synthetic span success, Playwright pass, artifact verification, optional SigNoz health.
  - Use `-SkipSigNoz` only if the collector is offline; log the reason in ECRR notes.
- Preserve `playwright-report/`, `test-results/`, and `artifacts/iona-*.png`.

### 5. Documentation and evidence
- Update `docs/BossCat/IONA_ECRR_REPORT.md` with the latest Examine/Clean/Report/Role findings.
- Refresh `IONA_GATE_ACTIVATION_SUMMARY.md` with timestamps and verification output.
- Note ongoing anomalies (for example the docker scan failure) inside `docs/IONA_ERRORS.md`.
- Run `pwsh scripts/process-ecrr-reports.ps1` if compliance dashboards need regeneration.

### 6. Commit, push, and signal
- Compose commits with ECRR tags, e.g. `test(canary): iona gate verification`.
- Ensure CI artifacts include the diagnostics evidence once added to the workflow.
- After CI passes, comment `@cat ready-for-gate` with pointers to artifacts and updated docs.

---

## Phase 2 – Diagnostic Telemetry Shell

### Overview
Deliver a `/diagnostics` experience that surfaces live metrics, traces, logs, and control actions (emit span, toggle instrumentation, adjust sampling). The shell must degrade gracefully when SigNoz is offline and must produce observability data about itself.

### Files to create or update
- `app/diagnostics/page.tsx` – route metadata and wrapper.
- `components/diagnostics/TelemetryShell.tsx` – overall layout, polling orchestration, error handling.
- `components/diagnostics/MetricsPanel.tsx`
- `components/diagnostics/TracesPanel.tsx`
- `components/diagnostics/LogsPanel.tsx`
- `components/diagnostics/ControlsPanel.tsx`
- `components/diagnostics/StatusIndicator.tsx` (shared badge/health component).
- `lib/telemetry/diagnostics-client.ts` – optional helper that wraps fetch calls and response typing.
- `app/api/telemetry/stats/route.ts`
- `app/api/telemetry/metrics/route.ts`
- `app/api/telemetry/traces/route.ts`
- `app/api/telemetry/logs/route.ts`
- `app/api/telemetry/emit-span/route.ts`
- Playwright coverage: extend `scripts/iona-snapshot.spec.ts` or add `scripts/iona-diagnostics.spec.ts` (minimum three tests: renders, controls respond, synthetic span button works).

### Data contracts
- `GET /api/telemetry/stats` -> `{ spanRatePerMin, errorRate, activeSessions, lastUpdated }`
- `GET /api/telemetry/metrics` -> array of `{ name, value, unit, trend }`
- `GET /api/telemetry/traces` -> recent spans `{ name, latencyMs, status, link }`
- `GET /api/telemetry/logs` -> recent log entries `{ level, message, timestamp }`
- `POST /api/telemetry/emit-span` -> triggers a synthetic span (call Python script or Node helper) returns `{ ok: true }`

Use `lib/observability/signoz.ts` for live queries when SigNoz is reachable; fall back to cached or simulated data with explicit banners when offline.

### UI behavior
- Poll stats every five seconds with abortable fetches.
- Display loading, error, and empty states per panel.
- Controls panel actions:
  - Toggle client instrumentation (link into `lib/telemetry/iona-telemetry.ts` settings).
  - Adjust sampling rate (persist using local storage or an API route).
  - Emit synthetic span button with in-flight spinner, success/failure notification, and log entry.
- Styling: Tailwind grid layout, calm color palette (Cat Nap Control Room aesthetic), readable typography, responsive breakpoints.

### Testing
- Playwright cases should:
  - Load `/diagnostics` and confirm all four panels render.
  - Stub API routes to validate polling and error handling (`page.route`).
  - Click the synthetic span button and verify success toast plus log table update.
- Update `playwright.config.ts` if new spec files are added; ensure `scripts/verify-iona-gate.ps1` covers diagnostics tests.

### Observability hooks
- Emit a client span `iona.diagnostics.view` when the page mounts.
- Add tracing to API routes (leverage existing OpenTelemetry middleware or wrap handlers).
- Tag emitted spans with `diagnostics.shell = true` and `actor = "cursor{implementer}"`.
- Record metrics for poll latency and error counts.

### Documentation and artifacts
- Author `docs/BossCat/IONA_DIAGNOSTICS_GUIDE.md` (architecture, usage, troubleshooting).
- Update `docs/BossCat/IONA_ECRR_REPORT.md` to cover diagnostics build steps.
- Capture screenshots (`artifacts/iona-diagnostics*.png`) via Playwright.
- Refresh indexes (`CURSOR_IMPLEMENTER_INDEX.md`, `CURSOR_IMPLEMENTER_QUICK_REF.md`) so teammates can find the new shell.

### Definition of done
- `/diagnostics` renders without console errors.
- All API handlers respond within 500 ms locally and surface useful error messages.
- Playwright suite (including diagnostics) passes.
- SigNoz contains spans tagged `diagnostics.shell`.
- ECRR documentation and artifacts committed.
- `.github/workflows/iona-gate-verify.yml` executes diagnostics tests and uploads evidence.

---

## Evidence Checklist
- Synthetic span output captured (save PowerShell transcript or redirect to `artifacts/iona-synthetic-span.txt`).
- Playwright HTML report archived plus screenshots.
- Updated compliance dashboards (`docs/dashboard/*.html`) regenerated when scripts allow.
- Fresh ECRR reports stored under `docs/ecrr/ECRR_REPORTS/` with timestamps and actor declaration.

## Ready Commands
```
pnpm dev
pwsh -File scripts/verify-iona-gate.ps1
pnpm playwright test scripts/iona-snapshot.spec.ts --project=chromium --grep "Diagnostics"
python synthetic/send_iona_boot_span.py
pwsh -File scripts/process-ecrr-reports.ps1
```

---

ECRR mantra: Examine -> Clean -> Report -> Role.  
BossCat principle: Local-first, evidence-first.  
Deliver the gate, ship the diagnostics shell, and close the loop with documented proof.
