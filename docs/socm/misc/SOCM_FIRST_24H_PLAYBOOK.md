# 🦋 SOCM First 24 Hours - Execution Playbook

**Post**: at://did:plc:ohvz4d5ucvbqiykwp2pkfato/app.bsky.feed.post/3m3gpf45i652i  
**Account**: @resonai.bsky.social  
**Status**: ✅ LIVE (Day 1 complete)  
**Next**: First 24h momentum lock-in

---

## ⏱️ T+0–24h RUN-OF-SHOW

### **Action 1: Pin + Thread the Launch Post** (5 minutes)

**In Bluesky UI**:
1. Go to your post
2. Click "..." menu → "Pin to profile"
3. Reply to your own post with Reply #1
4. Reply again with Reply #2

**Reply #1 - Roadmap CTA**:
```
What's next for Resonai [OTel]? 🗺️

• Week 1: .NET auto-instrumentation quickstarts → SigNoz
• Week 2: Windows Event Log → OTel Collector recipes  
• Week 3: ECRR runbooks + incident evidence patterns

GitHub → https://github.com/MoneyCat-inc/otel-ops-pack

Questions? Reply here—we'll turn good Qs into docs.
```

**Reply #2 - Who We're Here For**:
```
For Windows platform & .NET teams who want evidence-first observability—traces, metrics, logs with audit trails. No hand-wavy magic; just reproducible pipelines and clear rollback paths. 🐾
```

**Why Threading**:
- Lifts visibility in feeds
- Adds context for new followers
- Creates engagement hooks
- Stays within single-writer lane (you manually thread)

---

### **Action 2: Follow/Handshake** (15 minutes)

**Follow 5-8 accounts** from `docs/social/FOLLOW_LIST.yaml`:

**Priority follows** (high signal):
1. @opentelemetry.io (official - standards + releases)
2. @grafana.bsky.social (OSS observability ecosystem)
3. @dot.net (.NET official - Windows audience)
4. @clickhouse.com (database for observability)
5. @openobservability.bsky.social (community hub)

**For each account**:
1. Click Follow
2. Like 1-2 recent posts (relevant ones)
3. Leave **one value-add reply** (helpful, not promotional)

**Example replies**:
- Technical tip related to their post
- "This aligns with our approach at Resonai..."
- Answer a question they posed
- Share relevant doc link (if genuinely helpful)

**Why Handshaking**:
- Seeds your "Following" feed with signal
- Accelerates early-graph lock-in
- Builds relationships, not just numbers
- Community-first approach

---

### **Action 3: Health & Safety Check** (2 minutes)

```powershell
# 1. Verify no kill-switch
Test-Path .agent/LOCK
# Should be: False

# 2. Check ledger
Get-Content artifacts/social/posted.jsonl | Select-Object -Last 1 | ConvertFrom-Json
# Should show: real at:// URI, dryRun: False

# 3. Check queue
Get-Content artifacts/social/queue.jsonl | Select-Object -Last 1 | ConvertFrom-Json
# Should show: posted: True

# 4. Review evidence
Get-Content .agent/EVIDENCE.log | Select-Object -Last 10
# Should show: Complete ECRR sequence (A/B events)

# 5. Verify on Bluesky
# Visit: https://bsky.app/profile/resonai.bsky.social
# Should see: 1 post visible
```

**If any anomaly**:
- Create `.agent/LOCK` (emergency stop)
- File ECRR incident
- Review evidence logs
- Do NOT post again until resolved

---

## 📅 DAY-BY-DAY EXECUTION (Week 1)

### **Day 1** (Today) ✅ COMPLETE

- [x] Welcome post published
- [ ] Pin post to profile
- [ ] Add 2 threaded replies (roadmap + audience)
- [ ] Follow 5-8 accounts
- [ ] Handshake with value-add replies
- [ ] Cross-post announcement to LinkedIn
- [ ] Update personal Bluesky (@fubububu) mentioning launch

**LinkedIn Cross-Post** (suggested):
```
Excited to announce Resonai [OTel] is now on Bluesky! 🦋

Follow @resonai.bsky.social for:
• Evidence-first observability content
• Windows + OpenTelemetry tips
• BossCat automation stories
• ECRR methodology deep-dives

First post: https://bsky.app/profile/resonai.bsky.social/post/3m3gpf45i652i

#OpenTelemetry #Observability #DevOps
```

