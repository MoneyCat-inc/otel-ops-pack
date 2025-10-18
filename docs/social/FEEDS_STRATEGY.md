# 🦋 Bluesky Feeds Strategy

**Account**: @resonai.bsky.social  
**Date**: 2025-10-18  
**Purpose**: Discovery and engagement optimization

---

## 📰 What Are Feeds?

**Bluesky Feeds** are algorithmic timelines created by users or the community. Unlike Twitter's single algorithm, Bluesky lets you:
- Subscribe to multiple feeds
- Create custom feeds (code-based or no-code)
- Switch between feeds easily
- No ads, no manipulation

**Reference**: [The Verge - Custom Feeds](https://www.theverge.com/2023/5/26/23739174/bluesky-custom-feeds-algorithms-twitter-alternative)

---

## 🎯 Default Feeds (Built-In)

### **Essential Feeds to Use**

**1. Discover** (Default)
- Bluesky's main algorithmic feed
- Mix of popular + trending + personalized
- Good for general discovery

**2. Following** (Chronological)
- Pure chronological feed of accounts you follow
- No algorithm, no filtering
- Best for staying current with your network

**3. What's Hot** (Trending)
- Popular posts across Bluesky
- Updated frequently
- Good for finding trending topics

**4. Popular With Friends** (Social Graph)
- Posts popular among people you follow
- Network-based discovery
- Helps find quality content

**Reference**: [The Verge - Trending Features](https://www.theverge.com/2024/12/26/24329549/bluesky-trending-features)

---

## 🔍 Recommended Feeds for Resonai

### **Week 1: Subscribe to These**

**Official Feeds** (In-app):
- ✅ "Discover" - General discovery
- ✅ "Following" - Chronological timeline
- ✅ "What's Hot" - Trending content
- ✅ "Popular With Friends" - Social graph discovery

**Community Feeds** (Search for these):
- 🔍 "Tech Feed" - Technology news and discussions
- 🔍 "DevOps" - DevOps community feed
- 🔍 "Open Source" - OSS project updates
- 🔍 "Science" - Technical/scientific content

**How to Find**:
- Click "Feeds" in left sidebar
- Search for feed names
- Click "+" to subscribe

---

## 🛠️ Custom Feed Options

### **No-Code: SkyFeed Builder**

**URL**: https://skyfeed.app

**Capabilities**:
- Build feeds with keywords, hashtags, regex
- Filter by engagement (likes, reposts)
- Combine multiple criteria
- Share feed with community

**Example Feed - "OpenTelemetry News"**:
```
Keywords: OpenTelemetry, OTel, OTLP, observability, tracing
Hashtags: #OpenTelemetry, #Observability
Min Likes: 3
Exclude: spam keywords
```

**Reference**: [SkyFeed](https://skyfeed.app)

### **Code-Based: Feed Generator (Advanced)**

**URL**: https://github.com/bluesky-social/feed-generator

**Capabilities**:
- Full control over algorithm
- Host your own feed service
- TypeScript/Go/Python implementations
- Can integrate with your own data

**Example Feed - "OTel + Windows"**:
```typescript
// Filter for posts matching:
- #OpenTelemetry OR #OTel OR mentions "OpenTelemetry"
- AND (#Windows OR mentions "Windows")
- Ranked by recency + engagement
```

**Reference**: [ATProto Feed Generator](https://github.com/bluesky-social/feed-generator)

---

## 📈 Trend Monitoring

### **Lightweight: In-App Trending**

**Built-In Features**:
- Trending topics (right sidebar)
- Updated hourly
- Click tags to explore
- See what's popular today

**Usage**:
- Check trending before posting
- Use relevant trending tags (if authentic match)
- Engage with trending discussions

**Reference**: [The Verge - Trending](https://www.theverge.com/2024/12/26/24329549/bluesky-trending-features)

### **Programmatic: Jetstream (Firehose)**

**What It Is**: Real-time JSON firehose of all Bluesky activity

**URL**: https://docs.bsky.app/blog/jetstream

**Capabilities**:
- Subscribe to specific event types (posts, likes, follows)
- Filter by keywords, hashtags, accounts
- Self-hostable
- WebSocket streaming

**Example Use - Trend Bot**:
```typescript
// Subscribe to Jetstream
// Filter for: OpenTelemetry, OTel, #Observability, Windows
// Count mentions per hour
// Suggest tags to use in next post
```

**Reference**: [Bluesky Jetstream Docs](https://docs.bsky.app/blog/jetstream)

### **API: Engagement Metrics**

**After Posting**:
```typescript
// Measure post performance
app.bsky.feed.getLikes({ uri: "at://..." })
app.bsky.feed.getRepostedBy({ uri: "at://..." })
app.bsky.feed.getQuotes({ uri: "at://..." })
app.bsky.feed.getPostThread({ uri: "at://..." }) // Replies
```

**Reference**: [Bluesky API - getLikes](https://docs.bsky.app/docs/api/app-bsky-feed-get-likes)

---

## 🎯 Week 1 Feed Strategy

### **Days 1-3: Focus on Chronological**

**Primary Feed**: "Following"
- Post your 3 launch messages
- Follow 8-10 accounts
- Engage chronologically with their content
- Build initial relationships

**Why**: Algorithm needs signal; chronological is predictable

### **Days 4-7: Add Discovery Feeds**

**Secondary Feeds**: "What's Hot", "Popular With Friends"
- See what's trending in your network
- Discover new accounts to follow
- Identify popular discussion topics
- Adjust content based on engagement

### **Week 2+: Custom Feeds**

**Create "OTel + Windows" Feed** (SkyFeed):
- Keywords: OpenTelemetry, OTel, Windows, observability
- Share with community
- Drive discovery to your account
- Build niche community

---

## 🏷️ Tag Strategy (Based on Feeds)

### **Always Use** (1-2 per post)
- `#OpenTelemetry` - Core tech
- `#Observability` - Industry
- `#Windows` - Platform

### **Rotate** (1-2 per post)
- `#dotnet` - .NET developers
- `#DevOps` - Practitioners
- `#Automation` - Process focus
- `#Governance` - Compliance angle
- `#SRE` - Site reliability

### **Discover From**
- Trending topics (daily check)
- Popular posts in your niche
- What's Hot feed
- Jetstream analysis (optional)

---

## 📊 Feed Performance Tracking

### **Week 1 Metrics**

**Discover Feed**:
- Track impressions (if available)
- Note which posts appear in Discover
- Time of day for best visibility

**Following Feed**:
- Engagement rate from followed accounts
- Reply rate
- Repost rate

**Trending**:
- Do your posts appear in trending?
- Which tags drive discovery?
- What topics are hot?

### **Optimization**

**Based on Data**:
- Post timing (when engagement peaks)
- Tag effectiveness (which drive discovery)
- Content type (technical vs. community)
- Format (threads vs. single posts)

---

## 🔧 Future: Custom Feed Development

### **Phase 1: No-Code (SkyFeed)**

**Create**: "Evidence-First Observability"
```
Include:
- #OpenTelemetry, #Observability, #ECRR
- Mentions: "evidence", "audit trail", "governance"
- Min engagement: 2 likes
```

**Share**: Post feed link, pin to profile

### **Phase 2: Code-Based (Optional)**

**Host**: Feed Generator service
```typescript
// Filter logic:
- OpenTelemetry + Windows keywords
- Quality threshold (engagement, account age)
- Exclude spam patterns
- Rank by: recency + engagement + relevance
```

**Integrate**: Link from portal, add to README

---

## 📚 Resources

**Bluesky Official**:
- [Trending Topics](https://www.theverge.com/2024/12/26/24329549/bluesky-trending-features)
- [Custom Feeds](https://www.theverge.com/2023/5/26/23739174/bluesky-custom-feeds-algorithms-twitter-alternative)
- [Jetstream Firehose](https://docs.bsky.app/blog/jetstream)
- [API - getLikes](https://docs.bsky.app/docs/api/app-bsky-feed-get-likes)

**Tools**:
- [SkyFeed Builder](https://skyfeed.app) - No-code feed creation
- [Feed Generator](https://github.com/bluesky-social/feed-generator) - Code-based feeds

**Verification**:
- [Domain Handle Tutorial](https://bsky.social/about/blog/4-28-2023-domain-handle-tutorial)

---

## 🎯 Immediate Actions

### **Day 1** (Today)
- [x] Subscribe to default feeds (Discover, Following, What's Hot)
- [ ] Post welcome message
- [ ] Monitor engagement

### **Days 2-3**
- [ ] Subscribe to "Popular With Friends"
- [ ] Post technical + governance content
- [ ] Note which feeds show your posts

### **Week 2**
- [ ] Create custom feed via SkyFeed
- [ ] Share feed with community
- [ ] Analyze engagement patterns
- [ ] Optimize posting strategy

---

**Status**: ✅ Feed strategy documented and ready to execute

🦋 **Feeds + trending monitoring ready for Week 1 launch!**

