# 🎯 Ready-to-Paste GitHub Issue Bodies

**Copy these issue bodies directly into GitHub Issues for immediate assignment:**

---

## C5: Cohort Log & Tester Guide

**Title:** C5: Cohort Log & Tester Guide

**Body:**
```markdown
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
```

---

## C6: Beta Success Metrics

**Title:** C6: Beta Success Metrics

**Body:**
```markdown
## 🎯 Task Overview
Extend the metrics aggregation engine with beta-specific success metrics for retention tracking, comfort trends, and strain monitoring.

## 📋 Requirements

### Core Features
- **Retention calculation**: Days with sessions vs total days
- **Comfort trend analysis**: Time-series comfort level tracking
- **Strain rate monitoring**: Strain events per 100 minutes of practice
- **Weekly frequency tracking**: Session frequency over time

### Technical Constraints
- **Extend only**: Add new exports to `aggregate.ts`, don't modify existing
- **Pure functions**: All new functions must be pure (no side effects)
- **Local-first**: IndexedDB only, no network calls
- **Backward compatible**: Don't break existing aggregator exports

## 🔧 Implementation Plan

### Files to Create/Modify
- `src/engine/metrics/aggregate.ts` - **Extend only** with new pure functions
- `src/components/progress/BetaMetricsPanel.tsx` - New metrics display component
- `tests/unit/beta-metrics.test.ts` - Unit tests for new functions
- `tests/e2e/beta-metrics.e2e.spec.ts` - E2E tests for panel
- `docs/beta-metrics.md` - Metrics documentation
- `docs/release-notes/c6-beta-metrics.md` - Release notes

### New Function Contracts
```typescript
// Required new exports (add to aggregate.ts)
export function calcRetention(sessions: SessionSummaryV1[]): {
  daysWithSessions: number;
  totalDays: number;
  percent: number;
}

export function calcComfortTrend(sessions: SessionSummaryV1[]): number[]

export function calcStrainPer100Min(sessions: SessionSummaryV1[]): number

export function calcWeeklyFrequency(sessions: SessionSummaryV1[]): number[]
```

### Test Fixtures
- `fixtures/metrics/retention.json` - Retention calculation samples
- `fixtures/metrics/comfort-trend.json` - Comfort trend samples  
- `fixtures/metrics/strain-rate.json` - Strain rate samples

### Test Tags
- Unit tests: `@beta-metrics`
- E2E tests: `@beta-metrics`

## ✅ Acceptance Criteria

### Functional Requirements
- [ ] Panel renders from IndexedDB only (no network calls)
- [ ] All four new functions implemented as pure functions
- [ ] Retention calculation accurate for various session patterns
- [ ] Comfort trend provides meaningful time-series data
- [ ] Strain rate calculation handles edge cases correctly
- [ ] Weekly frequency tracking works across date ranges

### Technical Requirements
- [ ] **No modifications** to existing aggregator exports
- [ ] New functions are pure (no side effects)
- [ ] Unit math verified on edge cases (empty, sparse, mixed data)
- [ ] Panel component follows existing design patterns
- [ ] Accessibility compliance (WCAG AA)

### Testing Requirements
- [ ] Unit tests cover all edge cases for new functions
- [ ] E2E tests verify panel rendering and interactions
- [ ] Tests run green on Firefox + Chromium
- [ ] Deterministic fixtures for consistent testing

## 🚀 Ready Signals

### Development Complete
- [ ] Panel renders from IndexedDB only; no network calls
- [ ] Unit math verified on edge cases (empty, sparse, mixed)
- [ ] All tests passing with `@beta-metrics` tags
- [ ] Documentation complete and accurate

### PR Requirements
- [ ] Branch: `cohort/C6-beta-metrics`
- [ ] Labels: `cohort`, `metrics`, `ready-for-review`
- [ ] PR NOTES block includes: scope → files → tests → rollback
- [ ] No cross-slice edits (isolated to C6 paths only)

## 🔒 Guardrails

### Code Safety
- **Extend only**: Add new exports, don't modify existing
- **Pure functions**: No side effects, deterministic outputs
- **Backward compatible**: Existing code continues to work

### Data Privacy
- **Local-first**: No data leaves the device
- **IndexedDB only**: No network calls or external storage
- **Bounded calculations**: Handle large datasets efficiently

### Technical
- **Strict CSP**: No inline styles or scripts
- **Console guard**: No errors or warnings
- **Cross-browser**: Firefox + Chromium compatibility

## 🧪 Test Commands

```bash
# Unit tests
pnpm test:unit --filter beta-metrics

# E2E tests
pnpm test:e2e --grep "@beta-metrics"

# Full QA
pnpm run qa:full && pnpm run qa:summary
```

## 🔗 Dependencies

### Read-Only Access
- **C7 Dashboard Polish**: May read BetaMetricsPanel outputs via props
- **C8 Beta Launch**: Will reference metrics in documentation

### No Dependencies
- **C5 Cohort Log**: Independent implementation
- **Existing aggregators**: Extend only, don't modify

---

**Assignee**: Agent B  
**Priority**: High  
**Estimated Time**: 6-8 hours  
**Dependencies**: None (isolated implementation)
```

---

## C8: Beta Launch Checklist

