# Custom Feed Configuration - AntiClickbait Feeds
**Technical Rules for Bluesky Custom Feeds**

---

## 🎯 Feed Strategy

Create 3 complementary feeds that surface different aspects of the AntiClickbait mission:
1. **Fact-Check Firehose** - Official org posts + citations
2. **OSINT + Verification** - Practitioner threads + methods
3. **AntiClickbait HQ** - Your content + community engagement

---

## 📡 Feed 1: Fact-Check Firehose

**Feed URI:** `at://did:plc:[your-did]/app.bsky.feed.generator/factcheck-firehose`  
**Display Name:** "Fact-Check Firehose"  
**Description:** "Real-time fact-checks from verified orgs (Full Fact, AFP, PolitiFact, Reuters) + community posts citing them."

### SkyFeed Rules (No-Code)

**Simple Mode:**
```
Include posts if ANY of these match:

1. Author is @fullfact.org
2. Author is @factcheck.afp.com
3. Author is @politifact.bsky.social
4. Author is @reuters.com AND text contains "fact check"
5. Post quotes any of the above accounts
6. Hashtag is #FactCheck
7. Hashtag is #Debunk
```

**Advanced Mode (JSON-like):**
```json
{
  "logic": "OR",
  "rules": [
    {"type": "author", "value": "fullfact.org"},
    {"type": "author", "value": "factcheck.afp.com"},
    {"type": "author", "value": "politifact.bsky.social"},
    {
      "logic": "AND",
      "rules": [
        {"type": "author", "value": "reuters.com"},
        {"type": "text", "contains": ["fact check", "debunk", "false claim"]}
      ]
    },
    {"type": "quoted_post_author", "in": ["fullfact.org", "factcheck.afp.com", "politifact.bsky.social"]},
    {"type": "hashtag", "value": "FactCheck"},
    {"type": "hashtag", "value": "Debunk"}
  ]
}
```

### Feed Generator Code (TypeScript)

```typescript
// src/algos/factcheck-firehose.ts
import { QueryParams } from '../lexicon/types/app/bsky/feed/getFeedSkeleton'
import { AppContext } from '../config'

const FACT_CHECKER_DIDS = [
  'did:plc:27ovyakfahyrvm247jsfdkon', // fullfact.org
  'did:plc:dqa3uws2xsxnwtueag5zw6qk', // factcheck.afp.com
  'did:plc:hhteydoawq45y4nvmeipl7zy', // politifact.bsky.social
  'did:plc:jbvnehrrdqoulco4rf5gxg5r', // reuters.com
]

export const handler = async (ctx: AppContext, params: QueryParams) => {
  const posts = await ctx.db
    .selectFrom('post')
    .where((eb) =>
      eb.or([
        eb('author', 'in', FACT_CHECKER_DIDS),
        eb('quotedPost.author', 'in', FACT_CHECKER_DIDS),
        eb('text', 'like', '%#FactCheck%'),
        eb('text', 'like', '%#Debunk%'),
      ])
    )
    .orderBy('indexedAt', 'desc')
    .limit(params.limit ?? 50)
    .execute()

  return {
    cursor: posts[posts.length - 1]?.indexedAt,
    feed: posts.map((post) => ({ post: post.uri })),
  }
}
```

---

## 🔍 Feed 2: OSINT + Verification

**Feed URI:** `at://did:plc:[your-did]/app.bsky.feed.generator/osint-verification`  
**Display Name:** "OSINT + Verification"  
**Description:** "Media forensics, geolocation, and verification threads from Bellingcat, Sector035, and the OSINT community."

### SkyFeed Rules (No-Code)

**Simple Mode:**
```
Include posts if ANY of these match:

1. Author is @bellingcat.com
2. Author is @eliothiggins.bsky.social
3. Author is @sector035.bsky.social
4. Author is @mariannaspringbbc.bsky.social
5. Author is @alistaircoleman.bsky.social
6. Author is @quiztime.bsky.social
7. Hashtag is #OSINT
8. Text contains "verify" OR "verification" OR "geolocation"
9. Text contains "media forensics" OR "fact check"
10. Post quotes any OSINT account above
```

