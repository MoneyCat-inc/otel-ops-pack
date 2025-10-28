# Investor Demo - Dress Rehearsal Script

**Duration:** 7 minutes  
**Authority:** BossCat OEM  
**Version:** 1.0 (Phase 4)  
**Format:** Timestamped beats with exact clicks and expected visuals

---

## Pre-Demo Checklist (T-5 minutes)

- [ ] All 15 Docker containers running (`docker ps | wc -l` = 15+)
- [ ] SigNoz accessible: http://localhost:8080 → `{"status":"ok"}`
- [ ] Windows Collector: `sc query otelcol-contrib` → RUNNING
- [ ] No `.agent/JOB.lock` present
- [ ] Services NOT yet started (will start during demo)
- [ ] Browsers ready: Chrome/Edge with 4 tabs pre-opened
  - Tab 1: SigNoz (http://localhost:8080)
  - Tab 2: Executive Dashboard (file:///C:/otel/docs/demo/dashboard.html)
  - Tab 3: Data Room (file:///C:/otel/docs/demo/data-room.html)
  - Tab 4: This script (for timing reference)

---

## Timestamped Beats (7 minutes)

### 0:00 - 0:15 | Opening (Context Setting)

**Talking Points:**
> "Good morning. We're demoing our observability platform that proves operational safety through automated telemetry, hard performance gates, and disciplined AI agents."

**Action:** None (voice only)

**Expected State:** Slides visible, audience engaged

---

### 0:15 - 1:00 | Healthy System Baseline

**Talking Points:**
> "Let me show you a production .NET service with zero-code OpenTelemetry. Watch the live metrics."

**Actions:**
- [0:15] Switch to **Tab 2 (Executive Dashboard)**
- [0:20] Point to metrics tiles:
  - P95: 112ms (GREEN)
  - Error Rate: 0.0% (GREEN)
  - Throughput: 10 RPS
  - Gate: GREEN (0)

**Expected Visuals:**
- All 4 tiles visible, color-coded green
- Build SHA displayed (e.g., 4c66253)
- "Last update" timestamp refreshing

**Timing Note:** Keep this under 45 seconds (establish baseline quickly)

---

### 1:00 - 1:30 | Start Traffic (Laminar Flow)

**Talking Points:**
> "Our test harness generates controlled traffic. This is our baseline - 10 requests per second, steady state."

**Actions:**
- [1:00] Switch to **Tab 3 (Data Room)**
- [1:05] Click **"Start"** on "Laminar Flow" card
- [1:10] Point to:
  - Status badge turns GREEN ("Active")
  - Metrics update: RPS = 10
  - Action log shows: "[timestamp] Started laminar traffic scenario"

**Expected Visuals:**
- Laminar Flow card: status "Active" (green badge)
- Live Metrics panel: RPS climbs to 10
- Action log: New entry at top

**Timing Note:** Quick click, no explanation needed beyond "baseline traffic"

---

### 1:30 - 2:30 | Trace Drilldown

**Talking Points:**
> "Every request is traced end-to-end. Let me show you a typical transaction."

**Actions:**
- [1:30] Switch to **Tab 1 (SigNoz)**
- [1:35] Navigate: Traces tab → Filter: `service.name = "bosscat-svc2-api"`
- [1:45] Click on recent trace (any with ~100-150ms duration)
- [1:50] Expand span tree:
  ```
  GET /test (120ms total)
  ├─ ASP.NET Core (10ms)
  ├─ db.query.users (45ms)
  ├─ cache.get (12ms)
  └─ HttpClient → svc3-worker (48ms)
  ```
- [2:00] Point to attributes panel:
  - service.name
  - trace_id
  - http.method, http.status_code
  - deployment.environment = "investor-demo"

**Expected Visuals:**
- Trace list: Multiple recent traces visible
- Trace detail: Full span hierarchy with timings
- Attributes: Clean, well-labeled metadata

**Timing Note:** This is key - investors want to see the "magic" of distributed tracing

---

### 2:30 - 3:00 | Performance Gate Explanation

**Talking Points:**
> "We use k6 load tests with hard thresholds. The pipeline fails automatically if SLAs are breached - no human judgment required."

**Actions:**
- [2:30] Switch to **Tab 4 (or GitHub)** - show `.github/workflows/perf-gate-demo.yml`
- [2:40] Scroll to thresholds section (lines 34-48):
  ```yaml
  thresholds:
    'http_req_duration': ['p(95)<300']
    'http_req_failed': ['rate<0.01']
  ```
- [2:50] Point out: `abortOnFail: true` (auto-block on breach)

**Expected Visuals:**
- Workflow YAML visible
- Thresholds clearly highlighted
- Explain: "300ms p95, <1% errors - pipeline stops if breached"

**Timing Note:** Keep concise - just prove auto-gating exists

---

### 3:00 - 4:30 | Chaos Drill (The Highlight)

**Talking Points:**
> "Real systems face failures. Watch how we inject a network delay and the system responds."

**Actions:**
- [3:00] Switch to **Tab 3 (Data Room)**
- [3:05] Click **"Inject"** on "Network Delay" card
- [3:10] Observe:
  - Chaos warning banner appears: "⚠️ Chaos Active"
  - Network Delay status → "Active" (green badge)
  - Action log: "[timestamp] ⚠️ Chaos injection: network-delay activated"
- [3:20] Switch to **Tab 2 (Dashboard)**
- [3:25] Watch P95 metric update:
  - Value changes: 112ms → 550ms
  - Color changes: GREEN → RED
  - Subtext: "Target: <300ms" (breached)
- [3:35] Click on **P95 Latency** tile (drilldown to SigNoz)
- [3:40] SigNoz opens to filtered view: `duration > 500ms`
- [3:50] Open slow trace, point to HttpClient span: ~500ms duration
- [4:00] **Optional:** If Bedrock integrated:
  - Click "Explain" button
  - AI summary appears: "Network latency spike detected between svc2 and svc3..."
- [4:10] Explain: "We can see exactly where the delay is - the HttpClient outgoing span"

**Expected Visuals:**
- Data Room: Chaos indicator banner visible
- Dashboard: P95 tile RED
- SigNoz: Slow traces visible, span breakdown shows bottleneck
- (Optional) Bedrock explanation box with natural language summary

**Timing Note:** This is the climax - take 90 seconds, show the full observability stack

---

### 4:30 - 5:15 | Recovery & Evidence

**Talking Points:**
> "When issues occur, we follow ECRR: Evidence, Contain, Rollback, Report. Watch the recovery."

**Actions:**
- [4:30] Switch to **Tab 3 (Data Room)**
- [4:35] Click **"Clear"** on "Network Delay" card
- [4:40] Observe:
  - Chaos warning banner disappears
  - Network Delay status → "Inactive"
  - Action log: "[timestamp] ✅ Chaos injection: network-delay cleared"
- [4:50] Switch to **Tab 2 (Dashboard)**
- [4:55] Watch P95 metric normalize:
  - Value: 550ms → 112ms
  - Color: RED → GREEN
- [5:05] Explain: "System self-heals, full evidence captured in logs"

**Expected Visuals:**
- Data Room: No chaos active
- Dashboard: All tiles GREEN
- Metrics returned to baseline

**Timing Note:** Quick recovery (45 seconds) to show resilience

---

### 5:15 - 6:15 | Safety & Governance Proof

**Talking Points:**
> "Every change follows disciplined workflows. Agent A writes under strict budgets, Agent B monitors. No silent merges, full auditability."

**Actions:**
- [5:15] Open file explorer: `C:\otel\docs\BossCat\`
- [5:20] Open **BOSSCAT_LOG.md** in editor
- [5:25] Scroll to recent entries (top 5-10 lines):
  - Point out: Budget compliance, LOC counts, authority chain
  - Example: "Gate #020-R1B APPROVED GREEN... 56 LOC net... BossCat OEM"
- [5:40] Navigate to `.agent/` directory
- [5:45] Show files:
  - PLAN.md (execution plan)
  - EVIDENCE.log (timestamped actions)
  - No JOB.lock (clean state)
- [5:55] Explain A/B agent pattern:
  - "Agent A writes code, max 200 LOC per job"
  - "Agent B monitors, validates, never writes"
  - "BossCat OEM approves via `@cat ready-for-gate` signal"

**Expected Visuals:**
- BOSSCAT_LOG: Recent entries with budget compliance
- .agent/: Evidence files present, no locks
- Clean, organized artifact structure

**Timing Note:** This proves discipline - take 60 seconds to establish credibility

---

### 6:15 - 7:00 | Q&A & Wrap-Up

**Talking Points:**
> "Questions? I can show specific traces, explain the guardrails, or run another chaos scenario."

**Common Q&A Paths:**

**Q: "Show me the database query in a trace"**
- [6:20] SigNoz → Traces → Open any trace
- [6:25] Expand: Show `db.query.users` span with SQL statement
- [6:30] Point to attributes: db.system, db.statement, duration

**Q: "What if error rate spikes?"**
- [6:20] Data Room → Click "Trigger" on "Service Down"
- [6:25] Dashboard → Error Rate tile turns RED
- [6:30] SigNoz → Show error traces with status "error"
- [6:35] Clear chaos, show recovery

**Q: "How do budgets work?"**
- [6:20] Show `docs/comfort-cat/ROLES.md`
- [6:25] Point to: "≤2 jobs, ≤10 files, ≤200 LOC per job"
- [6:30] Show example from BOSSCAT_LOG with actual counts

**Wrap-Up (6:50):**
> "To summarize: automated observability, hard performance gates, AI-powered insights, and disciplined agent workflows. Everything you've seen is production-ready. Happy to share the evidence bundle."

**Final Action [6:55]:**
- Show: `artifacts/demo/investor-evidence-pack-[timestamp].zip`
- Offer: "This ZIP has all performance reports, traces, and governance audit trails"

---

## Timing Checkpoints

| Checkpoint | Time | What's Visible |
|------------|------|----------------|
| Intro | 0:00 | Voice only |
| Dashboard baseline | 0:30 | 4 green tiles |
| Traffic started | 1:15 | Laminar active |
| Trace drilldown | 2:00 | Span tree visible |
| k6 thresholds | 2:50 | YAML with abort flags |
| Chaos inject | 3:30 | Red P95 tile |
| Slow trace | 4:00 | Bottleneck span |
| Recovery | 5:00 | Green baseline |
| BOSSCAT_LOG | 5:30 | Budget compliance |
| Agent artifacts | 6:00 | Evidence files |
| Q&A | 6:15 | Interactive |
| Wrap-up | 7:00 | End |

---

## Fallback Strategies

### If SigNoz is slow/unresponsive
- Use pre-captured screenshots from `artifacts/demo/screenshots/`
- Explain: "In this screenshot, you can see..."
- Keep timing on track

### If a chaos scenario doesn't trigger
- Skip to next beat
- Use alternative chaos scenario (CPU throttle instead of network delay)
- Acknowledge: "For time, let me show you the recovery pattern..."

### If services crash mid-demo
- Use Data Room "Stop All" button
- Fallback to screenshot walkthrough
- Recovery: "The beauty of ECRR is we have full rollback capability"

### If Q&A runs long
- Time-box each question to 30 seconds
- Offer: "I can show you that in detail after if you'd like"
- Wrap by 7:30 max

---

## Critical Success Factors

**Must achieve:**
1. ✅ Show at least ONE complete trace with span tree
2. ✅ Demonstrate ONE chaos scenario (injected → detected → recovered)
3. ✅ Prove auto-gating (k6 thresholds with abortOnFail)
4. ✅ Show BOSSCAT_LOG audit trail with budget compliance

**Nice to have:**
- Bedrock "Explain" feature (if AWS configured)
- Multiple chaos scenarios
- Live metrics refresh during demo
- Evidence bundle generation

**Can skip if time-constrained:**
- ICF convergence panel
- Multiple trace examples
- Deep-dive into specific span attributes

---

## Rehearsal Notes

**Practice runs:** 3-5 times before investor presentation

**Timing calibration:**
- Run with timer visible
- Mark actual vs planned times
- Adjust talking points if running over

**Technical dry-runs:**
- Fresh boot: Test from clean Docker state
- Service failures: Rehearse recovery steps
- Browser refresh: Verify all links work

**Presentation polish:**
- Memorize key metrics: "112ms baseline, 300ms threshold, 0% errors"
- Practice smooth transitions between tabs
- Eliminate "ums" and "let me see..."

---

## Post-Demo Actions

**Immediate (within 5 minutes):**
- [ ] Stop all traffic scenarios (Data Room)
- [ ] Clear all chaos injections
- [ ] Verify metrics returned to baseline
- [ ] Export evidence bundle: `pwsh scripts/demo/export-evidence.ps1`

**Follow-up (within 24 hours):**
- [ ] Send evidence bundle to investors
- [ ] Log demo feedback in BOSSCAT_LOG
- [ ] Update rehearsal notes with lessons learned
- [ ] Commit any on-the-fly fixes

**Next iteration:**
- [ ] Review what landed vs what flopped
- [ ] Update timing based on actual duration
- [ ] Add any Q&A paths that came up
- [ ] Improve weakest section (usually chaos drill or governance proof)

---

## Emergency Contacts

**Technical Issues:**
- BossCat OEM: Fallback screenshots ready
- Cursor{Implementer}: Quick fixes during prep

**Demo Flow Issues:**
- Skip to next beat if segment fails
- Use "Let me show you instead..." with screenshots
- Never debug live - acknowledge and move on

---

**Authority:** BossCat OEM  
**Version:** 1.0  
**Last Rehearsal:** [DATE]  
**Rehearsal Outcome:** [GREEN/AMBER/RED]  
**Notes:** [Key learnings]

🐾 Ready for investor presentation