**Personal Bluesky** (from @fubububu):
```
Launched @resonai.bsky.social today! 🐾

Follow along if you're into Windows observability, OpenTelemetry, or evidence-first automation.

More technical deep-dives coming this week.

https://bsky.app/profile/resonai.bsky.social
```

---

### **Day 2** (Tomorrow) - Technical Stack

**Time**: 16:00 UTC

**Post**:
```powershell
. ./scripts/social/set-credentials.ps1

npm run social:compose -- `
  --text "🔧 Inside Resonai [OTel]: Windows Event Logs + OpenTelemetry Collector (service) + .NET auto-instrumentation → SigNoz. No agents, no lock-in—just OTLP, W3C trace context & audit trails. Starter pack + docs:" `
  --tags "OpenTelemetry,Observability,Windows,dotnet" `
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"

npm run social:approve
npm run social:post
```

**After posting**:
- Reply to any Day 1 comments
- Search #OpenTelemetry for relevant discussions
- Engage with 2-3 posts (value-add replies)

---

### **Day 3** - BossCat Governance

**Time**: 20:00 UTC (catches NA evening + EU late night)

**Post**:
```powershell
npm run social:compose -- `
  --text "🛡️ How we ship safely: ECRR (Examine→Clean→Report→Role), dual bots (A/B), kill-switch .agent/LOCK, gate \"@cat ready-for-gate\", and a public evidence log. Open automation, no silent merges. Learn more:" `
  --tags "DevOps,Automation,Governance,OpenTelemetry" `
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"

npm run social:approve
npm run social:post
```

**Thread with** (Reply #1):
```
Example: Our SOCM (social) lane has 3 guardrails:

1. Agent A composes/posts; Agent B approves only (single-writer)
2. Every action logged to .agent/EVIDENCE.log (audit trail)
3. touch .agent/LOCK = emergency stop (all bots halt)

No silent automation. Everything gated. 🐾
```

---

### **Day 4** - .NET Deep Dive

**Time**: 16:00 UTC

**Post**:
```powershell
npm run social:compose -- `
  --text "Zero-code traces for .NET on Windows: Install OTel auto-instrumentation, set CORECLR_ENABLE_PROFILING=1 + profiler GUID, point OTLP → SigNoz, set service name. Traces/metrics/logs without code changes. Then iterate safely. Guide in repo." `
  --tags "dotnet,OpenTelemetry,Windows" `
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"

npm run social:approve
npm run social:post
```

**Thread with** (technical details):
```
Key environment variables:

CORECLR_ENABLE_PROFILING=1
CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318}
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_SERVICE_NAME=your-app-name

Works with IIS, console apps, Windows Services. No SDK required for startup.
```

---

### **Day 5** - Community CTA

**Time**: 16:00 UTC

**Post**:
```powershell
npm run social:compose -- `
  --text "Resonai [OTel] is MIT-licensed and free. If you find it useful, support us on Patreon or Buy Me a Coffee. Your support funds more automation lanes, deeper SigNoz playbooks, and the anti-clickbait transparency hub. PRs welcome. 💚" `
  --tags "OpenSource" `
  --links "https://www.patreon.com/c/FaeMcLachlan,https://buymeacoffee.com/fubumaki"

npm run social:approve
npm run social:post
```

**Thread with** (Interactive CTA):
```
Reply with your Windows/.NET telemetry pain point—top 3 become docs or quick recipes next week.

Want to contribute? Check our open issues:
https://github.com/MoneyCat-inc/otel-ops-pack/issues

🐾 Community feedback drives our roadmap.
```

---

## 📊 METRICS TO WATCH (Week 1)

### **Daily Check** (10 minutes)

**Engagement** (per post at +24h):
- **Likes**: Target 3-5
- **Reposts**: Target 1-2
- **Replies**: Target 1-3
- **Engagement rate**: Target >1%

**Discovery**:
- Post visible in #OpenTelemetry feed?
- Appearing in "What's Hot"?
- Profile visits increasing?

**Growth**:
- New followers/day: Target 3-10
- Follow-backs from handshakes: Track ratio
- Quality of followers (check their profiles)

### **Weekly Analysis** (30 minutes)

**Content Performance**:
- Which posts got most engagement?
- Which tags drove discovery?
- Best posting time (UTC)?
- Thread vs. single post performance?

