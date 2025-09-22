# Maintenance

## 🔧 Env Clean & Healthy — How to run (5 min)

Use this quick path before any PR or release:

```pwsh
# 0) Fast cleanup
pnpm run tidy

# 1) Install (lockfile is the source of truth)
pnpm i --frozen-lockfile

# 2) Build (should exit 0)
pnpm build

# 3) (Optional) Run smoke tests if available
pnpm test:smoke

# 4) Verify headers & isolation in a local run
# Start dev (separate terminal) → next dev --turbo
# Then in browser console:
#   console.log(window.crossOriginIsolated)
# Expect: true
```

## Acceptance criteria (mirror in PR body):

- Tidy completes (== DONE ==)
- Install honors lockfile
- Build exits 0 (no CSP header warnings)
- (Optional) Smoke passes
- crossOriginIsolated === true on / (headers wired correctly)

The canonical block lives at the top of RUN_AND_VERIFY.md — copy/paste its table into each PR.

## Quick Commands

### Environment Health Check
```pwsh
# Check if environment is ready
pnpm run tidy && pnpm i --frozen-lockfile && pnpm build
```

### Smoke Testing
```pwsh
# Run smoke tests (requires dev server on http://localhost:3003)
pnpm test:smoke

# Run smoke tests in CI mode
pnpm test:smoke:ci
```

### Deep Clean (if needed)
```pwsh
# If build is slow after heavy Docker use
pnpm run tidy && pnpm run clean:deep
```

## Troubleshooting

### Common Issues
1. **Build fails**: Check for CSP header warnings, run `pnpm run tidy` first
2. **Smoke tests fail**: Ensure dev server is running on http://localhost:3003
3. **crossOriginIsolated is false**: Check `next.config.js` headers (COOP/COEP), service worker passthrough
4. **Port conflicts**: Use `scripts/kill-port.ps1` to clear port 3003

### Verification Steps
1. Run the acceptance criteria checklist
2. Check browser console for `window.crossOriginIsolated === true`
3. Verify smoke tests pass (if applicable)
4. Confirm build completes without warnings

## Integration Notes

- This maintenance guide aligns with the acceptance block in `RUN_AND_VERIFY.md`
- PR template includes the env health checklist for easy copy-paste
- Smoke tests use Playwright with Firefox for deterministic results
- All commands are designed to be idempotent and safe to re-run