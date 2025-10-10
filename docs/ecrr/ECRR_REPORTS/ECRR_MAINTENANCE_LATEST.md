# ECRR — Maintenance Latest

Pointer to the latest maintenance-focused ECRR report.

- Latest: `ECRR_PARALLEL_CLEANUP_PAGINATION_FIX_20251010.md`
- Scope: Parallel cleanup pagination root cause and fix
- Actors: BossCat Diagnostic Team (Investigator), Gap-Closer, QA Scribe

Quick Ops
- Overnight batch (proven): `pwsh -File scripts/cleanup-batch-overnight.ps1 -Rounds 8 -WaitMinutes 65`
- Parallel trial (fixed): `pwsh -File scripts/cleanup-parallel-aggressive.ps1 -Workers 15 -TargetRuns 500`

