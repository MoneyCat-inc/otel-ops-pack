# 🔐 Security Remediation Tracker - 30-Day Plan

**Start Date:** 2025-10-09 (Thursday)  
**Target Date:** 2025-11-08 (30 days)  
**BossCat Owner:** Gap-Closer 🩹  
**Status:** ✅ Plan Active

---

## 🎯 Baseline & Goal

**Baseline (2025-10-09):**
- Total: 33 vulnerabilities (4 CRITICAL, 29 HIGH)
- By Image:
  - SigNoz: 2 (0 CRIT, 2 HIGH) ✅
  - OTel Collector: 12 (1 CRIT, 11 HIGH)
  - ClickHouse: 0 (0 CRIT, 0 HIGH) 🎉
  - Zookeeper: 19 (3 CRIT, 16 HIGH)

**30-Day Goal:**
- Total: <15 vulnerabilities (target: 55% reduction)
- CRITICAL: 0 (must eliminate all)
- HIGH: <15 (acceptable residual)

**Progress Tracking:** Monthly Trivy scans

---

## 📅 Remediation Phases

### Week 1 (Oct 9-16): Quick Wins ⚡

**Target:** Reduce by 8-10 vulnerabilities

**Actions:**
1. **Update Zookeeper Java Dependencies**
   - Netty: 4.1.113.Final → 4.1.118.Final
   - Jetty: 9.4.56.v20240826 → 9.4.57.v20241219
   - **Impact:** -2 HIGH vulnerabilities
   - **Timeline:** 2-3 days
   - **Status:** ⏳ Pending

2. **Monitor for Debian 12.11+ Updates**
   - libxml2: 2.9.14+dfsg-1.3~deb12u2 → u3 (fixes 2 CRITICAL)
   - glibc: 2.36-9+deb12u10 → u11 (fixes 1 HIGH)
   - perl: 5.36.0-7+deb12u2 → u3 (fixes 1 HIGH)
   - libxslt: 1.1.35-1+deb12u1 → u2 (fixes 1 HIGH)
   - **Impact:** -5 to -7 vulnerabilities (2 CRITICAL, 3-5 HIGH)
   - **Timeline:** When Bitnami/SigNoz rebuild images
   - **Status:** ⏳ Monitoring

**Expected Week 1 Result:** 33 → 23-25 vulnerabilities

---

### Week 2 (Oct 16-23): Base Image Updates 🔄

**Target:** Reduce by 10-15 vulnerabilities

**Actions:**
1. **Check SigNoz Releases**
   - Current: v0.96.1
   - Monitor: v0.96.2, v0.97.0
   - Look for: Alpine 3.20.4+ base (OpenSSL fix)
   - **Impact:** -2 vulnerabilities (SigNoz OpenSSL)
   - **Timeline:** Check releases weekly
   - **Status:** ⏳ Monitoring

2. **Check Bitnami Zookeeper Releases**
   - Current: 3.9.3 (Debian 12.11)
   - Monitor: 3.9.4+ with updated base
   - Look for: libxml2 u3, glibc u11, perl u3 included
   - **Impact:** -10 to -15 vulnerabilities
   - **Timeline:** Check releases weekly
   - **Status:** ⏳ Monitoring

3. **Apply Updates When Available**
   - Update docker-compose-signoz.yml
   - Pull new images
   - Test in staging (if available)
   - Recreate containers
   - Re-scan with Trivy
   - **Status:** ⏳ Pending vendor releases

**Expected Week 2 Result:** 23-25 → 10-15 vulnerabilities

---

### Week 3-4 (Oct 23-Nov 8): Final Push 🎯

**Target:** Reduce to <15 total, 0 CRITICAL

**Actions:**
1. **Address Remaining High-Severity Items**
   - linux-pam CVE-2025-6020 (no fix yet - accept or mitigate)
   - libldap CVE-2023-2953 (no fix yet - accept or mitigate)
   - gnutls (if not fixed in base update)
   - **Impact:** Variable
   - **Status:** ⏳ Assess after Week 1-2

