# GitHub Issue Bodies for Cursor Agent Tasks

## T1 — Resonance Buckets v1 (LPC + fallback classifier)

```markdown
# T1: Resonance Buckets v1 (LPC + fallback classifier)

## Priority
🔴 **Critical** - Priority 10

## Goal
Surface stable F1/F2-driven "brightness" buckets across common mics; fallback to a tiny vowel classifier if LPC is unstable on phones.

## Scope
- Implement/finish the **LPC worklet** path and map coarse F1/F2 into front/central/back buckets with confidence gating
- Add a feature-flagged **fallback**: tiny vowel CNN or heuristic classifier that activates when LPC confidence is low
- Wire to the existing aura/bucket visualization; no new server calls

## Acceptance Criteria
- [ ] In quiet room + decent mic, sustained `/i/` and `/e/` land in the expected bucket ≥ 80% of voiced frames (desktop), with a test harness/lab page to verify
- [ ] Playwright lab test covers happy path + fallback toggle
- [ ] A11y labels for the bucket readout; zero inline styles
- [ ] ECRR report generated with before/after performance metrics

## Files to Touch
- `public/worklets/lpc-formant-tracker.js`
- `src/audio/resonance-buckets.ts`
- `src/components/ResonanceVisualizer.tsx`
- `tests/e2e/resonance-buckets.spec.ts`

## Testing Commands
```bash
# Test LPC worklet
pnpm dev
# Navigate to /labs/resonance-test

# Run e2e tests
pnpm test:e2e --grep "resonance"
```

## ECRR Requirements
- [ ] **Examine** — Capture current LPC implementation state
- [ ] **Clean** — Remove any inline styles, enforce guardrails
- [ ] **Report** — Generate ECRR report in `docs/ECRR_REPORTS/`
- [ ] **Role** — Declare Cursor Agent as implementor

## Labels
`enhancement`, `audio-engine`, `accessibility`, `high-priority`, `cursor-agent`

## Milestone
Resonance Robustness v1

## Assignee
@cursor-agent
```

---

## T2 — Prosody Carry-over Scenarios (voicemail + meeting intro)

```markdown
# T2: Prosody Carry-over Scenarios (voicemail + meeting intro)

## Priority
🟠 **High** - Priority 9

## Goal
Move from micro-phrases to simple applied speech tasks using existing rise/fall + expressiveness signals.

## Scope
- Add 2 scenario cards (voicemail; meeting intro) that record short utterances and evaluate end-rise/fall + expressiveness delta vs. user baseline
- Friendly copy; results summarized via live region ("gentle fall detected; nice variety today")

## Acceptance Criteria
- [ ] 2 cards gated behind a feature flag; **unit tests** for scoring utilities; **e2e** that runs with mock input using existing labs/mocks
- [ ] No absolute "gender" labels; only constructive phrasing per UX best practices
- [ ] ARIA live regions for dynamic feedback; keyboard navigation support
- [ ] ECRR report with user experience validation

## Files to Touch
- `src/components/scenarios/VoicemailCard.tsx`
- `src/components/scenarios/MeetingIntroCard.tsx`
- `src/audio/prosody-scoring.ts`
- `tests/unit/prosody-scoring.test.ts`
- `tests/e2e/scenarios.spec.ts`

## Testing Commands
```bash
# Test scenario cards
pnpm dev
# Navigate to /practice/scenarios

# Run unit tests
pnpm test:unit --grep "prosody"
```

## ECRR Requirements
- [ ] **Examine** — Capture current prosody implementation
- [ ] **Clean** — Ensure no inline styles, proper ARIA
- [ ] **Report** — Generate ECRR report with UX validation
- [ ] **Role** — Declare Cursor Agent as implementor

## Labels
`enhancement`, `prosody`, `scenarios`, `accessibility`, `cursor-agent`

## Milestone
Applied Prosody v1

## Assignee
@cursor-agent
```

---

## T3 — Vocal Strain Guardrails v1

```markdown
# T3: Vocal Strain Guardrails v1

## Priority
🟠 **High** - Priority 8

## Goal
Detect early signs of strain and insert gentle cooldowns.

## Scope
- Compute loudness proxy & jitter trend from existing telemetry; add a session-level "strainFlag" when thresholds are exceeded
- Inject a 30–60s SOVT cooldown card when flagged; store the flag in session summary (IndexedDB) without uploading audio

## Acceptance Criteria
- [ ] Thresholds configurable in a tuning HUD; **unit tests** for the heuristic; doc note explaining calibration plan for cohort testing
- [ ] UI copy is supportive ("let's reset and keep it comfy")
- [ ] Accessible cooldown interface with clear progress indicators
- [ ] ECRR report with strain detection accuracy metrics

## Files to Touch
- `src/audio/strain-detection.ts`
- `src/components/StrainCooldownCard.tsx`
- `src/components/TuningHUD.tsx`
- `tests/unit/strain-detection.test.ts`
- `docs/VOCAL_STRAIN_CALIBRATION.md`

## Testing Commands
```bash
# Test strain detection
pnpm dev
# Navigate to /practice/tuning

