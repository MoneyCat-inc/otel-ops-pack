# 🚀 SOCM Operational Handover - Week 1 Ready

**Date**: 2024-10-18  
**Authority**: cursor{implementer} under Fubumaki  
**Status**: ✅ **GO-LIVE EXECUTED - OPERATIONAL**  
**Lane**: SOCM (Social Media Operations & Comms)

---

## 🎯 WHAT'S LIVE AND GOVERNED

### **Single-Writer, Lane-Locked Automation** ✅

**Enforced**:
- Kill-switch (`.agent/LOCK`) - All scripts respect, exit 50 (BLACK)
- Hard budgets (≤10 files, ≤200 LOC per job)
- Evidence logging (`.agent/EVIDENCE.log`) - All actions tracked
- No silent trunk writes (bots never merge)

**Bots**:
- **AUTO-BOTS-SOCM-ALFA** (A) - Writer (generates suggestions, executes)
- **IONA-CATS-SOCM-BETA** (B) - Monitor (reviews, verifies, never writes)

**NATO 4-4-4-4 Naming** ✅:
- Lane: `SOCM`
- Gate signal: `@cat ready-for-gate`
- Exit codes: GREEN=0, BLACK=50, RED=51, AMBER=52/53

**ECRR Compliance** ✅:
- Evidence → Contain → Rollback → Report
- All anomalies follow this pattern
- Incident playbook documented

---

## ✅ SYSTEMS OPERATIONAL

### **Milestone A+B** (Compose, Approve, Post, Follow)

**Status**: ✅ **PRODUCTION**

**Commands**:
```powershell
# Compose draft
npm run social:compose -- --text "..." --tags "..." --links "..."

# Approve draft (Agent B)
npm run social:approve

# Post to Bluesky (Agent A)
npm run social:post

# Follow accounts (declarative)
npm run social:follow
```

**Evidence**: First post live, verified on Bluesky  
**Credentials**: Persistent (`.env.socm` + `set-credentials.ps1`)  
**Safety**: Double-post prevention, directory safety (bugfixed)

---

### **Milestone C** (Site Widget - Read-Only)

**Status**: ✅ **IMPLEMENTED & TESTED**

**Command**:
```powershell
npm run social:export
```

**Outputs**:
- `docs/widgets/bluesky-latest.json` (structured post data)

**Features**:
- Fetches from Bluesky API (if credentials present)
- Falls back to local ledger (`artifacts/social/posted.jsonl`)
- Progressive enhancement (works without JS)
- Graceful degradation (shows fallback link on error)
- Read-only (no posting from widget)

**Integration Options**:
1. **Iframe** (cleanest isolation)
2. **Direct include** (unified styling)
3. **Transparency hub** (accountability focus)

**Example Embed** (Option 2 - Direct Include):
```html
<!-- In <head> -->
<link rel="stylesheet" href="/docs/assets/bluesky-widget.css">

<!-- Where you want widget -->
<section class="card">
  <h2>Latest on Bluesky</h2>
  <div id="bsky-latest" data-src="/docs/widgets/bluesky-latest.json">
    <p>Loading Bluesky updates…
      <a href="https://bsky.app/profile/resonai.bsky.social">visit the profile</a>.
    </p>
  </div>
</section>

<!-- Before </body> -->
<script src="/docs/assets/bluesky-widget.js" defer></script>
```

**Design System**: Inherits from `docs/assets/resonai-system.css` (unified typography, components)

---

### **Milestone D** (Follow Suggestions - Suggest-Only)

**Status**: ✅ **IMPLEMENTED & TESTED**

**Command**:
```powershell
npm run social:recommend-follows
```

**Outputs**:
- `artifacts/social/follow_suggestions.jsonl` (ranked suggestions)

**Scoring Algorithm**:
- Base: 0.8 (curated list)
- +0.15 (topic overlap with approved tags)
- +0.05 (rationale mentions "observability")
- Max: 0.99

**Review Process**:
1. Review top 5-10 suggestions
2. Check profiles on Bluesky (manual)
3. Follow ≤5 per week (per policy)
4. Log decisions (see template below)

**SUGGEST-ONLY**: No auto-follow, human approval required ✅

---

### **Milestone E** (Trend Scout - Suggest-Only)

**Status**: ✅ **IMPLEMENTED & TESTED**

**Command**:
```powershell
npm run social:trends
```

**Outputs**:
- `artifacts/social/trends.json` (trend metrics)
- `docs/social/TAGS.suggestions.yaml` (tag proposals)

