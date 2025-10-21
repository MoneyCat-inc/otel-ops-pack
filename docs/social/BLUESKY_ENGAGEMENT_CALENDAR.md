# Bluesky Growth & Engagement Calendar - AntiClickbait Hub

**Authority:** Fubumaki  
**Actor:** Cursor{Implementer}  
**Date:** 2025-10-21  
**Status:** [OK] ACTIVE

---

## Executive Summary

Strategic posting calendar optimized for Bluesky's graph-based discovery (feeds, quotes, lists) rather than algorithmic boosts. Designed for AntiClickbait/Resonai Hub's public-interest, investigative, educational mission.

**Target:** 1-2 posts/day + 2-4 replies/day  
**Timing:** 9-11 AM UTC, 6-8 PM UTC (cross-Atlantic peak)  
**Tone:** Calm, evidential, authority-building (no outrage bait)

---

## 1. Signal Signature Optimization

### Profile Setup Checklist

**[ ] Handle:** Verified domain
- Current: `@resonai.bsky.social`
- Target: `@anticlickbait.resonai.io` or `@resonai.io`
- **Action:** Set up domain verification (requires DNS TXT record)
- **Reference:** https://bsky.social/about/blog/4-28-2023-domain-handle-tutorial

**[ ] Bio:** Short + mission clarity + emoji anchor
```
[PUZZLE] Tracking clickbait trends + truth literacy.
22 OTel features scored 0-100 on evidence.
Run by @resonai.io
```
- Current: "Expert Mouse Chaser" (playful but unclear)
- **Action:** Update to mission-focused bio

**[ ] Banner & Avatar:** High-contrast branding (readable at 48px)
- Current: BossCat avatar (good recognition)
- **Action:** Add banner with AntiClickbait Hub branding + URL

**[ ] Pinned Post:** Mission explainer or live hub link
- Current: Launch post (good foundation)
- **Action:** Consider updating to Hub showcase with latest stats

---

## 2. Weekly Posting Rhythm

### Daily Cadence (7 posts/week baseline)

