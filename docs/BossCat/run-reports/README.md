# Run reports (pointer)

Archived GitHub Actions run reports live in the private evidence repo:

**`MoneyCat-inc/otel-ops-evidence`** (private) → `docs/BossCat/run-reports/`

This directory in **otel-ops-pack** no longer holds the ~25k-file archive (Pack 2 Task 6).
Monthly rollups remain under `CHAR/PRSV/evidence-archives/` via `bosscat-monthly-evidence-rollup.yml`.

New reports are published by `.github/workflows/run-archiver.yml` using secret `EVIDENCE_REPO_TOKEN`
(fine-grained PAT: MoneyCat-inc / `otel-ops-evidence` only / Contents R/W). Missing or expired
token fails the workflow loudly — no `continue-on-error`.

## Retention

Raw reports in `otel-ops-evidence` are retained **90 days**, pruned quarterly by
`.github/workflows/evidence-retention-prune.yml` (dispatch dry-run default).

**Age derivation:** filename / path stamp (`YYYYMMDD` or `archived/YYYY/MM/`), else
`git log -1 --format=%ct` — **never** filesystem mtime (checkout resets mtimes).

Policy briefing: [BRIEFING_EVIDENCE_RETENTION.md](../BRIEFING_EVIDENCE_RETENTION.md).
