# PR Metadata Suggestions

## Title
```
docs: refresh ECRR Project Report with comprehensive wrap-up
```

## Labels
- `docs` - Documentation change
- `governance` - ECRR framework and project governance
- `ECRR` - ECRR-specific content
- `ready-to-merge` - All checks passed, ready for approval

## Description Template
```
## Summary
Replace brief ECRR Project Report with comprehensive wrap-up covering Examine/Clean/Report/Role framework.

## What Changed
- `docs/ECRR_PROJECT_REPORT.md` - Complete content refresh
- All existing cross-links preserved (11 files)
- No structural changes

## Review Checklist
- [ ] Header: "📑 Resonai — Full Project ECRR Report"
- [ ] Cross-links intact (see `.git/_grep_ecrr.txt`)
- [ ] Single file modified
- [ ] ECRR framework complete

## Proof Artifacts
- `.git/_proof.txt` - Clean working tree, correct header
- `.git/_grep_ecrr.txt` - All cross-link references verified

## Files Changed
- `docs/ECRR_PROJECT_REPORT.md` (content replacement only)

## Testing
- [x] Lint checks passed
- [x] Cross-link verification completed
- [x] Proof artifacts generated
```

## Branch Protection
- Requires: 1 reviewer approval
- Requires: CI checks to pass
- Auto-merge: Enabled (if all checks pass)

## Merge Strategy
- **Squash and merge** (recommended)
- **Commit message**: Use PR title
- **Delete branch**: After merge