**Community Building**:
- Reply ratio (your replies / inbound mentions)
- Conversation depth (threads started)
- Value-add ratio (helpful replies / total replies)
- Network effects (follows from your followers)

**Optimization**:
- Rotate underperforming tags
- Adjust posting times
- Refine content mix (technical vs. community)
- Identify high-value accounts to engage with

---

## 🔧 READY-TO-USE CONTENT (Copy/Paste)

### **.NET Auto-Instrumentation** (Day 4 - Technical)

**Main Post**: Already in Week 1 sequence

**Thread Reply** (Code snippet):
```
Environment variables for .NET auto-instrumentation:

CORECLR_ENABLE_PROFILING=1
CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318}
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_SERVICE_NAME=my-dotnet-app
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp

Works with: IIS, console apps, Windows Services, Kestrel
No SDK required—traces appear immediately in SigNoz 🎯
```

### **ECRR in Practice** (Day 3 - Governance)

**Thread Reply** (Real example):
```
Example from our SOCM lane:

Before posting:
• B approves draft (sets approved:true)
• A checks kill-switch (.agent/LOCK)
• A validates budget (≤10 files touched)

After posting:
• Draft marked posted:true (prevent double-post)
• URI logged to ledger (audit trail)
• ECRR events recorded (who/what/when)

Result: Every post has proof. Every action is reversible. 🐾
```

---

## 🎯 ENGAGEMENT STRATEGY

### **Reply Guidelines**

**Do**:
- ✅ Answer technical questions thoroughly
- ✅ Share relevant docs/code snippets
- ✅ Provide context from your experience
- ✅ Link to GitHub when genuinely helpful
- ✅ Use threads for longer explanations

**Don't**:
- ❌ Promote in every reply
- ❌ Generic "great post!" comments
- ❌ Long debates (keep depth in docs)
- ❌ Over-use hashtags in replies
- ❌ Auto-reply (always human-reviewed)

### **Value-Add Examples**

**Technical Help**:
```
We solved that with a noise filter lane that drops ~50% of redundant Windows events before SigNoz. 

Here's the pattern: [link to docs]

Happy to share the PowerShell if useful!
```

**Experience Sharing**:
```
Hit the same issue with ClickHouse backfill. We solved it by [brief approach].

Our ECRR report from that incident: [link]

The key was [1-sentence lesson].
```

**Question Answering**:
```
Yes! For .NET on Windows:

1. Set CORECLR_ENABLE_PROFILING=1
2. Point OTLP to SigNoz (port 4318)
3. Traces appear automatically

Full guide in our repo: [link]
```

---

## 📈 GROWTH SAFELY (RSI/ICF Pattern)

### **Iterative Improvement** (ECRR-Compliant)

**Agent B** (Monitor):
- Identifies recurring wins/failures
- Proposes tiny tuning (cadence, tags, content mix)
- Logs suggestions to evidence
- **Never writes** - only suggests

**Agent A** (Writer):
- Implements approved improvements
- Still within budgets (≤10 files, ≤200 LOC)
- Still gate-controlled (`@cat ready-for-gate`)
- Logs all changes to evidence

**BossCat OEM**:
- Final approval on improvements
- Can halt via kill-switch
- Reviews metrics weekly
- Adjusts strategy based on data

**Examples of Safe Iterations**:
- Tag swap (if one underperforms 2x)
- Posting time adjustment (based on engagement patterns)
- Content mix refinement (more/less technical)
- Threading strategy (based on what performs)

---

## 🔧 AUTOMATION NEXT STEPS

### **1. Follow Applier** (Milestone D Preview)

**Current**: Manual follows via Bluesky UI  
**Next**: Declarative follows via `follow.ts`

**Workflow**:
```bash
# Dry-run first (shows diff)
npm run social:follow

# Review output
# If looks good, manual approval or @cat ready-for-gate in PR

# Then apply (Milestone D)
npm run social:follow --apply
```

**Guardrails**:
- Agent B reviews YAML diffs
- Agent A applies after gate
- Evidence logged for each follow
- Budget enforced (≤N follows per run)

### **2. Trend Watcher** (Read-Only)

**Purpose**: Suggest tags/topics based on trends

**Workflow**:
1. Script reads Bluesky trending topics
2. Logs suggestions to evidence
3. Agent B reviews suggestions
4. Agent A uses to compose drafts (not auto-post)