| Day       | Primary Post                      | Reply Focus                   | Time (UTC) |
|-----------|-----------------------------------|-------------------------------|------------|
| Monday    | Mythbuster (debunk 1 claim)       | Fact-checker threads          | 9:00 AM    |
| Tuesday   | Tool Tuesday (OSINT/verification) | OSINT community               | 6:00 PM    |
| Wednesday | Case Study (Hub feature deep-dive)| Developer/OTel discussions    | 9:00 AM    |
| Thursday  | Thread (methodology explanation)  | Media literacy orgs           | 6:00 PM    |
| Friday    | Fact Recap (weekly digest)        | Week's trending misinfo       | 9:00 AM    |
| Saturday  | Community Spotlight               | Followed accounts             | 10:00 AM   |
| Sunday    | Signal Boost (share others' work) | Quiet engagement (optional)   | 6:00 PM    |

---

## 3. Content Templates

### Monday: Mythbuster

**Format:** Quote + Context pattern (Bluesky algorithm favors quotes with commentary)

**Template:**
```
[X] CLAIM: "[Viral claim here]"

[OK] FACT: [Actual situation in 1-2 sentences]

Source: @[fact-checker handle]
Context: [Why this matters / common misconception]

#FactCheck #MythBusting
```

**Example:**
```
[X] CLAIM: "OpenTelemetry auto-instrumentation has 50% performance overhead"

[OK] FACT: Typical overhead is single-digit % (varies by workload). Start with 100% sampling, then dial down via head/tail sampling.

Source: Our testing + @opentelemetry.io docs
Context: FUD spreads because people don't measure before/after

#OpenTelemetry #FactCheck
```

**Target:** 1 myth/week, rotating between OTel, observability, and platform claims

---

### Tuesday: Tool Tuesday

**Format:** Practical tool showcase with use case

**Template:**
```
[TOOLS] Tool Tuesday: [Tool Name]

What: [1 sentence description]
Use case: [Specific problem it solves]
Try it: [Link]

Real example: [Brief story of how you/others used it]

#OSINT #Tools #[Relevant tag]
```

**Example:**
```
[TOOLS] Tool Tuesday: Bluesky Insights (by @bellingcat.com)

What: Free analytics to audit account behavior & engagement patterns
Use case: Vet accounts before amplifying claims
Try it: https://bellingcat.gitbook.io/toolkit/more/all-tools/bluesky-insights

Real example: Used it to verify a "viral expert" had 10k followers gained in 48 hours (bot farm red flag)

#OSINT #Tools #Verification
```

**Target:** Rotate between verification tools, observability dashboards, and dev utilities

---

### Wednesday: Case Study

**Format:** Deep-dive into one Hub feature with evidence

**Template:**
```
[DATA] Case Study: [Hub Feature Name]

Claim: "[What we tested]"
Score: [0-100] / Reasoning: [Brief]

Evidence:
- [Artifact 1 with link]
- [Artifact 2 with link]
- [Testing method]

Limitation: [Honest caveat]

Full transparency: [Hub link]

#AntiClickbait #Evidence
```

**Example:**
```
[DATA] Case Study: "Zero-code auto-instrumentation"

Claim: "OpenTelemetry .NET attaches via env vars, no code changes"
Score: 85/100 / Reasoning: Works for most apps, some edge cases

Evidence:
- Config: https://github.com/MoneyCat-inc/otel-ops-pack/blob/main/config.yaml
- Demo video: [link]
- Tested on ASP.NET Core 6-8

Limitation: Some exotic hosting scenarios need manual setup

Full transparency: https://moneycat-inc.github.io/otel-ops-pack/anticlickbait/

#OpenTelemetry #Evidence
```

**Target:** Cover 1-2 Hub features per month, rotating through all 22

---

### Thursday: Thread (Methodology)

**Format:** Multi-post thread explaining ECRR or verification technique

**Template:**
```
[THREAD] How we score claims (ECRR method)

1/ Every claim in our Hub gets scored 0-100 on evidence quality.
Not vibes. Not hype. Just: can we verify it?

2/ ECRR = Evidence → Contain → Rollback → Report

Evidence: Artifact links, test results, real deployments
Contain: Scope claims (what works, what doesn't)
Rollback: Honest limitations + workarounds
Report: Transparent scoring

3/ Example: "Low latency" claim
- What does "low" mean? (200ms batches)
- How tested? (Windows Event Logs → SigNoz)
- What breaks it? (network issues, collector backpressure)

4/ This is how we avoid clickbait while staying useful.

No magic. No hand-waving. Just what actually works.

Hub: https://moneycat-inc.github.io/otel-ops-pack/anticlickbait/
```

**Target:** 1 methodology thread per 2 weeks, alternating with technique tutorials

---

### Friday: Fact Recap

**Format:** Weekly digest of corrected claims

**Template:**
```
[!] This week in corrections:

[X] Myth 1: [Brief claim] → [OK] Reality: [Truth]
[X] Myth 2: [Brief claim] → [OK] Reality: [Truth]
[X] Myth 3: [Brief claim] → [OK] Reality: [Truth]

Common theme: [Pattern you noticed]

Shoutout: @[fact-checker who helped]

#WeeklyRecap #FactCheck
```

**Example:**
```
[!] This week in corrections:

[X] "OTel kills performance" → [OK] Single-digit % typical overhead
[X] "Windows can't do traces" → [OK] .NET auto-instrumentation works great
[X] "SigNoz needs Kubernetes" → [OK] Docker Compose is fine for <100 services

Common theme: FUD spreads when people don't test themselves

Shoutout: @opentelemetry.io for patient community responses

#WeeklyRecap #OpenTelemetry
```

**Target:** Capture 3-5 corrections per week, mix OTel + broader tech claims

---

### Saturday: Community Spotlight

**Format:** Amplify good work from followed accounts

**Template:**
```
[WIN] Community spotlight: @[handle]

What they did: [Specific contribution]

Why it matters: [Impact / learning]

Check them out: [Link to their post/profile]

#Community #[Topic]
```

**Example:**
```
[WIN] Community spotlight: @sector035.bsky.social

What they did: Posted 52 consecutive weeks of OSINT tips (complete thread archive)

Why it matters: Free, actionable verification training for anyone. Built entire skill-building community.

Check them out: https://bsky.app/profile/sector035.bsky.social

#OSINT #Community
```

**Target:** Rotate through followed accounts, prioritize fact-checkers and OSINT practitioners

---

### Sunday: Signal Boost

**Format:** Quote + amplify others' evidence-based work

**Template:**
```
[>>] Worth reading:

[Quote their post]

Why: [Your 1-2 sentence take on why this matters]

[Original post link]
```

**Example:**
```
[>>] Worth reading:

"Bellingcat just released a geolocation training course (free, 6 hours, real case studies)"

Why: This is how you build media literacy at scale—open methodology, repeatable techniques, no paywalls.

https://bsky.app/profile/bellingcat.com/post/[id]
```

**Target:** 1-2 signal boosts per week, prioritize educational content

---

## 4. Reply Strategy (2-4/day)

### High-Value Reply Opportunities

**Priority 1: Fact-checker threads**
- Jump in early with supporting evidence or methodology clarification
- Tag relevant sources (e.g., @fullfact.org, @reuters.com)
- Calm tone, add context rather than dunking

**Example:**
```
Good addition—we tested similar claim in our transparency hub. 
Same pattern: headline overpromises, fine print has caveats.

Full scoring: [Hub link]
```

**Priority 2: OSINT community questions**
- Answer verification technique questions
- Share tools (Bluesky Insights, public datasets)
- Offer to test claims if relevant to OTel stack

**Example:**
```
For Windows log verification, we use OTel collector → SigNoz pipeline.
Config here: [link]

Captures full event metadata for audit trails.
```

**Priority 3: Trending misinfo corrections**
- Use "Quote + Context" format (algorithm boost)
- Link to authoritative sources
- No snark—just facts

**Example:**
```
[X] CLAIM: [Viral post]

[OK] FACT: [Correction in 1-2 lines]

Already debunked by @fullfact.org: [link]

Context: [Why this spreads / common confusion]
```

---

## 5. Tagging Strategy

### Core Tags (Rotate 2-3 per post)

**Mission Tags:**
- `#AntiClickbait` (brand anchor)
- `#FactCheck` (discovery feed)
- `#Evidence` (methodology signal)
- `#Transparency` (values signal)

**Technical Tags:**
- `#OpenTelemetry` (core audience)
- `#Observability` (broader ecosystem)
- `#DotNet` (platform)
- `#Windows` (niche but loyal)

**Community Tags:**
- `#OSINT` (verification community)
- `#MediaLiteracy` (educational angle)
- `#DevOps` (ops practitioners)
- `#SRE` (reliability engineers)

**Weekly Tags:**
- `#MythBusting` (Mondays)
- `#ToolTuesday` (Tuesdays)
- `#WeeklyRecap` (Fridays)

### Tagging Best Practices

**DO:**
- Tag fact-checkers when citing their work (@fullfact.org)
- Tag tool creators when showcasing (@bellingcat.com for Insights)
- Tag official accounts for platform news (@opentelemetry.io)

**DON'T:**
- Over-tag (3 tags max per post)
- Tag unrelated accounts for reach (spam signal)
- Use trending tags off-mission (trust erosion)

---

## 6. Feed, List & Starter Pack Strategy

### Subscribe to Feeds

**Recommended feeds to follow for discovery:**

1. **Skeptical Bytes** (fact-checking aggregator)
2. **Breaking News** (Reuters/Poynter curated)
3. **OSINT Digest** (verification techniques)
4. **OpenTelemetry News** (official + community)
5. **Dev Tools Weekly** (technical audience)

**How to find:** Search "feeds" in Bluesky app, filter by "fact check" or "OSINT"

---

### Create Custom Feed (via SkyFeed.app)

**AntiClickbait Verified Feed**

**Rules:**
- Include posts with `#FactCheck` OR from `@fullfact.org`, `@bellingcat.com`, `@reuters.com`
- Exclude posts with `#Breaking` (too much noise)
- Prioritize posts with quotes (context-added reposts)

**Setup:**
1. Go to https://skyfeed.app
2. Create new feed: "AntiClickbait Verified"
3. Add handles from FOLLOW_LIST.yaml (fact-checkers + OSINT)
4. Add hashtag filter: `#FactCheck` OR `#Evidence` OR `#Verification`
5. Publish feed
6. Share link in bio + Hub

**Publish link format:** `https://bsky.app/profile/[your-handle]/feed/[feed-name]`

---

### Build Starter Lists

**List 1: Trusted UK Fact-Checkers**
- @fullfact.org
- @bbc-verify (if available)
- @ferret-fact-service (Scotland)

**List 2: OSINT Experts**
- @bellingcat.com
- @eliothiggins.bsky.social
- @sector035.bsky.social
- @mariannaspringbbc.bsky.social
- @alistaircoleman.bsky.social

**List 3: Media Literacy Educators**
- @firstdraftnews.bsky.social
- @poynterinstitute.bsky.social
- @reutersinstitute.bsky.social

**How to create:**
1. Profile → Lists → Create New List
2. Add accounts from FOLLOW_LIST.yaml
3. Make public + add description
4. Share in Hub footer

---

### Starter Pack (Already Documented)

**Reference:** `docs/social/ANTICLICKBAIT_FOLLOW_STRATEGY.md` (lines 300-330)

**Name:** "AntiClickbait Transparency Hub"  
**Accounts:** All 21 from FOLLOW_LIST.yaml  
**Status:** Guide ready, needs browser session to create

---

## 7. Cross-Channel Integration

### Link Bluesky Everywhere

**[ ] GitHub Profile**
- Add to `README.md`: "Follow on Bluesky: [@resonai.bsky.social](https://bsky.app/profile/resonai.bsky.social)"
- Verified domain connection boosts authenticity

**[ ] AntiClickbait Hub**
- Footer link: "Discuss on Bluesky"
- Consider embedding latest post (iframe)

**[ ] Patreon/Sponsors**
- "Updates on Bluesky: @resonai.bsky.social"
- Cross-promote Hub launches

**[ ] LinkedIn (if applicable)**
- Link in profile (domain verification helps)

### Embed Bluesky Posts

**Option 1: iframe embed** (for Hub)
```html
<iframe 
  src="https://bsky.app/profile/resonai.bsky.social/post/[post-id]/embed"
  width="100%" 
  height="300"
  frameborder="0">
</iframe>
```

**Option 2: Static screenshot + link** (for GitHub)
- Screenshot of key post
- Link to live thread

---

## 8. Measurement & Adjustment

### Weekly Metrics (Manual Log)

**Track in spreadsheet:**
| Week | Posts | Replies | Followers | Avg Likes | Avg Quotes | Top Post |
|------|-------|---------|-----------|-----------|------------|----------|
| W1   | 7     | 14      | 2         | 1.2       | 0.3        | Mythbuster #1 |

**Tools:**
- **Bluesky Insights:** https://insights.bsky.app (engagement trends)
- **SkyBridge:** https://skybridge.fly.dev (cross-post stats)
- **Manual export:** App → Settings → Export Data → CSV

**KPIs:**
- **Follower growth:** +10-20/month (quality over quantity)
- **Quote ratio:** >0.2 (context-added reposts)
- **Reply engagement:** >5 replies/week from followed accounts
- **Hub clicks:** Track via UTM parameters

---

### Monthly Review Checklist

**[ ] Content Performance**
- Which day/format got most engagement?
- Which tags drove discovery?
- Any posts that underperformed? Why?

**[ ] Community Growth**
- New followers: Are they aligned with mission?
- Mutual follows: Are fact-checkers following back?
- Spam/low-quality: Block + report

**[ ] Mission Alignment**
- Did we stay evidential & calm?
- Any outrage bait slip through? Delete + note
- Corrections posted? Log for transparency

**[ ] Feed/List Maintenance**
- Are custom feeds still relevant?
- Any accounts to add/remove from lists?
- Starter pack updated with new accounts?

---

## 9. Governance: Stay On-Mission

### Red Lines (Never Cross)

**[X] NO outrage bait:** No dunking, no snark, no "look at this idiot"  
**[X] NO unverified amplification:** Always check before quote-boosting  
**[X] NO silent corrections:** If we're wrong, post correction notice  
**[X] NO off-mission drift:** Stay focused on evidence, transparency, tech

### Green Lights (Always Do)

**[OK] Archive deleted threads:** Screenshot before deletion (for records, not call-outs)  
**[OK] Post correction notices:** "Update: Our earlier claim needed correction..."  
**[OK] Credit sources:** Always tag fact-checkers, tool creators, researchers  
**[OK] Show work:** Link to artifacts, configs, test results

### Credibility Compound Interest

**Every correction = trust +1**  
**Every hype post = trust -5**  
**Every citation = authority +2**  
**Every dunk = authority -10**

**Play long game:** Reputation takes years to build, seconds to destroy.

---

## 10. 30-Day Kickoff Plan

### Week 1: Foundation

**[ ] Profile optimization** (handle, bio, banner, pinned post)  
**[ ] Subscribe to 5 recommended feeds**  
**[ ] Post Monday Mythbuster #1**  
**[ ] Reply to 3 fact-checker threads**  
**[ ] Create "OSINT Experts" list**

### Week 2: Rhythm Establishment

**[ ] Follow full posting calendar** (7 posts)  
**[ ] Daily replies** (2-4/day)  
**[ ] Create custom "AntiClickbait Verified" feed**  
**[ ] Measure Week 1 metrics**

### Week 3: Community Building

**[ ] Community Spotlight** (tag 2 followed accounts)  
**[ ] Signal Boost** (quote 3 quality posts)  
**[ ] Create "Media Literacy" list**  
**[ ] Start weekly metrics spreadsheet**

### Week 4: Refinement

**[ ] Monthly review** (content performance)  
**[ ] Adjust posting times** based on engagement  
**[ ] Create starter pack** (if browser session available)  
**[ ] Document learnings** in ECRR report

---

## 11. Content Bank (Pre-Written Templates)

### Emergency Corrections

**When you need to correct your own claim:**
```
[!] Correction: [Date post]

What we said: "[Original claim]"
What's accurate: "[Corrected version]"

How we got it wrong: [Brief explanation]
Source: [Link to correction]

Transparency matters. Thanks to @[whoever caught it] for the catch.
```

---

### When Cited by Others

**When fact-checker or researcher cites your work:**
```
[WIN] Honored to be cited by @[handle]

They're doing [what they're known for].
We're learning a ton from their methodology.

Check out their work: [link]

This is what good collaboration looks like.
```

---

### When Attacked/Trolled

**Calm, professional deflection:**
```
Appreciate the feedback. Our methodology is documented here: [Hub link]

If you spot errors, please cite sources and we'll investigate.

Corrections make us better.
```

*Do not engage further. Mute if it continues.*

---

## 12. Integration with Existing Docs

**Cross-References:**

- **Follow Strategy:** `docs/social/ANTICLICKBAIT_FOLLOW_STRATEGY.md`
- **SOCM Thread Packs:** `docs/socm/misc/SOCM_THREAD_PACK_DAY*.md`
- **Credentials Setup:** `scripts/social/set-credentials.ps1`
- **Follow Script:** `scripts/social/follow.ts`

**How this fits:**
- Days 1-3 (already posted) established mission
- This calendar sustains momentum
- Follow strategy provides network
- ECRR methodology ensures quality

---

## 13. Success Metrics (90-Day Targets)

### Quantitative

- **Followers:** 50 (quality-focused, aligned audience)
- **Posts:** 90 (1/day average)
- **Engagement rate:** 5% (likes + quotes / followers)
- **Hub clicks:** 200 (tracked via UTM)
- **Mutual follows:** 10 fact-checkers or OSINT pros

### Qualitative

- **Cited by fact-checker:** At least 1 institutional mention
- **Starter pack adopters:** 25+ one-click follows
- **Community contributions:** 3+ useful replies from followed accounts
- **Zero corrections needed:** Quality > speed, no rushed claims

---

## Quick Reference Card

```
DAILY CHECKLIST:
[ ] 1 primary post (9-11 AM or 6-8 PM UTC)
[ ] 2-4 replies (fact-checkers, OSINT, trending corrections)
[ ] Check notifications (respond within 24h)
[ ] Archive any deleted content (screenshots)

WEEKLY CHECKLIST:
[ ] Monday: Mythbuster
[ ] Tuesday: Tool Tuesday
[ ] Wednesday: Case Study
[ ] Thursday: Thread
[ ] Friday: Fact Recap
[ ] Saturday: Community Spotlight
[ ] Sunday: Signal Boost

MONTHLY CHECKLIST:
[ ] Review metrics (spreadsheet)
[ ] Audit feed/list relevance
[ ] Update starter pack
[ ] ECRR report (learnings)
```

---

**[PAW] Cursor{Implementer} - Engagement Calendar Ready**

**Status:** Full 90-day playbook complete with templates, metrics, and governance guardrails  
**Next:** Execute Week 1 kickoff or integrate with existing SOCM workflow