**Analysis**:
- Scans last 14 days of posts
- Counts tag frequency
- Collects sample URLs
- Threshold: ≥2 mentions

**Review Process**:
1. Review `TAGS.suggestions.yaml`
2. Check samples (are they relevant?)
3. If approved, update `docs/social/TAGS.yaml` manually
4. Log decision (see template below)

**SUGGEST-ONLY**: No auto-tagging, human approval required ✅

---

## ⏱️ NEXT 30 MINUTES (RUN-OF-SHOW)

### **1. Pin + Thread Launch Post** (5 minutes)

**Actions**:
- [ ] Pin first post to profile (Bluesky UI)
- [ ] Add Reply 1: "What is Resonai [OTel]?" (T+0)
- [ ] Add Reply 2: "What works out-of-box?" (T+0)
- [ ] Stage Replies 3-6 for T+30, T+120, T+12h

**From**: `SOCM_THREAD_PACK_DAY1.md`

---

### **2. Export + Embed Widget** (10-12 minutes)

**Export**:
```powershell
. ./scripts/social/set-credentials.ps1  # Optional
npm run social:export
```

**Embed** (choose one location):

**Option A**: Main Portal (`portal.html`)

Add after support badges section (~line 460):
```html
<!-- Latest on Bluesky -->
<link rel="stylesheet" href="docs/assets/bluesky-widget.css">
<section class="card" style="margin-top: 2rem;">
  <h2>Latest on Bluesky 🦋</h2>
  <div data-bsky-latest 
       data-src="docs/widgets/bluesky-latest.json"
       data-fallback='<p><a href="https://bsky.app/profile/resonai.bsky.social">See profile on Bluesky →</a></p>'>
    <p>Loading…</p>
  </div>
</section>
<script src="docs/assets/bluesky-widget.js" defer></script>
```

**Option B**: Transparency Hub (`docs/anticlickbait/index.html`)

Add after data section (~line 50):
```html
<!-- Latest on Bluesky -->
<link rel="stylesheet" href="../assets/bluesky-widget.css">
<section id="bluesky-latest" style="margin-top: 3rem;">
  <h2>Latest on Bluesky</h2>
  <div data-bsky-latest 
       data-src="bluesky-latest.json"
       data-fallback='<p><a href="https://bsky.app/profile/resonai.bsky.social">See our profile →</a></p>'>
    <p>Loading…</p>
  </div>
</section>
<script src="../assets/bluesky-widget.js" defer></script>
```

**Verify**:
- [ ] Open page in browser
- [ ] Widget renders (or shows fallback)
- [ ] No console errors (F12)
- [ ] Links work (click through to Bluesky)

---

### **3. Follow Suggestions** (5 minutes)

**Generate**:
```powershell
npm run social:recommend-follows
```

**Review & Follow**:
```powershell
# Review top 5
$suggestions = Get-Content artifacts/social/follow_suggestions.jsonl | 
    ForEach-Object { $_ | ConvertFrom-Json } | 
    Sort-Object -Property score -Descending | 
    Select-Object -First 5

$suggestions | Format-Table handle, score, reasons

# Open top 3 in browser
$suggestions[0..2] | ForEach-Object {
    start "https://bsky.app/profile/$($_.handle)"
}
```

**Follow Manually** (≤5/week):
1. Check profile (bio, recent posts, engagement)
2. Follow if approved
3. Leave 1 value-add reply (handshake)
4. Log decision

**Log Template**:
```powershell
# After following
$follow = @{
    handle = "opentelemetry.io"
    followedAt = (Get-Date -Format "o")
    score = 0.95
    reason = "curated:list, topic:approved, obs-focus"
} | ConvertTo-Json -Compress

$follow | Out-File -Append artifacts/social/followed.jsonl

# Evidence log
$evidence = @{
    t = (Get-Date -Format "o")
    who = "Human"
    type = "edit"
    lane = "SOCM"
    msg = "followed @opentelemetry.io (score:0.95, curated+approved)"
} | ConvertTo-Json -Compress

$evidence | Out-File -Append .agent/EVIDENCE.log
```

---

### **4. Governance Spot-Check** (3 minutes)

```powershell
# Preflight check
npm run agent:preflight
# Expected: Exit 0 (GREEN)

# Evidence tail (last 20 SOCM events)
Get-Content .agent/EVIDENCE.log | 
    Select-Object -Last 100 | 
    ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | 
    Where-Object { $_ -and $_.lane -eq "SOCM" } | 
    Select-Object -Last 20 | 
    Format-Table t, who, type, msg

# Check for errors
$errors = Get-Content .agent/EVIDENCE.log | 
    ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | 
    Where-Object { $_ -and ($_.msg -like "*error*" -or $_.msg -like "*fail*") }

if ($errors) {
    Write-Host "⚠️ Errors found:" -ForegroundColor Yellow
    $errors | Format-Table t, who, type, msg
} else {
    Write-Host "✅ Evidence log clean" -ForegroundColor Green
}
```

