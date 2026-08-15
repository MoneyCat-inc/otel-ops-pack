# B1 remasure snapshot (2026-08-15)

Canonical series (CI config-resolution path): **10,718/370 → 6,445/271** (post archive + fix1).

See `docs/BossCat/B1_LINT_MEASUREMENT_20260815.md` for the pinned command and OEM correction
of the superseded **7,402 / 244** claim.

## Fix batch 2 (this PR)

| Probe | Result |
|-------|--------|
| Before (canonical command, `main` @ `903b20df6`) | **6,445** errors / **271** live files (Linting: 272 includes README) |
| Batch | 10 low-debt live docs → **0** issues |
| After (same command) | **6,401** / **271** |

**Command** (must match measurement doc):

```bash
npx --yes markdownlint-cli2@0.14.0 --config .markdownlint-cli2.yaml \
  "docs/**/*.md" "README.md" "!docs/archive" "!docs/gate/archive"
```
