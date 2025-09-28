# Cursor Agent Starter Task Pack

> These are prioritized to close stakeholder asks: resonance robustness, carry-over prosody, safety guardrails, offline isolation, and a11y smoke coverage.

## Task Priority Queue

### T1 — Resonance Buckets v1 (LPC + fallback classifier)
**Priority**: 10 (Critical)  
**Goal**: Surface stable F1/F2-driven "brightness" buckets across common mics; fallback to a tiny vowel classifier if LPC is unstable on phones.

**Scope**:
* Implement/finish the **LPC worklet** path and map coarse F1/F2 into front/central/back buckets with confidence gating.
* Add a feature-flagged **fallback**: tiny vowel CNN or heuristic classifier that activates when LPC confidence is low.
* Wire to the existing aura/bucket visualization; no new server calls.

**Acceptance Criteria**:
* ✅ In quiet room + decent mic, sustained `/i/` and `/e/` land in the expected bucket ≥ 80% of voiced frames (desktop), with a test harness/lab page to verify.
* ✅ Playwright lab test covers happy path + fallback toggle.
* ✅ A11y labels for the bucket readout; zero inline styles.
* ✅ ECRR report generated with before/after performance metrics.

**Files to Touch**:
* `public/worklets/lpc-formant-tracker.js`
* `src/audio/resonance-buckets.ts`
* `src/components/ResonanceVisualizer.tsx`
* `tests/e2e/resonance-buckets.spec.ts`

---

### T2 — Prosody Carry-over Scenarios (voicemail + meeting intro)
**Priority**: 9 (High)  
**Goal**: Move from micro-phrases to simple applied speech tasks using existing rise/fall + expressiveness signals.

**Scope**:
* Add 2 scenario cards (voicemail; meeting intro) that record short utterances and evaluate end-rise/fall + expressiveness delta vs. user baseline.
* Friendly copy; results summarized via live region ("gentle fall detected; nice variety today").

**Acceptance Criteria**:
* ✅ 2 cards gated behind a feature flag; **unit tests** for scoring utilities; **e2e** that runs with mock input using existing labs/mocks.
* ✅ No absolute "gender" labels; only constructive phrasing per UX best practices.
* ✅ ARIA live regions for dynamic feedback; keyboard navigation support.
* ✅ ECRR report with user experience validation.

**Files to Touch**:
* `src/components/scenarios/VoicemailCard.tsx`
* `src/components/scenarios/MeetingIntroCard.tsx`
* `src/audio/prosody-scoring.ts`
* `tests/unit/prosody-scoring.test.ts`
* `tests/e2e/scenarios.spec.ts`

---

### T3 — Vocal Strain Guardrails v1
**Priority**: 8 (High)  
**Goal**: Detect early signs of strain and insert gentle cooldowns.

**Scope**:
* Compute loudness proxy & jitter trend from existing telemetry; add a session-level "strainFlag" when thresholds are exceeded.
* Inject a 30–60s SOVT cooldown card when flagged; store the flag in session summary (IndexedDB) without uploading audio.

**Acceptance Criteria**:
* ✅ Thresholds configurable in a tuning HUD; **unit tests** for the heuristic; doc note explaining calibration plan for cohort testing.
* ✅ UI copy is supportive ("let's reset and keep it comfy").
* ✅ Accessible cooldown interface with clear progress indicators.
* ✅ ECRR report with strain detection accuracy metrics.

**Files to Touch**:
* `src/audio/strain-detection.ts`
* `src/components/StrainCooldownCard.tsx`
* `src/components/TuningHUD.tsx`
* `tests/unit/strain-detection.test.ts`
* `docs/VOCAL_STRAIN_CALIBRATION.md`

---

### T4 — Offline Cross-Origin Isolation Smoke (Firefox)
**Priority**: 7 (Medium)  
**Goal**: Guarantee `crossOriginIsolated === true` online **and** offline (SW-controlled) in Firefox.

**Scope**:
* Add Playwright check that installs the SW, then verifies COOP/COEP persist for navigations/assets (fonts/worklets/WASM).
* Fix any asset headers (CORS/CORP) that fail under COEP in tests.

**Acceptance Criteria**:
* ✅ Green e2e that demonstrates isolation both online and under SW; no regressions in existing isolation tests.
* ✅ Firefox-specific test configuration and CI integration.
* ✅ Documentation of COEP requirements for assets.
* ✅ ECRR report with cross-browser compatibility validation.

**Files to Touch**:
* `tests/e2e/cross-origin-isolation.spec.ts`
* `playwright.firefox.config.ts`
* `public/sw.js` (if modifications needed)
* `docs/CROSS_ORIGIN_ISOLATION.md`

---

### T5 — A11y Smoke: Live Regions & Reduced Motion
**Priority**: 6 (Medium)  
**Goal**: Lock in WCAG baselines for dynamic feedback.

**Scope**:
* Add quick a11y smokes ensuring `aria-live="polite"` on key result lines (prosody verdicts, in-band meter), and honoring `prefers-reduced-motion`.
* Fix any gaps uncovered.

**Acceptance Criteria**:
* ✅ Playwright a11y checks pass; visual motion disabled under reduced-motion; no inline styles; docs updated in QA checklist.
* ✅ Screen reader compatibility verified with NVDA/JAWS.
* ✅ Keyboard navigation covers all interactive elements.
* ✅ ECRR report with accessibility audit results.

**Files to Touch**:
* `tests/e2e/accessibility.spec.ts`
* `src/components/PracticeHUD.tsx` (ARIA improvements)
* `app/ui.css` (reduced-motion utilities)
* `docs/ACCESSIBILITY_CHECKLIST.md`

---

## Task Execution Workflow

### 1. Task Selection
```bash
# Check current agent status
pnpm agent:status

# Review task queue
cat .agent/agent_queue.json
```

### 2. ECRR Process (Mandatory)
Each task must follow:

1. **Examine** — Capture current state, test environment
2. **Clean** — Remove drift, enforce guardrails  
3. **Report** — Generate ECRR report in `docs/ECRR_REPORTS/`
4. **Role** — Declare Cursor Agent as implementor

### 3. Implementation
```bash
# Start agent processing
pnpm agent:start

# Emergency stop if needed
touch .agent/LOCK

# Resume after fixes
rm .agent/LOCK
```

### 4. Verification
Each task includes specific acceptance criteria that must be met before marking complete.

## Integration Notes

* Tasks integrate with existing agent system (`.agent/` directory)
* Respects `.agent/LOCK` kill-switch
* Updates `.agent/state.json` with progress
* Generates ECRR reports for audit trail
* Follows existing guardrails (CSP, COOP/COEP, a11y)

## Creative Guidelines

All UI/UX decisions must reference:
- In repo: `docs/comfort-cat/`
- On Windows: `C:\otel\docs\comfort cat`

Follow the "Cat Nap Control Room" aesthetic: calm, efficient, playful.
