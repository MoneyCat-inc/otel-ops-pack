# C6: Beta Success Metrics

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

## 📝 PR NOTES Template

```
**Scope**: C6 Beta Success Metrics
**Files**: 
- src/engine/metrics/aggregate.ts (extend only)
- src/components/progress/BetaMetricsPanel.tsx
- tests/unit/beta-metrics.test.ts
- tests/e2e/beta-metrics.e2e.spec.ts
- docs/beta-metrics.md
- docs/release-notes/c6-beta-metrics.md
- fixtures/metrics/retention.json
- fixtures/metrics/comfort-trend.json
- fixtures/metrics/strain-rate.json

**Tests**: 
- Unit: @beta-metrics (pure function math, edge cases)
- E2E: @beta-metrics (panel rendering, interactions)

**Risk**: Low; isolated slice; extends existing without modification
**Rollback**: Revert commit (no shared code paths changed)
```

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
