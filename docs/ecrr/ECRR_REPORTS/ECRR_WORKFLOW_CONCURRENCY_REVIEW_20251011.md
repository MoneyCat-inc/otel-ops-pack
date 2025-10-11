# ECRR — Workflow Concurrency Review (bosscat-gate-verify)

- Workflow: .github/workflows/bosscat-gate-verify.yml
- Change Time (UTC): 2025-10-11

## Findings
- Concurrency block present at top-level (valid).
- Group used `${{ github.workflow }}-${{ github.ref }}` which includes full ref (e.g., `refs/heads/main`).

## Change
- Updated group to use `${{ github.ref_name }}` for cleaner, branch-only grouping.

```yaml
concurrency:
  group: bosscat-gate-verify-${{ github.workflow }}-${{ github.ref_name }}
  cancel-in-progress: true
```

## Rationale
- Avoids `refs/heads/` prefix in group names while preserving per-branch isolation.
- Keeps cancel-in-progress enabled to prevent overlapping runs for same branch.

## Compose Version Key Check
- Inspected `docker-compose-signoz.yml`; no `version:` key present. No change required.

## Result
- Status: Updated workflow committed.
- Impact: None on logic; improves naming clarity for concurrency groups.