2. **Re-scan and Verify**
   - Run complete Trivy scan
   - Document improvement
   - Update tests.json
   - **Timeline:** End of Week 4
   - **Status:** ⏳ Scheduled

3. **Generate Final Report**
   - ECRR report with before/after
   - Vulnerability reduction metrics
   - Remaining items with risk assessment
   - **Timeline:** Nov 8 (30-day mark)
   - **Status:** ⏳ Scheduled

**Expected Week 4 Result:** <15 vulnerabilities, 0 CRITICAL

---

## 📊 Tracking Metrics

### Weekly Scan Schedule

| Week | Scan Date | Total | CRITICAL | HIGH | Change | Notes |
|------|-----------|-------|----------|------|--------|-------|
| **Baseline** | Oct 9 | 33 | 4 | 29 | - | Initial scan |
| Week 1 | Oct 16 | TBD | TBD | TBD | TBD | Java deps update |
| Week 2 | Oct 23 | TBD | TBD | TBD | TBD | Base image updates |
| Week 3 | Oct 30 | TBD | TBD | TBD | TBD | Progress check |
| **Week 4** | **Nov 6** | **TBD** | **0** | **<15** | **TBD** | **Goal target** |

---

### Progress Indicators

**✅ Success Criteria:**
- CRITICAL: 4 → 0 (100% elimination)
- HIGH: 29 → <15 (≥48% reduction)
- Total: 33 → <15 (≥55% reduction)

**🎯 Milestones:**
- **25% reduction:** 33 → 25 (Week 1 target)
- **50% reduction:** 33 → 16-17 (Week 2 target)
- **55%+ reduction:** 33 → <15 (Week 4 goal)

---

## 🔧 Remediation Actions Detail

### Action 1: Zookeeper Java Dependencies

**CVEs Addressed:**
- CVE-2025-24970 (Netty - SSL validation issue)
- CVE-2024-13009 (Jetty - Gzip buffer corruption)

**Steps:**
1. Research Zookeeper image customization
2. Create custom Dockerfile with updated deps OR
3. Wait for Bitnami official update
4. Test updated image
5. Update docker-compose
6. Re-scan

**Timeline:** 2-7 days (depending on approach)

---

### Action 2: Debian Package Updates

**CVEs Addressed:**
- CVE-2025-49794, CVE-2025-49796 (libxml2) - 2 CRITICAL
- CVE-2025-4802 (glibc) - 1 HIGH
- CVE-2023-31484 (perl) - 1 HIGH
- CVE-2025-7424 (libxslt) - 1 HIGH

**Dependencies:**
- Requires: Debian 12.11+ base image with u3 patches
- Controlled by: SigNoz, Bitnami (upstream vendors)
- Timeline: When vendors rebuild images
- **Status:** External dependency

**Monitoring:**
- Check SigNoz releases weekly
- Check Bitnami Zookeeper releases weekly
- Subscribe to Debian security announcements

---

### Action 3: Risk Acceptance (No Fix Available)

**CVEs to Accept:**
- CVE-2023-45853 (zlib) - CRITICAL - "will_not_fix" status
- CVE-2025-6020 (linux-pam) - HIGH - "affected" status
- CVE-2023-2953 (libldap) - HIGH - "affected" status
- CVE-2025-7425 (libxslt) - HIGH - "affected" status

**Rationale:**
- No fixes available from Debian maintainers
- Functions not used in typical application paths
- Compensating controls in place
- Network isolation limits exposure

**Compensating Controls:**
- Localhost-only access (no internet exposure)
- Network segmentation (Docker isolation)
- Enhanced monitoring (DoS detection)
- Regular re-scanning (monthly Trivy)

**Timeline:** Ongoing monitoring, re-assess quarterly

---

## 📈 Expected Improvement Curve

```
Vulnerabilities
    |
 35 |●  Baseline (33)
    |
 30 |
    |
 25 |  ○  Week 1 target (25)
    |
 20 |
    |
 15 |___●___Week 2 target (15) ← GOAL LINE
    |
 10 |      ○  Week 4 actual (10-12 projected)
    |
  5 |
    |
  0 |________○________Aspirational (long-term)
    └─────────────────────────────────────>
      W0   W1   W2   W3   W4   Time
```

