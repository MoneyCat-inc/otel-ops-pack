# 📡 Vendor Release Monitoring Guide

**Purpose:** Track SigNoz, Bitnami, and Debian releases for security patches  
**Owner:** Gap-Closer 🩹  
**Frequency:** Weekly checks  
**Part of:** 30-day remediation plan

---

## 🎯 What We're Monitoring

### Critical Updates Needed

| Vendor | Component | Current | Watching For | CVEs Fixed |
|--------|-----------|---------|--------------|------------|
| **SigNoz** | signoz | v0.96.1 | v0.96.2+ | OpenSSL (2 HIGH) |
| **SigNoz** | otel-collector | v0.129.6 | v0.130.0+ | glibc, perl, gnutls |
| **Bitnami** | zookeeper | 3.9.3 | 3.9.4+ | libxml2 (2 CRIT), Java deps |
| **Debian** | Base packages | 12.10/12.11 | 12.12+ | System libraries |

---

## 🔗 Monitoring Sources

### SigNoz Releases

**GitHub Repository:**
- URL: https://github.com/SigNoz/signoz/releases
- Current: v0.96.1
- Watch for: v0.96.x patches, v0.97.0 major

**What to Look For:**
- Security fixes mentioned in changelog
- Alpine base image updates (3.20.3 → 3.20.4+)
- OpenSSL package updates (3.3.2 → 3.3.3)
- Dependency updates

**How to Check:**
```bash
# Visit releases page weekly
# Look for "security" keyword
# Check release notes for CVE mentions
# Compare version tags
```

**Action When Found:**
```bash
# Update docker-compose-signoz.yml
# Change: image: signoz/signoz:v0.96.1
# To: image: signoz/signoz:v0.96.2  # or latest

# Pull and recreate
docker-compose -f docker-compose-signoz.yml pull signoz
docker-compose -f docker-compose-signoz.yml up -d signoz

# Re-scan
trivy image signoz/signoz:v0.96.2
```

---

### Bitnami Zookeeper

**Docker Hub:**
- URL: https://hub.docker.com/r/bitnami/zookeeper/tags
- Current: 3.9.3 (via signoz/zookeeper:3.9.3)
- Watch for: 3.9.4+, updated Debian base

**What to Look For:**
- New tags with recent dates
- "security" in tag descriptions
- Debian 12.12+ base images
- Java dependency updates (Netty, Jetty)

**How to Check:**
```bash
# Visit Docker Hub tags page
# Sort by "Last pushed"
# Check tag details for base image version
# Look for changelog/release notes links
```

**Action When Found:**
```bash
# Update docker-compose
# Pull new image
docker pull signoz/zookeeper:3.9.4  # or latest tag

# Update docker-compose-signoz.yml
# Recreate container
docker-compose -f docker-compose-signoz.yml up -d signoz-zookeeper

# Re-scan
trivy image signoz/zookeeper:3.9.4
```

---

### Debian Security Advisories

**Debian Security Tracker:**
- URL: https://security-tracker.debian.org/tracker/
- Current: Debian 12 (Bookworm)
- Watch for: DSA announcements for libxml2, glibc, perl, gnutls

**Specific Packages to Monitor:**
- libxml2 (CVE-2025-49794, CVE-2025-49796) - CRITICAL
- zlib1g (CVE-2023-45853) - CRITICAL (will_not_fix)
- glibc (CVE-2025-4802) - HIGH
- perl (CVE-2023-31484) - HIGH
- libxslt (CVE-2025-7424, CVE-2025-7425) - HIGH

**How to Check:**
```bash
# Visit Debian Security Tracker
# Search for package name
# Check for Debian 12 (Bookworm) updates
# Look for DSA- or DLA- announcements
```

**Note:** Base OS updates only matter when vendors (SigNoz/Bitnami) rebuild their images with the new packages.

---

### ClickHouse Releases

**GitHub Repository:**
- URL: https://github.com/ClickHouse/ClickHouse/releases
- Current: 25.5.6
- Status: **CLEAN** (0 vulnerabilities)

**Monitoring:** LOW PRIORITY (currently perfect)

**Action:** Check quarterly, update only if:
- Security advisory issued
- New features needed
- Performance improvements

---

## 📅 Monitoring Schedule

### Weekly Checks (Every Monday)

