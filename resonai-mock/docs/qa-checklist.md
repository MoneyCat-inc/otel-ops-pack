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

## T3 Safety Guardrails Testing

### Strain Detection Coverage
- [ ] **Loudness Detection**
  - [ ] Detects sustained loud speech above threshold (-12 dBFS)
  - [ ] Requires minimum duration (1.2 seconds) for accuracy
  - [ ] Handles short loud bursts without false positives
  - [ ] Mock fixtures produce deterministic results

- [ ] **Jitter Trend Detection**
  - [ ] Monitors pitch instability over time window (1.5 seconds)
  - [ ] Detects rising jitter patterns (>20 cents change)
  - [ ] Calculates exponential moving average correctly
  - [ ] Handles stable pitch without false positives

- [ ] **Minimum Voiced Duration**
  - [ ] Requires 800ms minimum voiced time for detection
  - [ ] Prevents false positives from short utterances
  - [ ] Accurately calculates voiced duration from frames

### Cooldown Flow Testing
- [ ] **SOVT Cooldown Card**
  - [ ] Displays when strain is detected
  - [ ] Shows supportive messaging: "Let's reset and keep it comfy"
  - [ ] Includes progress ring (no motion under reduced-motion)
  - [ ] Rotates through exercises (lip trill, straw phonation, breathing)

- [ ] **Exercise Rotation**
  - [ ] Changes exercises every 15 seconds
  - [ ] Provides clear instructions for each exercise
  - [ ] Announces exercise changes via aria-live
  - [ ] Completes after configured cooldown duration (45 seconds)

### Configuration & Tuning
- [ ] **Threshold Controls**
  - [ ] Loudness threshold adjustable (-30 to 0 dBFS)
  - [ ] Duration threshold adjustable (500-3000ms)
  - [ ] Jitter threshold adjustable (10-50 cents)
  - [ ] Cooldown duration adjustable (15-120 seconds)

- [ ] **Preset Management**
  - [ ] Default preset (balanced sensitivity)
  - [ ] Conservative preset (more sensitive)
  - [ ] Relaxed preset (less sensitive)
  - [ ] Dynamic configuration updates

### Mock Data & Fixtures
- [ ] **Deterministic Fixtures**
  - [ ] Loud passage triggers strain detection
  - [ ] Rising jitter pattern triggers strain detection
  - [ ] Neutral passage does NOT trigger strain
  - [ ] Short voiced passage does NOT trigger strain
  - [ ] Mixed pattern triggers strain with multiple reasons

- [ ] **Fixture Testing**
  - [ ] All fixtures produce expected results
  - [ ] URL parameters work (?mock=loud|rising-jitter|neutral)
  - [ ] Mock mode enables testing without microphone
  - [ ] Results are reproducible across test runs

### Accessibility Testing
- [ ] **Screen Reader Support**
  - [ ] aria-live="polite" for strain announcements
  - [ ] Proper ARIA labels on all controls
  - [ ] Keyboard navigation throughout interface
  - [ ] Skip links for efficient navigation

- [ ] **Reduced Motion**
  - [ ] Respects `prefers-reduced-motion: reduce`
  - [ ] Disables animations when preference detected
  - [ ] Shows reduced motion indicator
  - [ ] Maintains functionality without motion

- [ ] **Color & Contrast**
  - [ ] Meets WCAG AA standards (4.5:1 ratio)
  - [ ] Status colors distinguishable without color alone
  - [ ] High contrast mode support

### Data & Privacy
- [ ] **Local-First Storage**
  - [ ] Strain events stored in IndexedDB only
  - [ ] No audio data uploaded to servers
  - [ ] Export functionality works offline
  - [ ] Clear data option for privacy

- [ ] **Event Schema**
  - [ ] strainFlag field present (boolean)
  - [ ] strainReasons field present (string array)
  - [ ] cooldownSec field present (number)
  - [ ] Event versioning and build info included

### Performance Testing
- [ ] **Real-time Processing**
  - [ ] <100ms latency for frame processing
  - [ ] Smooth UI updates during monitoring
  - [ ] No frame drops during detection
  - [ ] Efficient memory usage

- [ ] **Cooldown Performance**
  - [ ] Progress ring updates smoothly
  - [ ] Exercise rotation works reliably
  - [ ] Timer accuracy within 1 second
  - [ ] No memory leaks during extended use

### Edge Cases
- [ ] **Audio Edge Cases**
  - [ ] Handles frames with zero RMS
  - [ ] Handles frames with no voiced content
  - [ ] Handles frames with low confidence
  - [ ] Handles empty frame lists gracefully

- [ ] **Detection Edge Cases**
  - [ ] Short utterances don't trigger false positives
  - [ ] Creaky voice endings handled correctly
  - [ ] Mixed patterns detected appropriately
  - [ ] Configuration changes applied immediately

### Integration Testing
- [ ] **Labs Integration**
  - [ ] Strain labs page loads correctly
  - [ ] Navigation links work properly
  - [ ] Mock mode toggles correctly
  - [ ] Preset switching works reliably

- [ ] **Cooldown Integration**
  - [ ] Cooldown card displays when strain detected
  - [ ] Practice flow pauses during cooldown
  - [ ] Resumes practice after cooldown completion
  - [ ] Skip option works (if implemented)

### Security & Isolation
- [ ] **CSP Compliance**
  - [ ] No inline styles or scripts
  - [ ] Strict Content Security Policy enforced
  - [ ] No CSP violations in console

- [ ] **Cross-Origin Isolation**
  - [ ] COOP/COEP headers configured
  - [ ] SharedArrayBuffer support available
  - [ ] crossOriginIsolated returns true

- [ ] **Privacy Protection**
  - [ ] No audio data leaked to external services
  - [ ] All processing happens in browser
  - [ ] Export data contains no sensitive information

