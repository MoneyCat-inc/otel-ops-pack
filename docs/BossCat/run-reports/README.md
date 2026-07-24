# Run reports (pointer)

Archived GitHub Actions run reports live in the private evidence repo:

**https://github.com/MoneyCat-inc/otel-ops-evidence** → `docs/BossCat/run-reports/`

This directory in **otel-ops-pack** no longer holds the ~25k-file archive (Pack 2 Task 6).
Monthly rollups remain under `CHAR/PRSV/evidence-archives/` via `bosscat-monthly-evidence-rollup.yml`.

New reports are published by `.github/workflows/run-archiver.yml` using secret `EVIDENCE_REPO_TOKEN`
(fine-grained PAT: MoneyCat-inc / `otel-ops-evidence` only / Contents R/W). Missing or expired
token fails the workflow loudly — no `continue-on-error`.
