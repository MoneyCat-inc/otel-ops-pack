# 📑 **Resonai — Full Project ECRR Report**

**Date:** September 2025  
**Scope:** Entire Resonai voice-feminisation trainer project (M1 → M2)  
**Framework:** **ECRR** — *Examine • Clean • Report • Role*

---

## **E — Examine (Current State)**

### Product & Features

* **Instant Practice** (/try): one-tap mic, real-time pitch visualization, permission primer, A/B tests.
* **Practice FSM**: warm-up → reflection loop, IndexedDB session storage.
* **Prosody drills**: end-rise vs end-fall classification, expressiveness meter.
* **HUD & calibration**: 3-step mic calibration, real-time metrics at 60fps.
* **Redeployed site**: polished UI, working nav (Home/Listen/Practice/About), PWA setup.

### Technical Architecture

* **Frontend**: Next.js 14 App Router, React 18, TailwindCSS, Radix UI.
* **Audio engine**: Firefox-optimised mic capture (EC/NS/AGC off), AudioWorklets, CREPE-tiny ONNX pitch tracker + YIN fallback.
* **Data & persistence**: IndexedDB (Dexie.js), local-first storage, JSON session schema.
* **Deployment**: Vercel CI/CD pipeline, GitHub Actions with Playwright tests.
* **Security**: Strict CSP, COOP/COEP headers for cross-origin isolation.

### UX & Curriculum

* Affirming design (no gendered pass/fail, progress over time).
* Flow-based curriculum: breathing → pitch → resonance → prosody → flow.
* Inclusive onboarding, coach-tone microcopy, streaks and affirmations planned.

### Governance & Workflow

* Multi-agent system:

  * **You**: project lead, vision/approval
  * **ChatGPT Agent**: research, specs, orchestration
  * **Cursor Agent**: scoped implementation
  * **Codex Agent**: CI/CD, CSP guardrails, merges
  * **codex-local**: local dev ergonomics, .agent watchdog

---

## **C — Clean (Issues Addressed & Remaining Risks)**

### Addressed

* Fixed raw-text site → polished, production-ready UI.
* Replaced ScriptProcessorNode with AudioWorklet for low latency.
* Added IndexedDB persistence, PWA offline mode.
* Hardened CI/CD: Windows PR + nightly runs, fake mic tests.
* Privacy & accessibility baked in: local-first, ARIA/live regions, reduced motion.

### Remaining Risks

* **Offline isolation**: COOP/COEP persistence via Service Worker must be verified.
* **Formant tracking**: LPC resonance buckets unstable; fallback vowel-classifier may be needed.
* **Device variability**: Bluetooth mic sample-rate drift, re-init logic required.
* **Mobile performance**: Not yet proven on mid-tier Android.
* **Fairness of feedback**: DTW thresholds + expressiveness caps must avoid discouragement.
* **Community features**: Sharing/moderation roadmap pending.

---

## **R — Report (Findings & Evidence)**

### Strengths

* Local-first privacy architecture; no audio leaves device.
* Affirming UX, non-judgmental metrics.
* Production-ready deployment (Vercel, CI/CD, tests).
* Strong observability: analytics events, cohort gating, rollback safety.
* Multi-agent governance keeps delivery consistent and auditable.

### Weaknesses

* Early versions lacked CSS/JS, caused trust issues.
* Current resonance tracking unstable across environments.
* Feedback metrics can be gamed or demoralizing if not tuned.
* Mobile validation incomplete.

### Recommendations

* Run Playwright smokes for offline isolation, coach throttling, accessibility.
* Expose prosody thresholds in HUD for transparency.
* Clamp expressiveness impact on visuals to prevent gaming.
* Calibrate loudness/DTW thresholds with cohort testing.
* Add community guardrails before scaling social features.

---

## **R — Role (Actor Declarations)**

* **You (Project Lead)**: Vision, approvals, unblock external auth.
* **ChatGPT Agent**: Orchestrator, specs, acceptance criteria, SSOT governance.
* **Cursor Agent**: Code implementer, PRs under guardrails.
* **Codex Agent**: Coordinator for CI/CD, merges, repo hygiene.
* **codex-local**: Local dev ops (pnpm scripts, watchdog, guardrails).
* **QA Scribe & others**: Validation, trace/video evidence, governance logs.

Together, this ecosystem enforces **Plan → Build → Validate → Record → Repeat**, ensuring no repeated work and continuous improvement.

---

# ✅ **Verdict**

**Resonai is production-ready for a controlled beta cohort.**

* Core flows are stable, affirming, and private.
* Governance is strong and artifact-driven.
* Before broad release: validate offline isolation, mobile performance, and fairness of feedback.

With those checks complete, Resonai can safely scale toward its north-star: an affirming, local-first, adaptive voice training studio.