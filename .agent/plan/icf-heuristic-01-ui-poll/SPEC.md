# SPEC: ICF Heuristic 01 — Retry-on-slow-UI Smoke

## Goal
Reduce U-turns by adding a tiny poll/wait helper for UI smoke test readiness (≤20 LOC).

## Change-set (≤10 files / ≤2,000 LOC)
- Add helper in tests/smoke/lib/waitReady.{ps1|js} (≤20 LOC)
- Wire helper in one flaky check (1 call site)
- lane: tests
- labels: icf, ci

## Tests & Gates
- ICF_COMPLIANCE • SITE_HTML_CSP (no HTML changed)
- Evidence snippet in ECRR of pre/post runs

## Rollback
Disable helper via flag: `SMOKE_WAIT_READY=false` (default true)

## Ownership
- Actor: cursor{implementer}
- Verifier: Agent B (reader-only)
- Approver: BossCat OEM

