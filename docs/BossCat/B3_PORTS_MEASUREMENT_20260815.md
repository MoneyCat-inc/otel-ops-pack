<!-- markdownlint-disable MD013 MD034 -->
# B3 Measurement — OTLP ports single source of truth

**Date:** 2026-08-15  
**Authority:** BossCat OEM · Second Pass Wave 2 B3  
**Actor:** Cursor{Implementer}  
**Grounded against:** `origin/main` @ `7fc711a9e`  
**Status:** MEASUREMENT ONLY — no consumers converted in this commit

## Measurement

| Probe | Result |
|-------|--------|
| Files with `\b532[01]\b` (excl. `third_party`, `node_modules`, `docs/archive`) | **140** |
| Code/config consumers (BRAV/scripts/windows/ALFA/.github/.agent + root scripts) | **106** |
| Files with `\b431[78]\b` (export side, same rough scope) | **95** |
| Existing shared ports module | **none** (`git grep` / path search) |

### By area (5320/5321 file hits)

| Area | Files (approx.) |
|------|-----------------|
| BRAV | 44 |
| CHAR (evidence/docs trail) | 33 |
| scripts | 24 |
| root | 16 |
| docs (live) | 14 |
| ALFA | 6 |
| windows | 2 |

CHAR/docs hardcodes in *archived* or historical prose are **out of scope for conversion** (archives-as-filed; migration prose stays). Conversion targets: live code + config + runbooks that execute.

## Proposed config source (for OEM verify)

Three siblings, one logical source:

| Layer | Path | Role |
|-------|------|------|
| Checked-in JSON | `DELT/CONF/otel-ports.json` | Canonical numbers + labels (ingest gRPC/HTTP, export, UI) |
| PowerShell | `BRAV/SCPT/lib/OtelPorts.psm1` | `Get-OtelPorts` / constants for scripts |
| TypeScript | `ALFA/LIBS/lib/otel-ports.ts` | Named exports for app/tests |

**Suggested JSON shape** (not committed until approved):

```json
{
  "version": 1,
  "windows_collector_ingest": { "grpc": 5320, "http": 5321 },
  "signoz_otlp": { "grpc": 4317, "http": 4318 },
  "signoz_ui": { "http": 8080 },
  "notes": "Windows ingest avoids PlariumPlay 5300–5319 bind range"
}
```

PS/TS modules read that JSON (or duplicate the constants with a comment pointing at the JSON as source of truth if load-at-runtime is awkward for some scripts).

## Conversion plan (after OEM affirms location)

1. Land the three source files in one small PR.
2. Convert consumers in ≤10-file batches; prefer BRAV/SCPT + scripts first (highest density).
3. Done when `git grep -E '\b532[01]\b'` on converted paths returns only the config source + its tests.
4. Do **not** rewrite historical migration prose in archives.

## Deferred

- Stale run-card path cites from Q3 → **B1**, not B3.
- B4 PSSA fixes on overlapping `BRAV/SCPT` files wait until B3 conversions settle.

## Appendix — code/config consumer paths (106)

Measured `git grep -lE '\b532[01]\b'` on BRAV/scripts/windows/ALFA/.github/.agent and matching source extensions (excl. third_party/node_modules).