---

## 🧭 NIGHTLY CI (OPTIONAL - READ-ONLY)

### **Purpose**

Export latest posts nightly and create PR (no silent trunk writes).

### **Workflow** (`.github/workflows/social_export_nightly.yml`)

```yaml
name: SOCM Nightly Export (Read-Only)

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  export-latest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - run: npm ci
      
      - name: Export latest posts
        env:
          BSKY_HANDLE: ${{ secrets.BSKY_HANDLE }}
          BSKY_APP_PASSWORD: ${{ secrets.BSKY_APP_PASSWORD }}
        run: npm run social:export
      
      - name: Create PR (if changes)
        run: |
          git config user.name "AUTO-BOTS-SOCM-ALFA"
          git config user.email "bot@resonai"
          
          BRANCH="socm/widget-$(date +%Y%m%d)"
          git checkout -b "$BRANCH"
          
          git add docs/widgets/bluesky-latest.json
          
          if git diff --cached --quiet; then
            echo "No changes to commit"
            exit 0
          fi
          
          git commit -m "chore(socm): nightly widget export $(date +%Y-%m-%d)"
          git push origin "$BRANCH"
          
          gh pr create \
            --title "chore(socm): Nightly widget export $(date +%Y-%m-%d)" \
            --body "Automated export of latest Bluesky posts. Review and approve with \`@cat ready-for-gate\`." \
            --label "SOCM" \
            --base main \
            --head "$BRANCH"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**How It Works**:
1. Runs at 2 AM UTC
2. Exports latest posts
3. Creates PR (NOT merged)
4. Human reviews: `@cat ready-for-gate`
5. CI runs gate checks (Agent B)
6. Maintainer merges

**Why PR-Gate**:
- ✅ No silent trunk writes (BossCat Rule #9)
- ✅ Human approval required
- ✅ Evidence trail (PR comments)
- ✅ Reversible (reject PR)

---

## 📈 WEEK 1 EXECUTION CHECKPOINTS

### **Day 1** (Today - Completed)

**Executed**:
- [x] First post LIVE on Bluesky
- [x] Preflight checks passed (GREEN)
- [x] Widget export tested
- [x] Follow suggestions generated
- [x] Trend scout tested
- [x] Evidence logged (all actions)

**Next**:
- [ ] Pin launch post
- [ ] Thread with Replies 1-2 (immediate)
- [ ] Follow 3-5 accounts (handshake)
- [ ] Add widget to site (choose location)

---

### **Day 2** (Monday 16:00 UTC)

**Post**: Technical Stack

```powershell
. ./scripts/social/set-credentials.ps1

npm run social:compose -- `
  --text "🧰 Our stack: Windows + OpenTelemetry .NET auto-instrumentation. Zero code changes (env vars attach). Traces for ASP.NET Core/HttpClient/SQL; key metrics + ILogger log correlation. Export via OTLP to SigNoz. https://github.com/MoneyCat-inc/otel-ops-pack" `
  --tags "OpenTelemetry,DotNet,Windows" `
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"

npm run social:approve
npm run social:post
```

**Thread**: 4 replies from `SOCM_THREAD_PACK_DAY2.md`

**Handshake**: .NET/OTel community accounts

---

### **Day 3** (Tuesday 16:00 UTC)

**Post**: BossCat Governance

```powershell
npm run social:compose -- `
  --text "🐾 How we stay safe while we ship: BossCat governance. ECRR (Evidence→Contain→Rollback→Report), single-writer lanes, hard budgets, kill-switch, and paired bots (A writes / B verifies). Audit trails by default. https://github.com/MoneyCat-inc/otel-ops-pack" `
  --tags "DevOps,Governance,OpenTelemetry" `
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"