### Feed Generator Code (TypeScript)

```typescript
// src/algos/osint-verification.ts
import { QueryParams } from '../lexicon/types/app/bsky/feed/getFeedSkeleton'
import { AppContext } from '../config'

const OSINT_DIDS = [
  'did:plc:sb54dpdfefflykmf5bcfvr7t', // bellingcat.com
  'did:plc:2whlowi5jjjqrdrrj4lxh2lx', // eliothiggins.bsky.social
  'did:plc:r4zn5hi2hj24d3y3mj5my2id', // sector035.bsky.social
  'did:plc:e2zjxok622zf3zydlguqhd4y', // mariannaspringbbc.bsky.social
  'did:plc:j45cwydngasqcktrd4cdi6tx', // alistaircoleman.bsky.social
  'did:plc:g2r4agobasw676ilfmszxgft', // quiztime.bsky.social
]

const KEYWORDS = [
  'verify', 'verification', 'verified',
  'geolocation', 'geolocate', 'geolocated',
  'media forensics', 'forensic analysis',
  'fact check', 'debunk', 'OSINT'
]

export const handler = async (ctx: AppContext, params: QueryParams) => {
  const keywordPattern = KEYWORDS.map(k => `%${k}%`).join('|')
  
  const posts = await ctx.db
    .selectFrom('post')
    .where((eb) =>
      eb.or([
        eb('author', 'in', OSINT_DIDS),
        eb('quotedPost.author', 'in', OSINT_DIDS),
        eb('text', 'like', '%#OSINT%'),
        eb('text', 'regexp', keywordPattern),
      ])
    )
    .orderBy('indexedAt', 'desc')
    .limit(params.limit ?? 50)
    .execute()

  return {
    cursor: posts[posts.length - 1]?.indexedAt,
    feed: posts.map((post) => ({ post: post.uri })),
  }
}
```

---

## 🏠 Feed 3: AntiClickbait HQ

**Feed URI:** `at://did:plc:[your-did]/app.bsky.feed.generator/anticlickbait-hq`  
**Display Name:** "AntiClickbait HQ"  
**Description:** "BossCat's evidence-first posts + community engagement with #AntiClickbait and transparent observability."

### SkyFeed Rules (No-Code)

**Simple Mode:**
```
Include posts if ANY of these match:

1. Author is @resonai.bsky.social
2. Hashtag is #AntiClickbait
3. Text contains "hub.resonai.uk"
4. Post quotes @resonai.bsky.social
5. Hashtag is #OpenTelemetry AND text contains "evidence"
6. Hashtag is #OpenTelemetry AND text contains "transparency"
7. Text mentions @resonai.bsky.social (replies to your posts)
```

### Feed Generator Code (TypeScript)

```typescript
// src/algos/anticlickbait-hq.ts
import { QueryParams } from '../lexicon/types/app/bsky/feed/getFeedSkeleton'
import { AppContext } from '../config'

const BOSSCAT_DID = 'did:plc:[your-did-here]' // Replace with your actual DID

export const handler = async (ctx: AppContext, params: QueryParams) => {
  const posts = await ctx.db
    .selectFrom('post')
    .where((eb) =>
      eb.or([
        eb('author', '=', BOSSCAT_DID),
        eb('text', 'like', '%#AntiClickbait%'),
        eb('text', 'like', '%hub.resonai.uk%'),
        eb('quotedPost.author', '=', BOSSCAT_DID),
        eb.and([
          eb('text', 'like', '%#OpenTelemetry%'),
          eb.or([
            eb('text', 'like', '%evidence%'),
            eb('text', 'like', '%transparency%'),
          ])
        ]),
        eb('replyParent.author', '=', BOSSCAT_DID),
      ])
    )
    .orderBy('indexedAt', 'desc')
    .limit(params.limit ?? 50)
    .execute()

  return {
    cursor: posts[posts.length - 1]?.indexedAt,
    feed: posts.map((post) => ({ post: post.uri })),
  }
}
```