**Tasks:**
1. Check SigNoz releases (5 min)
2. Check Bitnami Zookeeper tags (3 min)
3. Check Debian security tracker (5 min)
4. Document findings (2 min)

**Total Time:** 15 minutes/week

**Checklist:**
```markdown
- [ ] SigNoz releases checked
- [ ] Bitnami Zookeeper checked
- [ ] Debian security tracker checked
- [ ] Any updates available? (Y/N)
- [ ] Update applied? (Y/N/Pending)
- [ ] Re-scan completed? (Y/N/NA)
```

---

### Monthly Actions

**Tasks:**
1. Run full Trivy scan (`pnpm security:scan:export`)
2. Review progress vs baseline
3. Update stakeholders
4. Adjust remediation plan if needed

**Script:** `scripts/monthly-trivy-scan.ps1`

**Output:**
- Console summary (progress vs baseline)
- JSON reports (artifacts/security-scans/)
- Trend analysis

---

## 🔔 Alert Criteria

### Immediate Action Required

**Triggers:**
- New CRITICAL vulnerability in ClickHouse (currently 0)
- New CRITICAL vulnerability in SigNoz core
- Active exploit announced for any of our 33 CVEs
- Total CRITICAL increases beyond 4

**Action:**
1. Assess impact immediately
2. Apply emergency patches if available
3. Notify BossCat OEM
4. Update risk assessment

---

### Weekly Review Required

**Triggers:**
- Total vulnerabilities increase by >5
- New HIGH vulnerabilities appear
- Fixes available for existing CRITICAL CVEs

**Action:**
1. Review changelog/advisory
2. Test fixes if available
3. Schedule update deployment
4. Document in weekly report

---

## 📊 Tracking Template

### Weekly Monitoring Log

```markdown
## Week N Monitoring (YYYY-MM-DD)

### SigNoz Releases
- Latest version: vX.Y.Z
- Security updates: [Yes/No]
- Action taken: [Applied/Pending/NA]

### Bitnami Zookeeper
- Latest tag: X.Y.Z-debian-12-rXX
- Base image: Debian 12.XX
- Action taken: [Applied/Pending/NA]

### Debian Security
- New DSAs: [List or None]
- Affected packages: [List or None]
- Vendor updates: [Available/Pending]

### Scan Results
- Total vulns: XX (Baseline: 33)
- CRITICAL: X (Baseline: 4)
- HIGH: XX (Baseline: 29)
- Progress: ±X vulnerabilities (±Y%)

### Next Actions
- [ ] Action 1
- [ ] Action 2
```

---

## 🎯 Success Indicators

### Weekly Milestones

**Week 1 (Oct 16):**
- Target: 25 vulnerabilities (-8 from baseline)
- Focus: Java dependency updates

**Week 2 (Oct 23):**
- Target: 15-20 vulnerabilities (-50% from baseline)
- Focus: Base image updates

**Week 3 (Oct 30):**
- Target: <15 vulnerabilities (goal achieved)
- Focus: Residual risk acceptance

**Week 4 (Nov 6):**
- Target: Maintain <15, 0 CRITICAL
- Focus: Final report and documentation

---

## 📂 File Locations

**Monitoring Logs:** `docs/BossCat/monitoring-logs/`  
**Scan Reports:** `artifacts/security-scans/`  
**Progress Reports:** `docs/BossCat/REMEDIATION_TRACKER_2025-10-09.md`  
**Stakeholder Updates:** `docs/BossCat/weekly-security-updates/`

---

## 🔧 Quick Reference Commands

```powershell
# Run monthly scan
pnpm security:scan

# Export detailed reports
pnpm security:scan:export

# Check specific image
trivy image signoz/signoz:v0.96.1

# Pull latest images (when updates available)
docker-compose -f docker-compose-signoz.yml pull

# Recreate with new images
docker-compose -f docker-compose-signoz.yml up -d --force-recreate

# Verify health after update
pwsh -File scripts\quick-monitor.ps1
```

---

## ✅ Monitoring Setup Complete

**Deliverables:**
- ✅ Vendor monitoring guide (this document)
- ✅ Weekly checklist template
- ✅ Alert criteria defined
- ✅ Quick reference commands

**Status:** Ready for weekly execution starting Oct 16

---

**Created:** 2025-10-09  
**BossCat OEM:** Vendor monitoring framework established  
**Next Check:** 2025-10-16 (Monday)

🐾 **Watching for vendor releases while the cat naps!**

