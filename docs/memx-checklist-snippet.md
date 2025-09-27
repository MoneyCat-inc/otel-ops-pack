# MEMX Verification Checklist (v1)

## 1) Status verification
- [ ] **Code present**: `/app/labs/memx/page.tsx` (and any MEMX HUD/components) exist; Labs route is registered. Labs are part of our planned surface for diagnostics.
- [ ] **Feature flag**: `NEXT_PUBLIC_FEATURE_MEMX` defined (and enabled for test runs). Add to `src/config/features.ts` and `.env.local` as needed.
- [ ] **Nav & route**: "MEMX Labs" shows in the header, `/labs/memx` responds 200.

## 2) Cross-origin isolation (required for SAB/WASM threads)
- [ ] `crossOriginIsolated === true` in Firefox (open the devtools console on `/labs/memx`).
- [ ] COOP/COEP headers in place (e.g., `Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`) and any third-party assets compliant (CORP/CORS).
- [ ] (If SW enabled) verify the SW preserves these headers on navigations/offline.

## 3) Low-latency audio sanity (Firefox/Win11 baseline)
- [ ] getUserMedia constraints disable EC/NS/AGC; AudioContext `latencyHint: 0`.
- [ ] No start-of-speech gating or surprise gain shifts; logs show expected sample rate (48 kHz typical on Windows).

## 4) Telemetry surface (what MEMX should show)
- [ ] Live values update at ≤100 ms cadence: SAB present, WASM heap (if applicable), frame budget (RAF), dropped frames, basic memory headroom.
- [ ] Pitch/intonation path present (CREPE/YIN pipeline or stubs) so prosody-adjacent signals don't regress when MEMX HUD toggles.

## 5) Local-first data & flow wiring
- [ ] IndexedDB write/read works (if MEMX exports a JSON snapshot): shape matches our session schema approach.
- [ ] Flow JSON (if MEMX participates in /labs flows) stays versioned and non-blocking; reflection pages still load.

## 6) Tests & build hygiene
- [ ] Typecheck/build clean (no TS/ESLint errors).
- [ ] **Playwright smoke** for `/labs/memx`: loads, no console errors, HUD toggles don't break prosody/perf overlays.
- [ ] Add these to QA checklist and CI "smokes" if not already tracked. Our audit gate expects isolation & session metrics verified.

## 7) Observability path (optional, when streaming is enabled)
- [ ] OTLP endpoints reachable; MEMX events land in the OTel/SigNoz dataset (name consistent with analytics schema).
- [ ] `scripts/verify-integration.ps1` (or equivalent) passes; no 4xx/5xx from collector. (OTel integration is part of our labs/ops surfaces in roadmap.)

## 8) UX & performance
- [ ] No crashes in Worklets/WASM; PerfOverlay steady ≥45 fps during MEMX capture.
- [ ] Labs/Warmup flows unaffected (M1/M2 paths still pass acceptance).

---

## Quick next moves (suggested)

1. **Lock it into the QA book**: add a "MEMX" block to `docs/qa-checklist.md` with today's pass/fail, exactly like the list above. Our audit checklists already call out isolation & session metrics; keep using that pattern.
2. **Add a Playwright smoke** `tests/memx.spec.ts` that:
   * Navigates to `/labs/memx`, asserts `window.crossOriginIsolated`, checks key HUD fields update at least once.
   * Verifies no console errors and that toggling MEMX HUD doesn't break `/labs/prosody` page load (light coupling check).

---

## Integration Notes

- **Guardrails Alignment**: This checklist enforces your core guardrails (isolation, low-latency audio, local-first logging, observability)
- **OTel Integration**: Leverages existing OTel pipeline for MEMX telemetry streaming
- **QA Framework**: Fits seamlessly into existing ECRR and audit processes
- **Development Workflow**: Designed for rapid iteration and validation
