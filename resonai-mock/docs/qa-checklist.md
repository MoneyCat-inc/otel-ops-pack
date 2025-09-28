# QA Checklist - Resonai Voice Practice

## Overview
This document provides comprehensive testing guidelines for the Resonai voice practice application, including the new T2 Prosody Scenarios feature.

## T2 Prosody Scenarios Testing

### Scenario Coverage
- [ ] **Voicemail Intro Scenario**
  - [ ] Loads with correct phrase: "Hi, this is [your name]. I'm calling about..."
  - [ ] Target: End with gentle fall
  - [ ] Expressiveness threshold: 0.3
  - [ ] Mock mode generates realistic results
  - [ ] Real recording mode works with microphone

- [ ] **Meeting Intro Scenario**
  - [ ] Loads with correct phrase: "Good morning everyone, thanks for joining today's call."
  - [ ] Target: End with slight rise
  - [ ] Expressiveness threshold: 0.4
  - [ ] Mock mode generates realistic results
  - [ ] Real recording mode works with microphone

### End-Rise/Fall Detection
- [ ] **Rise Detection**
  - [ ] Correctly identifies upward pitch slope in last 30% of utterance
  - [ ] Confidence threshold ≥70% for clean trials
  - [ ] Handles edge cases (too few frames, low confidence)

- [ ] **Fall Detection**
  - [ ] Correctly identifies downward pitch slope in last 30% of utterance
  - [ ] Confidence threshold ≥70% for clean trials
  - [ ] Handles edge cases (too few frames, low confidence)

- [ ] **Neutral Classification**
  - [ ] Correctly identifies flat or uncertain patterns
  - [ ] Used when confidence <70% or insufficient data

### Expressiveness Measurement
- [ ] **Baseline Comparison**
  - [ ] Compares current variation to user's baseline
  - [ ] Caps expressiveness at 2x baseline
  - [ ] Handles missing baseline gracefully

- [ ] **Absolute Measurement**
  - [ ] Uses pitch and energy variation when no baseline
  - [ ] Normalizes to 0-1 scale
  - [ ] Prevents gaming with exaggerated swoops

### Feedback System
- [ ] **Affirming Language**
  - [ ] Uses constructive, positive feedback
  - [ ] Avoids binary "gendered" terms
  - [ ] Provides specific, actionable suggestions

- [ ] **Feedback Examples**
  - [ ] "✅ Gentle fall detected — clear statement"
  - [ ] "✅ Nice variety in pitch — expressive delivery"
  - [ ] "💡 Try ending with a gentle fall for a clear statement"

### Accessibility Testing
- [ ] **Screen Reader Support**
  - [ ] aria-live="polite" for verdict announcements
  - [ ] Proper ARIA labels on all interactive elements
  - [ ] Keyboard navigation works throughout

- [ ] **Reduced Motion**
  - [ ] Respects `prefers-reduced-motion: reduce`
  - [ ] Disables animations when preference is set
  - [ ] Shows reduced motion indicator

- [ ] **Color Contrast**
  - [ ] Meets WCAG AA standards (4.5:1 ratio)
  - [ ] Status colors are distinguishable
  - [ ] No reliance on color alone for information

### Mock Data Testing
- [ ] **Mock Mode Functionality**
  - [ ] Toggle works correctly
  - [ ] Generates realistic scenario results
  - [ ] Provides variety in outcomes
  - [ ] No microphone access required

- [ ] **URL Parameters**
  - [ ] `?mock=voicemail` enables voicemail mock
  - [ ] `?mock=meeting` enables meeting mock
  - [ ] Mock mode persists across page interactions

### Data & Metrics
- [ ] **Event Schema Extension**
  - [ ] scenarioId field present
  - [ ] riseFallLabel field present
  - [ ] expressiveness01 field present (0-1)
  - [ ] pass field present (boolean)

- [ ] **Session Summaries**
  - [ ] Stored in IndexedDB (local-first)
  - [ ] Export functionality works
  - [ ] Clear results functionality works
  - [ ] Progress tracking accurate

### Performance Testing
- [ ] **Real-time Processing**
  - [ ] <200ms latency for frame processing
  - [ ] No frame drops during recording
  - [ ] Smooth UI updates at 60fps

- [ ] **Memory Usage**
  - [ ] No memory leaks during extended use
  - [ ] Efficient frame buffer management
  - [ ] Proper cleanup on scenario completion

## General Application Testing

### Core Functionality
- [ ] **Practice Session Flow**
  - [ ] Warmup → Practice → Reflection phases work
  - [ ] Real-time metrics display correctly
  - [ ] Session data saves to IndexedDB
  - [ ] Export/delete functionality works

