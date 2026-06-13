# Phase 2: Create Custom Feeds - Manual Instructions
**Time: 20 minutes | Tool: SkyFeed**

**Why Manual:** SkyFeed UI has minimal accessibility markup, making browser automation unreliable. Manual execution is faster and more reliable for this step.

---

## 🔐 **Step 1: Login to SkyFeed (2 min)**

1. **Open:** https://skyfeed.app/
2. **Fill Form:**
   - **Service:** `bsky.social` (pre-filled)
   - **Username:** `resonai.bsky.social`
   - **App Password:** from `.env.socm` (`BSKY_APP_PASSWORD`)
3. **Click:** "Continue"
4. **Result:** You'll be logged into SkyFeed dashboard

---

## 📡 **Step 2: Create Feed 1 - Fact-Check Firehose (6 min)**

### Basic Info
1. Click **"Create Feed"** or **"New Feed"** button
2. **Name:** `Fact-Check Firehose (Trusted)`
3. **Description:** `High-signal posts from vetted fact-checkers and newswires; quotes get a boost.`

### Rules Configuration

**Include - Authors (add each separately):**
- `fullfact.org`
- `factcheck.afp.com`
- `politifact.bsky.social`
- `reuters.com`

**Include - Text Contains (any match):**
- `fact check`
- `debunk`
- `misleading`
- `correction`
- `false claim`

**Include - Hashtags:**
- `#FactCheck`
- `#Debunk`

**Exclude - Text Contains:**
- `satire`
- `parody`

**Boost Settings:**
- **Quote-posts:** `+2.0` (or `+200%` if percentage-based)

### Publish
1. Click **"Save"** or **"Publish"**
2. **Copy the feed URL** (e.g., `at://did:plc:.../app.bsky.feed.generator/factcheck-firehose`)
3. Save this URL - you'll need it to add to Starter Pack

---

## 🔍 **Step 3: Create Feed 2 - OSINT + Verification (6 min)**

### Basic Info
1. Click **"Create Feed"** or **"New Feed"**
2. **Name:** `OSINT + Verification`
3. **Description:** `Reverse image, geolocation, EXIF/metadata, and method threads.`

### Rules Configuration

**Include - Authors:**
- `bellingcat.com`
- `eliothiggins.bsky.social`
- `sector035.bsky.social`
- `alistaircoleman.bsky.social`

**Include - Text Contains (any match):**
- `reverse image`
- `exif`
- `metadata`
- `geolocate`
- `osint`
- `verify`
- `geolocation`

**Include - Hashtags:**
- `#OSINT`
- `#Verification`

**Boost Settings:**
- **Posts with method terms:** `+1.2` (or `+120%`)

### Publish
1. **Save** or **Publish**
2. **Copy the feed URL**
3. Save for later

---

## 🏠 **Step 4: Create Feed 3 - AntiClickbait HQ (6 min)**

### Basic Info
1. Click **"Create Feed"** or **"New Feed"**
2. **Name:** `AntiClickbait HQ (Quotes Only)`
3. **Description:** `Our posts + partners when adding context (quotes only).`

### Rules Configuration

**Include - Authors:**
- `resonai.bsky.social`

**Include - Text Contains (any match):**
- `#AntiClickbait`
- `context`
- `sources`
- `needs context`

**Include - Hashtags:**
- `#AntiClickbait`

**Filter:**
- ✅ **Quote-posts only** (enable this filter if available)

**Boost Settings:**
- **Quote-posts:** `+3.0` (or `+300%`)

### Publish
1. **Save** or **Publish**
2. **Copy the feed URL**
3. You now have all 3 feed URLs!

---

## 📦 **Step 5: Add Feeds to Starter Pack (5 min)**

1. **Open your Starter Pack:** https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t
2. **Click:** "..." menu or "Edit" button
3. **Navigate to:** "Choose Feeds" or "Add Feeds" section
4. **Add your 3 feeds:**
   - Search for: "Fact-Check Firehose"
   - Search for: "OSINT + Verification"
   - Search for: "AntiClickbait HQ"
5. **Check all 3 boxes**
6. **Click:** "Save" or "Update"

**Result:** Starter Pack now shows "15 accounts + 3 feeds"

---

## ✅ **Verification Checklist**

After completing all steps:

- [ ] All 3 feeds visible at https://bsky.app/feeds (search by name)
- [ ] Each feed has content populating correctly
- [ ] Starter Pack updated to show "15 accounts + 3 feeds"
- [ ] Feed URLs saved for future reference
- [ ] Feeds are public and searchable

---

## 📝 **Feed URLs to Document**

Once created, save these URLs to `docs/social/CUSTOM_FEEDS_PUBLISHED.md`:

```markdown
# Custom Feeds Published

## Feed 1: Fact-Check Firehose (Trusted)
**URL:** [paste URL here]
**URI:** at://did:plc:[your-did]/app.bsky.feed.generator/[feed-id]

## Feed 2: OSINT + Verification
**URL:** [paste URL here]
**URI:** at://did:plc:[your-did]/app.bsky.feed.generator/[feed-id]

## Feed 3: AntiClickbait HQ (Quotes Only)
**URL:** [paste URL here]
**URI:** at://did:plc:[your-did]/app.bsky.feed.generator/[feed-id]
```

---

## 🚨 **Troubleshooting**

**Issue:** Feed doesn't populate with content  
**Fix:** Check that author handles are correct (some may need verification)

**Issue:** Too much noise in feed  
**Fix:** Add exclude terms or tighten keyword matching

**Issue:** Feed not appearing in search  
**Fix:** May take a few minutes to index; refresh and try again

**Issue:** Can't find "Quote-posts only" filter  
**Fix:** Use boost instead: set quote-posts to +5.0 to heavily favor them

---

## ⏱️ **Time Estimate**

- Login: 2 min
- Feed 1: 6 min
- Feed 2: 6 min
- Feed 3: 6 min
- Add to Pack: 5 min
- **Total: ~25 minutes**

---

## 🎯 **After Completion**

Post feed announcements (optional):
```
📡 New feed: Fact-Check Firehose
Trusted debunks & corrections from verified orgs.
Subscribe in Feeds; feedback welcome.
```

Update pinned post to mention feeds (optional):
```
🧩 AntiClickbait — calm, evidence-first media literacy.

3 custom feeds + 15 trusted sources in our Starter Pack.
Reply "CHECKLIST" for our 60-sec verification workflow.

https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t
```

---

**Status:** Instructions ready. Open SkyFeed and follow these steps to complete Phase 2!

**Estimated completion time:** 20-25 minutes from start to finish.

