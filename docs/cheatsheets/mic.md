# Low-Latency Microphone Capture Cheat Sheet

**Issue**: Browser DSP adds ~50ms latency, breaking real-time audio processing  
**Solution**: Disable all browser audio processing and optimize AudioContext

## 🚨 **Critical Settings**

### **Always Disable Browser DSP**
```typescript
const stream = await navigator.mediaDevices.getUserMedia({
  audio: {
    echoCancellation: false,    // ❌ Disable
    noiseSuppression: false,    // ❌ Disable  
    autoGainControl: false,     // ❌ Disable
    sampleRate: 48000,          // ✅ High sample rate
    channelCount: 1,            // ✅ Mono for processing
    latency: 0.01               // ✅ Minimum latency
  }
})
```

### **Optimize AudioContext**
```typescript
const audioContext = new AudioContext({
  latencyHint: 0,              // ✅ Minimum latency
  sampleRate: 48000,           // ✅ Match mic sample rate
  bufferSize: 128              // ✅ Small buffer (if supported)
})
```

## 🎯 **Target Performance**

- **End-to-end latency**: < 20ms
- **Buffer size**: 128 frames (2.67ms @ 48kHz)
- **No underruns**: Monitor `audioCtx.baseLatency`

## 🔧 **Implementation**

### **Complete Setup**
```typescript
class LowLatencyMic {
  private audioContext: AudioContext
  private source: MediaStreamAudioSourceNode
  private analyser: AnalyserNode
  
  async init() {
    // Get optimized stream
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: false,
        noiseSuppression: false,
        autoGainControl: false,
        sampleRate: 48000,
        channelCount: 1
      }
    })
    
    // Create optimized context
    this.audioContext = new AudioContext({
      latencyHint: 0,
      sampleRate: 48000
    })
    
    // Connect nodes
    this.source = this.audioContext.createMediaStreamSource(stream)
    this.analyser = this.audioContext.createAnalyser()
    this.analyser.fftSize = 2048
    this.analyser.smoothingTimeConstant = 0
    
    this.source.connect(this.analyser)
    
    // Log latency info
    console.log('Base latency:', this.audioContext.baseLatency)
    console.log('Sample rate:', this.audioContext.sampleRate)
  }
  
  // Process audio in 128-frame blocks
  processAudio() {
    const bufferLength = this.analyser.frequencyBinCount
    const dataArray = new Uint8Array(bufferLength)
    this.analyser.getByteFrequencyData(dataArray)
    
    // Process in chunks of 128 frames
    for (let i = 0; i < bufferLength; i += 128) {
      const chunk = dataArray.slice(i, i + 128)
      this.processChunk(chunk)
    }
  }
}
```

## 🔍 **Monitoring & Debugging**

### **Log Latency Metrics**
```typescript
// Monitor latency
setInterval(() => {
  console.log('Base latency:', audioContext.baseLatency)
  console.log('Output latency:', audioContext.outputLatency)
  console.log('Total latency:', audioContext.baseLatency + audioContext.outputLatency)
}, 1000)
```

### **Detect Underruns**
```typescript
// Check for audio dropouts
let lastProcessTime = 0
const processAudio = () => {
  const now = performance.now()
  const delta = now - lastProcessTime
  lastProcessTime = now
  
  // Should be ~2.67ms for 128 frames @ 48kHz
  if (delta > 5) {
    console.warn('Audio underrun detected:', delta + 'ms')
  }
  
  requestAnimationFrame(processAudio)
}
```

## 🚨 **Common Issues**

### **Firefox Defaults**
**Problem**: Firefox enables EC/NS by default  
**Solution**: Always explicitly disable in getUserMedia

### **Chrome Buffer Size**
**Problem**: Chrome uses 512-frame buffers  
**Solution**: Use `latencyHint: 0` and monitor `baseLatency`

### **Safari Limitations**
**Problem**: Safari has different audio processing  
**Solution**: Test on Safari and adjust settings accordingly

## 🎯 **Workarounds**

### **If Latency Too High**
1. Check browser audio settings
2. Disable system audio enhancements
3. Use dedicated audio interface
4. Monitor `audioCtx.baseLatency`

### **If Underruns Occur**
1. Increase buffer size temporarily
2. Reduce processing complexity
3. Use Web Workers for heavy processing
4. Implement adaptive buffering

### **If Audio Quality Poor**
1. Increase sample rate to 48kHz
2. Use higher bit depth if available
3. Check microphone quality
4. Verify no system audio processing

## 📋 **Testing Checklist**

- [ ] DSP disabled in getUserMedia
- [ ] AudioContext latencyHint: 0
- [ ] Base latency < 20ms
- [ ] No audio underruns
- [ ] 128-frame processing blocks
- [ ] Sample rate 48kHz
- [ ] Mono channel for processing

## 🔧 **Browser-Specific Notes**

### **Chrome**
- Use `latencyHint: 0` for minimum latency
- Monitor `baseLatency` for actual performance
- 512-frame buffers by default

### **Firefox**
- Explicitly disable all DSP options
- Better Web Audio API support
- More predictable latency

### **Safari**
- Limited Web Audio API features
- Different latency characteristics
- Test thoroughly on target devices

---

**Remember**: Every millisecond counts in real-time audio processing!