- [ ] **Audio Pipeline**
  - [ ] Microphone access granted/denied handling
  - [ ] AudioWorklet processing stable
  - [ ] Low-latency audio capture (<50ms)
  - [ ] EC/NS/AGC disabled in constraints

### Cross-Browser Testing
- [ ] **Chrome/Chromium**
  - [ ] Full functionality works
  - [ ] Cross-origin isolation enabled
  - [ ] SAB/WASM threads available

- [ ] **Firefox**
  - [ ] Full functionality works
  - [ ] AudioWorklet stability
  - [ ] Performance within acceptable limits

- [ ] **Safari/WebKit**
  - [ ] Core functionality works
  - [ ] Graceful degradation for unsupported features
  - [ ] No critical errors

### Mobile Testing
- [ ] **Touch Interface**
  - [ ] Touch targets ≥44px
  - [ ] Swipe gestures work (if implemented)
  - [ ] Orientation changes handled

- [ ] **Performance**
  - [ ] Acceptable latency on mid-tier devices
  - [ ] No excessive battery drain
  - [ ] Memory usage within limits

### Security & Privacy
- [ ] **Local-First Architecture**
  - [ ] No audio uploaded to servers
  - [ ] All data stays in browser
  - [ ] Export functionality works offline

- [ ] **CSP Compliance**
  - [ ] Strict CSP headers enforced
  - [ ] No inline styles or scripts
  - [ ] COOP/COEP headers configured

### Error Handling
- [ ] **Microphone Access**
  - [ ] Graceful handling of denied access
  - [ ] Clear error messages
  - [ ] Recovery suggestions provided

- [ ] **Audio Context Issues**
  - [ ] Handles suspended context
  - [ ] Automatic recovery when possible
  - [ ] User guidance for manual recovery

- [ ] **Network Issues**
  - [ ] Works offline (local-first)
  - [ ] Graceful degradation for SigNoz integration
  - [ ] No blocking of core functionality

## Automated Testing

### Unit Tests
- [ ] **Prosody Engine Tests**
  - [ ] Slope classification accuracy
  - [ ] Expressiveness calculation
  - [ ] Scenario evaluation logic
  - [ ] Edge case handling

- [ ] **Component Tests**
  - [ ] ScenarioCard rendering
  - [ ] Mock data generation
  - [ ] Accessibility attributes
  - [ ] State management

### E2E Tests
- [ ] **Playwright Tests**
  - [ ] Full scenario workflows
  - [ ] Cross-browser compatibility
  - [ ] Accessibility compliance
  - [ ] Performance benchmarks

### Integration Tests
- [ ] **Audio Pipeline**
  - [ ] End-to-end audio processing
  - [ ] Real-time feedback accuracy
  - [ ] Memory usage monitoring
  - [ ] Error recovery testing

## Performance Benchmarks

### Acceptable Thresholds
- [ ] **Audio Latency**: <200ms end-to-end
- [ ] **UI Responsiveness**: <16ms frame time
- [ ] **Memory Usage**: <100MB peak
- [ ] **CPU Usage**: <5% during active use
- [ ] **Battery Impact**: Minimal on mobile devices

### Load Testing
- [ ] **Extended Sessions**
  - [ ] 30+ minute practice sessions
  - [ ] Multiple scenario attempts
  - [ ] Memory cleanup verification
  - [ ] Performance degradation monitoring

## Release Checklist

### Pre-Release
- [ ] All unit tests passing
- [ ] E2E tests passing on all browsers
- [ ] Performance benchmarks met
- [ ] Accessibility audit completed
- [ ] Security review completed

### Post-Release
- [ ] Monitor error rates
- [ ] Track performance metrics
- [ ] Collect user feedback
- [ ] Plan improvements for next iteration

## Known Issues & Limitations

### Current Limitations
- [ ] **LPC Formant Tracking**: May be unstable, vowel classifier fallback available
- [ ] **Device Variability**: Bluetooth mics at 16kHz may cause drift
- [ ] **Mobile Stability**: Mid-tier Android devices need validation
- [ ] **Expressiveness Gaming**: Can be gamed with exaggerated swoops (caps applied)

### Future Improvements
- [ ] **Community Features**: Safe sharing and moderation flows
- [ ] **Advanced Analytics**: More sophisticated pattern recognition
- [ ] **Personalization**: Adaptive thresholds based on user progress
- [ ] **Offline Isolation**: Service Worker improvements for offline use
