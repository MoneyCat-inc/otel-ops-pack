# 🎯 Milestone 1: Resonance & Audio Stability - Detailed Implementation Plan

## 📊 Current State Analysis

**Current Audio Engine Architecture:**
- **Pitch Detection**: CREPE-tiny ONNX via WASM + YIN fallback ✅
- **Energy Analysis**: RMS calculation with high/low frequency tracking ✅  
- **Resonance Detection**: LPC processor stub with mock formant estimation ⚠️
- **Prosody Analysis**: Rise/fall classification with expressiveness metrics ✅

**Critical Gap Identified:**
The LPC processor (`lpc-processor.js`) is currently a **stub implementation** with mock formant estimation. This is the primary source of resonance instability mentioned in the audit reports.

---

## 🎯 Milestone 1 Objectives

### **Primary Goal**
Replace the LPC stub with a robust CNN vowel classifier fallback system to achieve <5% false positives on vowel classification across 10+ devices.

### **Secondary Goals**
- Implement circular buffer for audio samples with adaptive sizing
- Add device detection and auto-reinit for sample rate mismatches  
- Calibrate loudness thresholds with beta cohort data
- Expose prosody settings in Practice HUD for transparency

---

## ✅ Technical Tasks Breakdown

### **Task 1.1: CNN Vowel Classifier Prototype** 
*Timeline: Week 1-2 | Owner: Cursor Agent | Priority: CRITICAL*

#### **Implementation Details**
1. **Model Selection & Training**
   - Use lightweight CNN architecture (MobileNet-style) for vowel classification
   - Train on TIMIT dataset with 5 vowel classes: /a/, /e/, /i/, /o/, /u/
   - Target model size: <2MB for WASM deployment
   - Accuracy target: >95% on test set

2. **WASM Integration**
   - Convert trained model to ONNX format
   - Implement WASM wrapper for browser compatibility
   - Add fallback to LPC if CNN fails to load
   - Optimize for <10ms inference time per frame

3. **Integration Points**
   - Replace `estimateFormants()` in `lpc-processor.js`
   - Add confidence scoring for vowel classification
   - Implement graceful degradation to spectral centroid if CNN unavailable

#### **Acceptance Criteria**
- [ ] CNN model achieves >95% accuracy on TIMIT test set
- [ ] WASM model loads in <500ms on mid-tier devices
- [ ] Inference time <10ms per 256-sample frame
- [ ] Graceful fallback to LPC if CNN fails
- [ ] Model size <2MB compressed

#### **Test Coverage Requirements**
```typescript
// Unit Tests
describe('CNN Vowel Classifier', () => {
  test('loads model successfully', async () => {
    const classifier = new CNNVowelClassifier();
    await classifier.load();
    expect(classifier.isLoaded).toBe(true);
  });
  
  test('classifies vowels with >95% accuracy', () => {
    const testCases = loadTIMITTestSet();
    const results = testCases.map(tc => classifier.classify(tc.audio));
    const accuracy = calculateAccuracy(results, testCases.labels);
    expect(accuracy).toBeGreaterThan(0.95);
  });
  
  test('falls back to LPC on model failure', () => {
    const classifier = new CNNVowelClassifier();
    classifier.simulateFailure();
    const result = classifier.classify(testAudio);
    expect(result.method).toBe('lpc-fallback');
  });
});

// Integration Tests  
describe('LPC Processor Integration', () => {
  test('uses CNN classifier when available', () => {
    const processor = new LPCProcessor();
    processor.enableCNN();
    const formants = processor.estimateFormants(testBuffer);
    expect(formants.method).toBe('cnn');
    expect(formants.confidence).toBeGreaterThan(0.8);
  });
});
```

---

### **Task 1.2: Circular Buffer Implementation**
*Timeline: Week 2 | Owner: Cursor Agent | Priority: HIGH*

#### **Implementation Details**
1. **Buffer Architecture**
   - Implement ring buffer with configurable size (1024-4096 samples)
   - Add adaptive sizing based on device performance
   - Support multiple audio channels (mono/stereo)
   - Thread-safe operations for AudioWorklet environment

2. **Performance Optimization**
   - Use TypedArray for memory efficiency
   - Implement zero-copy operations where possible
   - Add buffer overflow/underflow detection
   - Optimize for 60fps updates with <5% CPU usage

3. **Integration Points**
   - Replace fixed buffer in `lpc-processor.js`
   - Add buffer size configuration to WorkletManager
   - Implement performance monitoring and auto-tuning

#### **Acceptance Criteria**
- [ ] Buffer handles 1024-4096 samples without memory leaks
- [ ] Adaptive sizing reduces CPU usage by >20% on low-end devices
- [ ] Zero buffer overflows/underflows in 24-hour stress test
- [ ] Thread-safe operations verified with concurrent access tests

