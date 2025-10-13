# Planner Brief — Week of 2025-10-12

Authority: BossCat OEM • Cycle: 7-day (ECRR)

## Examine — Signals Snapshot
- Nightly sentinels: [pending aggregation]
- RSI metrics (pills): generated_at shows last nightly; values tracked
- Recent gates: #132, #133, #130, #131 merged; hybrid collector gating live

## Priority Shortlist (P0→P2)
- P1: ICF Heuristic 01 — Retry-on-slow-UI Smoke (≤20 LOC)
- P1: RSI Metrics Extractor v0.1 (≤80 LOC)
- P2: Gate UX — Budget Comment Polish (≤50 LOC)

## Decisions — GATE + SITE Expansion
- Gate types recognized: IONA (default); BOSSCAT, OTEL reserved for future.
- Site tiers: `ci`, `stg`, `prod` (strict gating remains prod-only).
- Local CLI: add scripts to run gate verification per site.
- Workflow: expand matrix to include `stg` alongside `ci`, `prod`.

## Evidence Links
- Status Dashboard: docs/status.html
- Latest ECRR Closeout: docs/ecrr/ECRR_REPORTS/ECRR_GATE_CLOSEOUT_LATEST.md
- Registry (JSON): signature-registry.json
- Mascot Image: Vasilisa_High_Priestess_TinCanForest.jpg
- Research Conversion Summary: docs/BossCat/Research/CONVERSION_SUMMARY.md

## Notes
- Budgets enforced: ≤10 files / ≤2,000 LOC; sticky at ≥1,600 LOC
- Prod collector gating: STRICT; ci/stg/local: WARNINGS; strict_mode override available