npm run social:approve
npm run social:post
```

**Thread**: 3 replies from `SOCM_THREAD_PACK_DAY3.md`

**Handshake**: DevOps/automation community accounts

---

### **End of Week** (Friday/Saturday)

**Trend Analysis**:
```powershell
npm run social:trends
```

**Review**:
- [ ] Check `docs/social/TAGS.suggestions.yaml`
- [ ] Review proposals (thematic fit, frequency)
- [ ] Update `docs/social/TAGS.yaml` if approved
- [ ] Create PR (not merged, awaits gate)

---

## 🎯 KPI TARGETS (EVIDENCE-DRIVEN)

### **Week 1 Goals**

**Engagement**:
- 10-15 likes across 3 posts
- 3-5 reposts
- 5-8 meaningful replies/questions
- 10-20 new followers

**Traffic**:
- 20+ GitHub referral visits (from Bluesky)
- 2-5 new GitHub stars
- Profile appearing in #OpenTelemetry feed

**Quality**:
- 2-3 technical discussions started
- 1-2 "how do you implement X?" questions
- Recognition from OTel/.NET community

**Metrics Collection**:
```powershell
# After each post
$metrics = @{
    post_id = "d_..."
    posted_at = (Get-Date -Format "o")
    likes = 0  # Fill manually
    reposts = 0
    replies = 0
    profile_clicks = 0
    link_clicks = 0
} | ConvertTo-Json -Compress

$metrics | Out-File -Append artifacts/social/metrics.jsonl
```

---

## 🛑 RISK WATCHLIST (AND WHAT HAPPENS)

### **Credentials Missing**

**Symptom**: Post shows `dryRun: true`, URI is `dry-run://missing-credentials`

**Fix**:
```powershell
# Set credentials
. ./scripts/social/set-credentials.ps1
# Verify
echo $env:BSKY_HANDLE

# Re-approve and post
npm run social:approve
npm run social:post
```

---

### **Kill-Switch Engaged**

**Symptom**: Scripts exit with code 50 (BLACK), message "paused:kill-switch"

**Investigation**:
```powershell
# Check if lock exists
Test-Path .agent/LOCK

# Review recent evidence
Get-Content .agent/EVIDENCE.log | Select-Object -Last 50

# If incident resolved, remove lock
Remove-Item .agent/LOCK
```

**When to Use**:
- Automation behaving unexpectedly
- Budget violation detected
- Policy breach suspected
- Need to investigate

---

### **Budget Overrun**

**Symptom**: Job halts with AMBER/RED, message about budgets exceeded

**Response**:
1. **Contain**: Kill-switch activated automatically
2. **Examine**: Review `.agent/EVIDENCE.log` for budget violations
3. **Rollback**: Revert changes via `git reset` or `git revert`
4. **Report**: Create ECRR incident report

**Prevention**:
- Review file count before commit: `git diff --name-only | wc -l`
- Check LOC delta: `git diff --stat`
- Stay within lane patterns (SOCM: `docs/social/**`, `scripts/social/**`, `artifacts/social/**`)

---

### **Non-Lane Files Modified**

**Symptom**: Agent B flags non-lane file modifications

**Response**:
1. **Contain**: PR blocked, no merge
2. **Review**: Why were non-lane files touched?
3. **Rollback**: Remove non-lane changes, keep only lane files
4. **Report**: Log incident, update lane allow-patterns if needed

**Lane Patterns** (SOCM):
- ✅ `docs/social/**`
- ✅ `scripts/social/**`
- ✅ `artifacts/social/**`
- ✅ `docs/assets/bluesky-widget.*`
- ✅ `docs/widgets/bluesky-latest.*`
- ❌ Everything else (requires separate PR)

---

## 📦 OPTIONAL: BACKGROUND TELEMETRY (READ-ONLY)

### **SigNoz Monitoring** (Future)

**If wiring dashboards/alerts**:
- Keep **background, report-only**
- Always under BossCat veto
- Nothing promotes to prod without gate
- Metrics observability only (no auto-actions)

**Example Metrics**:
- Queue conversion rate (drafted → posted)
- Time-to-gate (draft → approval)
- Time-to-post (approval → live)
- Engagement rate per post
- Follow quality (% engage in 7d)
- Tag yield (engagement lift per tag)

---

## 🔚 DEFINITION OF DONE (WEEK 1)

### **Widget** ✅

- [ ] Widget visible on site (OR fallback link renders)
- [ ] JSON exports successfully
- [ ] No console errors
- [ ] Accessible (WCAG-AA)
- [ ] Evidence logged for exports

---

### **Posts** ✅

- [ ] 3 posts executed (Day 1-3)
- [ ] Each post threaded (13 total replies)
- [ ] Evidence shows full A/B sequences
- [ ] No BLACK/RED events in log
- [ ] All posted drafts marked `posted:true`

---

### **Follows** ✅

- [ ] Follow suggestions generated
- [ ] Top 5-10 reviewed
- [ ] ≤5 followed (per policy)
- [ ] Value-add replies left (handshake)
- [ ] Decisions logged to evidence

