# AntiClickbait Follow Strategy - Bluesky

**Authority:** Fubumaki  
**Actor:** Cursor{Implementer}  
**Date:** 2025-10-21  
**Status:** [OK] ACTIVE

---

## Executive Summary

High-signal follow list curated for the AntiClickbait Transparency Hub mission: fact-checkers, OSINT practitioners, and media literacy organizations that align with evidence-based transparency work.

**Total Accounts:** 21 (10 added this session)  
**Categories:** 5 (OSINT, Fact-check, Media Literacy, Observability, Platform)  
**Verified Accounts:** 11 (domain-verified handles)

---

## Follow List Composition

### OSINT / Verification (7 accounts)

**Purpose:** Real-time verification techniques, media forensics, geolocation practice

| Handle | Type | Focus | Verified |
|--------|------|-------|----------|
| `@bellingcat.bsky.social` | Org (legacy) | Open-source investigations | - |
| `@bellingcat.com` | Org (main) | Investigations, tool releases | [x] |
| `@eliothiggins.bsky.social` | Individual | Bellingcat founder, media forensics threads | - |
| `@quiztime.bsky.social` | Community | Geolocation challenges & verifications | - |
| `@sector035.bsky.social` | Individual | Daily #OSINT tips, tool roundups | - |
| `@mariannaspringbbc.bsky.social` | Individual | BBC Social Media Investigations (UK disinfo) | - |
| `@alistaircoleman.bsky.social` | Individual | Ex-BBC Verify, verification & conspiracy beat | - |

**Key Value:**
- **Sector035:** Weekly OSINT practice, tool announcements
- **Bellingcat:** Methodology transparency, case studies
- **BBC reporters:** UK policy misinfo, platform dynamics

---

### Fact-Checkers (5 accounts)

**Purpose:** Fast debunks, verification standards, institutional credibility

| Handle | Type | Coverage | Verified |
|--------|------|----------|----------|
| `@fullfact.org` | Org | UK independent fact-checker | [x] |
| `@factcheck.afp.com` | Org | Global network, viral visuals | [x] |
| `@politifact.bsky.social` | Org | US fact-checking, fast rumor control | - |
| `@apfactcheck.bsky.social` | Org | AP Fact Check | - |
| `@reuters.com` | Org | Reuters main + Bluesky-specific debunks | [x] |

**Key Value:**
- **Reuters/AFP:** Already debunking Bluesky-specific viral claims (e.g., fake ads, fake "Ackman shuts Bluesky" posts)
- **Full Fact:** UK policy myths, on-platform corrections
- **PolitiFact:** Active on Bluesky, US-focused but high engagement

**Debunk Sources:**
- Reuters Fact Check: https://www.reuters.com/fact-check/
- AFP Fact Check: https://factcheck.afp.com/

---

### Media Literacy / Research (3 accounts)

**Purpose:** Platform dynamics, news audience research, ethical standards

| Handle | Type | Focus | Verified |
|--------|------|-------|----------|
| `@firstdraftnews.bsky.social` | Org | Misinformation research & training | - |
| `@poynterinstitute.bsky.social` | Org | Ethics, news literacy, PolitiFact parent | - |
| `@reutersinstitute.bsky.social` | Org | Reuters Institute (Oxford) - news audiences & platforms | - |

**Key Value:**
- **Reuters Institute:** Research papers on platform migration, news credibility
- **Poynter:** Media ethics, fact-checking standards
- **First Draft:** Training resources, misinformation case studies

---

### Observability (4 accounts)

**Purpose:** Core mission alignment (OpenTelemetry), technical audience

| Handle | Type | Focus | Verified |
|--------|------|-------|----------|
| `@opentelemetry.io` | Org | OpenTelemetry official - standards + releases | [x] |
| `@grafana.bsky.social` | Org | Grafana Labs - OSS observability ecosystem | [x] |
| `@clickhouse.com` | Org | ClickHouse official - database for observability | [x] |
| `@openobservability.bsky.social` | Community | Open Observability Talks - community nexus | [x] |