**Title:** C8: Beta Launch Checklist

**Body:**
```markdown
## 🎯 Task Overview
Create comprehensive beta launch documentation including preflight validation, onboarding procedures, success metrics, and rollback procedures.

## 📋 Requirements

### Core Documentation
- **Preflight checklist**: C1-C7 gates + QA validation
- **Onboarding guide**: Cohort flag enablement, privacy FAQ, data controls
- **Success metrics**: Retention %, comfort trend, strain per 100 min
- **Rollback procedures**: Disable flags → revert → verify → re-run QA

### User Experience
- **Copy-paste commands**: All commands must be executable
- **Clear procedures**: Step-by-step instructions for each process
- **Troubleshooting**: Common issues and solutions
- **Privacy focus**: Data export/delete procedures prominently featured

## 🔧 Implementation Plan

### Files to Create/Modify
- `docs/BETA_LAUNCH_CHECKLIST.md` - Main preflight checklist
- `docs/cohort-onboarding.md` - User onboarding procedures
- `docs/rollback-procedures.md` - Rollback and recovery procedures
- `README.md` - **Add only** "Beta Launch" link section (no other edits)
- `docs/release-notes/c8-beta-launch.md` - Release notes

### Content Requirements
- **Preflight**: C1-C7 gates + `pnpm qa:full` + `qa:summary`
- **Onboarding**: How to enable cohort flags, privacy FAQ, export/delete
- **Success metrics**: Retention %, comfort trend, strain per 100 min
- **Rollback**: Disable flags → revert → verify isolation/a11y → re-run QA

### Test Requirements
- **Docs only**: No unit/E2E tests required
- **Link validation**: All internal links must work
- **Command validation**: All commands must be copy-paste executable

## ✅ Acceptance Criteria

### Documentation Requirements
- [ ] All documentation renders correctly (Markdown)
- [ ] All internal links are valid and working
- [ ] All commands are copy-paste clean and executable
- [ ] Privacy procedures are prominently featured
- [ ] Troubleshooting section covers common issues

### Content Requirements
- [ ] Preflight checklist covers all C1-C7 gates
- [ ] Onboarding guide explains cohort flag enablement
- [ ] Success metrics align with C6 BetaMetricsPanel outputs
- [ ] Rollback procedures are step-by-step and safe
- [ ] README.md has "Beta Launch" section added (no other changes)

### Technical Requirements
- [ ] All commands tested and working
- [ ] Links validated (no 404s)
- [ ] Markdown renders correctly in GitHub
- [ ] Documentation follows existing style guide

## 🚀 Ready Signals

### Development Complete
- [ ] Docs render; all links valid; commands copy-paste clean
- [ ] Preflight checklist covers all required gates
- [ ] Onboarding procedures are clear and complete
- [ ] Rollback procedures are safe and tested

### PR Requirements
- [ ] Branch: `cohort/C8-beta-launch-checklist`
- [ ] Labels: `cohort`, `docs`, `ready-for-review`
- [ ] PR NOTES block includes: scope → files → tests → rollback
- [ ] No cross-slice edits (isolated to C8 paths only)

## 🔒 Guardrails

### Documentation Standards
- **Copy-paste ready**: All commands must work as written
- **Link validation**: No broken internal links
- **Privacy focus**: Data controls prominently featured
- **Clear procedures**: Step-by-step instructions

### Content Safety
- **Safe rollback**: Procedures must not cause data loss
- **Tested commands**: All commands validated before documentation
- **Accurate metrics**: Success metrics align with C6 implementation

### Technical
- **Markdown compliance**: Renders correctly in GitHub
- **Style consistency**: Follows existing documentation patterns
- **Minimal README changes**: Add only, don't edit existing sections

## 🧪 Validation Commands

```bash
# Full QA (as documented in preflight)
pnpm run qa:full && pnpm run qa:summary

# Link validation (manual check)
# - Check all internal links in docs
# - Verify all commands work as written
# - Test rollback procedures in safe environment
```

## 🔗 Dependencies

### Content Dependencies
- **C1-C7**: Preflight checklist references all previous implementations
- **C6 Beta Metrics**: Success metrics align with BetaMetricsPanel outputs
- **C5 Cohort Log**: Onboarding references cohort logging features

### No Code Dependencies
- **Pure documentation**: No code changes required
- **Link validation**: Manual verification of all links
- **Command testing**: Manual validation of all commands

## 📚 Documentation Structure

### BETA_LAUNCH_CHECKLIST.md
- Preflight validation steps
- C1-C7 gate requirements
- QA command execution
- Success criteria

### cohort-onboarding.md
- Cohort flag enablement
- Privacy FAQ
- Data export/delete procedures
- Troubleshooting common issues

### rollback-procedures.md
- Safe rollback steps
- Flag disable procedures
- Verification steps
- Recovery procedures

### README.md Changes
- Add "Beta Launch" section
- Link to main documentation
- **No other edits** to existing content

---

**Assignee**: Agent D  
**Priority**: High  
**Estimated Time**: 3-4 hours  
**Dependencies**: C1-C7 implementations (for reference)
```

---

**Ready to deploy:** Copy these issue bodies directly into GitHub Issues and assign to respective agents!
