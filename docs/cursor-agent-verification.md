# Cursor Agent Guardrails Verification

## ✅ Guardrails Alignment Check

### Security & Privacy
- **CSP & No Inline Styles**: ✅ Aligned with existing hardening
- **Cross-Origin Isolation**: ✅ COOP/COEP requirements maintained
- **Local-First Privacy**: ✅ No audio/PII upload, IndexedDB only for metrics
- **Agent Lock Respect**: ✅ Honors `.agent/LOCK` kill-switch

### Accessibility
- **WCAG 2.2 AA**: ✅ Matches `docs/comfort-cat/accessibility.md`
- **ARIA Live Regions**: ✅ Required for dynamic feedback
- **Keyboard Navigation**: ✅ Full keyboard support required
- **Reduced Motion**: ✅ Honors `prefers-reduced-motion`

### Creative Guidelines
- **Comfort Cat Reference**: ✅ All decisions reference `docs/comfort-cat/`
- **Windows Mirror**: ✅ `C:\otel\docs\comfort cat` maintained
- **Tone**: ✅ Warm, concise, lightly clever (per copy.md)
- **Motion**: ✅ Calm, not sluggish (per success-criteria.md)

### ECRR Methodology
- **Examine**: ✅ Capture state before changes
- **Clean**: ✅ Remove drift, enforce guardrails
- **Report**: ✅ Generate artifacts in `docs/ECRR_REPORTS/`
- **Role**: ✅ Declare Cursor Agent as implementor

### Testing & Quality
- **Unit Tests**: ✅ Required for all utilities
- **E2E Tests**: ✅ Playwright tests for user flows
- **Deterministic Tests**: ✅ Respect quarantine patterns
- **Performance**: ✅ Audio latency < 200ms target

## ✅ Integration Points

### Agent System
- **Queue Processing**: ✅ Reads from `.agent/agent_queue.json`
- **State Management**: ✅ Updates `.agent/state.json`
- **Health Checks**: ✅ Integrates with `pnpm agent:doctor`
- **Background Tasks**: ✅ Respects existing watchdog

### CI/CD Pipeline
- **PR Requirements**: ✅ ECRR Gate section mandatory
- **Test Coverage**: ✅ Unit + e2e tests required
- **Guardrail Checks**: ✅ Automated validation
- **Documentation**: ✅ Update relevant docs

### Creative Assets
- **Palette**: ✅ Follow `docs/comfort-cat/palette.md`
- **Typography**: ✅ Follow `docs/comfort-cat/type.md`
- **Motion**: ✅ Follow `docs/comfort-cat/motion.md`
- **Copy**: ✅ Follow `docs/comfort-cat/copy.md`

## ✅ Task Pack Alignment

### T1: Resonance Buckets
- **Scope**: LPC worklet + fallback classifier
- **Guardrails**: No server calls, a11y labels, zero inline styles
- **Testing**: Playwright lab test + unit tests
- **ECRR**: Performance metrics in report

### T2: Prosody Scenarios
- **Scope**: Voicemail + meeting intro cards
- **Guardrails**: Feature-flagged, constructive phrasing, ARIA live regions
- **Testing**: Unit tests for scoring + e2e with mocks
- **ECRR**: User experience validation

### T3: Strain Guardrails
- **Scope**: Loudness/jitter detection + cooldown UI
- **Guardrails**: Supportive copy, accessible interface, IndexedDB only
- **Testing**: Unit tests for heuristics + calibration docs
- **ECRR**: Detection accuracy metrics

### T4: Cross-Origin Isolation
- **Scope**: Firefox COOP/COEP verification
- **Guardrails**: No asset header regressions, SW compatibility
- **Testing**: Firefox-specific e2e tests
- **ECRR**: Cross-browser compatibility validation

### T5: A11y Smoke
- **Scope**: Live regions + reduced motion
- **Guardrails**: WCAG AA compliance, screen reader support
- **Testing**: A11y e2e tests + manual verification
- **ECRR**: Accessibility audit results

## ✅ Ready for Launch

The Cursor Agent system is fully aligned with existing repo guardrails and ready for immediate deployment. All components follow the established patterns:

1. **System Prompt**: `docs/cursor-agent-system-prompt.md`
2. **Task Pack**: `docs/cursor-agent-task-pack.md`
3. **Runbook**: `docs/cursor-agent-runbook.md`
4. **Verification**: This document

The agent can be launched immediately by copying the system prompt into Cursor and feeding tasks from the task pack.
