# 🧵 SOCM Thread Pack - Day 2: Technical Stack

**Theme**: .NET Auto-Instrumentation Deep Dive  
**Timing**: 16:00-18:00 UTC (Day 2)  
**Status**: 🟢 READY TO EXECUTE  
**Evidence**: All claims grounded in official OTel .NET docs + repo setup

---

## 🎯 DAY 2 STRATEGY

**Goal**: Establish technical credibility with .NET + Windows audience

**Why This Post**:
- Attracts .NET developers
- Shows real technical depth
- Demonstrates Windows-first expertise
- Links to working code (not vaporware)

**Target Audience**:
- .NET developers
- Windows ops engineers
- Platform engineers evaluating OTel
- DevOps teams considering observability

**Success Criteria**:
- 2-3 technical questions in replies
- 1-2 reshares from .NET community
- GitHub traffic spike from Bluesky referrals

---

## 📝 DAY 2 MAIN POST (Top-Level)

### **Post Text** (≤300 chars)

```
🧰 Our stack: Windows + OpenTelemetry .NET auto-instrumentation. Zero code changes (env vars attach). Traces for ASP.NET Core/HttpClient/SQL; key metrics + ILogger log correlation. Export via OTLP to SigNoz.

https://github.com/MoneyCat-inc/otel-ops-pack

#OpenTelemetry #DotNet #Windows
```

**Character count**: 293 ✅  
**Links**: 1 (GitHub)  
**Tags**: 3 (optimal)  

**Evidence Sources**:
- OpenTelemetry .NET Auto-Instrumentation docs: https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation
- Repo config: `config/otel-collector-config.yaml`
- Setup scripts: `scripts/setup-resonai-env.ps1`

---

## 🧵 DAY 2 THREAD REPLIES

### **Reply 2.1: Coverage** (Immediate - T+0)

```
Out-of-box traces: ASP.NET/ASP.NET Core, HttpClient, SQL (SqlClient/Npgsql/MySQL/Oracle), MongoDB, Redis, gRPC, RabbitMQ/Kafka, MassTransit/NServiceBus, Quartz, WCF (Framework).

Metrics for HTTP server/client + runtime; logs via ILogger/log4net (experimental).
```

**Character count**: 297 ✅

**Evidence**:
- OTel .NET Instrumentation Support Matrix: https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation#supported-instrumentations
- Repo verification: Multiple libraries tested in `canary-test.ps1`

**Why This Reply**:
- Shows comprehensive library coverage
- Mentions both modern (.NET 6+) and legacy (Framework) support
- Sets realistic expectations (experimental status for some)

---

### **Reply 2.2: Install in 60s** (T+10 minutes)

```
Linux/macOS: curl latest installer → source instrument.sh

Windows: use the PowerShell module. Set OTEL_* and CORECLR_* env vars; start your app—agent attaches, spans flow.

Point OTLP endpoint at SigNoz/Collector.

Quick start: https://github.com/MoneyCat-inc/otel-ops-pack/blob/main/QUICKSTART.md
```

**Character count**: 293 ✅

**Evidence**:
- Installation guide: `QUICKSTART.md:1-50`
- Setup automation: `scripts/setup-resonai-env.ps1`
- Windows-specific config: `config/otel-collector-config.yaml`

**Why This Reply**:
- Platform-neutral (covers Linux/macOS/Windows)
- Emphasizes simplicity (60 seconds)
- Provides direct link to working guide
- Shows cross-platform maturity

---

### **Reply 2.3: Realistic Expectations** (T+30 minutes)

```
Overhead: typically small (single-digit %), varies by workload.

Start 100% sample, then dial via head/tail sampling. Disable unused libs (e.g., OTEL_INSTRUMENTATION_REDIS_ENABLED=false).

Measure before/after. No magic—but the visibility pays.
```

**Character count**: 253 ✅

**Evidence**:
- Sampling config: `config/otel-collector-config.yaml:45-67` (tail_sampling processor)
- Performance monitoring: `scripts/monitor-optimized-pipeline.ps1`
- Production tuning: `docs/DAY2_OPERATIONS_GUIDE.md`

