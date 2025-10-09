# C5: Cohort Log & Tester Guide

## 🎯 Task Overview
Implement local-first cohort logging system with bounded storage and offline export capabilities for beta testing coordination.

## 📋 Requirements

### Core Features
- **Bounded log storage**: Last 100 sessions only, automatic rotation
- **Offline export**: JSON export functionality for tester coordination
- **Clear functionality**: One-click data deletion for privacy
- **Local-first**: No network calls, IndexedDB only

### User Experience
- **Tester-friendly interface**: Simple log viewing and export
- **Privacy controls**: Clear data deletion with confirmation
- **Accessibility**: WCAG AA compliance, keyboard navigation
- **Motion safety**: Respects `prefers-reduced-motion`

## 🔧 Implementation Plan

### Files to Create/Modify
- `src/engine/metrics/cohortLog.ts` - Log management engine
- `app/labs/cohort-log/page.tsx` - Log viewing interface
- `tests/unit/cohort-log.test.ts` - Unit tests
- `tests/e2e/cohort-log.e2e.spec.ts` - E2E tests
- `docs/cohort-tester-guide.md` - Tester documentation
- `docs/release-notes/c5-cohort-log.md` - Release notes

### Test Fixtures
- `fixtures/cohort/log-samples.json` - Bounded log samples (last 100 entries)

### Test Tags
- Unit tests: `@cohort-log`
- E2E tests: `@cohort-log`

## ✅ Acceptance Criteria

### Functional Requirements
- [ ] Log rotates to last 100 sessions automatically
- [ ] Export functionality works offline (JSON format)
- [ ] Clear functionality removes all data with confirmation
- [ ] No network calls made during operation

### Technical Requirements
- [ ] Single `aria-live="polite"` region for announcements
- [ ] Keyboard navigation and focus rings pass
- [ ] Console guard active (no errors)
- [ ] Strict CSP compliance (no inline styles)

### Testing Requirements
- [ ] Unit tests cover log rotation, export, and clear functionality
- [ ] E2E tests verify UI interactions and accessibility
- [ ] Tests run green on Firefox + Chromium
- [ ] Deterministic fixtures for consistent testing

## 🚀 Ready Signals

### Development Complete
- [ ] Log rotates to last 100 sessions; export & clear work offline
- [ ] Single `aria-live="polite"`; keyboard and focus rings pass
- [ ] All tests passing with `@cohort-log` tags
- [ ] Documentation complete and accurate

### PR Requirements
- [ ] Branch: `cohort/C5-cohort-log`
- [ ] Labels: `cohort`, `privacy`, `a11y`, `ready-for-review`
- [ ] PR NOTES block includes: scope → files → tests → rollback
- [ ] No cross-slice edits (isolated to C5 paths only)

## 🔒 Guardrails

### Privacy & Security
- **Local-first**: No data leaves the device
- **Bounded storage**: Automatic cleanup prevents data accumulation
- **Clear confirmation**: Prevents accidental data deletion

### Accessibility
- **WCAG AA compliance**: Screen reader support, keyboard navigation
- **Motion safety**: Static fallbacks for reduced motion preferences
- **Focus management**: Proper tab order and focus indicators

### Technical
- **Strict CSP**: No inline styles or scripts
- **Console guard**: No errors or warnings
- **Cross-browser**: Firefox + Chromium compatibility

## 📝 PR NOTES Template

```
**Scope**: C5 Cohort Log & Tester Guide
**Files**: 
- src/engine/metrics/cohortLog.ts
- app/labs/cohort-log/page.tsx
- tests/unit/cohort-log.test.ts
- tests/e2e/cohort-log.e2e.spec.ts
- docs/cohort-tester-guide.md
- docs/release-notes/c5-cohort-log.md
- fixtures/cohort/log-samples.json

**Tests**: 
- Unit: @cohort-log (log rotation, export, clear)
- E2E: @cohort-log (UI interactions, accessibility)

**Risk**: Low; isolated slice; local-first only
**Rollback**: Revert commit (no shared code paths changed)
```

## 🧪 Test Commands

```bash
# Unit tests
pnpm test:unit --filter cohort-log

# E2E tests  
pnpm test:e2e --grep "@cohort-log"

# Full QA
pnpm run qa:full && pnpm run qa:summary
```

---

**Assignee**: Agent A  
**Priority**: High  
**Estimated Time**: 4-6 hours  
**Dependencies**: None (isolated implementation)
