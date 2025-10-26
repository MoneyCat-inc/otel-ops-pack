# 🚨 Audio Canary Incident Report

**Gate:** #020 (Audio Canary & Rollout)  
**Date:** YYYY-MM-DD HH:MM:SS UTC  
**Reporter:** [Name/Role]  
**Severity:** [HIGH/MEDIUM/LOW]

---

## 📋 Incident Summary

**Canary Phase:** [INIT / RAMP_10 / RAMP_50 / RAMP_100 / COMPLETE]  
**Target Percentage:** [0% / 10% / 50% / 100%]  
**Breach Type:** [Underrun / Jitter / Correlation / Other]  
**Auto-Halt:** [YES / NO]

**One-Line Summary:**  
[Brief description of what went wrong]

---

## 📊 KPIs at Breach

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| **Underrun Ratio** | X.XX% | <0.5% | [PASS/FAIL] |
| **Tick Jitter (max)** | X.XX ms | ≤8 ms | [PASS/FAIL] |
| **Correlation (r)** | 0.XXXX | ≥0.78 | [PASS/FAIL] |

---

## 🕐 Timeline

**Canary Start:** YYYY-MM-DD HH:MM:SS UTC  
**Breach Detected:** YYYY-MM-DD HH:MM:SS UTC  
**Auto-Halt Triggered:** YYYY-MM-DD HH:MM:SS UTC  
**Rollback Completed:** YYYY-MM-DD HH:MM:SS UTC  
**Total Duration:** X minutes

---

## 🔍 Breach Details

**Phase When Breach Occurred:** [Phase name]  
**Elapsed in Phase:** X minutes / Y minutes planned

**KPI That Breached:**  
[Describe which metric exceeded threshold and by how much]

**Observed Behavior:**  
[What was happening when breach detected - logs, symptoms, user reports]

---

## 🔧 Rollback Actions Taken

**1. Automatic Actions:**
- [ ] Auto-halt triggered by canary state machine
- [ ] AUDIO_ENABLED flag set to false
- [ ] OTLP span emitted (audio.enable.canary with breach attributes)

**2. Manual Actions:**
- [ ] Executed `pwsh -File scripts\rollback-audio.ps1`
- [ ] Verified pm-engine container restarted
- [ ] Confirmed `/health` shows `audio_enabled: false`
- [ ] Tested `POST /audio` returns HTTP 503

**3. Verification:**
- [ ] Audio ingestion blocked (HTTP 503)
- [ ] No audio flowing to visualization
- [ ] Container stable
- [ ] No residual errors

---

## 📈 Impact Assessment

**Users Affected:** [Number/percentage if known]  
**Duration of Issue:** X minutes  
**Data Loss:** [YES/NO - describe if yes]  
**Service Degradation:** [NONE / PARTIAL / FULL]

---

## 🔎 Root Cause Analysis

**Preliminary Assessment:**  
[Initial thoughts on what caused the breach]

**Contributing Factors:**
- [Factor 1]
- [Factor 2]

**Requires Further Investigation:**
- [ ] [Item 1]
- [ ] [Item 2]

---

## ✅ Resolution

**Status:** [RESOLVED / INVESTIGATING / MONITORING]

**Actions to Prevent Recurrence:**
1. [Action 1]
2. [Action 2]

**Follow-Up Required:**
- [ ] Adjust KPI thresholds
- [ ] Fix identified issue
- [ ] Re-run canary with modifications
- [ ] Update documentation

---

## 📂 Evidence

**OTLP Span ID:** [Trace ID from SigNoz]  
**Logs:** [Link to relevant logs]  
**Screenshots:** [Attach dashboard, metrics, etc.]  
**Rollback Verification:** [Confirmation that rollback succeeded]

---

**Incident Closed:** [YES/NO]  
**Closed By:** [Name]  
**Closed Date:** YYYY-MM-DD HH:MM:SS UTC

---

🐾 *Canary incident documented. Follow ECRR methodology for post-incident analysis.*