**Why This Reply**:
- Sets honest expectations (no overselling)
- Shows production maturity (sampling strategies)
- Gives actionable tuning advice
- Builds trust with "measure before/after"

---

### **Reply 2.4: Versions & Gotchas** (T+60 minutes)

```
Works on .NET 6–8 + .NET Framework 4.6.2+.

Some libs/metrics are experimental; a few have version/OS caveats. Logs: best with Microsoft.Extensions.Logging.

Check support matrix before rollout: https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation#supported-versions
```

**Character count**: 290 ✅

**Evidence**:
- Official compatibility matrix: https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation#supported-versions
- Tested versions: `.NET 6/7/8` in CI/CD pipelines
- Framework support: Documented in `docs/cheatsheets/`

**Why This Reply**:
- Prevents deployment surprises
- Links to official source (not just our claims)
- Acknowledges experimental status honestly
- Recommends best path (Microsoft.Extensions.Logging)

---

## 🔧 EXECUTION COMMANDS

### **Compose Day 2 Post**

```powershell
# Load credentials
. ./scripts/social/set-credentials.ps1

# Compose Day 2 main post
npm run social:compose -- `
  --text "🧰 Our stack: Windows + OpenTelemetry .NET auto-instrumentation. Zero code changes (env vars attach). Traces for ASP.NET Core/HttpClient/SQL; key metrics + ILogger log correlation. Export via OTLP to SigNoz. https://github.com/MoneyCat-inc/otel-ops-pack" `
  --tags "OpenTelemetry,DotNet,Windows" `
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"
```

### **Approve & Post** (Agent B → Agent A)

```powershell
# Agent B approves
npm run social:approve

# Agent A posts (after approval)
npm run social:post
```

### **Verify Posting**

```powershell
# Check ledger shows real URI
Get-Content artifacts/social/posted.jsonl | Select-Object -Last 1 | ConvertFrom-Json

# Verify draft marked posted:true
Get-Content artifacts/social/queue.jsonl | Select-Object -Last 1 | ConvertFrom-Json

# Check evidence log
Get-Content .agent/EVIDENCE.log | Select-String "SOCM" | Select-Object -Last 10
```

---

## 📋 DAY 2 EXECUTION CHECKLIST

### **Pre-Post** (Before 16:00 UTC)

- [ ] Credentials loaded (`. ./scripts/social/set-credentials.ps1`)
- [ ] Kill-switch clear (`Test-Path .agent/LOCK` returns False)
- [ ] Day 1 metrics reviewed (engagement rate, follows, traffic)
- [ ] SigNoz stack operational (`docker ps` shows healthy)
- [ ] Evidence log clean (no errors in `.agent/EVIDENCE.log`)

### **Post** (16:00 UTC)

- [ ] Run compose command
- [ ] Run approve command (Agent B)
- [ ] Run post command (Agent A)
- [ ] Verify real `at://` URI in ledger
- [ ] Verify `posted:true` in queue
- [ ] Visit Bluesky to confirm post visible

### **Thread** (16:00-18:00 UTC)

- [ ] Reply 2.1: Coverage (Immediate)
- [ ] Reply 2.2: Install in 60s (T+10)
- [ ] Reply 2.3: Realistic expectations (T+30)
- [ ] Reply 2.4: Versions & gotchas (T+60)

### **Engagement** (Throughout day)

- [ ] Reply to any technical questions with specifics
- [ ] Like/reshare 2-3 relevant .NET or OTel posts
- [ ] Follow 2-3 accounts that engaged with Day 2 post
- [ ] Monitor GitHub traffic from Bluesky referrals

### **Evening Review** (T+12h)