#### **Test Coverage Requirements**
```typescript
describe('Circular Buffer', () => {
  test('handles overflow gracefully', () => {
    const buffer = new CircularBuffer(1024);
    const largeData = new Float32Array(2048);
    buffer.write(largeData);
    expect(buffer.getSize()).toBe(1024);
  });
  
  test('adaptive sizing reduces CPU usage', () => {
    const buffer = new CircularBuffer(1024);
    buffer.enableAdaptiveSizing();
    const startCPU = measureCPUUsage();
    // Simulate low-end device conditions
    buffer.adaptToPerformance(0.3); // 30% CPU budget
    const endCPU = measureCPUUsage();
    expect(endCPU).toBeLessThan(startCPU * 0.8);
  });
});
```

---

### **Task 1.3: Device Detection & Auto-Reinit**
*Timeline: Week 3 | Owner: Cursor Agent | Priority: HIGH*

#### **Implementation Details**
1. **Device Detection**
   - Detect Bluetooth vs USB microphone types
   - Monitor sample rate changes (16kHz vs 48kHz)
   - Detect device disconnection/reconnection
   - Track device-specific performance characteristics

2. **Auto-Reinit System**
   - Automatically restart AudioWorklet on sample rate changes
   - Recalibrate buffer sizes for new device characteristics
   - Preserve user settings across device changes
   - Add user notification for device changes

3. **Integration Points**
   - Extend WorkletManager with device monitoring
   - Add device change callbacks to audio engine
   - Implement graceful recovery from device failures

#### **Acceptance Criteria**
- [ ] Detects Bluetooth mic sample rate drift within 100ms
- [ ] Auto-reinit completes in <2 seconds without audio interruption
- [ ] User settings preserved across device changes
- [ ] Zero audio dropouts during device transitions

---

### **Task 1.4: Loudness Threshold Calibration**
*Timeline: Week 4 | Owner: ChatGPT Agent + QA Scribe | Priority: HIGH*

#### **Implementation Details**
1. **Cohort Testing Setup**
   - Recruit 8-12 beta users with diverse voice characteristics
   - Implement A/B testing framework for threshold variations
   - Collect 2 weeks of usage data per user
   - Analyze false positive/negative rates

2. **Threshold Optimization**
   - Test current >=5s @ 0.8 RMS rule
   - Experiment with adaptive thresholds based on user baseline
   - Implement user-specific calibration during onboarding
   - Add manual override controls

3. **Data Collection & Analysis**
   - Log all loudness events with context
   - Analyze patterns in false triggers
   - Correlate with user feedback and retention
   - Generate calibration recommendations

#### **Acceptance Criteria**
- [ ] <2% false positive rate on loudness detection
- [ ] >90% user satisfaction with loudness feedback
- [ ] Adaptive thresholds improve accuracy by >30%
- [ ] Manual override available for all users

---

### **Task 1.5: Practice HUD Transparency Controls**
*Timeline: Week 4 | Owner: Cursor Agent | Priority: MEDIUM*

#### **Implementation Details**
1. **HUD Enhancement**
   - Add threshold visibility toggles
   - Show real-time confidence scores
   - Display current detection method (CNN vs LPC)
   - Add manual threshold adjustment sliders

2. **User Experience**
   - Progressive disclosure of advanced controls
   - Tooltips explaining each threshold
   - Reset to defaults functionality
   - Export/import settings for sharing

3. **Accessibility**
   - ARIA labels for all controls
   - Keyboard navigation support
   - Screen reader compatibility
   - High contrast mode support

#### **Acceptance Criteria**
- [ ] All thresholds visible and adjustable in HUD
- [ ] Real-time confidence scores displayed
- [ ] 100% keyboard navigation support
- [ ] Settings persist across sessions

---

## 🧪 Test Coverage Requirements

### **Unit Test Coverage: >95%**
- CNN vowel classifier accuracy and performance
- Circular buffer overflow/underflow handling
- Device detection and auto-reinit logic
- Loudness threshold calibration algorithms
- HUD control accessibility and functionality

### **Integration Test Coverage: >90%**
- End-to-end audio processing pipeline
- Device change scenarios and recovery
- Cross-browser compatibility (Chrome, Firefox, Safari)
- Mobile device performance validation

### **E2E Test Coverage: >80%**
- Complete practice flow with audio analysis
- Device switching during practice sessions
- Threshold adjustment and persistence
- Error recovery and graceful degradation

---

## 🎯 Acceptance Criteria Summary

### **Technical Requirements**
- [ ] **Resonance Stability**: <5% false positives on vowel classification across 10+ devices
- [ ] **Audio Latency**: <140ms p95 processing time on mid-tier Android
- [ ] **Device Compatibility**: 100% on Chrome/Firefox desktop, 90% mobile
- [ ] **Performance**: <5% CPU usage for audio processing at 60fps

### **User Experience Requirements**
- [ ] **Loudness Calibration**: <2% false positive rate with cohort validation
- [ ] **Transparency**: All thresholds visible and adjustable in Practice HUD
- [ ] **Reliability**: Zero audio dropouts during device transitions
- [ ] **Accessibility**: 100% keyboard navigation and screen reader support