**Key Value:** Core technical audience, maintains OTel focus alongside AntiClickbait work

---

### Platform (.NET / Azure) (2 accounts)

**Purpose:** Windows audience alignment, enterprise reach

| Handle | Type | Focus | Verified |
|--------|------|-------|----------|
| `@dot.net` | Org | .NET official - Platform news for Windows audience | [x] |
| `@msftazuresupport.bsky.social` | Org | Azure Support - Cloud signal with reach | [x] |

**Key Value:** Bridges OTel (Windows stack) with broader .NET/Azure community

---

## Verification Strategy

### Domain-Verified Handles

**What to check:** Domain-verified handles (e.g., `@fullfact.org`, `@reuters.com`, `@bellingcat.com`) are the most trustworthy on Bluesky. When you see these, the organization controls the domain and linked it to their Bluesky account.

**How to verify:**
1. Click on the profile
2. Look for the blue checkmark next to the handle
3. Click the checkmark to see who verified the account

**Reference:** [The Verge: Bluesky blue checks for authentic accounts](https://www.theverge.com/news/652687/bluesky-blue-checks-verification-authentic-notable-accounts)

### Trusted Verifier Model

Bluesky uses a "Trusted Verifier" system where established organizations (e.g., NYT, WIRED) can verify accounts. This is different from Twitter's old blue check system.

---

## Tools & Resources

### Bluesky Insights (by Bellingcat)

**URL:** https://bellingcat.gitbook.io/toolkit/more/all-tools/bluesky-insights

**Purpose:** Free analytics to audit account behavior & engagement patterns (like "Social Blade" for Bluesky)

**Use Cases:**
- Vet new accounts before amplifying
- Check follower growth patterns for bot behavior
- Analyze engagement authenticity
- Verify claim credibility by checking account history

**When to use:** Before citing or amplifying any account not on this curated list

---

### Starter Packs

**Fact-Checkers Pack:** https://blueskystarterpack.com/fact-checkers  
**Purpose:** Bulk-discover reputable fact-checking teams (42+ lists as of Sep 2025)

**How to use:**
1. Browse starter pack lists
2. One-click follow entire curated groups
3. Prune accounts that don't fit your focus

**Note:** Starter packs are user-curated, always verify with domain-verified handles or cross-check against institutional websites

---

## Manual Follow Instructions

**Current Status:** Follow list is declarative (YAML), actual following requires manual execution or API integration (Milestone B)

**To follow manually:**
1. Visit https://bsky.app/profile/[handle]
2. Click "Follow" button
3. Track completion: 0/21 done

**To follow via script (when API integrated):**
```bash
npx tsx scripts/social/follow.ts --apply
```

**Current behavior:** `--apply` flag is a placeholder; network follow via ATProto will be implemented at Milestone B

---

## Engagement Guidelines

### What to engage with:

- **Debunk threads:** Fact-check organizations explaining methodology
- **OSINT practice:** Sector035 geolocation challenges, Bellingcat tool tutorials
- **Research papers:** Reuters Institute platform studies
- **Verification techniques:** BBC reporters' media forensics threads

### What to amplify from AntiClickbait account:

- Evidence-backed claims with artifact links
- Methodology explanations (ECRR framework)
- Tool releases (dashboard, transparency hub)
- Real-world outcomes (not hype)

### What to avoid:

- Partisan political commentary (stay methodology-focused)
- Unverified viral claims (even if from followed accounts—verify first)
- Hype without artifacts
- Engagement bait

---

## Monitoring Strategy

### Weekly Review (Sundays)

- [ ] Check notifications for replies from followed accounts
- [ ] Review trending posts from fact-checkers (debunk opportunities)
- [ ] Monitor OSINT accounts for new tools/techniques
- [ ] Check if any followed accounts have domain-verification updates

### Monthly Audit (1st of month)

- [ ] Review follower growth patterns (Bluesky Insights)
- [ ] Prune inactive or low-signal accounts
- [ ] Add new high-signal accounts discovered via network
- [ ] Update FOLLOW_LIST.yaml with rationale

### Quarterly Strategy (Q1, Q2, Q3, Q4)

- [ ] Evaluate follow list effectiveness (engagement quality)
- [ ] Compare against new starter packs (fact-checker ecosystem changes)
- [ ] Adjust category balance (OSINT vs fact-check vs media literacy)
- [ ] Document learnings in ECRR report

---

## Starter Pack Creation Guide

**Status:** [PENDING] - Requires browser access or API integration

**To create "AntiClickbait Transparency Hub" starter pack:**

1. **Navigate to:** https://bsky.app/
2. **Click:** Profile -> Starter Packs -> Create New
3. **Name:** "AntiClickbait Transparency Hub"
4. **Description:**
   ```
   High-signal follow list for evidence-based transparency work:
   - Tier-1 fact-checkers (Full Fact, AFP, Reuters, PolitiFact)
   - OSINT practitioners (Bellingcat, Sector035, BBC reporters)
   - Media literacy orgs (Poynter, Reuters Institute)
   
   Curated for the AntiClickbait mission by @resonai.bsky.social
   
   22 features scored 0-100: https://hub.resonai.uk/
   ```
5. **Add accounts:** All 21 from FOLLOW_LIST.yaml
6. **Visibility:** Public
7. **Publish**
8. **Share link:** In AntiClickbait Hub footer + docs/social/ README

**Note:** This requires active Bluesky session. Add to next browser automation session or manual task list.

---

## Success Metrics

### Immediate (Week 1)

- [ ] All 21 accounts followed
- [ ] At least 3 engagements with fact-check content
- [ ] Zero low-quality amplifications

### Short-term (Month 1)

- [ ] 5+ fact-checkers follow back
- [ ] 1+ collaboration opportunity (e.g., methodology discussion)
- [ ] Starter pack created & shared
- [ ] 10+ users via starter pack

### Long-term (Quarter 1)

- [ ] AntiClickbait Hub cited by fact-checker
- [ ] OSINT community uses our transparency scoring
- [ ] 100+ starter pack adopters
- [ ] Evidence-based methodology spreads

---

## Integration with AntiClickbait Hub

**Cross-reference:** https://hub.resonai.uk/

**How follow list supports the mission:**

1. **Evidence standards:** Fact-checkers model verification rigor we apply to OTel claims
2. **Methodology transparency:** OSINT accounts show "work shown" approach (matches ECRR)
3. **Institutional credibility:** Domain-verified accounts validate our own transparency standards
4. **Network effects:** Starter pack amplifies Hub reach to aligned audiences
5. **Feedback loop:** Engagement teaches us what resonates with verification community

---

## Maintenance

**Owner:** Cursor{Implementer} (SOCM lane)  
**Reviewer:** Fubumaki  
**Frequency:** Weekly check-ins, monthly audits  
**YAML Source:** `docs/social/FOLLOW_LIST.yaml`  
**Script:** `scripts/social/follow.ts` (dry-run by default)

**To propose additions:**
1. Add to `docs/social/FOLLOW_LIST.yaml` with rationale
2. Run `npx tsx scripts/social/follow.ts` to verify
3. Document in PR or ECRR report
4. Apply with `--apply` flag (when API integrated)

---

## References

- **Bluesky Insights:** https://bellingcat.gitbook.io/toolkit/more/all-tools/bluesky-insights
- **Fact-Checkers Starter Pack:** https://blueskystarterpack.com/fact-checkers
- **Bluesky Verification:** https://www.theverge.com/news/652687/bluesky-blue-checks-verification-authentic-notable-accounts
- **Reuters Fact Check (Bluesky-specific):** https://www.reuters.com/fact-check/
- **Sector035 OSINT Tips:** https://bsky.app/profile/sector035.bsky.social

---

**[PAW] Cursor{Implementer} - AntiClickbait Follow Strategy**  
**Status:** Follow list updated, starter pack guide ready, monitoring framework established  
**Next:** Manual follow execution or Milestone B API integration

