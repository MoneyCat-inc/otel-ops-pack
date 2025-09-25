# ECRR-01 — Cross-Origin Isolation Rollout

## Scope
- Enforce `COOP: same-origin` and `COEP: require-corp` on HTML, workers, and cached responses.
- Preserve isolation offline via `public/coi-keepalive-sw.js`.
- Gate `onnxruntime-web` threading on `crossOriginIsolated`.
- Verify Firefox mic capture uses raw input (EC/NS/AGC disabled).
- Expand Playwright coverage with offline continuity.

## Acceptance Evidence
- `pnpm playwright test isolation_headers.spec.ts --project=firefox`
- `pnpm playwright test playwright/tests/offline_isolation.spec.ts --project=firefox`
- `curl -I http://localhost:3003/` shows COOP & COEP headers.
- Console logs: `crossOriginIsolated === true` (online/offline), mic settings show EC/NS/AGC `false`.
- ONNX guard reports `ort.env.wasm.numThreads > 1` under COI, fallback path exercised when false.

## Checklist Updates
- Audit gates now include "COI online+offline", "Mic constraints applied", "ONNX threads gated by COI", "No third-party assets breaking COEP".
- Runbook references: `scripts/ecrr/verify-headers.ps1`, `docs/ecrr/COI-FAQ.md`.

## Implementation Notes
- Service Worker installs after first COI load to avoid first-paint issues
- Navigation responses cached with COOP/COEP headers preserved offline
- ONNX threading enabled only when `window.crossOriginIsolated === true`
- Mic constraints enforced: echoCancellation, noiseSuppression, autoGainControl all false
- AudioContext configured with `latencyHint: 0` for minimal latency

## Verification Commands
```powershell
# Headers verification
pwsh -File scripts/ecrr/verify-headers.ps1

# Playwright tests
pnpm playwright test isolation_headers.spec.ts --project=firefox
pnpm playwright test playwright/tests/offline_isolation.spec.ts --project=firefox

# Manual verification
curl -I http://localhost:3003/
curl -I http://localhost:3003/worker.js
```

## Risk Mitigation
- Self-hosted critical assets (fonts, models, scripts) to avoid COEP violations
- Service Worker only modifies navigation responses, not API calls
- Graceful fallback for ONNX when COI unavailable
- Comprehensive Playwright coverage for offline scenarios
