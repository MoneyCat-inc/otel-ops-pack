# 📊 Resonai — ECRR Report

**Date:** September 21, 2025  
**Project:** Resonai — Local-first Voice Feminization Trainer  

[![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](ECRR_REPORT.md)
<sub>Manage badges: see <a href="../badges.md">docs/badges.md</a></sub>

---

## 🟣 Executive Summary

Resonai is a **browser-based, privacy-first trainer** that helps trans and nonbinary users practice voice feminization through **real-time, local-only feedback**.  

- **M1 delivered**: safe warm-up FSM, reflection orbs, IndexedDB session storage:contentReference[oaicite:0]{index=0}.  
- **M2 delivered**: prosody drills, expressiveness metrics, adaptive coaching, instant practice flow:contentReference[oaicite:1]{index=1}:contentReference[oaicite:2]{index=2}.  
- **Deployment**: Production-ready Next.js app with PWA, strict CSP, accessibility, and CI/CD on Vercel:contentReference[oaicite:3]{index=3}:contentReference[oaicite:4]{index=4}.  
- **Audit verdict**: **Cohort-ready beta** -- strong privacy, accessible UX, with minor risks to validate (offline isolation, fairness thresholds, mobile stability):contentReference[oaicite:5]{index=5}.  

---

## 🟢 Contributions

**Product & UX**
- Warmup FSM -> reflection -> IndexedDB persistence:contentReference[oaicite:6]{index=6}.  
- Instant Practice (/try): one-tap mic, real-time feedback, cohort gating, KPI dashboard:contentReference[oaicite:7]{index=7}:contentReference[oaicite:8]{index=8}.  
- Prosody slice: end-rise detection, expressiveness metric, coaching copy, HUD:contentReference[oaicite:9]{index=9}:contentReference[oaicite:10]{index=10}.  
- Inclusive UX & curriculum: co-designed flows, affirming copy, discreet notifications:contentReference[oaicite:11]{index=11}.  
- Design patterns for interactive phonetics: modular lessons, gamification, safe practice:contentReference[oaicite:12]{index=12}.  

**Engineering & Infrastructure**
- Audio pipeline: low-latency AudioWorklets, CREPE-tiny ONNX + YIN fallback:contentReference[oaicite:13]{index=13}.  
- Resonance tracking via LPC buckets; spectral tilt proxy for breathiness:contentReference[oaicite:14]{index=14}.  
- Local-first flow JSON schema + metrics (time-in-target, jitter, expressiveness):contentReference[oaicite:15]{index=15}.  
- Security: strict CSP, COOP/COEP headers, no inline styles:contentReference[oaicite:16]{index=16}:contentReference[oaicite:17]{index=17}.  
- Accessibility: ARIA live regions, WCAG 2.2 AA targets:contentReference[oaicite:18]{index=18}.  
- Background agent (codex-local, BossCat) to maintain SSOT, quarantine flakes, enforce guardrails:contentReference[oaicite:19]{index=19}:contentReference[oaicite:20]{index=20}.  

**Ops & Governance**
- Automated CI/CD pipelines (Playwright, Windows CI, nightly isolation checks):contentReference[oaicite:21]{index=21}:contentReference[oaicite:22]{index=22}.  
- Independent audit confirming readiness for beta:contentReference[oaicite:23]{index=23}.  
- Documentation: handoff reports, deployment reports, agent role reports:contentReference[oaicite:24]{index=24}:contentReference[oaicite:25]{index=25}:contentReference[oaicite:26]{index=26}.  

---

## 🟠 Risks

- **Offline isolation**: Firefox service workers must preserve COOP/COEP headers:contentReference[oaicite:27]{index=27}.  
- **Resonance buckets**: LPC formant estimates noisy; fallback classifier may be needed:contentReference[oaicite:28]{index=28}.  
- **Device variability**: Bluetooth mic resampling (16 kHz) can cause drift:contentReference[oaicite:29]{index=29}.  
- **Mobile performance**: Mid-tier Android stability not yet validated:contentReference[oaicite:30]{index=30}.  
- **Fairness**: DTW match thresholds and loudness guardrails risk discouraging learners if uncalibrated:contentReference[oaicite:31]{index=31}.  
- **Community features**: Sharing/moderation roadmap not fully defined:contentReference[oaicite:32]{index=32}.  

---

## 🟢 Readiness

**Status:** ✅ **Cohort-ready Beta**  
- **Architecture**: Local-first, IndexedDB, strict isolation:contentReference[oaicite:33]{index=33}.  
- **UX**: Affirming, accessible, responsive:contentReference[oaicite:34]{index=34}:contentReference[oaicite:35]{index=35}.  
- **Testing**: 100% unit coverage on new modules, deterministic E2E:contentReference[oaicite:36]{index=36}:contentReference[oaicite:37]{index=37}.  
- **Privacy**: All audio stays local; delete/export supported:contentReference[oaicite:38]{index=38}.  
- **Deployment**: Stable Vercel builds, CI/CD pipelines:contentReference[oaicite:39]{index=39}:contentReference[oaicite:40]{index=40}.  

**Next Steps**  
1. **Cohort calibration** (8-12 users) for DTW fairness & loudness thresholds:contentReference[oaicite:41]{index=41}.  
2. **Validate offline COOP/COEP** persistence in Firefox:contentReference[oaicite:42]{index=42}.  
3. **Mobile validation** on mid-tier Android devices:contentReference[oaicite:43]{index=43}.  
4. **Community roadmap** for consent-first sharing & moderation:contentReference[oaicite:44]{index=44}.  

---

✅ **Verdict:** Resonai is **safe, private, and pedagogically sound**. With targeted cohort testing, it is ready to scale from prototype -> beta -> broader release.
