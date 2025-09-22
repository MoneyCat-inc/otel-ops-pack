# Resonai - ECRR Project Report

## E - Examine (Current State)

- Core product: a local-first voice feminization trainer built with Next.js 14, React 18, TypeScript, Tailwind, and AudioWorklets.
- Delivered milestones:
   - M1: safe warm-up FSM, IndexedDB session logging.
   - M2: prosody drills, expressiveness metric, coaching copy.
   - Instant Practice: /try flow with one-tap mic, analytics, A/B testing, pilot gating.
- Audio engine: Firefox-optimized low-latency capture using CREPE-tiny ONNX with YIN fallback.
- Practice flows: JSON-defined daily practices (onboarding -> warm-up -> glide -> phrase -> reflection).
- Deployment: Vercel with strict CSP, COOP, and COEP headers.
- System context: D-MONOLITH (Ryzen 3900X, RTX 2080 Super, 32 GB RAM, Windows 11 Pro).
- Governance: multi-agent workflow (ChatGPT orchestrator, Codex for CI/security, Cursor for implementation, BossCat for upkeep).
- Audit status: independent review marks project production-ready for controlled beta; residual risks in offline isolation, mobile stability, feedback fairness.

## C - Clean (Risks and Gaps)

- Isolation: Service Worker must preserve COOP and COEP headers for offline use.
- Resonance and formants: LPC tracking unstable; vowel classifier fallback may be required.
- Device variability: Bluetooth microphones at 16 kHz cause drift; need auto-reinit.
- Mobile coverage: mid-tier Android latency and stability remain unvalidated.
- Loudness guardrails: current >=5 s @ 0.8 RMS threshold may mis-trigger; cohort calibration needed.
- Expressiveness metric: can be gamed with exaggerated swoops; apply caps.
- UI and accessibility: reduced motion and neuro-inclusive copy variants not fully systematized.
- Community layer: safe sharing and moderation flows outstanding.

## R - Report (Recommendations and Roadmap)

1. Audio and DSP
   - Harden LPC to F1 and F2 buckets or pivot to vowel classifier if instability persists.
   - Calibrate loudness heuristics with beta cohort of 8-12 users.
   - Expose prosody thresholds in HUD for transparent tuning.
2. Product flows
   - Add pitch band and resonance drills per roadmap.
   - Extend adaptive flow logic for gating, retries, and cooldowns.
   - Integrate Orb v2 visuals (resonance hue, shimmer trends).
3. Safety and privacy
   - Confirm offline isolation continuity via Playwright smoke tests.
   - Clamp expressiveness-to-Orb shimmer mapping to deter gaming.
   - Enforce local-first analytics: IndexedDB only, opt-in sharing.
4. Operations and cohort
   - Run controlled beta (30-50 participants) with coach and SLP sharing panel.
   - Instrument retention (>=35 percent at four weeks) and strain flag safety (<1 percent repeats).
   - Quarantine flaky tests and publish nightly SSOT via BossCat worker.
5. Community
   - Draft moderation policies modeled on safe trans voice forums.
   - Build peer feedback channels with explicit opt-in consent.

## R - Role (Ownership)

- You (Project Lead): set vision, approve scope, provide authorization.
- ChatGPT Agent (Orchestrator): plan, build, validate, and record; author prompts, specs, acceptance criteria.
- Cursor Agent (Implementer): build scoped UI features in Cursor IDE under guardrails.
- Codex (Coordinator): own CI, security posture, repository hygiene, merges.
- BossCat: background upkeep; refresh SSOT, quarantine flaky tests, fix accessibility and CSP drift.
- codex-local: maintain local developer ergonomics, pnpm scripts, devcontainers, environment parity, guardrails.

Verdict: Resonai is production-ready for controlled beta. Core flows, audio engine, and governance are strong; a targeted cohort test should validate safety thresholds and fairness ahead of broader expansion.
