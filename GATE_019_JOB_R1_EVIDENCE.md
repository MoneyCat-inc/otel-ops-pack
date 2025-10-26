# Gate #019 — Job R1: Envelope Calibration & Intake Mapping

**Authority:** BossCat OEM  
**Date:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Job:** R1 - Envelope Calibration (≤200 LOC, ≤6 files)  
**Status:** 🔵 **CODE COMPLETE - TESTING REQUIRED**

---

## 📋 Implementation Summary

**Objective:** Add attack/release envelope follower to audio-injector to improve reactivity tracking.

**Files Modified:** 2
1. `viz-engine-projectm/audio-injector.hpp` (+8 LOC)
2. `viz-engine-projectm/audio-injector.cpp` (+38 LOC)

**Total LOC:** 46 (well under 200 LOC budget)

---

## 🔧 Changes Implemented

### 1. Envelope Follower - Header (`audio-injector.hpp`)

**Added:**
- `float envelope() const` — Public getter for envelope output
- `float envelope_` — Private state variable for envelope follower
- `float attack_coeff_` — Attack time constant coefficient
- `float release_coeff_` — Release time constant coefficient
- `void init_envelope(...)` — Initialize envelope parameters

### 2. Envelope Follower - Implementation (`audio-injector.cpp`)

**Added:**

#### Constructor Initialization
```cpp
AudioBuffer::AudioBuffer(size_t capacity)
    : envelope_(0.0f)  // Initialize envelope state
{
    init_envelope(20.0f, 150.0f, 44100.0f);  // 20ms attack, 150ms release
}
```

#### Envelope Follower Logic (`update_stats()`)
```cpp
// Gate #019: Update envelope follower with attack/release
float error = abs_sample - envelope_;
if (error > 0.0f) {
    // Attack: signal rising
    envelope_ += attack_coeff_ * error;
} else {
    // Release: signal falling
    envelope_ += release_coeff_ * error;
}
```

#### Coefficient Calculation (`init_envelope()`)
```cpp
void AudioBuffer::init_envelope(float attack_ms, float release_ms, float sample_rate) {
    // Convert time constants (ms) to per-sample coefficients
    // Formula: coeff = 1 - exp(-1 / (time_ms * sample_rate / 1000))
    
    float attack_samples = attack_ms * sample_rate / 1000.0f;
    float release_samples = release_ms * sample_rate / 1000.0f;
    
    // Prevent division by zero
    if (attack_samples < 1.0f) attack_samples = 1.0f;
    if (release_samples < 1.0f) release_samples = 1.0f;
    
    attack_coeff_ = 1.0f - std::exp(-1.0f / attack_samples);
    release_coeff_ = 1.0f - std::exp(-1.0f / release_samples);
}
```

---

## 📐 Technical Details

### Envelope Follower Algorithm

**Type:** Asymmetric attack/release envelope follower

**Parameters:**
- Attack time: 20ms (fast response to transients)
- Release time: 150ms (smooth decay)
- Sample rate: 44100 Hz

**Behavior:**
- **Attack:** When signal rises, envelope tracks quickly (20ms time constant)
- **Release:** When signal falls, envelope decays slowly (150ms time constant)
- **Output:** Smooth envelope that highlights mid-energy dynamics

### Mathematical Basis

**Time Constant to Coefficient Conversion:**
```
coeff = 1 - exp(-1 / (time_ms * sample_rate / 1000))
```

This formula ensures proper exponential behavior where:
- 63% of target reached after 1 time constant
- 95% of target reached after 3 time constants
- 99% of target reached after 5 time constants

**Attack Coefficient (20ms @ 44.1kHz):**
```
attack_samples = 20 * 44100 / 1000 = 882 samples
attack_coeff = 1 - exp(-1 / 882) ≈ 0.001134
```

**Release Coefficient (150ms @ 44.1kHz):**
```
release_samples = 150 * 44100 / 1000 = 6615 samples
release_coeff = 1 - exp(-1 / 6615) ≈ 0.000151
```

---

## ⚠️ Testing Status: MANUAL COMPILATION REQUIRED

**Current Status:** Code complete, but **not yet compiled or tested**.

### Compilation Required

The C++ code must be compiled before testing:

```bash
# Navigate to viz-engine-projectm directory
cd viz-engine-projectm

# Compile audio-injector (example command - adjust for your build system)
g++ -c audio-injector.cpp -o audio-injector.o -std=c++17 -O2

# Compile and link test
g++ audio-test.cpp audio-injector.o -o audio-test -std=c++17 -O2 -lm

# Run test
./audio-test
```

### Expected Test Results

