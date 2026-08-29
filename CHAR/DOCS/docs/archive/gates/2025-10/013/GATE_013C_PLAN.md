# Gate #013C - In-Process Audio Renderer (Native ProjectM Feed)

**Authority:** BossCat OEM (Taskmaster-Overseer)  
**Executor:** Cursor{Implementer}  
**Timing:** Execute AFTER Gate #016 (visual optimizations)  
**Status:** 🟡 **AUTHORIZED - Awaiting Gate #016 Completion**

---

## 🎯 **Executive Decision**

**Option Selected:** Option 1 - In-Process Renderer with native projectM feed  
**Success Probability:** 90% (high confidence)  
**Rationale:** Clean app-layer integration; deterministic; no OS audio plumbing

**De-prioritized:** Option 2 (PulseAudio debug) - attempt only if #013C hits hard dependency  
**Contingency:** Option 3 (abandon audio) - if product decision shifts to visual-only

---

## 🧭 **Lane & Governance**

**Lane:** `lane/audio-013c` (short-lived, single job stream)  
**Allowed Paths:** `app/audio/**`, `app/renderer/**`, `docs/**` (docs only)  
**Roles:** Writer (A) implements | Balancer (B) validates (read-only)  
**Kill-Switch:** `.agent/LOCK` respected at all times

**Budgets (HARD):**
- Jobs: ≤ 2
- Files: ≤ 10 total
- LOC: ≤ 200 per job
- TTL: ≤ 90 min per job
- Retries: ≤ 3 total

**Exit Codes:**
- 0 = GREEN
- 50 = LOCK active
- 51 = Git state blocked
- 52 = Writer conflict
- 53 = Retry exhausted

---

## 📦 **Job A - Injector & Telemetry** (≤200 LOC, ≤6 files)

### **Goal**
Add minimal AudioInjector and ProjectMInjector that wraps native `projectM::feedPCM()` with safe buffering & format conversion.

### **Components**

**1. `app/audio/AudioInjector.hpp/.cpp`**
- Interface + ring buffer
- Convert: 16-bit PCM → float [-1, 1]
- Mono or stereo downmix
- Sample-rate validation (44.1kHz)
- Back-pressure handling

**2. `app/audio/ProjectMInjector.cpp`**
- Concrete adapter for `projectM::feedPCM(...)`
- Steady cadence drain from ring buffer
- Underrun detection and logging

**3. Instrumentation**
- Export: RMS, peak, band-energy [low, mid, high]
- Reuse existing 100-LOC stats tracker
- ECRR evidence trail

### **Tests (Changed-Paths Only)**

**Unit Tests:**
- Synthetic sine burst fixture (silent → loud → silent)
- AM-sine envelope test
- Injector math correctness

**Metric Validity:**
- Compute **Pearson r** between known envelope and measured RMS time-series
- **Accept if r ≥ 0.90** (unit test)
- Replaces invalid variance-scaling metric from Gate #013B

### **Evidence**
- `.agent/EVIDENCE.log` - JSONL events (plan, preflight, edits, tests)
- Test results with Pearson r values
- RMS/peak/band-energy stats

---

## 🔄 **Job B - Renderer Integration** (≤200 LOC, ≤6 files)

### **Goal**
Wire injector into render loop so projectM receives continuous PCM frames without underruns.

### **Components**

**1. Render Loop Integration**
- Hook update tick → drain injector → `feedPCM(...)`
- Frame-time guard to avoid drift
- Underrun handling (zero-fill + log)

**2. Buffer Management**
- Continuous PCM feed
- Underrun detection
- Graceful degradation

### **Go/No-Go Tests**

**Buffer Health:**
- Underrun ratio **< 1%** over 60s synthetic playback
- No dropped frames beyond baseline
- Renderer loop jitter within existing budget

**Signal Tracking:**
- AM-sine envelope → **Pearson r ≥ 0.70** between envelope and visualization intake RMS
- Post-feed measurement (in-process monitor)

**Stability:**
- Frame timing maintained
- No visual regressions

### **Observability**
- Emit synthetic "audio-on" trace (tagged `channel=synthetic, kind=audio`)
- Correlate with existing gate phases
- Final readiness check integration

---

## ✅ **Success Criteria (Gate #013C GREEN)**

**Functional:**
- ✅ ProjectM receives PCM continuously
- ✅ Injector passes **r ≥ 0.90** (unit tests)
- ✅ Integration passes **r ≥ 0.70** (signal tracking)

**Reliability:**
- ✅ Buffer underrun ≤ 1%
- ✅ No frame timing regressions beyond current thresholds

**Process:**
- ✅ ECRR evidence complete
- ✅ Budgets respected (≤2 jobs / ≤10 files / ≤200 LOC per job)
- ✅ Kill-switch honored
- ✅ Changed-paths tests only
- ✅ Balancer validation clean

**Gate Readiness:**
- ✅ All standard gate checks green
- ✅ Synthetic-trace capture in telemetry backend
- ✅ Final verification as per readiness guide

