# 🎯 SOCM Week 1 - Quick Reference Card

**Status**: ✅ OPERATIONAL  
**Watch**: 48 hours active  
**Next**: Execute immediately

---

## ⚡ IMMEDIATE ACTIONS (30 Minutes)

### **1. Pin Launch Post** (Bluesky UI)
```
URL: https://bsky.app/profile/resonai.bsky.social/post/3m3gpf45i652i
Action: Click "..." → "Pin to profile"
```

### **2. Thread with Replies 1-2** (T+0)
**From**: `SOCM_THREAD_PACK_DAY1.md`

**Reply 1**:
```
What is Resonai [OTel]? A small, evidence-first Windows observability pack: OpenTelemetry auto-instrumentation + SigNoz backend, audit trails by default, no vendor lock-in.

Start here → https://github.com/MoneyCat-inc/otel-ops-pack

#OpenTelemetry #Windows
```

**Reply 2**:
```
What's supported out-of-the-box? ASP.NET/ASP.NET Core, HttpClient, SqlClient, Npgsql, Redis, gRPC, plus log correlation via ILogger. Most traces work zero-code; metrics/logs vary by library.

#dotnet #Observability
```

### **3. Follow Top 5** (Manual)
```powershell
# Top 5 from suggestions
bellingcat.bsky.social
quiztime.bsky.social  
sector035.bsky.social
politifact.bsky.social
apfactcheck.bsky.social
```

**For Each**: Follow → Like recent post → Value-add reply

### **4. Test Widget** (Browser)
```powershell
start docs/anticlickbait/index.html
```
**Verify**: Posts render, no errors, links work

---

## 📅 WEEK 1 SCHEDULE

**Monday 16:00 UTC** (Day 2):
```powershell
npm run social:compose -- --text "🧰 Our stack: Windows + OpenTelemetry .NET auto-instrumentation..." --tags "OpenTelemetry,DotNet,Windows" --links "https://github.com/MoneyCat-inc/otel-ops-pack"
npm run social:approve
npm run social:post
```
**Thread**: 4 replies from `SOCM_THREAD_PACK_DAY2.md`

**Tuesday 16:00 UTC** (Day 3):
```powershell
npm run social:compose -- --text "🐾 How we stay safe while we ship: BossCat governance..." --tags "DevOps,Governance,OpenTelemetry" --links "https://github.com/MoneyCat-inc/otel-ops-pack"
npm run social:approve
npm run social:post
```
**Thread**: 3 replies from `SOCM_THREAD_PACK_DAY3.md`

---

## 🛡️ GOVERNANCE ONE-LINERS

```powershell
# Preflight
npm run agent:preflight  # Expect: 0 (GREEN)

# Kill-switch check
Test-Path .agent/LOCK  # Expect: False

# Evidence tail
Get-Content .agent/EVIDENCE.log | Select-Object -Last 20

# Widget refresh
npm run social:export

# Follow suggestions
npm run social:recommend-follows

# Trend scout
npm run social:trends
```

---

## 📊 KPI TARGETS

**Week 1**:
- 10-15 likes
- 3-5 reposts
- 5-8 replies
- 10-20 new followers
- 20+ GitHub visits

---

## 🎯 T+48H SUMMARY

**Copy to** `.agent/EVIDENCE.log` **after Day 2**:

```json
{"t":"[timestamp]","who":"Human","type":"report","lane":"SOCM","msg":"48h-watch-summary: posts=3, follows=X, widget-refreshes=Y, trends-reviewed=yes, anomalies=none"}
{"t":"[timestamp]","who":"Human","type":"report","lane":"SOCM","msg":"engagement: likes=X, reposts=Y, replies=Z, new-followers=N, github-visits=M"}
{"t":"[timestamp]","who":"Human","type":"report","lane":"SOCM","msg":"widget-status: deployed, load-time<1s, accessible, graceful-fallback-working"}
{"t":"[timestamp]","who":"Human","type":"report","lane":"SOCM","msg":"trends-decision: accepted-tags=[list] OR no-tags-approved, rationale=[reason]"}
{"t":"[timestamp]","who":"Human","type":"report","lane":"SOCM","msg":"needs-tuning: [improvements] OR all-green"}
```

---

🐾 **BossCat: OPERATIONAL**  
🦋 **Bluesky: LIVE**  
🚀 **Execute NOW!**

