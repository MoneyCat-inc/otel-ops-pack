# SPEC: Gate UX — Budget Comment Polish

## Goal
Add first failing gate name to sticky budget comment for faster reviews.

## Change-set
- Edit .github/workflows/bosscat-gate-verify.yml (≤50 LOC)
- lane: ci
- labels: ci

## Tests & Gates
- ICF_COMPLIANCE
- Manual verify comment content on PR

## Rollback
Revert only the comment step

## Ownership
- Actor: cursor{implementer}
- Verifier: Agent B
- Approver: BossCat OEM

