# Bluesky Profile Update Checklist - Hub Link Integration

**Date:** 2025-10-21  
**Authority:** Fubumaki  
**Actor:** Manual execution (browser automation unavailable)  
**Status:** [OK] Last synced 2026-06-12 via `npx tsx scripts/social/sync-bsky-profile.ts`

---

## Executive Summary

Update Bluesky profile (@resonai.bsky.social) to prominently feature the live hub URL and optimize for AntiClickbait mission discovery.

**Current State:** Basic profile with "Expert Mouse Chaser" bio  
**Target State:** Mission-focused profile with hub integration  
**Estimated Time:** 10 minutes

---

## 1. Bio Update (PRIORITY 1)

### Current Bio
```
Expert Mouse Chaser
```

### Recommended Bio (Option A - Mission-focused)
```
Evidence-first observability + truth literacy.
22 OTel features scored 0-100.
Hub: https://hub.resonai.uk/
```
**Character count:** 105 / 256 [OK]

### Alternative Bio (Option B - Shorter)
```
Tracking clickbait trends + truth literacy.
Windows • OpenTelemetry • Evidence-based.
https://hub.resonai.uk/
```
**Character count:** 110 / 256 [OK]

### Alternative Bio (Option C - Developer-focused)
```
BossCat OTel observability pack for Windows.
Evidence-first transparency scoring.
Hub: https://hub.resonai.uk/
```
**Character count:** 106 / 256 [OK]

**Action Steps:**
1. Go to https://bsky.app/settings
2. Click "Edit Profile"
3. Update "Bio" field with chosen option
4. Click "Save"

---

## 2. Banner Upload (PRIORITY 2)

### Current State
- No custom banner (default gradient)

### Recommended Action
**Option A:** Create banner with hub branding
- Dimensions: 3000 x 1000 px (or 1500 x 500 px minimum)
- Include: "BossCat Hub" text + hub.resonai.uk URL
- Style: High contrast, readable at small sizes
- Colors: Match hub aesthetic (dark theme with teal accent)

**Option B:** Temporary text banner
- Use Canva or similar: https://www.canva.com/
- Template: "Twitter Header" (works for Bluesky)
- Text: "Evidence-First Observability • hub.resonai.uk"
- Font: Sans-serif, bold, high contrast

**Action Steps:**
1. Create banner image (3000 x 1000 px)
2. Go to https://bsky.app/settings
3. Click "Edit Profile"
4. Click "Change banner" → Upload image
5. Position and crop as needed
6. Click "Save"

**Placeholder if no design time:**
- Skip for now
- Add to Week 2 tasks in engagement calendar

---

## 3. Pinned Post Update (PRIORITY 3)

### Current Pinned Post
- Launch post (Oct 18, 3:09 AM)
- Good foundation, but could be updated with hub link

### Recommended Action
**Option A:** Update existing pin (add reply with hub link)
- Reply to current pinned post
- Text: "Hub is now live: https://hub.resonai.uk/ — 22 features, evidence-scored 0-100. Full transparency."
- Pin the REPLY instead of main post

**Option B:** Create new pinned post (hub showcase)
```
[DATA] BossCat Hub is live: https://hub.resonai.uk/

Evidence-first observability for Windows:
- 22 OTel features scored 0-100
- Full transparency (source links, limitations, artifacts)
- Real deployments, real metrics

No hype. Just what actually works.

#OpenTelemetry #AntiClickbait
```
**Character count:** 281 / 300 [OK]

**Action Steps (Option B):**
1. Go to https://bsky.app/
2. Click "New post" (+ button)
3. Paste text above
4. Post
5. Click the 3-dot menu on the new post
6. Select "Pin to profile"

---

## 4. Profile Links Section (If Available)

**Note:** Bluesky may have added a "Links" section to profiles. Check settings.

If available:
1. Go to https://bsky.app/settings → Edit Profile
2. Look for "Links" or "Website" field
3. Add: https://hub.resonai.uk/
4. Save

---

## 5. Posted Content Verification (NO ACTION NEEDED)

### Status Check
- [x] Days 1-3 thread content: No hub links (correct as-is)
- [x] Website intro post (Oct 21, 11:35 AM): Already has CORRECT link `https://hub.resonai.uk/`
- [x] No correction post needed

**Verified:** All posted Bluesky content already points to correct hub URL.

---

## 6. Future Posts - Hub Link Integration

### When to Include Hub Link

**Always include in:**
- Case Study posts (Wednesdays)
- Fact Recap posts (Fridays)
- Any post referencing AntiClickbait methodology

**Standard footer for hub posts:**
```
Full transparency: https://hub.resonai.uk/
```

**Example integration:**
```
[Original post content about OTel feature]

Evidence + artifacts in our hub: https://hub.resonai.uk/

#OpenTelemetry
```

---

## 7. Domain Verification (ADVANCED - Optional)

### Upgrade Handle to Domain-Verified

**Current:** `@resonai.bsky.social`  
**Target:** `@resonai.io` or `@hub.resonai.uk`

**Benefits:**
- Blue verification checkmark
- Increased trust/authority
- Better discovery in searches

**Requirements:**
- Control over DNS for domain
- Add TXT record: `_atproto.resonai.io` with DID value