# Run strain tests
pnpm test:unit --grep "strain"
```

## ECRR Requirements
- [ ] **Examine** — Capture current telemetry and strain patterns
- [ ] **Clean** — Ensure supportive UI copy, accessible interface
- [ ] **Report** — Generate ECRR report with detection accuracy
- [ ] **Role** — Declare Cursor Agent as implementor

## Labels
`enhancement`, `safety`, `strain-detection`, `accessibility`, `cursor-agent`

## Milestone
Safety Guardrails v1

## Assignee
@cursor-agent
```

---

## T4 — Offline Cross-Origin Isolation Smoke (Firefox)

```markdown
# T4: Offline Cross-Origin Isolation Smoke (Firefox)

## Priority
🟡 **Medium** - Priority 7

## Goal
Guarantee `crossOriginIsolated === true` online **and** offline (SW-controlled) in Firefox.

## Scope
- Add Playwright check that installs the SW, then verifies COOP/COEP persist for navigations/assets (fonts/worklets/WASM)
- Fix any asset headers (CORS/CORP) that fail under COEP in tests

## Acceptance Criteria
- [ ] Green e2e that demonstrates isolation both online and under SW; no regressions in existing isolation tests
- [ ] Firefox-specific test configuration and CI integration
- [ ] Documentation of COEP requirements for assets
- [ ] ECRR report with cross-browser compatibility validation

## Files to Touch
- `tests/e2e/cross-origin-isolation.spec.ts`
- `playwright.firefox.config.ts`
- `public/sw.js` (if modifications needed)
- `docs/CROSS_ORIGIN_ISOLATION.md`

## Testing Commands
```bash
# Test Firefox isolation
pnpm test:e2e --config playwright.firefox.config.ts

# Check COOP/COEP headers
curl -I http://localhost:3000
```

## ECRR Requirements
- [ ] **Examine** — Capture current COOP/COEP state
- [ ] **Clean** — Fix any asset header issues
- [ ] **Report** — Generate ECRR report with compatibility data
- [ ] **Role** — Declare Cursor Agent as implementor

## Labels
`bug`, `firefox`, `cross-origin-isolation`, `testing`, `cursor-agent`

## Milestone
Offline Isolation v1

## Assignee
@cursor-agent
```

---

## T5 — A11y Smoke: Live Regions & Reduced Motion

```markdown
# T5: A11y Smoke: Live Regions & Reduced Motion

## Priority
🟡 **Medium** - Priority 6

## Goal
Lock in WCAG baselines for dynamic feedback.

## Scope
- Add quick a11y smokes ensuring `aria-live="polite"` on key result lines (prosody verdicts, in-band meter), and honoring `prefers-reduced-motion`
- Fix any gaps uncovered

## Acceptance Criteria
- [ ] Playwright a11y checks pass; visual motion disabled under reduced-motion; no inline styles; docs updated in QA checklist
- [ ] Screen reader compatibility verified with NVDA/JAWS
- [ ] Keyboard navigation covers all interactive elements
- [ ] ECRR report with accessibility audit results

## Files to Touch
- `tests/e2e/accessibility.spec.ts`
- `src/components/PracticeHUD.tsx` (ARIA improvements)
- `app/ui.css` (reduced-motion utilities)
- `docs/ACCESSIBILITY_CHECKLIST.md`

## Testing Commands
```bash
# Run accessibility tests
pnpm test:e2e --grep "accessibility"

# Test with screen reader
# (Manual testing with NVDA/JAWS)
```

## ECRR Requirements
- [ ] **Examine** — Capture current a11y state
- [ ] **Clean** — Fix any a11y gaps found
- [ ] **Report** — Generate ECRR report with audit results
- [ ] **Role** — Declare Cursor Agent as implementor

## Labels
`enhancement`, `accessibility`, `wcag`, `testing`, `cursor-agent`

## Milestone
A11y Polish v1

## Assignee
@cursor-agent
```

---

## 📋 **Usage Instructions**

1. **Copy each issue body** above
2. **Paste into GitHub** → New Issue
3. **Add labels** and **assign to milestone**
4. **Assign to @cursor-agent** (or your preferred assignee)
5. **Start with T1** for highest impact

## 🎯 **Ready to Deploy**

These issue bodies are:
- ✅ **Copy-pasteable** into GitHub
- ✅ **Structured** with clear acceptance criteria
- ✅ **ECRR-compliant** with required methodology
- ✅ **Test-ready** with specific commands
- ✅ **Labeled** for easy project management

Just copy, paste, and start shipping! 🚀
