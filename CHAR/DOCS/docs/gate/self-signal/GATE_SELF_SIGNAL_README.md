# 🐾 Gate Self-Signal Monitoring System — Quick Reference

**Status:** ✅ **FULLY OPERATIONAL & MONITORING**  
**Last Updated:** 2025-10-23 16:30  
**Gate:** 🟠 WARN (awaiting SigNoz platform fix)

---

## 🎯 What Is This?

Autonomous system that detects when SigNoz fixes the exporter→ClickHouse gap **without requiring human ping**.

- ✅ Runs in background (30-minute polling)
- ✅ Sends canary traces automatically
- ✅ Queries ClickHouse for traces with `service.name='canary-test'`
- ✅ Breaks with alert when traces are detected
- ✅ Ready to execute 10-minute gate advancement runbook
- ✅ Flips gate to 🟢 GREEN when conditions met

---

## 📋 Quick Links

| Item | File | Purpose |
|------|------|---------|
| **THIS FILE** | `GATE_SELF_SIGNAL_README.md` | Quick reference guide |
| **Final Status** | `GATE_SELF_SIGNAL_FINAL_STATUS.md` | Complete operational summary |
| **Operational Summary** | `GATE_SELF_SIGNAL_OPERATIONAL_SUMMARY.md` | System overview & expectations |
| **Protocol** | `GATE_SELF_SIGNAL_PROTOCOL.md` | 10-minute gate advancement runbook |
| **Infrastructure Fix** | `GATE_SELF_SIGNAL_INFRASTRUCTURE_FIX.md` | Docker exec solution details |
| **Monitoring Loop Script** | `gate-self-signal-monitor.ps1` | Background polling process |
| **Self-Signal Check** | `gate-self-signal-check.ps1` | Individual check execution |
| **Canary Sender** | `send-canary-trace-direct.ps1` | OTLP trace generator |

---

## 🚀 Current Status

```bash
🟢 MONITORING LOOP: RUNNING (background PowerShell)
✅ Polling: Every 30 minutes
✅ Infrastructure: docker exec ClickHouse queries (working)
✅ Schema: span_attributes table (validated)
❌ Traces: Not persisting yet (platform gap confirmed)
⏳ Next check: ~30 min from 16:25
```

---

## 🔄 What's Happening Now

**Background Loop** (`gate-self-signal-monitor.ps1`):

1. Every 30 minutes:
   - Sends canary trace to SigNoz
   - Waits 2 seconds for ingestion
   - Queries ClickHouse: `SELECT count() FROM span_attributes WHERE tagKey='service.name' AND
     stringTagValue='canary-test'`
   - Evaluates exit code
2. If **exit 0** (traces found):
   - 🟢 BREAK loop
   - 🎯 Print alert with next steps
   - 📋 Ready for gate advancement (see **GATE_SELF_SIGNAL_PROTOCOL.md**)
3. If **exit 1** (no traces):
   - ⏳ Wait 30 min
   - 🔄 Retry
4. If **exit 2** (query error):
   - ⚠️ Log error
   - 🔧 Check ClickHouse health
   - 🔄 Retry

---

## 🟢 When Platform Fix Lands (What Happens Automatically)

**Step 1: Detection** (automatic)

```text
[HH:MM:SS] Check #N
✅✅✅ PLATFORM FIX DETECTED ✅✅✅
Exit Code 0: Traces persisting to ClickHouse
```

**Step 2: Gate Advancement** (manual, ~10 min)
Execute **GATE_SELF_SIGNAL_PROTOCOL.md**:

- Verify stability (5 canary bursts)
- Capture evidence (query output + config)
- Regenerate ECRR artifacts
- Post `@cat ready-for-gate` with bundle

**Step 3: Verdict Flip** (automatic)

```text
🟠 WARN → 🟢 GREEN
✅ All 5 criteria met
✅ Evidence attached
✅ Ready to promote
```

---

## 🛠️ Manual Commands

### **Run Self-Signal Check (One-Time)**

```powershell
pwsh -File gate-self-signal-check.ps1
```

**Returns:**

- Exit 0 = traces found ✅
- Exit 1 = no traces (hold) ⏳
- Exit 2 = query failed ⚠️

### **Start Background Loop (If Stopped)**

```powershell
pwsh -File gate-self-signal-monitor.ps1
```

### **Start with Fast Polling (5 min, for testing)**

```powershell
pwsh -File gate-self-signal-monitor.ps1 -IntervalSeconds 300
```

### **Send Canary Manually**

```powershell
pwsh -File send-canary-trace-direct.ps1
```

### **Check Docker Processes**

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### **Query ClickHouse Directly**

```powershell
docker exec signoz-clickhouse clickhouse-client --query `
  "SELECT count() FROM signoz_traces.span_attributes `
   WHERE tagKey='service.name' AND stringTagValue='canary-test' `
   AND timestamp >= now() - INTERVAL 10 MINUTE;"
```

---

## 📊 Expected Timeline