**Still gated**: All posts require human approval

### **3. CI Gate** (Already Implemented)

**Workflow**: Already in `.github/workflows/social_post.yml`

**Usage**:
1. Queue draft via compose
2. Push to branch
3. Create PR
4. Comment: `@cat ready-for-gate`
5. CI runs approve → post automatically

**Guardrails**:
- Still respects kill-switch
- Still logs evidence
- Still within budgets
- Human-triggered only

---

## 🎨 PUBLIC VISIBILITY (Milestone C Preview)

### **Portal Integration** (Low-Lift)

**Add to `portal.html`** or status page:

**"Latest Posts" Widget**:
```html
<div class="latest-posts">
  <h3>Latest from Bluesky 🦋</h3>
  <div id="recent-posts">
    <!-- Read from artifacts/social/posted.jsonl -->
    <!-- Show: timestamp + text snippet + link -->
  </div>
  <a href="https://bsky.app/profile/resonai.bsky.social">
    View all posts →
  </a>
</div>
```

**Read-Only**:
- No tracking pixels
- Reads local `posted.jsonl`
- Static generation (no API calls)
- Preserves single-writer discipline

### **Data Room Demo Tie-In**

**When posting about chaos drills**:
1. Run Data Room scenario
2. Capture screenshot/GIF
3. Post with visual
4. Link to full report

**Example**:
```
Just ran a chaos drill: 10K events/sec burst → queue steward → noise filter → SigNoz.

Result: Pipeline held <200ms, no drops. 🎯

[Screenshot of dashboard]

Full ECRR report: [link]
```

---

## 📊 DAILY METRICS TEMPLATE

### **Day 1 Scorecard** (Check at T+24h)

**Post Performance**:
- Likes: ___ (target: 3-5)
- Reposts: ___ (target: 1-2)
- Replies: ___ (target: 1-3)
- Profile visits: ___ (track in Bluesky analytics if available)

**Discovery**:
- Visible in #OpenTelemetry feed? ___
- Visible in "What's Hot"? ___
- Hashtag reach: ___

**Growth**:
- New followers: ___ (target: 3-10)
- Follow-backs: ___ / ___ (ratio)
- Quality followers: ___ (check profiles)

**Engagement Quality**:
- Technical questions: ___
- Value-add replies: ___
- Meaningful conversations started: ___

**ECRR Compliance**:
- Evidence events logged: ✅
- No kill-switch activations: ✅
- Budget maintained: ✅
- Gate control enforced: ✅

---

## 🧪 CONTENT EXPERIMENTS (Week 2+)

### **Format Tests**

**Thread vs. Single**:
- Compare engagement on threaded posts vs. single posts
- Track which format drives more replies
- Optimize based on data

**Technical vs. Community**:
- Mix ratio (aim for ≥40% technical)
- Track which gets more engagement
- Adjust based on audience feedback

**Visual vs. Text-Only**:
- Add screenshots/diagrams to some posts
- Compare engagement
- Alt-text required for accessibility

### **Timing Tests**

**Post at different UTC times**:
- 16:00 UTC (EU afternoon, NA morning)
- 20:00 UTC (NA afternoon, EU evening)
- 12:00 UTC (EU morning, NA night)

**Track engagement by time**:
- Which gets most likes?
- Which gets most replies?
- Which appears in feeds more?

### **Tag Tests**

**Rotate secondary tags**:
- Week 1: #DevOps
- Week 2: #SRE  
- Week 3: #Monitoring

**Track**:
- Which tags drive discovery?
- Which get most engagement?
- Which build quality followers?

---

## 🔒 CONTINUOUS SAFETY

### **Daily Preflight** (Before each post)

```powershell
# 1. Load credentials
. ./scripts/social/set-credentials.ps1

# 2. Check kill-switch
if (Test-Path .agent/LOCK) {
    Write-Host "⛔ Kill-switch active! Remove .agent/LOCK before posting."
    exit 50
}

# 3. Verify queue clean
Get-Content artifacts/social/queue.jsonl | ConvertFrom-Json | 
    Where-Object { $_.posted -eq $false -and $_.approved -eq $true }

# 4. Compose new post
npm run social:compose -- --text "..." --tags "..." --links "..."

# 5. Review draft
Get-Content artifacts/social/queue.jsonl | Select-Object -Last 1

# 6. Approve & post
npm run social:approve
npm run social:post

# 7. Verify
Get-Content artifacts/social/posted.jsonl | Select-Object -Last 1
```

