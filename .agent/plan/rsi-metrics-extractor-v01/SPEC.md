# SPEC: RSI Metrics Extractor v0.1

## Goal
Compute real Convergence & U-turns from evidence logs for status pills.

## Change-set
- Edit .github/workflows/nightly-dashboard-export.yml (≤80 LOC)
- Parse .agent/EVIDENCE.log or DELT/ARTF/*; write docs/status/metrics.json
- lane: ci
- labels: ci, docs

## Tests & Gates
- SITE_DEPLOY_VERIFY confirms pills show updated 'generated_at'
- ICF_COMPLIANCE (budgets, no inline)

## Rollback
Revert step; restore previous counters (placeholders)

## Ownership
- Actor: cursor{implementer}
- Verifier: Agent B
- Approver: BossCat OEM

