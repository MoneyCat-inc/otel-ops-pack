<!-- markdownlint-disable MD013 MD034 MD060 -->
# B1 remasure snapshot (2026-08-15)

Canonical series (CI config-resolution path):
**10,718/370 → 6,445/271 → 6,401 → 6,162 → 6,128 → 6,096 → 5,749** (post archive, fix1–4 scale, and interim main clearance).

See `docs/BossCat/B1_LINT_MEASUREMENT_20260815.md` for the pinned command and OEM correction
of the superseded **7,402 / 244** claim.

## Fix batch 4 scale (this PR)

| Probe | Result |
|-------|--------|
| Before (canonical command, branch from `main`) | **6,096** / **271** (Linting: 272) |
| Batch | **35** low-debt live docs (1–15 errors) → **0** issues |
| After (same command) | **5,749** / **271** |

**Command:**

```bash
npx --yes markdownlint-cli2@0.14.0 --config .markdownlint-cli2.yaml \
  "docs/**/*.md" "README.md" "!docs/archive" "!docs/gate/archive"
```

Count leave-behind from `Summary:` (or match `\.md:\d+` lines) - never `tail -1`.