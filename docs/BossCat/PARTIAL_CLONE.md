<!-- markdownlint-disable MD013 MD034 -->
# Partial clone (Second Pass D1)

**Decision:** leave packed history intact; newcomers use a blobless partial clone.  
**Authority:** BossCat OEM · Second Pass Plan D1 = (b) · 2026-08-15  
**Why not rewrite:** a casual `git filter-repo` force-push invalidates every clone, worktree, and agent checkout at once. Revisit a purge only with a declared freeze window and every implementer seat notified.

## Recommended clone

```bash
git clone --filter=blob:none https://github.com/MoneyCat-inc/otel-ops-pack.git
```

Blobless partial clone downloads commit/tree metadata first and fetches file blobs on demand. First-clone time and disk use drop without rewriting shared history.

### Optional: sparse checkout (advanced)

If you only need a subtree for a lane, combine filter with sparse-checkout after clone. Prefer the blobless clone alone unless you have a measured need.

## What this does *not* do

- It does **not** shrink the remote `.git` pack (~725 MB class; mostly deleted evidence blobs and historical LEDGER weight).
- It does **not** change `CHAR/EVID` retention (pass-one rule: keep all; guard future accumulation).
- Full clones remain valid; CI and existing worktrees need no migration.

## When to revisit filter-repo (option a)

Only when **all** of the following are true:

1. Freeze window declared in BossCat chat / log with start and end.
2. Cursor{Implementer}, Kiro{Implementer}, and machine operator `@fubumaki` notified.
3. Coordinated force-push runbook reviewed; every active worktree listed.
4. Evidence that partial clone is insufficient for the stated goal.

Until then: **do not** rewrite history.