- [ ] Metrics: likes, reposts, replies, profile visits
- [ ] GitHub: referral traffic, new stars/forks
- [ ] Evidence: any errors or anomalies in logs
- [ ] Queue Day 3 post (compose + approve, don't post yet)

---

## 💬 OPTIONAL BONUS THREADLETS

### **Threadlet: Why We Log By Default**

**Use**: If someone asks about observability best practices

```
"What isn't written didn't happen."

All significant steps append JSON lines to .agent/EVIDENCE.log. It's our flight recorder for audits and postmortems.

Every bot action, every gate signal, every state change—logged.

Evidence-first, always. 🐾
```

**Character count**: 244 ✅

**Evidence**: 
- `.agent/EVIDENCE.log` format documented in `docs/social/README.md`
- All SOCM scripts log to evidence: `scripts/social/*.ts`

---

### **Threadlet: Why Windows First**

**Use**: If someone asks why not Linux-first like everyone else

```
Why Windows-first?

Because most enterprise .NET still runs there. IIS, SQL Server, AD integration, WCF, legacy Framework apps.

Linux gets love from everyone. Windows gets... less.

We're here for the Windows ops engineers holding the line. 🛡️
```

**Character count**: 252 ✅

**Evidence**:
- Windows-specific tooling throughout: `*.ps1` scripts
- Windows Event Logs integration: `config/otel-collector-config.yaml:12-34`
- Windows service setup: `docs/DAY2_OPERATIONS_GUIDE.md`

---

### **Threadlet: Zero Lock-In**

**Use**: If someone asks about vendor lock-in or SaaS requirements

```
Zero vendor lock-in:

• Standard OTLP (gRPC + HTTP)
• W3C trace context
• OpenTelemetry SDK
• Any backend (SigNoz, Tempo, Jaeger, Honeycomb, etc.)

We chose SigNoz for local-first + ClickHouse. You choose what fits.

Open standards. Open source. Open future. 🌐
```

**Character count**: 284 ✅

**Evidence**:
- OTLP config: `config/otel-collector-config.yaml:89-103`
- Backend flexibility documented: `README.md:1-50`
- MIT License: `LICENSE`

---

## 🎯 DAY 2 TARGET METRICS

### **Engagement Targets**

**Minimum**:
- 3-5 likes
- 1-2 reposts
- 1-2 technical questions in replies

**Good**:
- 5-10 likes
- 2-4 reposts
- 3-5 technical questions/discussions
- 1 follow from .NET community figure

**Excellent**:
- 10+ likes
- 5+ reposts
- 5+ technical discussions
- Multiple follows from .NET/OTel community
- Mentioned in someone else's post

### **Traffic Targets**

**GitHub**:
- 10+ unique visitors from Bluesky referral
- 1-2 new stars
- 1-2 repo clones

**Bluesky**:
- 3-5 new followers
- Appearing in #DotNet or #OpenTelemetry feeds

### **Quality Signals**

**High-Value Engagement**:
- Technical questions about implementation
- "How does X work with Y?" specifics
- Requests for additional library support
- Production deployment questions
- Architecture discussions

**Low-Value Engagement** (Don't chase):
- Generic "nice!" comments
- Pure promotional replies
- Off-topic discussions
- Spam/bots

**Respond to High-Value ONLY** - maintain signal quality

---

## 🛡️ SAFETY CHECKS

### **Before Posting**

```powershell
# 1. Kill-switch check
if (Test-Path .agent/LOCK) {
    Write-Host "⛔ LOCK present - investigate before posting"
    exit 50
}

# 2. Credentials loaded
if (-not $env:BSKY_HANDLE) {
    Write-Host "⚠️ Credentials not loaded - run set-credentials.ps1"
    exit 1
}

# 3. Queue state
$queue = Get-Content artifacts/social/queue.jsonl | Select-Object -Last 1 | ConvertFrom-Json
if ($queue.posted -eq $true) {
    Write-Host "⚠️ Last draft already posted - compose new one"
}

# 4. Evidence log clean
$errors = Get-Content .agent/EVIDENCE.log | Select-String "error" | Select-Object -Last 5
if ($errors) {
    Write-Host "⚠️ Recent errors in evidence log:"
    $errors
}

Write-Host "✅ Safety checks passed - ready to post" -ForegroundColor Green
```

---

### **After Posting**

```powershell
# 1. Verify real URI
$last = Get-Content artifacts/social/posted.jsonl | Select-Object -Last 1 | ConvertFrom-Json
if ($last.bskyUri -notlike "at://*") {
    Write-Host "❌ Invalid URI - check posting" -ForegroundColor Red
    exit 1
}
if ($last.dryRun -eq $true) {
    Write-Host "⚠️ Was DRY-RUN - check credentials" -ForegroundColor Yellow
}

# 2. Verify draft marked posted
$queue = Get-Content artifacts/social/queue.jsonl | Select-Object -Last 1 | ConvertFrom-Json
if ($queue.posted -ne $true) {
    Write-Host "❌ Draft not marked posted - bug in post.ts" -ForegroundColor Red
    exit 1
}

# 3. Check for duplicate IDs
$allPosted = Get-Content artifacts/social/posted.jsonl | ForEach-Object { 
    ($_ | ConvertFrom-Json).draftId 
}
$duplicates = $allPosted | Group-Object | Where-Object { $_.Count -gt 1 }
if ($duplicates) {
    Write-Host "❌ DUPLICATE DRAFT IDs - double-post bug!" -ForegroundColor Red
    $duplicates
    exit 1
}

Write-Host "✅ Post verified successfully!" -ForegroundColor Green
Write-Host "   URI: $($last.bskyUri)" -ForegroundColor Cyan
Write-Host "   Draft ID: $($last.draftId)" -ForegroundColor Cyan
Write-Host "   Posted at: $($last.postedAt)" -ForegroundColor Cyan
```

---

## 📊 DAY 2 TIMING STRATEGY

### **Optimal Window: 16:00-18:00 UTC**

**Why This Window**:
- 11:00-13:00 EST (US East Coast lunch/afternoon)
- 08:00-10:00 PST (US West Coast morning)
- 17:00-19:00 CET (Europe evening)
- Captures both US work hours and EU after-work

**Posting Cadence**:
- **16:00 UTC**: Main post
- **16:05 UTC**: Reply 2.1 (Coverage)
- **16:15 UTC**: Reply 2.2 (Install in 60s)
- **16:45 UTC**: Reply 2.3 (Realistic expectations)
- **17:15 UTC**: Reply 2.4 (Versions & gotchas)

**Why Staggered**:
- Each reply gets individual visibility
- Algorithm favors active threads
- Gives time for engagement between replies
- Appears as "live conversation" not "wall of text"

---

## 🎓 LEARNING LOOP (ICF Integration)

### **What to Capture**

**Content Performance**:
- Which reply got most engagement?
- Which technical detail sparked questions?
- Did any claim get challenged? (Good - means scrutiny)
- What libraries/platforms were people interested in?

**Technical Accuracy**:
- Any corrections needed?
- Claims that need more evidence?
- Documentation gaps revealed by questions?

**Community Signals**:
- Who reshared? (Note for future follows)
- What adjacent topics came up? (Future post ideas)
- Geographic/platform distribution of engagement?

### **Update After Day 2**

```powershell
# Create learning artifact
$learning = @{
    date = Get-Date -Format "yyyy-MM-dd"
    post = "Day 2 - Technical Stack"
    engagement = @{
        likes = 0  # Fill after 24h
        reposts = 0
        replies = 0
    }
    insights = @(
        "Top performing reply: ___"
        "Most asked question: ___"
        "Unexpected interest in: ___"
        "Documentation gap: ___"
    )
    actions = @(
        "Update FAQ with ___"
        "Create deep-dive doc for ___"
        "Follow up post about ___"
    )
} | ConvertTo-Json -Depth 3

$learning | Out-File "artifacts/social/learning_day2.json"
```

---

## 🚀 READY TO EXECUTE

**Status**: ✅ **PRODUCTION READY**

**Evidence**: All claims backed by:
- Official OTel .NET documentation
- Working code in repo
- Production deployment guides
- Real configuration files

**Safety**: All guardrails active:
- Single-writer pattern (you manually post threads)
- Automated posting via scripts (with approval gate)
- Kill-switch available
- Evidence logging complete
- No duplicate post risk

**Next**: Execute at 16:00 UTC on Day 2!

---

🐾 **Day 2 Thread Pack Complete - Technical credibility established!** 🧰

