# 🎯 Resonai Beta Stabilization Roadmap (2025)

> ## ARCHIVED — snapshot of 2025-10, not current status
>
> Pre-Pack-3B-split Resonai-era document; describes systems retired by Roadmap 2026 H2
> (`docs/BossCat/ROADMAP_2026H2.md`, all phases closed 2026-08-14). Current authority:
> `docs/PURPOSE.md`. Bannered in place 2026-08-25 (audit follow-up); not maintained.

## Executive Summary

Resonai is **beta-ready** with core flows, audio engine, and governance systems operational. This roadmap focuses on **calibration, validation, and safety** to prepare for controlled public beta expansion.

**Current Status**: Production-ready for controlled beta (8-12 users)  
**Target**: Public beta launch (100+ users) by Q2 2025  
**Key Focus**: Resonance stability, fairness calibration, mobile validation, community safety

---

## 🗓️ 6-Month Milestone Structure

### **Phase 1: Core Stabilization** (Weeks 1-8)
*Focus: Audio engine reliability, safety calibration, offline hardening*

### **Phase 2: Mobile & Accessibility** (Weeks 9-16) 
*Focus: Cross-platform validation, WCAG compliance, performance optimization*

### **Phase 3: Community & Safety** (Weeks 17-24)
*Focus: Moderation systems, peer feedback, coach portal MVP*

---

## 📋 Detailed Milestone Breakdown

## **MILESTONE 1: Resonance & Audio Stability** 
*Timeline: Weeks 1-4 | Priority: CRITICAL*

### 🎯 Objectives
- Stabilize formant tracking across devices
- Calibrate loudness guardrails with real user data
- Implement vowel classifier fallback for mobile

### 📊 Acceptance Criteria
- [ ] **Resonance Stability**: <5% false positives on vowel classification across 10+ devices
- [ ] **Loudness Calibration**: Cohort-tested thresholds (8-12 users) with <2% false triggers
- [ ] **Mobile Audio**: <140ms latency on mid-tier Android devices
- [ ] **Device Compatibility**: Auto-reinit for Bluetooth mic sample rate drift

### 🔧 Technical Tasks
1. **Prototype CNN vowel classifier** (WASM fallback for LPC instability)
2. **Implement circular buffer** for audio samples with adaptive sizing
3. **Add device detection** and auto-reinit for sample rate mismatches
4. **Calibrate loudness thresholds** with beta cohort data
5. **Expose prosody settings** in Practice HUD for transparency

### 📈 Success Metrics
- Audio processing latency: <140ms p95
- Resonance accuracy: >95% on test corpus
- Device compatibility: 100% on Chrome/Firefox desktop, 90% mobile

---

## **MILESTONE 2: Safety & Fairness Calibration**
*Timeline: Weeks 5-8 | Priority: CRITICAL*

### 🎯 Objectives
- Validate feedback fairness with diverse user cohort
- Implement fatigue detection and prevention
- Add transparency controls for user agency

### 📊 Acceptance Criteria
- [ ] **Fairness Study**: DTW thresholds calibrated to be encouraging, not discouraging
- [ ] **Fatigue Detection**: Jitter/shimmer tracking with usage limits
- [ ] **Transparency**: All thresholds visible and adjustable in HUD
- [ ] **Safety Rails**: <1% strain flag repeats in cohort testing

### 🔧 Technical Tasks
1. **Run cohort fairness study** (8-12 users, 2-week duration)
2. **Implement fatigue heuristics** (vocal load tracking, jitter analysis)
3. **Add threshold controls** to Practice HUD
4. **Create usage limits** with progressive warnings
5. **Validate safety metrics** with SLP consultation

### 📈 Success Metrics
- User satisfaction: >4.0/5.0 on feedback fairness
- Safety incidents: 0 strain flags in final week
- Retention: >80% completion rate in cohort

---

## **MILESTONE 3: Offline & Cross-Origin Hardening**
*Timeline: Weeks 9-12 | Priority: HIGH*

### 🎯 Objectives
- Ensure COOP/COEP headers persist offline
- Add comprehensive offline testing
- Implement service worker reliability

