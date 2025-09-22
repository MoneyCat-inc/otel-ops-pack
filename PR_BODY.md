# ECRR-01 — Cross-Origin Isolation + SW continuity, Playwright spec, ONNX/FF guards, audit update

## Summary
This change enforces COOP/COEP across the app, hardens the Service Worker so Firefox keeps crossOriginIsolated online and offline, verifies `onnxruntime-web` threads only when COI is present (with safe fallbacks), and adds Firefox Playwright coverage for offline continuity. The audit checklist now tracks COI, mic constraints, ONNX gating, and third-party asset compliance.

## Evidence
- ✅ `pnpm playwright test isolation_headers.spec.ts --project=firefox`
- ✅ `pnpm playwright test playwright/tests/offline_isolation.spec.ts --project=firefox`
- ✅ `curl -I http://localhost:3003/` → `Cross-Origin-Opener-Policy` + `Cross-Origin-Embedder-Policy`
- ✅ Runtime guard logs show `crossOriginIsolated=true`, `ort.env.wasm.numThreads>1`
- ✅ Console confirms mic settings (EC/NS/AGC `false`) and `AudioContext({ latencyHint: 0 })`

## Risk notes & mitigations
- Third-party iframes/scripts must return CORS/CORP-friendly responses; critical assets remain self-hosted.
- Offline continuity relies on the SW preserving headers; the SW installs after the first COI load and only rewrites navigation responses.

## ✅ ECRR Gate
- **Examine** — Environment state captured: existing isolation tests, Playwright config, package.json scripts
- **Clean** — Artifacts prepared with proper structure following ECRR framework
- **Report** — Complete artifact package delivered with verification commands
- **Role** — Cursor Agent: Observability Copilot preparing merge-ready package

## Attached Artifacts
- `artifacts/ecrr-01-verification.log` - Header verification script output
- `artifacts/ecrr-01-playwright-isolation.json` - Core COI Playwright test results
- `artifacts/ecrr-01-playwright-offline.json` - Offline continuity test results
- `ECRR-01-SMOKE-TEST-RESULTS.md` - Complete smoke test documentation
- `docs/ECRR_REPORTS/2025-09-22-terminal-session-ecrr-01.md` - ECRR terminal session report

## Commits
- `6ec222a` - ECRR-01: Cross-Origin Isolation + SW continuity, Playwright spec, ONNX/FF guards
- `6099c81` - ECRR-01: Complete package with terminal reports and smoke test results
- `[latest]` - Add ECRR-01 verification logs for PR attachment

Ready for merge once CI confirms local test results.