**Steps:**
1. Go to https://bsky.app/settings
2. Click "Change Handle"
3. Select "I have my own domain"
4. Follow instructions to add DNS TXT record
5. Verify domain
6. Handle updates automatically

**DNS Record Example:**
```
Type: TXT
Name: _atproto
Value: did:plc:ohvz4d5ucvbqiykwp2pkfato
TTL: 3600
```

**Reference:** https://bsky.social/about/blog/4-28-2023-domain-handle-tutorial

**Note:** This requires access to DNS management (Cloudflare for resonai.uk)

---

## 8. Quick Reference Card

```
PROFILE UPDATE CHECKLIST:
[ ] 1. Update bio with hub URL (5 min)
[ ] 2. Upload custom banner (15 min) OR skip to Week 2
[ ] 3. Pin new hub showcase post (5 min)
[ ] 4. Add website link if profile links available (2 min)
[ ] 5. Consider domain verification (30 min setup)

VERIFICATION:
[ ] Visit @resonai.bsky.social and confirm changes
[ ] Test hub link works from profile
[ ] Screenshot updated profile for records
```

---

## 9. Manual Execution Guide

### Step-by-Step (10 minutes total)

**Step 1: Bio Update (3 minutes)**
1. Open https://bsky.app/settings in browser
2. Log in if needed (credentials in `.env.socm`)
3. Click "Edit Profile"
4. Update "Bio" field with Option A text:
   ```
   Evidence-first observability + truth literacy.
   22 OTel features scored 0-100.
   Hub: https://hub.resonai.uk/
   ```
5. Click "Save"

**Step 2: New Pinned Post (5 minutes)**
1. Open https://bsky.app/
2. Click "New post" (+ icon, top right)
3. Paste hub showcase text (see Option B above)
4. Click "Post"
5. Click 3-dot menu on new post → "Pin to profile"

**Step 3: Verification (2 minutes)**
1. Visit https://bsky.app/profile/resonai.bsky.social
2. Confirm bio shows hub URL
3. Confirm pinned post shows hub showcase
4. Click hub link to verify it loads correctly

---

## 10. Evidence Collection

After completing manual updates, collect evidence:

**Screenshots needed:**
1. Updated profile page (bio + pinned post visible)
2. Bio edit screen (showing new text)
3. Pinned post with hub URL
4. Hub link click-through (hub.resonai.uk loading)

**Save to:** `docs/social/evidence/bluesky-profile-update-20251021/`

**Document in ECRR report:** Create `ECRR_BLUESKY_PROFILE_UPDATE_20251021.md`

---

## 11. Integration with Engagement Calendar

Once profile is updated, refer to:
- **Week 1 Foundation:** `docs/social/BLUESKY_ENGAGEMENT_CALENDAR.md` (lines 20-46)
- **Follow Strategy:** `docs/social/ANTICLICKBAIT_FOLLOW_STRATEGY.md`
- **Daily Templates:** Use hub URL in Case Study and Fact Recap posts

**Next steps after profile update:**
1. Execute Week 1 kickoff (7 posts)
2. Manual follow of 21 curated accounts
3. Daily engagement (2-4 replies)
4. Weekly metrics tracking

---

## 12. Status Tracking

**Current Status:** [PENDING] Manual execution required  
**Owner:** Fubumaki  
**Estimated Completion:** 10 minutes  
**Dependencies:** None (browser access sufficient)

**Completion Checklist:**
```
[ ] Bio updated with hub URL
[ ] Banner uploaded (or deferred to Week 2)
[ ] New hub showcase post pinned
[ ] Profile links added (if available)
[ ] Evidence screenshots collected
[ ] ECRR report created (optional)
[ ] Profile URL shared in docs: @resonai.bsky.social
```

---

## 13. Troubleshooting

**Issue: Can't log in to Bluesky**
- Solution: Run `.\scripts\social\set-credentials.ps1` to verify `.env.socm`
- Credentials: `@resonai.bsky.social` + app password from `.env.socm`

**Issue: Bio too long**
- Solution: Use Alternative Bio Option B (110 chars) or Option C (106 chars)
- Limit: 256 characters

**Issue: Can't pin post**
- Solution: Unpin current post first (3-dot menu → "Unpin from profile")
- Only 1 pinned post allowed at a time

**Issue: Hub link not clickable in bio**
- Solution: Bluesky auto-links URLs starting with http:// or https://
- Verify full URL is present: `https://hub.resonai.uk/`

---

## 14. Automation Future (Milestone B)

When ATProto API integration is added:

**Script:** `scripts/social/profile-update.ts`
```typescript
// Update profile via API
await agent.upsertProfile({
  displayName: "BossCat",
  description: "Evidence-first observability + truth literacy.\n22 OTel features scored 0-100.\nHub: https://hub.resonai.uk/"
})
```

**Until then:** Manual execution via browser (this checklist)

---

**[PAW] Cursor{Implementer} - Profile Update Checklist Ready**

**Status:** Manual execution guide complete  
**Priority:** Bio update (3 min) + pinned post (5 min) = 8 minutes total  
**Evidence:** Screenshot profile after update  
**Next:** Execute checklist, then proceed with Week 1 engagement calendar

