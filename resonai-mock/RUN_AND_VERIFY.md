# RUN_AND_VERIFY.md

## ✅ Verification (artifact-first)

- **Units**: `pnpm test:unit` → must pass.
- **E2E (PR lane)**: `pnpm e2e:grep:noflake` → must pass deterministically.
- **E2E (Nightly)**: `pnpm e2e:grep:flaky` → tolerated with retries; artifacts uploaded to `.artifacts/` / `playwright-report/`.

If any E2E spec requires audio APIs, mark `@flaky` and move it to the Nightly lane until stabilized.

## 🔒 CSP Verification

- **Production CSP**: `curl -I http://localhost:3000/ | rg "Content-Security-Policy"` → no `'unsafe-inline'`
- **Headers**: `curl -I http://localhost:3000/ | rg "Cross-Origin|Permissions-Policy"` → COOP/COEP + microphone=(self)
- **Inline Styles**: `pnpm e2e:grep:noflake` → CSP smoke test passes (no inline styles detected)

## 🔋 Battery Awareness

- **PerfOverlay**: Shows `Battery: XX%` when supported, `n/a` otherwise
- **Low Power Mode**: Displays warning when battery < 20% and not charging
- **Console Logs**: Battery info logged to console for debugging

## 📱 Mobile Testing

- **PR Lane**: `pnpm e2e:pr:mobile` → Android tests pass deterministically
- **Nightly Lane**: `pnpm e2e:nightly` → Full mobile matrix with retries
- **Quarantine**: Mobile audio tests marked `@flaky` and excluded from PR lane

## Test Framework Separation

### Directory Structure
```
tests/
├── unit/           # Vitest only (*.test.ts)
└── e2e/            # Playwright only (*.spec.ts)
```

### Scripts
- `test:unit` - Run Vitest unit tests
- `test:e2e` - Run Playwright E2E tests
- `e2e:grep:noflake` - PR lane: stable tests only
- `e2e:grep:flaky` - Nightly: flaky tests with retries
- `smoke` - Full smoke test bundle

### Quarantine System
- Tag flaky tests with `@flaky` in test title
- PR lane excludes flaky tests for deterministic results
- Nightly lane runs flaky tests with retries for tolerance

### CI/CD
- **PR Lane**: Deterministic, workers=1, retries=0
- **Nightly Lane**: Tolerant, workers=4, retries=3
- **Artifacts**: Reports uploaded to GitHub Actions artifacts

## Verification Commands

```bash
# Local confidence pass
pnpm test:unit
pnpm e2e:grep:noflake

# Nightly simulation (optional)
pnpm e2e:grep:flaky

# Full smoke test
pnpm smoke
```