### 📊 Acceptance Criteria
- [ ] **Offline Isolation**: COOP/COEP headers maintained in service worker mode
- [ ] **Playwright Tests**: Offline isolation verification in CI
- [ ] **Service Worker**: Reliable offline functionality with proper caching
- [ ] **Security Audit**: Zero CSP violations in offline mode

### 🔧 Technical Tasks
1. **Implement offline COOP/COEP** persistence in service worker
2. **Add Playwright smoke tests** for offline isolation
3. **Create offline-first caching** strategy
4. **Security audit** of offline functionality
5. **Performance testing** of service worker overhead

### 📈 Success Metrics
- Offline functionality: 100% feature parity
- Security compliance: Zero CSP/COOP violations
- Performance impact: <5% overhead from service worker

---

## **MILESTONE 4: Mobile Performance & Accessibility**
*Timeline: Weeks 13-16 | Priority: HIGH*

### 🎯 Objectives
- Validate mobile performance on mid-tier Android
- Achieve WCAG 2.2 AA compliance
- Optimize touch interactions and responsive design

### 📊 Acceptance Criteria
- [ ] **Mobile Latency**: <140ms audio processing on mid-tier Android
- [ ] **WCAG Compliance**: 100% AA compliance across all flows
- [ ] **Touch Optimization**: 44px minimum touch targets, gesture support
- [ ] **Responsive Design**: Seamless experience across device sizes

### 🔧 Technical Tasks
1. **Mobile performance lab** setup with mid-tier Android devices
2. **WCAG 2.2 audit** and remediation across all components
3. **Touch target optimization** (44px minimum, gesture support)
4. **Responsive breakpoint** testing and refinement
5. **Accessibility testing** with screen readers and assistive tech

### 📈 Success Metrics
- Mobile performance: <140ms latency, <5% frame drops
- Accessibility score: 100% WCAG AA compliance
- Touch usability: >95% success rate on gesture tests

---

## **MILESTONE 5: Engagement & Retention Systems**
*Timeline: Weeks 17-20 | Priority: MEDIUM*

### 🎯 Objectives
- Implement streak mechanics and achievement system
- Add narrative practice scenarios
- Create progress visualization and analytics

### 📊 Acceptance Criteria
- [ ] **Streak System**: Daily practice tracking with encouraging feedback
- [ ] **Achievement Badges**: Unlockable milestones with affirming copy
- [ ] **Narrative Scenarios**: Story-driven practice sessions
- [ ] **Progress Analytics**: Clear visualization of improvement over time

### 🔧 Technical Tasks
1. **Design streak mechanics** with encouraging copy and reduced-motion support
2. **Implement achievement system** with ARIA-compliant notifications
3. **Create narrative practice** scenarios with branching storylines
4. **Build progress dashboard** with privacy-preserving analytics
5. **Add social sharing** (opt-in) with privacy controls

### 📈 Success Metrics
- Engagement: >35% 4-week retention rate
- Daily active users: >60% of registered users
- Achievement completion: >80% of users earn first badge

---

## **MILESTONE 6: Community & Moderation Foundation**
*Timeline: Weeks 21-24 | Priority: MEDIUM*

### 🎯 Objectives
- Design safe community sharing system
- Implement moderation policies and tools
- Create coach/SLP portal MVP

### 📊 Acceptance Criteria
- [ ] **Moderation System**: Automated content filtering with human review
- [ ] **Safe Sharing**: Opt-in voice clip sharing with privacy controls
- [ ] **Coach Portal**: SLP dashboard for progress monitoring
- [ ] **Community Guidelines**: Clear policies modeled on safe trans forums

### 🔧 Technical Tasks
1. **Draft community guidelines** based on safe trans voice forums
2. **Implement content moderation** with automated filtering
3. **Create coach portal MVP** with progress sharing (opt-in)
4. **Build safe sharing system** with granular privacy controls
5. **Design peer feedback** channels with consent management

### 📈 Success Metrics
- Community safety: 0 harassment incidents
- Coach adoption: >50% of SLPs use portal features
- Sharing engagement: >20% opt-in rate for safe sharing

---

## 🚀 Sprint Structure (2-Week Sprints)

### **Sprint 1-2: Audio Engine Hardening**
- Week 1: CNN vowel classifier prototype, device detection
- Week 2: Circular buffer implementation, mobile optimization