### **Quality Requirements**
- [ ] **Test Coverage**: >95% unit, >90% integration, >80% E2E
- [ ] **Performance**: <10ms CNN inference, <500ms model loading
- [ ] **Compatibility**: Graceful fallback to LPC if CNN unavailable
- [ ] **Documentation**: Complete API docs and troubleshooting guides

---

## ⚠️ Risks & Mitigations

### **High-Risk Items**

#### **Risk 1: CNN Model Performance**
- **Risk**: CNN model fails to achieve >95% accuracy or has >10ms inference time
- **Mitigation**: Implement LPC fallback, optimize model architecture, use quantization
- **Contingency**: Fall back to improved LPC implementation with spectral analysis

#### **Risk 2: WASM Compatibility**
- **Risk**: CNN model fails to load on certain browsers or devices
- **Mitigation**: Test on wide range of devices, implement progressive loading, add fallback
- **Contingency**: Use WebGL-based inference or server-side processing

#### **Risk 3: Device Detection Accuracy**
- **Risk**: Auto-reinit fails or causes audio dropouts
- **Mitigation**: Implement buffering, test on diverse devices, add manual controls
- **Contingency**: Disable auto-reinit, require manual device selection

### **Medium-Risk Items**

#### **Risk 4: Cohort Testing Delays**
- **Risk**: Unable to recruit 8-12 beta users within timeline
- **Mitigation**: Start recruitment early, offer incentives, use internal team for initial testing
- **Contingency**: Use synthetic data and expert review for threshold calibration

#### **Risk 5: Performance Regression**
- **Risk**: New audio processing increases CPU usage beyond 5%
- **Mitigation**: Implement performance budgets, add monitoring, optimize algorithms
- **Contingency**: Reduce processing frequency or disable features on low-end devices

---

## 👥 Role Assignments

### **Cursor Agent (Primary Implementer)**
- **Tasks**: 1.1 (CNN Classifier), 1.2 (Circular Buffer), 1.3 (Device Detection), 1.5 (HUD Controls)
- **Deliverables**: Code implementation, unit tests, integration tests
- **Timeline**: Weeks 1-4
- **Success Criteria**: All technical tasks completed with >95% test coverage

### **ChatGPT Agent (Orchestrator)**
- **Tasks**: 1.4 (Cohort Testing), overall coordination, risk management
- **Deliverables**: Testing strategy, cohort recruitment, data analysis
- **Timeline**: Weeks 1-4
- **Success Criteria**: Cohort testing completed with actionable insights

### **QA Scribe (Validator)**
- **Tasks**: Test execution, quality assurance, documentation
- **Deliverables**: Test results, quality reports, user acceptance testing
- **Timeline**: Weeks 2-4
- **Success Criteria**: All acceptance criteria validated with evidence

### **Codex Agent (Coordinator)**
- **Tasks**: CI/CD integration, security review, performance monitoring
- **Deliverables**: Automated testing, security audit, performance benchmarks
- **Timeline**: Weeks 1-4
- **Success Criteria**: All code integrated with green CI pipeline

---

## 📈 Success Metrics & Monitoring

### **Real-Time Metrics**
- Audio processing latency (p50, p95, p99)
- CNN inference time per frame
- Device detection accuracy and response time
- CPU usage during audio processing
- Buffer overflow/underflow events

### **Daily Reviews**
- Test coverage reports
- Performance benchmark results
- Device compatibility test results
- User feedback from cohort testing

### **Weekly Assessments**
- Milestone progress against acceptance criteria
- Risk assessment and mitigation status
- Resource allocation and timeline adjustments
- Quality metrics and technical debt

---

## 🚀 Immediate Next Steps (This Week)

1. **Start CNN Model Development** (Cursor Agent)
   - Research lightweight CNN architectures for vowel classification
   - Set up training pipeline with TIMIT dataset
   - Create WASM integration prototype

2. **Set Up Cohort Testing Infrastructure** (ChatGPT Agent)
   - Design A/B testing framework for threshold calibration
   - Create user recruitment materials and consent forms
   - Set up data collection and analysis pipeline

3. **Implement Circular Buffer Prototype** (Cursor Agent)
   - Create basic ring buffer implementation
   - Add performance monitoring and adaptive sizing
   - Integrate with existing LPC processor

4. **Create Device Detection Framework** (Cursor Agent)
   - Implement device monitoring in WorkletManager
   - Add sample rate change detection
   - Create auto-reinit mechanism prototype

5. **Set Up Testing Infrastructure** (QA Scribe)
   - Create test automation for audio processing
   - Set up performance benchmarking tools
   - Prepare device compatibility test suite

---

*This implementation plan provides a detailed roadmap for achieving resonance and audio stability in Resonai. Each task includes specific technical requirements, acceptance criteria, test coverage, and risk mitigation strategies to ensure successful delivery within the 4-week timeline.*
