# 🦋 Bluesky Content Seeds - Ready to Compose

**For**: @resonai.bsky.social  
**Purpose**: First 5 posts to establish presence  
**Status**: Ready to queue via `compose.ts`

---

## 🎯 Post 1: Welcome / Introduction

**Text**:
```
🐾 Hi Bluesky — Resonai [OTel] here. We build evidence-first observability for Windows engineers. Every dashboard, script, and runbook ships with an audit trail. No vendor lock-in, no hype, just production telemetry that works.
```

**Tags**: `OpenTelemetry,Observability,Windows`  
**Links**: `https://github.com/MoneyCat-inc/otel-ops-pack`

**Compose Command**:
```bash
npm run social:compose -- \
  --text "🐾 Hi Bluesky — Resonai [OTel] here. We build evidence-first observability for Windows engineers. Every dashboard, script, and runbook ships with an audit trail. No vendor lock-in, no hype, just production telemetry that works." \
  --tags "OpenTelemetry,Observability,Windows" \
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"
```

---

## 🔍 Post 2: What We Do

**Text**:
```
What is Resonai [OTel]? We wire Windows Event Logs, file logs, and custom metrics into SigNoz at <200ms latency. BossCat automation lanes handle gate checks, noise filtering (~50% volume reduction), and nightly dashboard exports. All ECRR-compliant.
```

**Tags**: `DevOps,SRE`  
**Links**: `https://github.com/MoneyCat-inc/otel-ops-pack`

**Compose Command**:
```bash
npm run social:compose -- \
  --text "What is Resonai [OTel]? We wire Windows Event Logs, file logs, and custom metrics into SigNoz at <200ms latency. BossCat automation lanes handle gate checks, noise filtering (~50% volume reduction), and nightly dashboard exports. All ECRR-compliant." \
  --tags "DevOps,SRE" \
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"
```

---

## 🛠️ Post 3: Technical Stack

**Text**:
```
Stack: OpenTelemetry Collector + SigNoz + ClickHouse on Windows. PowerShell automation, Playwright for dashboard exports, Tetragram agent system for gates. Local-first, Docker Compose deployment. MIT licensed. Built by @fubububu.bsky.social 🐾
```

**Tags**: `OpenSource,Windows`  
**Links**: `https://github.com/MoneyCat-inc/otel-ops-pack`

**Compose Command**:
```bash
npm run social:compose -- \
  --text "Stack: OpenTelemetry Collector + SigNoz + ClickHouse on Windows. PowerShell automation, Playwright for dashboard exports, Tetragram agent system for gates. Local-first, Docker Compose deployment. MIT licensed. Built by @fubububu.bsky.social 🐾" \
  --tags "OpenSource,Windows" \
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"
```

---

## 📊 Post 4: ECRR Methodology

**Text**:
```
Our ECRR mantra: Examine → Clean → Report → Role. Every change creates an audit trail. Every gate has a kill-switch. Every metric has a baseline. That's how you ship observability without surprises. #SRE #Observability
```

**Tags**: `SRE,Observability`  
**Links**: `https://github.com/MoneyCat-inc/otel-ops-pack/blob/main/ART_OF_ECRR.md`

**Compose Command**:
```bash
npm run social:compose -- \
  --text "Our ECRR mantra: Examine → Clean → Report → Role. Every change creates an audit trail. Every gate has a kill-switch. Every metric has a baseline. That's how you ship observability without surprises." \
  --tags "SRE,Observability" \
  --links "https://github.com/MoneyCat-inc/otel-ops-pack/blob/main/ART_OF_ECRR.md"
```

---

## 💚 Post 5: Community / Support

**Text**:
```
Resonai [OTel] is free & open source. If you find it useful, consider supporting development on Patreon or Ko-fi. Your support funds more automation lanes, deeper playbooks, and the anti-clickbait transparency hub. 💚
```

**Tags**: `OpenSource`  
**Links**: `https://www.patreon.com/c/FaeMcLachlan,https://ko-fi.com/fubumaki`

**Compose Command**:
```bash
npm run social:compose -- \
  --text "Resonai [OTel] is free & open source. If you find it useful, consider supporting development on Patreon or Ko-fi. Your support funds more automation lanes, deeper playbooks, and the anti-clickbait transparency hub. 💚" \
  --tags "OpenSource" \
  --links "https://www.patreon.com/c/FaeMcLachlan,https://ko-fi.com/fubumaki"
```

---

## 📣 Progress batch (published 2026-06-12)

Six live posts — progress + marketing. Re-run or adapt via `scripts/social/post-progress-batch.ts`.

| # | Theme | URL |
|---|--------|-----|
| 1 | Pipeline + support pages synced | https://bsky.app/profile/resonai.bsky.social/post/3mo3vp5gvef2a |
| 2 | Core pitch (OTel → SigNoz) | https://bsky.app/profile/resonai.bsky.social/post/3mo3vp7yloe2o |
| 3 | Ko-fi launch | https://bsky.app/profile/resonai.bsky.social/post/3mo3vpckc6h2i |
| 4 | Patreon vs Ko-fi paths | https://bsky.app/profile/resonai.bsky.social/post/3mo3vpf54zb2m |
| 5 | Windows SRE / GitHub CTA | https://bsky.app/profile/resonai.bsky.social/post/3mo3vpholev2z |
| 6 | AntiClickbait Starter Pack | https://bsky.app/profile/resonai.bsky.social/post/3mo3vpk7wgc2k |

