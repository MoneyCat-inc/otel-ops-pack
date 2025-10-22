# AntiClickbait Starter Pack - Trusted Sources
**Bluesky Starter Pack Composition**

---

## 📋 Pack Metadata

**Title:** AntiClickbait—Trusted Sources  
**Description:** Evidence-first fact-checking, OSINT, and observability. No hype, just verifiable claims with sources.  
**Creator:** @resonai.bsky.social (BossCat)  
**Category:** Fact-Checking / Media Literacy  
**Publish Date:** 2025-10-22

---

## 👥 Accounts to Include (15 curated)

### Fact-Checking Orgs (4)
1. **@fullfact.org** (Full Fact)
   - UK's independent fact-checker (domain-verified)
   - Why: On-platform corrections & UK policy myths
   
2. **@factcheck.afp.com** (AFP Fact Check)
   - Global network, quick debunks on viral visuals (domain-verified)
   - Why: Fast response to international claims
   
3. **@politifact.bsky.social** (PolitiFact)
   - US fact-checking, Truth-O-Meter (domain-verified via parent)
   - Why: Active on Bluesky, fast rumor control
   
4. **@reuters.com** (Reuters)
   - Frequent Bluesky-related debunks (domain-verified)
   - Why: Institutional credibility + global reach

### OSINT / Verification (5)
5. **@bellingcat.com** (Bellingcat)
   - Open-source investigations (domain-verified)
   - Why: Gold standard for media forensics
   
6. **@eliothiggins.bsky.social** (Eliot Higgins)
   - Bellingcat founder, frequent media forensics threads
   - Why: Hands-on verification breakdowns
   
7. **@sector035.bsky.social** (Sector035)
   - Weekly #OSINT tips, geolocation practice, tool roundups
   - Why: Practical skill-building content
   
8. **@mariannaspringbbc.bsky.social** (Marianna Spring)
   - BBC Social Media Investigations - UK disinfo reporting
   - Why: Mainstream journalism + investigative depth
   
9. **@quiztime.bsky.social** (Quiztime)
   - Geolocation/verification community hub
   - Why: Interactive learning, collaborative verification

### Media Literacy (2)
10. **@poynterinstitute.bsky.social** (The Poynter Institute)
    - Ethics, news literacy, PolitiFact parent
    - Why: Educational resources + meta-analysis
    
11. **@reutersinstitute.bsky.social** (Reuters Institute)
    - Oxford research on news audiences & platforms
    - Why: Academic rigor, trend analysis