## T4 Offline Isolation Testing

### Cross-Origin Isolation Coverage
- [ ] **Online Isolation**
  - [ ] `window.crossOriginIsolated === true` on all routes
  - [ ] SharedArrayBuffer available when isolation is enabled
  - [ ] COOP/COEP headers present on all responses
  - [ ] No COEP/CORS console errors for assets

- [ ] **Service Worker Integration**
  - [ ] Service Worker registers successfully on first visit
  - [ ] Headers preserved when serving offline content
  - [ ] Cross-origin isolation maintained in offline mode
  - [ ] Service Worker updates don't break isolation

- [ ] **Offline Mode Testing**
  - [ ] Isolation maintained when going offline
  - [ ] Page reloads successfully offline
  - [ ] Navigation between pages works offline
  - [ ] Mixed online/offline scenarios handled correctly

### Header Configuration
- [ ] **COOP/COEP Headers**
  - [ ] Cross-Origin-Opener-Policy: same-origin
  - [ ] Cross-Origin-Embedder-Policy: require-corp
  - [ ] Cross-Origin-Resource-Policy: cross-origin
  - [ ] Permissions-Policy: cross-origin-isolated=()

- [ ] **Security Headers**
  - [ ] X-Content-Type-Options: nosniff
  - [ ] Referrer-Policy: strict-origin-when-cross-origin
  - [ ] X-Frame-Options: SAMEORIGIN
  - [ ] Content-Security-Policy configured correctly

- [ ] **Service Worker Headers**
  - [ ] Service-Worker-Allowed: /
  - [ ] Cache-Control: no-cache, no-store, must-revalidate
  - [ ] COOP/COEP headers preserved in offline responses

### Asset Loading
- [ ] **Worklet Files**
  - [ ] Content-Type: application/javascript
  - [ ] COOP/COEP headers present
  - [ ] No COEP errors when loading worklets
  - [ ] Blob: support enabled in CSP

- [ ] **Font Files**
  - [ ] Font-src 'self' in CSP
  - [ ] No cross-origin font loading issues
  - [ ] Proper MIME type handling

- [ ] **Image Assets**
  - [ ] Img-src 'self' data: https: blob: in CSP
  - [ ] No COEP errors for images
  - [ ] Proper CORS handling for external images

### Browser Compatibility
- [ ] **Firefox Support**
  - [ ] Cross-origin isolation enabled
  - [ ] SharedArrayBuffer available
  - [ ] Service Worker functions correctly
  - [ ] No console errors

- [ ] **Chromium Support**
  - [ ] Cross-origin isolation enabled
  - [ ] SharedArrayBuffer available
  - [ ] Service Worker functions correctly
  - [ ] No console errors

- [ ] **WebKit Support**
  - [ ] Cross-origin isolation enabled
  - [ ] SharedArrayBuffer available
  - [ ] Service Worker functions correctly
  - [ ] No console errors

### Service Worker Functionality
- [ ] **Registration & Activation**
  - [ ] Registers on first visit
  - [ ] Activates successfully
  - [ ] Handles updates gracefully
  - [ ] Unregisters old versions

- [ ] **Offline Caching**
  - [ ] Caches offline pages correctly
  - [ ] Serves cached content with headers
  - [ ] Handles cache misses gracefully
  - [ ] Updates cache when online

- [ ] **Header Preservation**
  - [ ] Critical headers preserved offline
  - [ ] CSP headers maintained
  - [ ] Security headers intact
  - [ ] Isolation headers preserved

### Error Handling
- [ ] **Service Worker Errors**
  - [ ] Handles registration failures gracefully
  - [ ] Continues working if SW fails
  - [ ] Logs errors appropriately
  - [ ] Doesn't break page functionality

- [ ] **Network Errors**
  - [ ] Handles offline scenarios
  - [ ] Provides fallback content
  - [ ] Maintains isolation during errors
  - [ ] Recovers when back online

- [ ] **Asset Loading Errors**
  - [ ] Handles missing assets gracefully
  - [ ] No COEP errors in console
  - [ ] Continues functioning with missing assets
  - [ ] Logs appropriate warnings

### Performance Testing
- [ ] **Service Worker Performance**
  - [ ] Fast registration and activation
  - [ ] Efficient caching strategy
  - [ ] Minimal impact on page load
  - [ ] Memory usage within limits

- [ ] **Offline Performance**
  - [ ] Fast offline page serving
  - [ ] Responsive navigation offline
  - [ ] Efficient cache utilization
  - [ ] No memory leaks

### Integration Testing
- [ ] **Page Integration**
  - [ ] All pages work offline
  - [ ] Navigation works offline
  - [ ] Forms and interactions work offline
  - [ ] Audio worklets function offline

- [ ] **Feature Integration**
  - [ ] MEMX functionality offline
  - [ ] Prosody scenarios offline
  - [ ] Strain detection offline
  - [ ] Practice flows offline

### Security Testing
- [ ] **Header Security**
  - [ ] All security headers present
  - [ ] CSP properly configured
  - [ ] No security vulnerabilities
  - [ ] Proper CORS handling

- [ ] **Isolation Security**
  - [ ] Cross-origin isolation maintained
  - [ ] SharedArrayBuffer properly secured
  - [ ] No cross-origin leaks
  - [ ] Proper resource policies

### Monitoring & Debugging
- [ ] **Console Monitoring**
  - [ ] No COEP/CORS errors
  - [ ] No Service Worker errors
  - [ ] Appropriate debug logging
  - [ ] Clean console output

- [ ] **Status Monitoring**
  - [ ] Service Worker status visible
  - [ ] Isolation status visible
  - [ ] SharedArrayBuffer status visible
  - [ ] Debug information available