```
.agent/test-conflict-resolution.ps1
.agent/tools/smoke.mjs
ALFA/APPS/app/api/telemetry/emit-span/route.ts
ALFA/APPS/app/api/telemetry/stats/route.ts
ALFA/LIBS/components/telemetry/ControlsPanel.tsx
ALFA/LIBS/lib/tracing.ts
ALFA/OTEL/synthetic/send_trace_canary.py
ALFA/TEST/unit/memx-enhanced.spec.ts
ALFA/TEST/unit/memx.spec.ts
BRAV/SCPT/agent-telemetry-integration.ps1
BRAV/SCPT/agent/COMMUNITY-OUTREACH.md
BRAV/SCPT/agent/CUTOVER-CHECKLIST.md
BRAV/SCPT/agent/health-gate.ps1
BRAV/SCPT/agent/phase2-workflows.yml
BRAV/SCPT/agent/PREMIUM-FEATURES.md
BRAV/SCPT/agent/production-agent-system.ts
BRAV/SCPT/agent/README-PREMIUM.md
BRAV/SCPT/agent/synthetic-telemetry.ps1
BRAV/SCPT/agent/VERIFICATION-PACK.md
BRAV/SCPT/auto-bots/health-monitor-bot.js
BRAV/SCPT/bosscat-hands-free-switch-on.ps1
BRAV/SCPT/capture-dashboard-screenshot.ps1
BRAV/SCPT/ci/run-scenario.js
BRAV/SCPT/diagnostic.ps1
BRAV/SCPT/diagnostic.sh
BRAV/SCPT/ecrr-doctor.ps1
BRAV/SCPT/emit-synthetic-span.js
BRAV/SCPT/emit-synthetic-span.mjs
BRAV/SCPT/emit-synthetic-span.README.md
BRAV/SCPT/emit-synthetic-span.ts
BRAV/SCPT/iona-trace-canary.ps1
BRAV/SCPT/kiro/regen-steering.ps1
BRAV/SCPT/optimize-end-to-end-pipeline.ps1
BRAV/SCPT/publish-e2-results.ps1
BRAV/SCPT/run-dfg.ps1
BRAV/SCPT/run-otel-doe-enhanced.ps1
BRAV/SCPT/run-otel-doe.ps1
BRAV/SCPT/send_iona_boot_span.mjs
BRAV/SCPT/send_synthetic_otel.py
BRAV/SCPT/send-canary-log.ps1
BRAV/SCPT/send-otlp-log.ps1
BRAV/SCPT/simple-optimization-test.ps1
BRAV/SCPT/start-dashboard-server.bat
BRAV/SCPT/start-dashboard-server.ps1
BRAV/SCPT/test-e2e-pipeline.ps1
BRAV/SCPT/test-end-to-end-pipeline.ps1
BRAV/SCPT/test-environment.ps1
BRAV/SCPT/test-otel-integration.ps1
BRAV/SCPT/test-signoz-telemetry-integration.ps1
BRAV/SCPT/validate-all.ps1
BRAV/SCPT/verify-e2-dashboard.ps1
BRAV/SCPT/verify-gate-readiness.py
BRAV/SCPT/verify-iona-gate.ps1
BRAV/SCPT/verify-memx-integration.ps1
BRAV/SCPT/verify-pipeline.ps1
BRAV/SCPT/verify-wiring.ps1
BRAV/SCPT/workspace-isolation-manager.ps1
canary-check-min.ps1
canary-monitor.ps1
canary-test.ps1
CHAR/EVID/artifacts/doe/stage1-20250921-190700/configs/row11-r2-20250921-190700.yaml
CHAR/EVID/artifacts/doe/stage1-20250921-190853/configs/row11-r2-20250921-190853.yaml
CHAR/EVID/artifacts/doe/stage1-20250921-190945/configs/row11-r2-20250921-190945.yaml
CHAR/EVID/artifacts/doe/stage1-20250921-191739/configs/row16-r2-20250921-191739.yaml
CHAR/EVID/artifacts/doe/stage1-20250921-191826/configs/row16-r2-20250921-191826.yaml
CHAR/EVID/artifacts/doe/stage1-20250921-230850/configs/row11-r2-20250921-230850.yaml
CHAR/EVID/artifacts/doe/stage1-20250922-021355/configs/row11-r2-20250922-021355.yaml
CHAR/EVID/artifacts/doe/stage1-20250922-030640/configs/row11-r2-20250922-030640.yaml
CHAR/EVID/artifacts/doe/stage1-20250922-030818/configs/row11-r2-20250922-030818.yaml
CHAR/EVID/artifacts/doe/stage2-20250921-191444/configs/stage2_row11-r2-20250921-191444.yaml
CHAR/EVID/artifacts/doe/stage2-20250921-191628/configs/stage2_row11-r2-20250921-191628.yaml
CHAR/EVID/artifacts/doe/stage2-20250921-230852/configs/row11-r2-20250921-230852.yaml
CHAR/EVID/artifacts/doe/stage2-20250921-230856/configs/stage2_row11-r2-20250921-230856.yaml
CHAR/EVID/artifacts/doe/stage2-20250921-231348/configs/stage2_row16-r2-20250921-231348.yaml
config.yaml
DELT/FIXT/baseline/config.yaml
DELT/TMPL/templates/complete-integration.yaml
integration-tests.ps1
make-audit-pack.ps1
scripts/emit-gate-016-traces.ts
scripts/emit-simple-trace.mjs
scripts/emit-synthetic-span.js
scripts/emit-synthetic-span.ts
scripts/examples/log-with-trace.ts
scripts/gate026/run-dotnet-app-instrumented.ps1
scripts/gate028/test-collector-path.ps1
scripts/gate029/generate-traffic.ps1
scripts/gate029/orchestrator.ps1
scripts/gate029/verify-collector-5317.ps1
scripts/legacy/quick-status.ps1
scripts/legacy/restart-collector.ps1
scripts/legacy/setup/bring-up.ps1
scripts/legacy/test/test-runbook-execution.ps1
scripts/legacy/verify-collector.ps1
scripts/legacy/verify/check-ports.ps1
scripts/legacy/verify/validate-pipeline.ps1
scripts/legacy/verify/verify-hardened-collector.ps1
scripts/windows/deploy-dotnet-service.ps1
scripts/windows/health-check-otlp.ps1
scripts/windows/invoke-clean-host-e2e.ps1
scripts/windows/orchestrate-two-services.ps1
scripts/windows/run-dotnet-test-instrumented.ps1
scripts/windows/test-otlp-e2e.ps1
verify-integration.ps1
windows/otelcol/otelcol-contrib-config.yaml
windows/otelcol/README.md
```