**Test Suite:** `audio-test.cpp` (existing from Gate #013)

**Scenarios:** 3 synthetic audio tests (60s each)
1. **Sine Burst:** Pure tone with burst envelope
2. **AM Sine:** Amplitude-modulated sine wave
3. **Bass Sweep:** (if implemented)

**Acceptance Criteria:**
- Pearson r(envelope, expected) ≥ **0.78** for each scenario
- Underrun ratio < **0.5%**

**Previous Baseline (Gate #013):**
- Target: r ≥ 0.90
- Achieved: r = 1.0000 (sine burst), r = 0.9999 (AM sine)

**Gate #019 Target:**
- Lower threshold: r ≥ **0.78** (more practical for real-world audio)
- Should pass easily given previous 0.99+ performance

---

## 📊 Expected Evidence (Post-Testing)

Once compiled and tested, the evidence should include:

### 1. Test Output Table
```
Scenario       | RMS Correlation | Envelope Correlation | Underrun % | Status
---------------|-----------------|----------------------|------------|--------
Sine Burst     | 1.0000          | 0.xxxx               | 0.00%      | PASS
AM Sine        | 0.9999          | 0.xxxx               | 0.00%      | PASS
Bass Sweep     | x.xxxx          | 0.xxxx               | 0.00%      | PASS/FAIL
```

### 2. Envelope Tracking Validation
- Compare `audio_envelope` output vs expected envelope shape
- Verify attack time ≈ 20ms (fast rise)
- Verify release time ≈ 150ms (slow decay)

### 3. Audio Metrics Export
- Confirm `AudioBuffer::envelope()` accessor works
- Values in range [0.0, 1.0]
- Smooth transitions (no glitches)

---

## 🚧 Blocker: C++ Compilation Required

**Issue:** Cursor{Implementer} cannot compile or execute C++ code.

**Required Actions:**
1. **Compile:** Build audio-injector.cpp and audio-test.cpp
2. **Execute:** Run `./audio-test` to generate results
3. **Verify:** Confirm Pearson r ≥ 0.78 for all scenarios
4. **Document:** Capture test output in this evidence file

**Options:**
- **Option A:** Manual compilation and testing by human operator
- **Option B:** CI/CD pipeline compilation (if configured)
- **Option C:** Docker container build with test execution

---

## 📋 Job R1 Checklist

**Code Complete:**
- ✅ Envelope follower added to `audio-injector.hpp`
- ✅ Attack/release logic implemented in `audio-injector.cpp`
- ✅ Time constant calculation correct (exponential coefficients)
- ✅ Initialization with default parameters (20ms/150ms)
- ✅ Public accessor `envelope()` exposed
- ✅ LOC budget: 46/200 (23% used) ✅

**Testing Required:**
- 🔲 Compile C++ code
- 🔲 Run audio-test.cpp
- 🔲 Verify Pearson r ≥ 0.78 (3/3 scenarios)
- 🔲 Confirm underrun < 0.5%
- 🔲 Capture test output
- 🔲 Update this evidence file with results

**Integration (Optional for Job R2):**
- 🔲 Expose envelope metric via `/audio/stats` endpoint
- 🔲 Add overlay meter in Milk v0 (optional)
- 🔲 Export to `/milk/health` JSON (optional)

---

## 🎯 Next Steps

**Immediate:**
1. **Compile C++ code** using project build system
2. **Run tests** and capture output
3. **Verify KPIs** (r ≥ 0.78, underrun < 0.5%)
4. **Update this document** with test results

**If Tests Pass:**
- Mark Job R1 as GREEN
- Proceed to Job R2 (Feature Flag + Canary)
- Integrate envelope metric into API

**If Tests Fail:**
- Debug envelope follower coefficients
- Adjust attack/release time constants
- Re-test until r ≥ 0.78 achieved

---

## 🔒 Budget Compliance

| Budget Item | Limit | Used | Status |
|-------------|-------|------|--------|
| **Files** | ≤ 6 | 2 | ✅ (33%) |
| **LOC** | ≤ 200 | 46 | ✅ (23%) |
| **Scope** | C++/renderer only | audio-injector only | ✅ |

---

## 🐾 Job R1 Status

**Code Implementation:** ✅ **COMPLETE**  
**Testing:** 🔲 **BLOCKED** (requires C++ compilation)  
**Verdict:** **PENDING MANUAL TESTING**

**Recommendation:**  
Compile and test the C++ code to verify envelope follower performance. If Pearson r ≥ 0.78 across all scenarios, mark Job R1 GREEN and proceed to Job R2.

---

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Date:** 2025-10-26  
**Status:** Code complete, awaiting manual compilation and testing

🐾 *Envelope follower implemented. Compilation required to verify KPIs.*

