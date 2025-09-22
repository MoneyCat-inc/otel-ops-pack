# 📑 **Resonai — Full Project ECRR Report**

## **E — Examine (Current State)**

**Product**

* A **local-first voice feminization trainer**: low-latency pitch, resonance, and prosody feedback, running fully in-browser with IndexedDB persistence.
* **M1 → M2 delivered**:

  * M1: Warmup FSM, Reflection + Orbs, IndexedDB storage.
  * M2: Prosody drills, expressiveness metrics, Pitch Band prep.
* **Deployment**: Production app on Vercel with strict CSP/COOP/COEP, service worker caching, and PWA support.

**Architecture**

* Next.js 14 + React 18 + Tailwind CSS.
* AudioWorklets for real-time DSP (pitch via CREPE-tiny + YIN fallback, resonance via LPC prototype, loudness via RMS/tilt).
* IndexedDB schema for flows & sessions.
* Background worker (watchdog/runner) automating SSOT upkeep, flaky test quarantines, and artefact regeneration.

**User Experience & Curriculum**

* Flow-based progression: warmup → glide → phrase → reflection.
* Affirming UX: self-vs-self comparisons, no gendered scoring.
* Inclusive curriculum: pitch, resonance, prosody, articulation.
* Visual metaphors: vertical “voice thread”, orb shimmer, expressiveness meters.
* Accessibility: WCAG 2.2 AA, ARIA live regions, reduced-motion.

**Ops & Governance**

* CI/CD: GitHub Actions with Windows + nightly runs.
* Playwright + Vitest tests; 100% coverage on new features.
* Role structure:

  * **You**: Product lead.
  * **ChatGPT Agent**: Research + orchestration.
  * **Cursor Agent**: Scoped UI implementation.
  * **Codex Agent**: CI/CD, merges, CSP guardrails.
  * **codex-local**: Local workflow steward.
  * **BossCat**: Background guardian for repo health.

---

## **C — Clean (Risks & Gaps)**

1. **Offline COOP/COEP continuity** — must confirm Firefox keeps isolation via cached headers.
2. **Formant tracking** — LPC buckets unstable; fallback vowel-classifier required.
3. **Device variability** — Bluetooth sample rate changes (16kHz) can cause drift.
4. **Mobile stability** — Mid-tier Android not yet validated.
5. **Feedback fairness** — DTW thresholds and expressiveness scores risk discouragement/gaming.
6. **Community layer** — Sharing/moderation roadmap pending.
7. **Integration setup** — bootstrap scripts, env parity, and JSON logs could ease local agent integration.

---

## **R — Report (Audit Findings)**

* ✅ **Strengths**: Local-first privacy, accessible UX, affirming design, robust CI/CD, clear agent workflow, strong test culture.
* ⚠️ **Weaknesses**: Initial deployments lacked styling/isolation; fixed by M1/M2 hardening.
* 🔍 **Audit recommendations**:

  * Add Playwright smokes for offline isolation & accessibility.
  * Expose/tune prosody thresholds via HUD.
  * Clamp expressiveness to prevent gaming.
  * Calibrate loudness/DTW thresholds with real cohort.

---

## **R — Role (Agent Ecosystem)**

* **You (Product Lead)**: Vision, approvals, external auth.
* **ChatGPT Agent**: Specs, TASKS.md/DECISIONS.md upkeep, orchestration.
* **Cursor Agent**: Implements scoped UI features under guardrails.
* **Codex Agent**: Coordinator/merger; enforces CSP/CI/tests.
* **codex-local**: Maintains local workflows, pnpm/env parity, devcontainers.
* **BossCat**: Continuous repo guardian; runs background jobs, keeps SSOT/tests green.

Together, the loop is: **Plan → Build → Validate → Record → Repeat** with shared artefacts (TASKS.md, DECISIONS.md, SSOT, CI reports).

---

# ✅ **Summary**

The **Resonai project** has matured into a **production-ready, local-first trainer** with affirming UX, real-time DSP, and strong governance. The **next phase** should address **mobile/device stability, fairness calibration, and community features**, while maintaining the **agent loop** that ensures no work is repeated.
