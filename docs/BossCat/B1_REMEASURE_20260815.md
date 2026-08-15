# B1 remasure snapshot (2026-08-15)

Canonical series (CI config-resolution path):
**10,718/370 → 6,445/271 → 6,401 → 6,162 → 6,128** (post archive, fix1–3, and #517 debt clearance).

See `docs/BossCat/B1_LINT_MEASUREMENT_20260815.md` for the pinned command and OEM correction
of the superseded **7,402 / 244** claim.

## Fix batch 3 (this PR)

| Probe | Result |
|-------|--------|
| Before (canonical command, `main` @ `b63f4bf2f`) | **6,162** / **271** (Linting: 272) |
| Batch | 10 low-debt live docs → **0** issues |
| After (same command) | **6,128** / **271** |

**Command:**

```bash
npx --yes markdownlint-cli2@0.14.0 --config .markdownlint-cli2.yaml \
  "docs/**/*.md" "README.md" "!docs/archive" "!docs/gate/archive"
```

Count leave-behind from `Summary:` (or match `\.md:\d+` lines) — never `tail -1`.