### **Weekly Review** (Evidence audit)

```powershell
# Review week's evidence
Get-Content .agent/EVIDENCE.log | 
    Select-String -Pattern "SOCM" | 
    Select-Object -Last 50

# Check for anomalies
# - All events have agent (A or B)?
# - All exits are "ok" or documented?
# - No unexpected kill-switch hits?
# - Budget stayed within limits?
```

---

## 🎯 SUCCESS METRICS (Week 1)

### **Quantitative Targets**

**Posting**:
- [x] 1/5 posts complete (Day 1 ✅)
- [ ] 2/5 posts (Day 2)
- [ ] 3/5 posts (Day 3)
- [ ] 4/5 posts (Day 4)
- [ ] 5/5 posts (Day 5)

**Community**:
- [ ] 5-8 accounts followed
- [ ] 20-50 followers gained
- [ ] 10+ total interactions
- [ ] 1-2 technical discussions started

**Infrastructure**:
- [x] SOCM lane operational
- [x] No kill-switch activations
- [x] All posts logged in evidence
- [x] Budget maintained

### **Qualitative Goals**

**Discovery**:
- Posts appear in #OpenTelemetry feed
- Hashtags driving traffic
- Profile visits from discovery

**Engagement**:
- Quality replies (not just likes)
- Technical questions being asked
- Community members following

**Brand**:
- Known for evidence-first approach
- Recognized in observability community
- Personal + project synergy working

---

## 🐾 BOSSCAT COMPLIANCE (Ongoing)

### **Every Post Must**:

- [x] Be composed via `social:compose`
- [x] Be approved by Agent B via `social:approve`
- [x] Log ECRR events (plan → edit → report → exit)
- [x] Check kill-switch before posting
- [x] Mark draft posted:true after success
- [x] Record URI to ledger
- [x] Stay within lane budgets
- [x] Use NATO 4-4-4-4 agent naming

### **Never**:

- ❌ Auto-post without approval
- ❌ Bypass gate control
- ❌ Ignore kill-switch
- ❌ Delete drafts (append-only)
- ❌ Exceed budgets (≤10 files, ≤200 LOC)
- ❌ Skip ECRR logging

---

## 📋 QUICK COMMAND REFERENCE

**Daily**:
```powershell
. ./scripts/social/set-credentials.ps1  # Once per session
npm run social:compose -- --text "..." --tags "..." --links "..."
npm run social:approve
npm run social:post
```

**Verify**:
```powershell
Get-Content artifacts/social/posted.jsonl | Select-Object -Last 1
Get-Content .agent/EVIDENCE.log | Select-Object -Last 10
```

**Emergency**:
```powershell
# Stop everything
touch .agent/LOCK

# Resume
rm .agent/LOCK
```

---

## 🏁 FIRST 24H CHECKLIST

**Immediate** (T+0–2h):
- [ ] Pin launch post to profile
- [ ] Add 2 threaded replies (roadmap + audience)
- [ ] Follow 5-8 priority accounts
- [ ] Handshake with value-add replies
- [ ] Cross-post to LinkedIn
- [ ] Update personal Bluesky

**Today** (T+2–24h):
- [ ] Monitor engagement on launch post
- [ ] Reply to any comments/questions
- [ ] Subscribe to default feeds
- [ ] Search #OpenTelemetry for discussions
- [ ] Engage with 3-5 relevant posts

**Tomorrow** (Day 2):
- [ ] Post Technical Stack (16:00 UTC)
- [ ] Reply to Day 1 comments
- [ ] Continue engagement
- [ ] Track metrics

---

## 🎯 SESSION CLOSEOUT

**Infrastructure**: ✅ Production-ready  
**First Post**: ✅ Live on Bluesky  
**Safety**: ✅ All guardrails verified  
**Week 1 Content**: ✅ Ready to execute  
**Credential System**: ✅ Working perfectly  
**Documentation**: ✅ Complete (5,921 LOC)  

**Commits**: 18 total  
**Status**: 🟢 **PRODUCTION LAUNCHED**

---

🦋 **Resonai [OTel] is live on Bluesky!**  
🐾 **BossCat: First 24h playbook ready for execution!**  

**Next**: Pin + thread → Follow + engage → Day 2 post tomorrow! 🚀