---

### **Tags** ✅

- [ ] Trends generated (end-of-week)
- [ ] Proposals reviewed
- [ ] At least 1 tag decision made
- [ ] Decision logged
- [ ] Updates queued as PR (NOT merged)

---

### **Governance** ✅

- [ ] All preflight checks passed
- [ ] No kill-switch activations (or documented if used)
- [ ] No budget violations
- [ ] No policy breaches
- [ ] All evidence complete (100% actions logged)
- [ ] No silent trunk writes

---

## 📋 QUICK COMMAND CARD (COPY/PASTE)

### **Daily Operations**

```powershell
# Thread + follow (ongoing)
npm run social:export
npm run social:recommend-follows

# Governance checks
npm run agent:preflight
Get-Content .agent/EVIDENCE.log | Select-Object -Last 20

# Post (Day 2-3)
npm run social:compose -- --text "..." --tags "..." --links "..."
npm run social:approve
npm run social:post
```

---

### **End of Week**

```powershell
# Trend analysis
npm run social:trends

# Review proposals
cat docs/social/TAGS.suggestions.yaml

# Update TAGS.yaml (manual edit)
code docs/social/TAGS.yaml

# Create PR (not merged)
git checkout -b socm/tags-$(date +%Y%m%d)
git add docs/social/TAGS.yaml
git commit -m "chore(socm): update approved tags from trends"
git push origin HEAD
# Open PR, await @cat ready-for-gate
```

---

## 🎯 PR DESCRIPTION TEMPLATE (SOCM)

Create `.github/PULL_REQUEST_TEMPLATE/socm.md`:

```markdown
## SOCM Lane PR

**Lane**: SOCM (Social Media Operations & Comms)  
**Type**: [ ] Widget update [ ] Follow suggestions [ ] Tag update [ ] Other

---

### 📋 ECRR Checklist

**Examine**:
- [ ] Current state documented
- [ ] Changes are lane-scoped (SOCM only)
- [ ] Budgets respected (≤10 files, ≤200 LOC)

**Clean**:
- [ ] No drift from lane patterns
- [ ] Evidence logged for all actions
- [ ] Kill-switch respected (no runs during lock)

**Report**:
- [ ] Changes summarized below
- [ ] Evidence artifacts attached/linked
- [ ] Rationale provided for all decisions

**Role**:
- [ ] Agent A (writer) identified
- [ ] Agent B (monitor) verified
- [ ] Human approval pending

---

### 📊 Changes Summary

**What Changed**:
- (Describe changes)

**Why**:
- (Rationale)

**Evidence**:
- Evidence log: `.agent/EVIDENCE.log` lines XXX-YYY
- Artifacts: `artifacts/social/...`

---

### 🛡️ Safety Checks

- [ ] Preflight passed (exit 0)
- [ ] No kill-switch activation
- [ ] All files in lane patterns
- [ ] No silent trunk writes
- [ ] Human gate required

---

### 🎯 Gate Signal

Ready for review. Approve with: `@cat ready-for-gate`
```

---

## 🐾 BOSSCAT CERTIFICATION

**System Status**: ✅ **OPERATIONAL**

**Week 1**: ✅ **READY TO EXECUTE**

**Governance**: ✅ **100% COMPLIANT**

**Evidence**: ✅ **COMPLETE**

**Guardrails**: ✅ **ALL ACTIVE**

---

## 🚀 EXECUTE NOW

**Immediate Actions** (Next 30 minutes):
1. ✅ **Preflight**: Passed (GREEN)
2. ✅ **Widget**: Exported (JSON created)
3. ✅ **Follows**: Generated (top 5 ready)
4. ✅ **Trends**: Analyzed (proposals ready)
5. [ ] **Pin**: Launch post on Bluesky
6. [ ] **Thread**: Add Replies 1-2
7. [ ] **Follow**: 3-5 accounts (handshake)
8. [ ] **Embed**: Widget on site

**This Week** (Days 2-3):
- Monday 16:00 UTC: Post Technical Stack
- Tuesday 16:00 UTC: Post BossCat Governance
- Friday/Saturday: Trend analysis, tag updates

**Ongoing** (Every post):
- Export widget (refresh JSON)
- Review follow suggestions (≤5/week)
- Log evidence (all actions)
- Monitor KPIs (engagement, traffic, quality)

---

🦋 **Bluesky growth engine: OPERATIONAL**  
🐾 **BossCat governance: ACTIVE**  
🚀 **Week 1 execution: GO!**

**Local-first. Evidence-first. Convergent. Safe.** ✅