| Phase | Duration | Trigger |
|-------|----------|---------|
| Polling | Ongoing | Every 30 min |
| Platform fix | Variable | SigNoz team |
| Detection | <5 sec | Next poll |
| Alert | Immediate | Loop breaks |
| Validation | 10 min | Runbook execution |
| **GATE: GREEN** | ~15 min | Verdict certified |

---

## 🔐 Gate Advancement Criteria (All 5 Must Pass)

When `exit 0` detected:

1. ✅ Self-signal returns exit code 0 (count() > 0)
2. ✅ Stability verified (canary bursts increase)
3. ✅ Service name preserved (action: insert, not upsert)
4. ✅ Evidence bundle attached (query output + ECRR)
5. ✅ ClickHouse schema/permissions confirmed OK

→ **Only then:** Flip 🟠 WARN → 🟢 GREEN

---

## 📦 Files in This System

**Core Scripts:**

- `gate-self-signal-check.ps1` — Single check execution
- `gate-self-signal-monitor.ps1` — Background polling loop
- `send-canary-trace-direct.ps1` — Canary trace sender

**Documentation:**

- `GATE_SELF_SIGNAL_PROTOCOL.md` — Gate advancement runbook ⭐ READ WHEN ALERT FIRES
- `GATE_SELF_SIGNAL_FINAL_STATUS.md` — Complete operational summary
- `GATE_SELF_SIGNAL_OPERATIONAL_SUMMARY.md` — System overview
- `GATE_SELF_SIGNAL_INFRASTRUCTURE_FIX.md` — Docker exec solution details
- `GATE_SELF_SIGNAL_README.md` — This file

**Prior Diagnostics:**

- `PLATFORM_ESCALATION_DIAGNOSTIC_20251023.md` — Root cause evidence
- `GATE_TRACE_DEBUG_REPORT_20251023.md` — Trace flow analysis
- `signoz-collector-config.yaml` — SigNoz collector config (resource/defaults: insert)

---

## 🟢 When Alert Fires: Immediate Actions

1. **Read:** `GATE_SELF_SIGNAL_PROTOCOL.md` (complete runbook)
2. **Verify:** Run 5 more canary bursts, confirm counts increase
3. **Capture:** Create evidence markdown with query output
4. **Regenerate:** Create ECRR JSON artifact
5. **Signal:** Post `@cat ready-for-gate` with bundle

**Total time:** ~10 minutes to flip verdict

---

## 🧪 Test Evidence

**Last test run:** 2025-10-23 16:27:36

```bash
✅ Canary sent to SigNoz (HTTP 200)
✅ ClickHouse accessed via docker exec
✅ Query schema correct (span_attributes)
✅ Exit code 1 returned (HOLD - no traces yet)
❌ Traces not found (platform gap confirmed)
```

---

## 🚨 If Something Goes Wrong

### **ClickHouse Query Fails (Exit Code 2)**

**Check:**

```powershell
docker ps | findstr signoz-clickhouse
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM system.tables WHERE database='signoz_traces';"
```

**If container not running:**

```powershell
docker-compose up -d signoz-clickhouse
```

### **Loop Stopped**

**Restart:**

```powershell
Start-Process pwsh -ArgumentList "-NoProfile -Command `"pwsh -File gate-self-signal-monitor.ps1`""
```

### **No Traces After Platform Fix**

**Verify config:**

- Ensure `signoz-collector-config.yaml` has `action: insert` (not `upsert`)
- Check Windows otelcol exporter endpoint
- Verify canary is setting `service.name=canary-test`

---

## 🐾 Doctrine Alignment

This system embodies:

- **ECRR:** Evidence-first, autonomous, objective criteria
- **BossCat:** Gate discipline, safe promotion, quality gates
- **Cat Nap Control Room:** Calm, efficient, minimal interruption until fix lands

---

## 📞 Support

**System Working Correctly If:**

- ✅ Background loop running (see `tasklist | findstr pwsh`)
- ✅ Self-signal check returns exit code 1 (hold, no traces)
- ✅ Canary sent successfully (HTTP 200)
- ✅ ClickHouse query responds (zero count while waiting)

**When Alert Fires:**

- ✅ Exit code 0 detected
- ✅ Loop breaks with green alert
- ✅ Next steps printed
- ✅ Ready for 10-minute gate advancement

---

## 🎯 Success Looks Like

```yaml
[16:55:03] Check #2 (elapsed: 30.1 min)
✅✅✅ PLATFORM FIX DETECTED ✅✅✅
Exit Code 0: Traces are persisting to ClickHouse

🎯 NEXT STEPS:
1. Execute gate advancement runbook
2. Verify stability (5 canary bursts)
3. Capture evidence
4. Regenerate ECRR artifacts
5. Post @cat ready-for-gate

See: GATE_SELF_SIGNAL_PROTOCOL.md

🛑 MONITORING LOOP EXITED
Total checks: 2
Total elapsed: 30.1 minutes
```

→ **Follow GATE_SELF_SIGNAL_PROTOCOL.md (10 min) → Verdict: 🟢 GREEN**

---

**🐾 System operational. Monitoring active. Awaiting platform resolution.**

When traces land → Gate advances → Ready certified → 🟢 GREEN
