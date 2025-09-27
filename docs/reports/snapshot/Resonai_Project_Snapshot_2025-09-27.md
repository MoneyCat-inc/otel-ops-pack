
# 📊 Resonai Project — Unified Snapshot (2025-09-27)

## 🎯 Mission & Goals
Resonai is a **local-first, privacy-preserving voice feminization trainer**. The vision is to provide affirming, accessible training through:
1. **Inclusive UX & Curriculum** — gender-affirming onboarding, adaptive lesson flows【47†source】.  
2. **Real-Time Audio Feedback** — pitch, resonance, prosody, expressiveness【49†source】【57†source】.  
3. **Local-First Architecture** — IndexedDB storage, no cloud uploads, strict CSP/COOP/COEP【55†source】【58†source】.  
4. **Production-Grade Reliability** — CI/CD guardrails, automated testing, agent maintenance【59†source】【66†source】.

---

## 🏗 System Architecture
- **Frontend**: Next.js 14, React 18, TailwindCSS, Radix UI【60†source】.  
- **Audio Processing**:  
  * Pitch — CREPE-tiny ONNX via WASM + YIN fallback【57†source】.  
  * Resonance — LPC / formant proxy + spectral centroid【49†source】.  
  * Prosody — rise/fall classifier + expressiveness metric【52†source】【53†source】.  
- **Persistence**: IndexedDB (Dexie) with flow/session JSON【58†source】.  
- **Security**: Strict CSP, cross-origin isolation in Firefox & Chrome【55†source】.  
- **Ops**: Vercel deployment, Playwright E2E, GitHub Actions CI, Windows PowerShell scripts【67†source】【61†source】.  
- **Host Machine**: Windows 11 Pro, Ryzen 3900X, RTX 2080 Super, 32 GB RAM【54†source】.  

---

## ✅ Current State
### Features Delivered
- **Instant Practice (/try)** with real-time pitch visualization【60†source】【61†source】.  
- **Prosody drills** with expressiveness scoring【52†source】【53†source】.  
- **Mic Calibration Flow** (device select, level check, environment)【72†source】【73†source】.  
- **Practice HUD** with metrics at 60 fps, <5% CPU【72†source】.  
- **Cohort-gated Pilot** with analytics dashboard【60†source】【61†source】.  
- **Offline Export/Delete** for privacy【58†source】.  

### Deployments
- **resonai-red.vercel.app**: functional navigation (Home, Practice, Listen, About), profile selector, privacy statements【63†source】.  
- Prior audits noted styling gaps & missing COOP/COEP, later fixed in redeployment【62†source】【64†source】.  

### Quality
- 100% unit + E2E coverage on new slices【52†source】【73†source】.  
- CI/CD pipeline green with nightly flake quarantine【70†source】.  
- Accessibility: ARIA live regions, keyboard focus, WCAG AA compliance【67†source】【72†source】.  

---

## 🤖 Roles & Agents
- **You (Project Lead)**: vision, priorities, orchestration【65†source】【70†source】.  
- **ChatGPT Agent (Orchestrator)**: plans, specs, governance, SSOT enforcement【70†source】.  
- **Codex Agent (Coordinator)**: security posture, CI/CD, repo hygiene【66†source】.  
- **Cursor Agent (Implementer)**: scoped UI/dev tasks inside Cursor IDE【66†source】.  
- **Codex-Local**: maintains local dev ergonomics, pnpm scripts, guardrails【71†source】.  
- **BossCat (Maintenance Worker)**: background jobs—SSOT refresh, flake quarantine【73†source】.  

---

## ⚠️ Risks & Gaps
- **Offline isolation**: service worker must preserve COOP/COEP【59†source】.  
- **Formant stability**: LPC resonance buckets unstable; may require CNN fallback【49†source】.  
- **Device variability**: Bluetooth mic sample-rate drift (16 kHz vs 48 kHz)【59†source】.  
- **Mobile performance**: mid-tier Android latency/accuracy not fully validated【50†source】.  
- **Feedback fairness**: DTW thresholds for intonation similarity must avoid discouragement【59†source】.  
- **Community features**: moderation, sharing policies still pending【49†source】.  

---

## 🚀 Next Steps
1. **Cohort Testing** — 8–12 users to calibrate thresholds (loudness guard, DTW fairness)【59†source】.  
2. **Resonance Stability** — spike CNN vowel classifier if LPC fails on phones【50†source】.  
3. **Mobile Benchmarks** — validate latency & accuracy on mid-tier Android【50†source】.  
4. **Community & Sharing** — design moderated peer feedback + consent toggles【49†source】.  
5. **SSOT Worker** — ensure Codex-Local & BossCat background agents keep artifacts in sync【69†source】【73†source】.  

---

# ✅ Status: Production-Ready (Controlled Beta Cohort)
Resonai is **ready for a controlled beta**, with core features (pitch, prosody, HUD, calibration) functioning, strong guardrails in place, and clear next steps for risk validation and expansion.