---

## 🔄 **Fallback Tree**

### **If Job A Fails (r < 0.90):**
1. **Rollback → ECRR → Fix math or fixture**
2. Retry once within TTL
3. If still fails: **ABORT #013C**
4. Consider **Option 2** (Pulse/ALSA loopback) within same lane **only if budgets remain**

### **If Job B Fails (underruns >1% or unstable loop):**
1. Revert Job B only
2. Keep injector module (A) if independently green
3. Open follow-up job **within budgets** for scheduler/timing adjustments

### **If Product Decision Shifts to Visual-Only:**
1. Execute **Option 3** (abandon audio)
2. Close audio scope
3. Brief post-mortem in evidence bundle

---

## 📋 **Execution Checklist**

### **Preflight:**
- [ ] Ensure no `.agent/LOCK`
- [ ] Acquire `.agent/JOB.lock`
- [ ] Declare plan (≤150 words)
- [ ] Log to `.agent/EVIDENCE.log`

### **During Execution:**
- [ ] Evidence: JSONL events at each step
- [ ] Tests: Changed-paths only
- [ ] Budgets: Monitor LOC/files/TTL
- [ ] Balancer: Read-only validation

### **Testing:**
- [ ] Unit tests: Pearson r ≥ 0.90
- [ ] Integration: Pearson r ≥ 0.70
- [ ] Buffer health: Underrun < 1%
- [ ] Stability: No regressions

### **Exit:**
- [ ] Rebase-check only (no merge)
- [ ] Drop `.agent/JOB.lock`
- [ ] Update BOSSCAT_LOG.md
- [ ] Signal: `@cat ready-for-gate : #013C`

---

## 🎯 **Gate Rules Applied**

**Rule #1 (Two Make the Strike):**
- A implements (Writer)
- B validates (Balancer, read-only)
- Dual verification before gate opens

**Rule #2 (Single-Writer, Lane-Locked):**
- Only Writer A modifies files
- `.agent/JOB.lock` enforced
- Lane scope: `lane/audio-013c`

**Rule #7 (Changed-Paths Tests):**
- Tests run only for modified code
- No broad test sweeps
- Keep latency low

**Rule #9 (Bots Do Not Merge):**
- No trunk merges by automation
- Human approval required
- Evidence for review only

---

## 📊 **Technical Specifications**

### **Audio Format**
- Input: 16-bit signed PCM, little-endian
- Sample rate: 44.1 kHz
- Channels: Mono or stereo (downmix if needed)
- Output: Float32 [-1.0, 1.0] for projectM

### **Buffer Configuration**
- Ring buffer size: 4096 samples (~93ms at 44.1kHz)
- Underrun threshold: 1% over 60s
- Back-pressure: Drop oldest samples if full

### **Metrics**
- RMS: Root mean square amplitude
- Peak: Maximum absolute amplitude
- Band energy: [low: 0-250Hz, mid: 250-2000Hz, high: 2000Hz+]
- Pearson r: Audio envelope ↔ visual RMS correlation

### **ProjectM Integration**
- API: `projectM::feedPCM(float* samples, int channels, int count)`
- Call frequency: Every render frame (~30 FPS)
- Buffer drain: ~1470 samples per frame (44100/30)

---

## 🔍 **Lessons from Gate #013B**

**What Went Wrong:**
- Built monitor instead of injector
- No `projectM::feedPCM()` calls
- Invalid reactivity metric (variance scaling)
- Mischaracterized status (AMBER vs. BLOCKED)

**How #013C Fixes It:**
1. **Direct injection:** Actual `projectM::feedPCM()` calls ✓
2. **Valid metrics:** Real Pearson correlation (r ≥ 0.90/0.70) ✓
3. **Clear success criteria:** Functional + reliability + process ✓
4. **Honest reporting:** ECRR discipline throughout ✓

---

## 📅 **Timing**

**Prerequisites:**
- ✅ Gate #016 (visual optimizations) must be GREEN
- ✅ Gate #008 reconciliation complete
- ✅ Working tree clean
- ✅ Kill-switch clear

**Execution Window:**
- Start: After Gate #016 completion
- Duration: ≤ 90 min per job (2 jobs max)
- Signal: `@cat ready-for-gate : #013C` when complete

**Dependencies:**
- libprojectM API documentation
- Existing 100-LOC stats tracker
- Ring buffer implementation
- PCM format conversion utilities

---

## 🐾 **Status**

**Current:** 🟡 **AUTHORIZED - Awaiting Gate #016**  
**Next:** Complete Gate #016 (visual optimizations)  
**Then:** Execute Gate #013C per this plan  
**Signal:** `@cat ready-for-gate : #013C` on completion

**Authority:** BossCat OEM (Taskmaster-Overseer)  
**Governance:** Immutable Persona v1.1 + ECRR + Two-Agent Guard  
**Discipline:** Changed-paths tests only | No bot merges | Evidence first

---

**Cursor{Implementer} - Plan captured, awaiting Gate #016 completion.**

