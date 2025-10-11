# Chaos Engineering Drill Playbooks

**Authority:** BossCat OEM Gate #006 P1-F  
**Lane:** DOCS  
**Tool:** Enhanced Data Room (laminar/chaotic/canary modes)  
**Status:** ✅ STANDARDIZED PLAYBOOKS READY

---

## 🎯 **Standard Drill Scenarios**

### Scenario 1: Network Delay + Packet Loss

**Objective:** Verify system resilience under network degradation  
**Tool:** Enhanced Data Room → Chaotic mode

**Steps:**
1. Open `docs/BossCat/data_room_enhanced.html`
2. Click "Chaotic" mode
3. Set: Delay 100-500ms, Packet loss 5-10%
4. Send burst of 100 logs
5. Monitor: Throughput drop, latency spike, recovery time

**Expected Behavior:**
- ✅ Latency elevated but <500ms
- ✅ Error rate <10%
- ✅ System recovers within 30s
- ❌ RED: System hangs, OOM, or >50% errors

---

### Scenario 2: Service Down (Failover)

**Objective:** Validate circuit-breaker + failover behavior  
**Tool:** Manual stop/start + Data Room monitoring

**Steps:**
1. Run: `docker stop signoz-otel-collector`
2. Send logs via Data Room (expect failures)
3. Monitor: Error handling, queue behavior
4. Run: `docker start signoz-otel-collector`
5. Verify: Auto-recovery, queue drain

**Expected Behavior:**
- ✅ Graceful error handling (no crash)
- ✅ Queue buffers requests
- ✅ Auto-reconnect within 60s
- ✅ Queued data delivered post-recovery
- ❌ RED: Data loss, service crash, no recovery

---

### Scenario 3: CPU Throttle + Memory Spike

**Objective:** Ensure stability under resource pressure  
**Tool:** Docker resource limits + load testing

**Steps:**
1. Apply CPU limit: `docker update --cpus="0.5" signoz-otel-collector`
2. Apply memory limit: `docker update --memory="512m" signoz-otel-collector`
3. Send sustained load (500 logs/sec for 5 minutes)
4. Monitor: CPU usage, memory growth, responsiveness
5. Remove limits: `docker update --cpus="0" --memory="0"`

**Expected Behavior:**
- ✅ System remains responsive (no freeze)
- ✅ Memory stays <512MB (no OOM)
- ✅ Throughput degrades gracefully (<50% drop)
- ✅ Recovery after limits removed
- ❌ RED: OOM crash, complete stall, >90% throughput loss

---

## 🧪 **Data Room Enhanced Controls**

**Modes:**
- **Laminar:** Clean baseline (no chaos)
- **Chaotic:** Network delay + packet loss
- **Canary:** Periodic health pings

**Metrics Tracked:**
- Throughput (logs/sec)
- Latency (p50, p95, max)
- Success rate
- Error count
- Recovery time

**UI Location:** `docs/BossCat/data_room_enhanced.html`

---

## 📋 **Drill Execution Template**

### Pre-Drill Checklist
- [ ] Baseline metrics captured
- [ ] SigNoz stack healthy
- [ ] Data Room accessible
- [ ] Monitoring active

### During Drill
- [ ] Document start time
- [ ] Capture metrics (screenshot/logs)
- [ ] Note anomalies
- [ ] Monitor recovery

### Post-Drill
- [ ] Compare vs baseline
- [ ] Document pass/fail
- [ ] Identify improvements
- [ ] File ECRR report

---

## 🎯 **Pass/Fail Criteria**

**PASS** ✅ if:
- System recovers automatically
- No data loss
- Error rate within tolerance (<10%)
- Performance degrades gracefully

**FAIL** ❌ if:
- System crashes/hangs
- Data loss occurs
- No auto-recovery
- Error rate >50%

---

## 🔄 **Rollback Procedures**

**Emergency Stop:**
```bash
# Stop chaos
# - Data Room: Click "Stop" button
# - Docker: docker restart signoz-otel-collector
# - Limits: docker update --cpus="0" --memory="0" <container>
```

**Recovery Verification:**
```bash
# Check health
curl http://localhost:8080/api/v1/health

# Verify OTLP
Test-NetConnection localhost -Port 5318

# Send canary
pnpm emit:enhanced
```

---

**Authority:** BossCat OEM P1-F  
**Seal:** 🐾 Chaos Drill Playbooks Standardized