---

## 🛠️ Deployment Options

### Option 1: SkyFeed (No-Code, Fastest)

1. Go to [skyfeed.app](https://skyfeed.app/)
2. Login with Bluesky
3. Create new feed → paste rules from "Simple Mode" above
4. Publish → get feed URI
5. Add to Starter Pack

**Pros:** 5 minutes per feed, no coding  
**Cons:** Limited customization, dependent on SkyFeed service

### Option 2: Official Feed Generator (Self-Hosted)

1. Clone repo:
   ```bash
   git clone https://github.com/bluesky-social/feed-generator.git
   cd feed-generator
   npm install
   ```

2. Add algo files:
   ```
   src/algos/
   ├── factcheck-firehose.ts
   ├── osint-verification.ts
   └── anticlickbait-hq.ts
   ```

3. Register in `src/algos/index.ts`:
   ```typescript
   import factcheckFirehose from './factcheck-firehose'
   import osintVerification from './osint-verification'
   import anticlickbaitHq from './anticlickbait-hq'

   export default {
     'factcheck-firehose': factcheckFirehose,
     'osint-verification': osintVerification,
     'anticlickbait-hq': anticlickbaitHq,
   }
   ```

4. Deploy to Vercel/Railway/Fly.io
5. Publish feeds:
   ```bash
   yarn publishFeed factcheck-firehose
   yarn publishFeed osint-verification
   yarn publishFeed anticlickbait-hq
   ```

**Pros:** Full control, custom logic  
**Cons:** Requires dev setup, hosting costs

### Option 3: Hybrid

- Start with SkyFeed for quick launch (Week 1)
- Migrate to self-hosted after validating engagement (Month 2+)

---

## 📊 Performance Tuning

### Engagement Optimization

**Track these metrics per feed:**
- Subscription count (how many users added the feed)
- Posts per day (volume)
- Engagement rate (likes/reposts per post in feed)
- Click-through to profiles (use UTM params if linking externally)

**Adjust rules based on data:**
- If "Fact-Check Firehose" is too noisy → add minimum like threshold
- If "OSINT + Verification" is too quiet → broaden keyword set
- If "AntiClickbait HQ" feels too self-promotional → include more community quotes

### Quality Filters

Add these to reduce noise (SkyFeed or code):
```
Exclude if:
- Post has < 3 characters
- Author has < 10 followers (spam filter)
- Post contains promotional keywords ("subscribe", "follow for follow")
- Language is not English (optional, depends on audience)
```

---

## 🚀 Launch Sequence

**Day 1 (Today):**
1. Create all 3 feeds in SkyFeed (30 minutes total)
2. Test each feed by subscribing yourself
3. Screenshot feeds for evidence

**Day 2:**
1. Add feeds to Starter Pack
2. Publish Starter Pack
3. Update pinned post with Starter Pack link

**Week 1:**
1. Monitor feed engagement
2. Adjust rules if volume is too high/low
3. Promote feeds in replies to popular posts

---

## 📝 Feed Metadata Summary

| Feed | Purpose | Volume/Day | Target Audience |
|------|---------|------------|-----------------|
| **Fact-Check Firehose** | Official debunks + citations | 15-30 posts | Journalists, researchers |
| **OSINT + Verification** | Methods + practitioner threads | 10-25 posts | OSINT learners, verification enthusiasts |
| **AntiClickbait HQ** | Community + your content | 5-15 posts | Your followers, engagement hub |

---

**Ready to build!** Let me know if you want:
- [ ] SkyFeed rule exports (JSON for direct import)
- [ ] Full feed-generator codebase setup
- [ ] Announcement thread drafts for each feed

🐾