### Observability (Tech Context) (3)
12. **@opentelemetry.io** (OpenTelemetry)
    - Official OTel project (domain-verified)
    - Why: Standards body for observability (BossCat's tech lane)
    
13. **@grafana.bsky.social** (Grafana)
    - OSS observability ecosystem
    - Why: Open-source transparency ethos
    
14. **@clickhouse.com** (ClickHouse)
    - Database for observability (domain-verified)
    - Why: Infrastructure for evidence-based systems

### Your Account (Hub)
15. **@resonai.bsky.social** (BossCat)
    - Evidence-first observability + truth literacy
    - Why: Creator account, connects fact-checking to tech transparency

---

## 📡 Custom Feeds to Include (2-3)

### Feed 1: "Fact-Check Firehose"
**Description:** All posts from verified fact-checking orgs + quote-posts that cite them  
**Rule Set:**
```
OR conditions:
- author:fullfact.org
- author:factcheck.afp.com
- author:politifact.bsky.social
- author:reuters.com (filter: contains "fact check" OR "debunk")
- quoted_post.author IN [fullfact.org, factcheck.afp.com, politifact.bsky.social]
```

### Feed 2: "OSINT + Verification"
**Description:** Media forensics, geolocation, verification threads from practitioners  
**Rule Set:**
```
OR conditions:
- author:bellingcat.com
- author:eliothiggins.bsky.social
- author:sector035.bsky.social
- author:mariannaspringbbc.bsky.social
- hashtag:#OSINT
- text contains: "verify" OR "geolocation" OR "media forensics"
- quoted_post.hashtags contains: #OSINT
```

### Feed 3 (Optional): "AntiClickbait HQ"
**Description:** BossCat + accounts engaging with the #AntiClickbait mission  
**Rule Set:**
```
OR conditions:
- author:resonai.bsky.social
- hashtag:#AntiClickbait
- hashtag:#OpenTelemetry (when paired with "evidence" OR "transparency")
- quoted_post.author:resonai.bsky.social
```

---

## 🛠️ Implementation Steps

### 1. Create Starter Pack (In-App)
1. Go to your profile → **Starter Packs** tab
2. Click **Create**
3. **Add accounts:** Paste the 15 handles from above
4. **Add feeds:** Create the 2-3 custom feeds first (see Feed Setup below)
5. **Title:** AntiClickbait—Trusted Sources
6. **Description:** "Evidence-first fact-checking, OSINT, and observability. No hype, just verifiable claims with sources. Curated by @resonai.bsky.social"
7. Click **Publish**
8. Copy the Starter Pack URL

### 2. Create Custom Feeds (Using SkyFeed)
**Option A: No-Code (SkyFeed)**
1. Go to [skyfeed.app](https://skyfeed.app/)
2. Login with your Bluesky account
3. **Feed Builder** → New Feed
4. Add rules from the rule sets above (use simple mode)
5. Save & Publish
6. Copy feed URI (e.g., `at://did:plc:.../app.bsky.feed.generator/...`)

**Option B: Code (Official Feed Generator)**
- Clone: https://github.com/bluesky-social/feed-generator
- Edit `src/algos/` to add your custom logic
- Deploy to your server or Vercel
- Run `yarn publishFeed`

### 3. Add Starter Pack to Your Profile
1. Update bio to include: "Starter Pack: [link]"
2. Create a new pinned post:
   ```
   🔍 New to fact-checking on Bluesky?
   
   Start here: [Starter Pack link]
   
   15 trusted sources + 3 custom feeds for evidence-first media literacy.
   
   #AntiClickbait #FactCheck #OSINT
   ```

### 4. Promote the Pack
- Share in replies to popular fact-checking posts
- Quote-post major debunks with "More sources like this in our Starter Pack: [link]"
- Add to your GitHub Pages hub as an embedded link

---

## 📊 Success Metrics

Track these weekly:
- **Pack follows:** How many people clicked "Follow all"
- **Individual follows:** Which accounts in the pack get the most adds
- **Feed subscriptions:** Which feed has the highest adoption
- **Engagement on pack promotion posts:** Likes, reposts, replies

**Goal (Week 1):** 10 pack follows, 50 individual account follows via the pack

---

## 🔄 Maintenance

**Monthly Review:**
- Add new high-quality accounts as they emerge
- Remove any accounts that go inactive or off-mission
- Update feed rules based on engagement patterns
- Consider splitting into specialized packs (OSINT-only, Fact-Check-only) once this one hits 50+ follows

**Signal Quality Checks:**
- Review accounts quarterly: Are they still posting high-quality verification content?
- Check domain verification status (re-verify if domains change)
- Monitor for policy violations or reputation issues

---

## 🎯 Why This Pack Works

1. **Domain Verification:** 7 of 15 accounts are domain-verified (immediate trust signal)
2. **Category Balance:** Fact-checking (27%), OSINT (33%), Media Literacy (13%), Tech Context (20%), Your Hub (7%)
3. **Geographic Diversity:** UK, US, International coverage
4. **Institutional + Individual:** Mix of orgs and practitioners
5. **Custom Feeds:** Pre-filtered signal so followers don't need to curate manually

---

## 📝 Starter Pack Copy (For Bluesky UI)

**Title:**
```
AntiClickbait—Trusted Sources
```

**Description (max 300 chars):**
```
Evidence-first fact-checking, OSINT, and observability. 15 verified accounts + 3 custom feeds for media literacy. No hype, just verifiable claims with sources. Curated by @resonai.bsky.social.
```

**Short URL to promote:**
```
bsky.app/starter-pack/[your-pack-id]
```

---

## 🚀 Next Steps After Publishing

1. **Announce in a thread:**
   ```
   [1/4] 🚀 Just published: AntiClickbait Starter Pack
   
   15 trusted sources for fact-checking, OSINT, and evidence-based tech.
   
   Link: [starter-pack-url]
   ```

2. **Cross-promote:**
   - Mention in your next hub update
   - Add to email signature
   - Share in relevant Bluesky communities

3. **Iterate:**
   - Monitor which accounts resonate most
   - Consider creating niche packs (e.g., "OSINT for Beginners", "UK Fact-Checkers")

---

**Ready to build!** Once you publish, drop the Starter Pack URL here and I'll help you draft the announcement thread. 🐾

