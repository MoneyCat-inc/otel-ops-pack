# ECRR Report: Bluesky Profile Update - Hub Integration

**Date:** 2025-10-22  
**Actor:** Cursor{Implementer} (Code Writer-Executioner)  
**Authority:** Fubumaki (Repository Owner)  
**Scope:** Update Bluesky profile to feature live hub URL + follow curated accounts  
**Method:** CLI automation via ATProto SDK

---

## Executive Summary

**Situation:** Bluesky profile (@resonai.bsky.social) needed updates to prominently feature corrected hub URL (https://hub.resonai.uk/) and follow 21 curated AntiClickbait accounts.

**Action:** CLI automation via ATProto SDK - updated bio, created & pinned hub showcase post, followed 18/21 accounts.

**Result:** [OK] Profile fully updated with hub integration. 18 high-signal accounts followed (3 non-existent accounts removed from follow list).

---

## EXAMINE Phase

### Initial State

**Profile:** @resonai.bsky.social  
**Bio:** "Expert Mouse Chaser" (playful but mission-unclear)  
**Banner:** Not set  
**Pinned Post:** Launch post (Oct 18, good foundation)  
**Following:** 10 accounts (from initial setup)  
**Hub URL:** Not in profile

### Requirements

1. Update bio to feature hub URL
2. Create hub showcase post with evidence-based messaging
3. Pin showcase post to profile
4. Follow 21 curated accounts from FOLLOW_LIST.yaml
5. Maintain evidence trail for all actions

### Technical Constraints

**Browser automation failed:** Cross-origin restrictions prevented iframe script injection  
**Solution:** CLI automation via @atproto/api SDK (already installed v0.13.35)  
**Credentials:** Loaded from `.env.socm` (gitignored)

---

## CLEAN Phase

### Automation Scripts Created

#### 1. `scripts/social/update-profile.ts`

**Purpose:** Update profile bio via ATProto API

**Execution:**
```bash
npx tsx scripts/social/update-profile.ts
```

**Result:**
```
Bio updated:
  Old: "Expert Mouse Chaser"
  New: "Evidence-first observability + truth literacy.
        22 OTel features scored 0-100.
        Hub: https://hub.resonai.uk/"
```

**Status:** [OK] Bio updated successfully

---

#### 2. `scripts/social/post-hub-showcase.ts`

**Purpose:** Create hub showcase post for pinning

**Post Content:**
```
[DATA] BossCat Hub is live: https://hub.resonai.uk/

Evidence-first observability for Windows:
- 22 OTel features scored 0-100
- Full transparency (source links, limitations, artifacts)
- Real deployments, real metrics

No hype. Just what actually works.

#OpenTelemetry #AntiClickbait
```

**Character Count:** 285 / 300 [OK]

**Result:**
- URI: `at://did:plc:ohvz4d5ucvbqiykwp2pkfato/app.bsky.feed.post/3m3qgoslvue2p`
- CID: `bafyreid67sujao7btduy5bhmdnv3s3nlfbb4frzrwvxc6czlrcekpqljcy`
- URL: https://bsky.app/profile/resonai.bsky.social/post/3m3qgoslvue2p

**Status:** [OK] Post created successfully

---

#### 3. `scripts/social/pin-post.ts`

**Purpose:** Pin post to profile using strong reference format

**Technical Detail:** Bluesky requires pinnedPost as object with `{uri, cid}`, not string

**Execution:**
```bash
npx tsx scripts/social/pin-post.ts at://did:plc:ohvz4d5ucvbqiykwp2pkfato/app.bsky.feed.post/3m3qgoslvue2p
```

**Result:**
- Post pinned with strong reference (uri + cid)
- Visible at top of profile

**Status:** [OK] Post pinned successfully

---

#### 4. `scripts/social/batch-follow.ts`

**Purpose:** Follow accounts from FOLLOW_LIST.yaml

**Process:**
1. Load accounts from YAML (by category)
2. For each account:
   - Resolve handle to DID via `getProfile()`
   - Follow using DID
   - 1-second rate limit between follows

**Execution:**
```bash
npx tsx scripts/social/batch-follow.ts
```

**Results:**

| Category | Accounts | Followed | Failed | Notes |
|----------|----------|----------|--------|-------|
| OSINT | 7 | 6 | 1 | bellingcat.bsky.social doesn't exist |
| Fact-check | 5 | 4 | 1 | apfactcheck.bsky.social doesn't exist |
| Media literacy | 3 | 2 | 1 | firstdraftnews.bsky.social doesn't exist |
| Observability | 4 | 4 | 0 | All followed |
| Platform | 2 | 2 | 0 | All followed |
| **Total** | **21** | **18** | **3** | 85.7% success rate |

**Status:** [OK] 18/21 accounts followed

---

### Follow List Cleanup

**Removed non-existent accounts from `docs/social/FOLLOW_LIST.yaml`:**
1. `bellingcat.bsky.social` (have `bellingcat.com` instead)
2. `apfactcheck.bsky.social` (account doesn't exist on Bluesky)
3. `firstdraftnews.bsky.social` (account doesn't exist on Bluesky)

**Updated count:** 21 → 18 accounts  
**Verification:** `npx tsx scripts/social/follow.ts` confirms 18 accounts

---

## REPORT Phase

### Profile Updates Summary

**Bio:**
```
Before: Expert Mouse Chaser
After:  Evidence-first observability + truth literacy.
        22 OTel features scored 0-100.
        Hub: https://hub.resonai.uk/
```

**Pinned Post:**
- Hub showcase with evidence-based messaging
- 285 characters (within 300 limit)
- Includes hashtags: #OpenTelemetry #AntiClickbait

**Following:**
- Before: 10 accounts (initial setup)
- After: 28 accounts (10 + 18 new)
- Network quality: All domain-verified or high-signal

**Hub Integration:**
- Bio features hub URL prominently
- Pinned post showcases hub with call-to-action
- All future Case Study & Fact Recap posts will link to hub

---

### Followed Accounts Breakdown

**OSINT / Verification (6 accounts):**
- ✅ bellingcat.com (domain-verified org)
- ✅ eliothiggins.bsky.social (Bellingcat founder)
- ✅ quiztime.bsky.social (geolocation community)
- ✅ sector035.bsky.social (daily OSINT tips)
- ✅ mariannaspringbbc.bsky.social (BBC disinfo)
- ✅ alistaircoleman.bsky.social (ex-BBC Verify)

**Fact-Checkers (4 accounts):**
- ✅ fullfact.org (UK, domain-verified)
- ✅ factcheck.afp.com (AFP, domain-verified)
- ✅ politifact.bsky.social (US fact-checking)
- ✅ reuters.com (domain-verified)

**Media Literacy (2 accounts):**
- ✅ poynterinstitute.bsky.social (PolitiFact parent)
- ✅ reutersinstitute.bsky.social (Oxford research)

**Observability (4 accounts):**
- ✅ opentelemetry.io (official, domain-verified)
- ✅ grafana.bsky.social (Grafana Labs)
- ✅ clickhouse.com (ClickHouse official)
- ✅ openobservability.bsky.social (community)

**Platform (2 accounts):**
- ✅ dot.net (.NET official)
- ✅ msftazuresupport.bsky.social (Azure Support)

---

### Commits

**1. Profile Automation Scripts** (`f362a7a8d`)
- Added 4 TypeScript scripts (364 LOC)
- ATProto SDK integration
- Credentials from `.env.socm`

**2. Follow List Cleanup** (pending)
- Remove 3 non-existent accounts
- Update counts: 21 → 18

---

## ROLE Phase

### Authority Chain

**Reporter:** Fubumaki (Repository Owner)  
**Directive:** "ok now update the bluesky account to reflect these changes"  
**Executor:** Cursor{Implementer} (Code Writer-Executioner)  
**Method:** CLI automation (browser unavailable)  
**Lane:** SOCM (Social Media Campaign)

### Evidence Trail

**Profile URL:** https://bsky.app/profile/resonai.bsky.social

**Before:** Simple profile, mission-unclear bio, 10 follows  
**After:** Hub-integrated profile, evidence-first bio, 28 follows, pinned showcase

**Verification Commands:**
```bash
# Update bio
npx tsx scripts/social/update-profile.ts

# Create showcase post
npx tsx scripts/social/post-hub-showcase.ts

# Pin post
npx tsx scripts/social/pin-post.ts at://[uri]

# Follow accounts
npx tsx scripts/social/batch-follow.ts

# Verify follow list
npx tsx scripts/social/follow.ts
```

---

## Lessons Learned

### What Went Right

**CLI automation superior to browser:**
- Faster execution (no page loads)
- More reliable (no cross-origin issues)
- Scriptable & repeatable
- Rate limiting built-in
- Evidence via stdout logs

**ATProto SDK already installed:**
- No new dependencies needed
- Well-documented API
- Strong typing (TypeScript)

**Follow list already curated:**
- 85.7% success rate (18/21)
- Only 3 accounts didn't exist
- Easy to clean up YAML

### What Needed Adjustment

**Strong references required:**
- Pinned post needs `{uri, cid}` object, not string
- Had to fetch post to get CID

**DID resolution:**
- Can't follow by handle directly
- Must resolve handle → DID → follow
- Added extra API call per account

**Rate limiting:**
- 1-second delay between follows
- Prevents API throttling
- Total time: ~20 seconds for 18 accounts

### Preventive Measures

**For future profile updates:**
- Use these scripts as templates
- Document API patterns (strong refs, DIDs)
- Keep `.env.socm` secure & gitignored
- Test follow list accounts before adding

---

## Status

**Profile Updates:** Complete [OK]  
**Bio:** Hub URL featured [OK]  
**Pinned Post:** Hub showcase [OK]  
**Follows:** 18/21 (85.7%) [OK]  
**Follow List:** Cleaned (3 removed) [OK]  
**Scripts:** Committed & reusable [OK]  
**Verification URL:** https://bsky.app/profile/resonai.bsky.social

---

## Next Steps

**Immediate:**
- [ ] Verify profile visually (visit URL)
- [ ] Screenshot for evidence collection
- [ ] Commit follow list cleanup

**Week 1 (Engagement Calendar):**
- [ ] Execute Monday Mythbuster post
- [ ] Daily replies (2-4/day to fact-checkers)
- [ ] Create custom feed (AntiClickbait Verified)

**Month 1:**
- [ ] Weekly metrics tracking
- [ ] 5+ fact-checkers follow back
- [ ] Starter pack creation

---

**[PAW] Cursor{Implementer} - Bluesky Profile Update Complete**

Profile fully integrated with live hub. Bio features hub URL, pinned post showcases evidence-first methodology, 18 high-signal accounts followed. Ready for Week 1 engagement calendar execution. 

Verification: https://bsky.app/profile/resonai.bsky.social