```powershell
npm run social:progress-batch
npm run social:week2
npm run social:export
```

### Week-2 engagement (published 2026-06-12)

| # | Theme | URL |
|---|--------|-----|
| 1 | quick-monitor tip | https://bsky.app/profile/resonai.bsky.social/post/3mo3vzmob7a2u |
| 2 | Dashboard myth-buster | https://bsky.app/profile/resonai.bsky.social/post/3mo3vzp7s7o2m |
| 3 | Starter Pack promo | https://bsky.app/profile/resonai.bsky.social/post/3mo3vzrrif72a |
| — | CHECKLIST on pinned | https://bsky.app/profile/resonai.bsky.social/post/3mo3vzucy6l2i |

---

## 📅 Posting Schedule Recommendation

### **Week 1** (Launch)
- **Day 1**: Post 1 (Welcome)
- **Day 2**: Post 2 (What We Do)
- **Day 3**: Post 3 (Technical Stack)
- **Day 4-5**: Engage with replies, follow relevant accounts
- **Day 6**: Post 4 (ECRR Methodology)
- **Day 7**: Post 5 (Support CTA)

### **Week 2+** (Organic)
- 2-3 posts per week
- Mix of technical updates, behind-the-scenes, community engagement
- Reply to discussions in #OpenTelemetry and #Observability tags

---

## 🎯 Tag Strategy

### **Primary Tags** (Always use 1-2):
- `#OpenTelemetry` - Core technology
- `#Observability` - Industry category
- `#Windows` - Platform specificity

### **Rotate Secondary Tags**:
- `#DevOps` - Practitioner audience
- `#SRE` - Site reliability engineering
- `#Monitoring` - Discovery
- `#SigNoz` - Specific tool
- `#OpenSource` - Community values

### **Avoid**:
- Generic tags (#tech, #programming)
- More than 2 tags per post
- Trending tags unrelated to content

---

## 📋 Workflow: Draft → Approve → Post

### **1. Compose** (Agent A)
```bash
npm run social:compose -- --text "..." --tags "..." --links "..."
```

### **2. Review** (Human)
```bash
cat artifacts/social/queue.jsonl
# Check the latest draft
```

### **3. Approve** (Agent B)
```bash
npm run social:approve
# Sets approved:true on latest draft
```

### **4. Post** (Agent A)
```bash
# With credentials (real post):
BSKY_HANDLE=resonai.bsky.social \
BSKY_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx \
npm run social:post

# Without credentials (dry-run):
npm run social:post
```

### **5. Verify**
```bash
# Check ledger
cat artifacts/social/posted.jsonl

# Check evidence
tail -20 .agent/EVIDENCE.log

# Check Bluesky UI
# Visit: https://bsky.app/profile/resonai.bsky.social
```

---

## 🧪 Testing Checklist

### **Before First Real Post**:
- [ ] Create Bluesky App Password (Settings → App Passwords)
- [ ] Test with sandbox account first (recommended)
- [ ] Verify `.agent/LOCK` kill-switch works
- [ ] Test approve script
- [ ] Dry-run post without credentials
- [ ] Real post to sandbox
- [ ] Verify post appears in Bluesky UI
- [ ] Check `posted.jsonl` has real `at://` URI
- [ ] Review `.agent/EVIDENCE.log` events

### **After First Production Post**:
- [ ] Post appears at https://bsky.app/profile/resonai.bsky.social
- [ ] Links are clickable
- [ ] Tags are discoverable
- [ ] Cross-link from personal account (@fubububu)
- [ ] Mirror to LinkedIn (optional)
- [ ] Monitor engagement

---

## 💡 Quick Post Ideas (Future)

### **Technical Deep Dives**:
- "How we reduced log noise by 50% with noise filter lanes"
- "Building a canary monitoring system with PowerShell + SigNoz"
- "Why we chose ClickHouse for observability storage"

### **Behind the Scenes**:
- "BossCat automation lanes explained: AUTO-BOTS vs IONA-CATS"
- "The Art of ECRR: Evidence before claims, always"
- "Building a kill-switch culture: Why every automation needs a pause button"

### **Community Engagement**:
- "What's your biggest Windows observability pain point?"
- "Poll: Which SigNoz dashboard do you use most?"
- "Looking for contributors: Help us build X feature"

### **Release Announcements**:
- "New: Automated nightly dashboard exports via Playwright"
- "Gate 007 complete: Production rollout verified"
- "Milestone: 50% noise reduction achieved"

---

## 📊 Success Metrics

### **Engagement** (First Month):
- 10-20 followers (quality over quantity)
- 5-10 meaningful replies/discussions
- 2-3 reposts from community

### **Discovery**:
- Posts appear in #OpenTelemetry feed
- Tagged in observability discussions
- Links clicked from Bluesky

### **Cross-Platform**:
- LinkedIn ↔ Bluesky cross-posting
- Personal ↔ Project account synergy
- Patreon supporters from Bluesky discovery

---

**Status**: ✅ Ready to execute - All seeds prepared!

