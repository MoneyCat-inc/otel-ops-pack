# 🐾 Production Monitoring Schedule

**Post Gate #008 Approval**  
**Created:** 2025-10-22  
**Authority:** BossCat OEM post-approval condition

> **Scope notice (2026-09-02 truth pass).** Written 2025-10-22 for the Gate #008 hub launch.
> The hub/site checks and the Bluesky campaign section belong to lanes extracted in Pack 3B
> (2026-07-24): `moneycat-site` and `socm`. `scripts/monitor-bluesky-metrics.ps1` and
> `docs/evidence/bluesky/` do not exist in this repo. The three workflows under *Automation
> Status* were RETIRED 2026-08-03 (`workflow_dispatch` only). The OTel pipeline section is
> corrected in place; the rest is kept as the record of the schedule.

---

## Daily Monitoring Tasks

### Hub Production Health (hub.resonai.uk)

**Frequency:** Every 5 minutes (automated) + Daily review  
**Script:** `scripts/monitor-hub-production.ps1`

**Checks:**

- [x] Hub homepage (/) - HTTP 200
- [x] Status page (/docs/status.html) - HTTP 200
- [x] Live metrics dashboard - HTTP 200
- [x] Data room - HTTP 200
- [x] robots.txt - HTTP 200
- [x] favicon.svg - HTTP 200

**Manual:** `pwsh -File scripts\monitor-hub-production.ps1 -Once`  
**Continuous:** `pwsh -File scripts\monitor-hub-production.ps1 -DurationMinutes 60`

**Alerts:**

- Any endpoint returning non-200 status
- Response time > 5 seconds
- SSL certificate issues

---

### Bluesky Campaign Metrics

**Frequency:** Daily manual check  
**Script:** `scripts/monitor-bluesky-metrics.ps1`

**Metrics:**

- Follower count (track growth rate)
- Post engagement (likes, reposts, replies per post)
- Starter Pack adoption
- AntiClickbait community mentions

**Manual:** `pwsh -File scripts\monitor-bluesky-metrics.ps1`

**Evidence:**

- Screenshots → `docs/evidence/bluesky/`
- Metrics → `docs/status/kpis.json`
- Milestones → `docs/BossCat/BOSSCAT_LOG.md`

---

### OTel Pipeline Health

**Frequency:** Continuous (existing monitoring)  
**Scripts:**

- `scripts/quick-monitor.ps1` - Fast health check
- `scripts/monitor-optimized-pipeline.ps1` - Detailed monitoring
- `BRAV/SCPT/send_synthetic_otel_simple.py` - Synthetic canary (Gate #026A route)

**Checks:**

- [x] Windows Collector service: RUNNING
- [x] Docker containers: 7/7 healthy
- [x] OTLP endpoints: 5320/5321 (Windows collector), 4317/4318 (SigNoz collector); UI 8080
- [x] SigNoz health API: {"status":"ok"}
- [x] Metrics port 8888: SERVING
- [x] Canary tests: PASSING

**Existing:** Already operational, continue current cadence

---

## Weekly Tasks

### Gate Health Review

**Frequency:** Weekly (Monday mornings)  
**Checklist:**

- [ ] Review `docs/BossCat/BOSSCAT_LOG.md` for new incidents (IONA_ERRORS.md is a closed ledger)
- [ ] Check gate verification pass rate
- [ ] Review ECRR report count and quality
- [ ] Verify all services healthy
- [ ] Check for security vulnerabilities

### Hub Analytics

**Frequency:** Weekly  
**Actions:**

- [ ] Review hub.resonai.uk traffic (if analytics enabled)
- [ ] Check for broken links
- [ ] Verify all dashboards loading
- [ ] Review any user feedback

### Bluesky Growth

**Frequency:** Weekly  
**Actions:**

- [ ] Calculate follower growth rate
- [ ] Analyze post engagement trends
- [ ] Review Starter Pack adoption
- [ ] Plan next week's content

---

## Monthly Tasks

### Gate Retrospective

**Frequency:** Monthly (first Monday)  
**Review:**

- Gate velocity trends
- Remediation patterns
- Documentation quality
- Process improvements

### Infrastructure Health

**Frequency:** Monthly  
**Actions:**

- [ ] Review Docker container logs
- [ ] Check disk usage and cleanup
- [ ] Verify backup integrity
- [ ] Update dependencies if needed

---

## Escalation Criteria

### Critical (Immediate Action)

- Hub homepage returning errors
- SigNoz health API down
- Windows Collector service stopped
- Canary tests failing
- Docker containers unhealthy

**Action:** Immediate investigation, escalate to BossCat OEM if production-impacting

### Warning (Next Business Day)

- Individual dashboard endpoint errors
- Slow response times (> 5 sec)
- Bluesky post engagement drop > 50%
- IONA incidents (MEDIUM severity)

**Action:** Create ECRR report, track for next gate

### Info (Weekly Review)

- Minor IONA incidents (LOW severity)
- Bluesky metrics fluctuations
- Documentation updates needed

**Action:** Track in weekly review, address in batch

---

## Automation Status

### Existing

- ⛔ Hub uptime smoke (.github/workflows/hub-smoke.yml) - RETIRED 2026-08-03, dispatch only
- ⛔ Link check (.github/workflows/link-check.yml) - RETIRED 2026-08-03; docs-lane-checks covers changed docs
- ⛔ Update KPIs (.github/workflows/update-kpis.yml) - RETIRED 2026-08-03, dispatch only

### Manual (For Now)

- ⏳ Bluesky metrics - Manual daily check
- ⏳ Hub analytics - Manual weekly review (if enabled)

### Future Automation

- 📋 Bluesky API integration for automated metrics
- 📋 Hub analytics dashboard (if traffic warrants)
- 📋 Automated IONA incident detection

---

## Monitoring Dashboard

**Current:** Use SigNoz UI (<http://localhost:8080>) for pipeline metrics  
**Future:** Consider consolidated monitoring dashboard combining:

- Hub health status
- Bluesky metrics
- Pipeline health
- Gate status

---

**Last Updated:** 2025-10-22  
**Status:** Active monitoring post Gate #008 approval

🐾 *Production monitoring schedule for Cat Nap Control Room*