### **Sprint 3-4: Safety Calibration**
- Week 3: Cohort fairness study launch, fatigue detection
- Week 4: Threshold controls, safety validation

### **Sprint 5-6: Offline Hardening**
- Week 5: Service worker COOP/COEP, offline testing
- Week 6: Playwright CI integration, security audit

### **Sprint 7-8: Mobile & Accessibility**
- Week 7: Mobile performance lab, WCAG audit
- Week 8: Touch optimization, responsive design

### **Sprint 9-10: Engagement Systems**
- Week 9: Streak mechanics, achievement system
- Week 10: Narrative scenarios, progress analytics

### **Sprint 11-12: Community Foundation**
- Week 11: Moderation system, safe sharing
- Week 12: Coach portal MVP, community guidelines

---

## 📊 Risk Mitigation & Contingencies

### **High-Risk Items**
1. **Resonance Stability**: If LPC fails, pivot to CNN classifier (2-week delay)
2. **Mobile Performance**: If latency >140ms, optimize WASM or reduce features
3. **Fairness Calibration**: If thresholds discourage users, adjust algorithm (1-week delay)

### **Contingency Plans**
- **Audio Engine**: Maintain YIN fallback, add more robust formant tracking
- **Mobile Issues**: Progressive enhancement, graceful degradation
- **Community Safety**: Conservative moderation, human review for all content

---

## 🎯 Success Criteria for Public Beta Launch

### **Technical Requirements**
- [ ] Audio latency <140ms on mid-tier Android
- [ ] 100% WCAG AA compliance
- [ ] Zero security vulnerabilities
- [ ] 99.9% uptime over 30 days

### **User Experience Requirements**
- [ ] >4.0/5.0 user satisfaction score
- [ ] >35% 4-week retention rate
- [ ] <1% safety incident rate
- [ ] >80% feature completion rate

### **Community Requirements**
- [ ] Moderation system operational
- [ ] Coach portal functional
- [ ] Community guidelines published
- [ ] Safe sharing system tested

---

## 📈 Monitoring & Metrics Dashboard

### **Real-Time Metrics**
- Audio processing latency (p50, p95, p99)
- User engagement (DAU, session duration)
- Safety incidents (strain flags, reports)
- Technical performance (error rates, uptime)

### **Weekly Reviews**
- Milestone progress against acceptance criteria
- Risk assessment and mitigation status
- User feedback analysis and action items
- Technical debt and optimization opportunities

### **Monthly Assessments**
- Overall roadmap progress and timeline adjustments
- Resource allocation and team capacity
- Market feedback and competitive analysis
- Strategic pivots and scope adjustments

---

## 🎭 Role Assignments

### **Project Lead (You)**
- Vision setting and priority approval
- Resource allocation and timeline management
- External stakeholder communication
- Final decision authority on scope changes

### **ChatGPT Agent (Orchestrator)**
- Milestone planning and specification
- Cross-team coordination and communication
- Risk assessment and mitigation planning
- Documentation and knowledge management

### **Cursor Agent (Implementer)**
- UI/UX implementation and accessibility
- Audio engine optimization and mobile support
- Performance tuning and optimization
- Feature development and testing

### **Codex Agent (Coordinator)**
- CI/CD pipeline maintenance and security
- Code quality and technical debt management
- Infrastructure and deployment automation
- Security audits and compliance

### **BossCat (Maintenance)**
- Background upkeep and SSOT maintenance
- Flaky test quarantine and resolution
- Documentation updates and artifact management
- Continuous monitoring and alerting

### **codex-local (Local Steward)**
- Developer environment and tooling
- Local testing and validation
- Guardrail enforcement and compliance
- Local development workflow optimization

---

## 🎯 Next Immediate Actions (This Week)

1. **Set up cohort testing infrastructure** for 8-12 beta users
2. **Create mobile performance lab** with mid-tier Android devices
3. **Begin CNN vowel classifier prototype** development
4. **Draft community guidelines** based on safe trans forums
5. **Implement Playwright offline testing** for COOP/COEP validation

---

*This roadmap provides a structured path from beta-ready to public launch, focusing on the critical areas of audio stability, user safety, and community foundation. Each milestone includes clear acceptance criteria, technical tasks, and success metrics to ensure measurable progress toward a successful public beta launch.*
