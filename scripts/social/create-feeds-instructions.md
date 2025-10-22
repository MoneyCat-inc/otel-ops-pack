# Create 3 Custom Feeds - Quick Instructions
**Time: 20 minutes via SkyFeed UI**

---

## 🔐 Step 1: Log into SkyFeed (2 min)

1. Go to: https://skyfeed.app/
2. Fill in login:
   - **Service:** bsky.social (pre-filled)
   - **Username:** resonai.bsky.social
   - **App Password:** [from .env.socm]
3. Click **Continue**

---

## 📡 Step 2: Create Feed 1 - Fact-Check Firehose (6 min)

1. Click **"Create Feed"** or **"Feed Builder"**
2. **Name:** `Fact-Check Firehose (Trusted)`
3. **Description:** `High-signal posts from vetted fact-checkers and newswires; quotes get a boost.`

### Rules (Add these in SkyFeed builder):

**Include - Authors (add all):**
- @fullfact.org
- @factcheck.afp.com
- @politifact.bsky.social
- @reuters.com

**Include - Text Contains (any of these):**
- fact check
- debunk
- misleading
- correction
- false claim

**Include - Hashtags:**
- #FactCheck
- #Debunk

**Exclude - Text Contains:**
- satire
- parody

**Boost:**
- Quote-posts: +2.0 (or +200% if percentage-based)

4. Click **Publish** or **Save**
5. Copy the feed URL (e.g., `at://did:plc:.../app.bsky.feed.generator/...`)

---

## 🔍 Step 3: Create Feed 2 - OSINT + Verification (6 min)

1. **Create Feed** → New
2. **Name:** `OSINT + Verification`
3. **Description:** `Reverse image, geolocation, EXIF/metadata, and method threads.`

### Rules:

**Include - Authors:**
- @bellingcat.com
- @eliothiggins.bsky.social
- @sector035.bsky.social
- @mariannaspringbbc.bsky.social

**Include - Text Contains:**
- reverse image
- exif
- metadata
- geolocate
- osint
- verify
- geolocation

**Include - Hashtags:**
- #OSINT
- #Verification

**Boost:**
- Posts with method terms: +1.2

4. **Publish** → Copy feed URL

---

## 🏠 Step 4: Create Feed 3 - AntiClickbait HQ (6 min)

1. **Create Feed** → New
2. **Name:** `AntiClickbait HQ (Quotes Only)`
3. **Description:** `Our posts + partners when adding context (quotes only).`

### Rules:

**Include - Authors:**
- @resonai.bsky.social

**Include - Text Contains:**
- #AntiClickbait
- context
- sources
- needs context

**Include - Hashtags:**
- #AntiClickbait

**Filter:**
- ✅ **Quote-posts only** (check this option if available)

**Boost:**
- Quote-posts: +3.0

4. **Publish** → Copy feed URL

---

## 📋 Step 5: Add Feeds to Starter Pack (5 min)

1. Go to your Starter Pack: https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t
2. Click **"Edit"** or **"..."** menu → **"Edit starter pack"**
3. Navigate to **"Choose Feeds"** step
4. Search for your 3 feeds by name:
   - Fact-Check Firehose (Trusted)
   - OSINT + Verification
   - AntiClickbait HQ (Quotes Only)
5. Check all 3 boxes
6. Click **Save** or **Update**

---

## ✅ Verification

After completing all steps:

- [ ] All 3 feeds visible at https://bsky.app/feeds (search your feed names)
- [ ] Starter Pack shows "15 accounts + 3 feeds"
- [ ] Each feed has a unique URI you can share
- [ ] Feed content populates correctly (test by subscribing)

---

## 🚀 Alternative: Automated Feed Creation

If you prefer code over UI, I can create a feed-generator deployment:

```bash
# Option: Self-hosted feeds (30 min setup)
git clone https://github.com/bluesky-social/feed-generator.git custom-feeds
cd custom-feeds
npm install
# ... add our 3 feed algos
# ... deploy to Vercel
npx bluesky-feed publish
```

**Let me know if you want the automated approach instead!**

---

**Current Status:**
- ✅ Phase 1: Starter Pack published
- ⏸️ Phase 2: Feeds pending (manual SkyFeed login)
- ✅ Phase 3: Announcement posted
- ✅ Phase 4: Pinned post updated
- ⏸️ Phase 5: Week-1 scheduling pending

**Time So Far:** ~20 minutes (70 min under budget)