---

## 🔔 Monitoring & Alerts

### Monthly Scan Automation

**Script:** `scripts/monthly-trivy-scan.ps1`  
**Usage:**
```powershell
# Manual scan
pwsh -File scripts\monthly-trivy-scan.ps1

# With export
pwsh -File scripts\monthly-trivy-scan.ps1 -ExportReport
```

**NPM Scripts:**
```bash
pnpm security:scan         # Run scan with console output
pnpm security:scan:export  # Export to artifacts/security-scans/
```

**GitHub Actions:** `.github/workflows/trivy-security-scan.yml`
- Triggers: PR, push to main, monthly (1st at 02:00 UTC), manual
- Uploads: SARIF to GitHub Security tab
- Reports: Summary in Actions output

---

### Alert Thresholds

**Immediate Action Required:**
- New CRITICAL vulnerability detected
- Total CRITICAL increases
- Critical data store (ClickHouse) no longer clean

**Weekly Review Required:**
- Total vulnerabilities increases by >5
- HIGH count increases significantly
- Fixes available for existing CVEs

**Monthly Review:**
- Progress vs 30-day goal
- Vendor update availability
- Risk assessment refresh

---

## 📞 Stakeholder Communication

### Weekly Updates (Every Monday)

**Template:**
```markdown
Subject: Security Remediation Progress - Week N

Current Status:
- Total: X vulnerabilities (Y CRITICAL, Z HIGH)
- Change: ±N from baseline
- Progress: N% toward 30-day goal

This Week:
- [Actions taken]
- [Vendor updates applied]
- [Remaining work]

Next Week:
- [Planned actions]
- [Expected improvement]
```

---

### 30-Day Final Report (Nov 8)

**Template:**
```markdown
Subject: 30-Day Security Remediation - Final Results

Starting Point (Oct 9):
- Total: 33 vulnerabilities (4 CRITICAL, 29 HIGH)

Ending Point (Nov 8):
- Total: X vulnerabilities (Y CRITICAL, Z HIGH)
- Reduction: N vulnerabilities (M% improvement)

Goal Achievement:
- Target: <15 total, 0 CRITICAL
- Actual: [ACHIEVED / PARTIALLY ACHIEVED / MISSED]

Next Steps:
- [Ongoing monitoring]
- [Future remediation plans]
```

---

## ✅ Quick Reference

### Commands

```powershell
# Monthly security scan
pnpm security:scan

# Export scan report
pnpm security:scan:export

# Check specific image
trivy image --severity CRITICAL,HIGH signoz/signoz:v0.96.1

# Scan all and save
trivy image signoz/signoz:v0.96.1 --format json > scan.json
```

### Files

- **Scan Script:** `scripts/monthly-trivy-scan.ps1`
- **CI Workflow:** `.github/workflows/trivy-security-scan.yml`
- **Tracker:** `docs/BossCat/REMEDIATION_TRACKER_2025-10-09.md` (this doc)
- **Scan Reports:** `artifacts/security-scans/`

---

## 🎯 Success Criteria

**Required for 30-Day Success:**
- [ ] 0 CRITICAL vulnerabilities (down from 4)
- [ ] <15 total vulnerabilities (down from 33)
- [ ] ClickHouse remains clean (maintain 0)
- [ ] SigNoz <5 vulnerabilities (currently 2)
- [ ] Monthly scan automation active
- [ ] Trivy CI integration complete

**Bonus Goals:**
- [ ] <10 total vulnerabilities (67% reduction)
- [ ] All HIGH vulnerabilities addressed
- [ ] Automated remediation pipeline
- [ ] Dashboard visualization

---

**Tracker Created:** 2025-10-09  
**BossCat OEM:** Remediation plan active, monitoring automated  
**Next Scan:** 2025-10-16 (7 days)

🐾 **Tracking vulnerability remediation progress - monthly laps begin!**

