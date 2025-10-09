# 🧭 Parallel Rollout Coordination Kit

**Date**: January 27, 2025  
**Status**: Ready for 4-Agent Parallel Rollout  
**Completed**: C7 Dashboard Polish & UX ✅  

## 📋 Agent Assignment Summary

| Agent | Task | Branch | Status | Files |
|-------|------|--------|--------|-------|
| **Agent A** | C5: Cohort Log & Tester Guide | `cohort/C5-cohort-log` | 🟡 Ready | 7 files |
| **Agent B** | C6: Beta Success Metrics | `cohort/C6-beta-metrics` | 🟡 Ready | 8 files |
| **Agent C** | C7: Dashboard Polish & UX | `cohort/C7-dashboard-polish` | ✅ **COMPLETE** | 6 files |
| **Agent D** | C8: Beta Launch Checklist | `cohort/C8-beta-launch-checklist` | 🟡 Ready | 5 files |

## 🎯 Ground Rules (All Agents)

### Branch & PR Standards
- **Branch names**: `cohort/<C#>-<short-name>`
- **PR labels**: `cohort`, `privacy`, `a11y` (as relevant) + `ready-for-review`
- **PR NOTES block**: scope → files → tests → rollback
- **One concern per PR**: Small diffs, no cross-slice edits

### Testing Requirements
- **Unit + E2E**: With tags, deterministic fixtures, console guard active
- **Cross-browser**: Firefox + Chromium compatibility
- **Test tags**: `@cohort-log`, `@beta-metrics`, `@dashboard-polish`

### Guardrails
- **Local-first**: No uploads, IndexedDB only
- **Strict CSP**: No inline styles
- **A11y**: `aria-live` exactly once per component
- **Motion safety**: `prefers-reduced-motion` respected

## 🔧 Collision Avoidance Map

### File Ownership
- **C5**: `src/engine/metrics/cohortLog.ts`, `app/labs/cohort-log/page.tsx`
- **C6**: `src/engine/metrics/aggregate.ts` (extend only), `src/components/progress/BetaMetricsPanel.tsx`
- **C7**: `src/components/OrbV2.tsx`, `src/components/progress/FriendlySummary.tsx`, `app/progress/page.tsx` ✅
- **C8**: `docs/` files, `README.md` (add only)

### Critical Constraints
- **Only C7** touches `app/progress/page.tsx` ✅ **COMPLETE**
- **Only C8** edits `README.md` (add "Beta Launch" section only)
- **C6** extends `aggregate.ts` via **new exports only** (no renames/removals)
- **Separate release notes**: `docs/release-notes/c#.md` to avoid merge conflicts

## 🧪 Test Matrix Commands

```bash
# C5 - Cohort Log
pnpm test:unit --filter cohort-log
pnpm test:e2e --grep "@cohort-log"

# C6 - Beta Metrics  
pnpm test:unit --filter beta-metrics
pnpm test:e2e --grep "@beta-metrics"

# C7 - Dashboard Polish ✅ COMPLETE
pnpm test:unit --filter summary-wording
pnpm test:e2e --grep "@dashboard-polish"

# C8 - Beta Launch (docs only)
pnpm run qa:full && pnpm run qa:summary
```

## ✅ Merge Gate Requirements

### Technical Validation
- [ ] Unit + E2E tests green under Firefox + Chromium
- [ ] No console errors (COEP/CORS/CSP)
- [ ] No network calls added
- [ ] `aria-live` exactly once per component
- [ ] Reduced-motion honored

### Documentation Validation
- [ ] PR NOTES present and complete
- [ ] Scope clearly defined
- [ ] Files listed accurately
- [ ] Tests documented
- [ ] Rollback plan specified

## 📝 PR NOTES Template (All Agents)

```
**Scope**: <C# short description>
**Files**: 
- List key files + fixtures + docs
**Tests**: 
- Unit + E2E tags (or docs only for C8)
**Risk**: Low; isolated slice; local-first only
**Rollback**: Revert commit (no shared code paths changed)
```

## 🚀 Deployment Strategy

### Phase 1: Parallel Development
- **Agents A, B, D** work in parallel on their assigned tasks
- **Agent C** (C7) already complete ✅
- **No dependencies** between C5, C6, C8

### Phase 2: Integration Testing
- **C7** already integrated and tested ✅
- **C5, C6, C8** integrate independently
- **Cross-browser testing** on all implementations

### Phase 3: Beta Launch
- **C8** provides launch checklist
- **C6** provides success metrics
- **C5** provides cohort logging
- **C7** provides polished dashboard ✅

## 🔗 Dependencies & Integration

### C7 Dependencies (COMPLETE ✅)
- **C6 BetaMetricsPanel**: C7 may read outputs via props
- **No blocking dependencies**: C7 can proceed independently

### C6 Dependencies
- **C7 Dashboard**: May read BetaMetricsPanel outputs
- **C8 Documentation**: Will reference C6 metrics

### C8 Dependencies
- **C1-C7**: References all implementations in preflight
- **C6 Metrics**: Aligns success metrics with C6 outputs

## 📊 Success Metrics

### Technical Metrics
- **Test coverage**: 100% for all new components
- **Accessibility**: WCAG AA compliance across all features
- **Performance**: < 5s load time maintained
- **Cross-browser**: Firefox + Chromium compatibility

### User Experience Metrics
- **C5**: Log rotation, export, clear functionality
- **C6**: Retention %, comfort trend, strain rate
- **C7**: Shimmer effects, friendly summaries ✅
- **C8**: Complete documentation, working commands

## 🎯 Ready for Launch

### C7 Status: ✅ COMPLETE
- **OrbV2 shimmer overlay** with resonance animations
- **FriendlySummary component** with encouraging language
- **Motion safety** with reduced-motion support
- **21 unit tests** passing
- **Comprehensive E2E tests** for visual polish
- **Release notes** complete

### Next Steps
1. **Assign C5, C6, C8** to respective agents
2. **Provide GitHub issue bodies** (created above)
3. **Monitor parallel development** progress
4. **Coordinate integration** testing
5. **Execute beta launch** checklist

---

**Coordination Complete**: All agents have clear assignments, collision avoidance, and success criteria.  
**C7 Complete**: Dashboard polish ready for production.  
**Ready for Parallel Rollout**: C5, C6, C8 can proceed simultaneously.
