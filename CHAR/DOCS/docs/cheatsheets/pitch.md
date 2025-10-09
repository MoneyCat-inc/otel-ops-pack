# Pitch Tracking Stack Cheat Sheet

**Issue**: Pitch tracking fails on low-end devices or produces octave errors  
**Solution**: CREPE-tiny primary with YIN fallback, plus smoothing filters

## 🎯 **Primary Stack: CREPE-tiny**

### **ONNX/WASM Implementation**
```typescript
import { InferenceSession } from 'onnxruntime-web'

class CREPEPitchTracker {
  private session: InferenceSession
  
  async init() {
    // Load CREPE-tiny model
    this.session = await InferenceSession.create('/models/crepe-tiny.onnx', {
      executionProviders: ['wasm'],
      graphOptimizationLevel: 'all'
    })
  }
  
  async getPitch(audioBuffer: Float32Array): Promise<number> {
    // Preprocess audio (normalize, window)
    const preprocessed = this.preprocessAudio(audioBuffer)
    
    // Run inference
    const results = await this.session.run({
      input: new Tensor('float32', preprocessed, [1, 1024])
    })
    
    // Extract pitch from output
    const pitch = this.extractPitch(results.output)
    return pitch
  }
  
  private preprocessAudio(buffer: Float32Array): Float32Array {
    // Normalize to [-1, 1]
    const normalized = buffer.map(x => x / 32768.0)
    
    // Apply window function (Hann)
    const windowed = normalized.map((x, i) => {
      const window = 0.5 * (1 - Math.cos(2 * Math.PI * i / (buffer.length - 1)))
      return x * window
    })
    
    return windowed
  }
}
```

## 🔄 **Fallback: YIN Algorithm**

### **WASM/TypeScript Implementation**
```typescript
class YINPitchTracker {
  private threshold = 0.15
  private sampleRate = 48000
  
  getPitch(audioBuffer: Float32Array): number {
    const yinBuffer = this.yinAlgorithm(audioBuffer)
    const tau = this.findTrough(yinBuffer)
    
    if (tau === -1) return 0
    
    // Interpolate for better accuracy
    const interpolatedTau = this.interpolateTrough(yinBuffer, tau)
    const pitch = this.sampleRate / interpolatedTau
    
    return pitch
  }
  
  private yinAlgorithm(buffer: Float32Array): Float32Array {
    const yinBuffer = new Float32Array(buffer.length / 2)
    
    for (let tau = 0; tau < yinBuffer.length; tau++) {
      let sum = 0
      for (let i = 0; i < buffer.length - tau; i++) {
        const delta = buffer[i] - buffer[i + tau]
        sum += delta * delta
      }
      yinBuffer[tau] = sum
    }
    
    return yinBuffer
  }
}
```

## 🎛️ **Smoothing Filters**

### **Median Filter (5-frame)**
```typescript
class MedianFilter {
  private buffer: number[] = []
  private size = 5
  
  filter(value: number): number {
    this.buffer.push(value)
    if (this.buffer.length > this.size) {
      this.buffer.shift()
    }
    
    // Sort and return median
    const sorted = [...this.buffer].sort((a, b) => a - b)
    const mid = Math.floor(sorted.length / 2)
    return sorted[mid]
  }
}
```

### **Kalman Filter for Octave Errors**
```typescript
class KalmanPitchFilter {
  private state = { pitch: 0, velocity: 0 }
  private covariance = { pitch: 1, velocity: 1 }
  private processNoise = 0.01
  private measurementNoise = 0.1
  
  filter(measuredPitch: number): number {
    // Predict
    this.state.pitch += this.state.velocity
    this.covariance.pitch += this.processNoise
    
    // Update
    const kalmanGain = this.covariance.pitch / (this.covariance.pitch + this.measurementNoise)
    this.state.pitch += kalmanGain * (measuredPitch - this.state.pitch)
    this.covariance.pitch *= (1 - kalmanGain)
    
    // Detect octave errors
    if (Math.abs(measuredPitch - this.state.pitch) > this.state.pitch * 0.5) {
      // Likely octave error, use previous state
      return this.state.pitch
    }
    
    return this.state.pitch
  }
}
```

## 🔧 **Complete Implementation**

### **Adaptive Pitch Tracker**
```typescript
class AdaptivePitchTracker {
  private crepe: CREPEPitchTracker
  private yin: YINPitchTracker
  private medianFilter: MedianFilter
  private kalmanFilter: KalmanPitchFilter
  private useCREPE = true
  private performanceMonitor = new PerformanceMonitor()
  
  async init() {
    try {
      await this.crepe.init()
      this.useCREPE = true
    } catch (error) {
      console.warn('CREPE failed, falling back to YIN:', error)
      this.useCREPE = false
    }
    
    this.medianFilter = new MedianFilter()
    this.kalmanFilter = new KalmanPitchFilter()
  }
  
  async getPitch(audioBuffer: Float32Array): Promise<number> {
    const startTime = performance.now()
    
    let rawPitch: number
    
    if (this.useCREPE) {
      try {
        rawPitch = await this.crepe.getPitch(audioBuffer)
      } catch (error) {
        console.warn('CREPE failed, switching to YIN')
        this.useCREPE = false
        rawPitch = this.yin.getPitch(audioBuffer)
      }
    } else {
      rawPitch = this.yin.getPitch(audioBuffer)
    }
    
    // Apply smoothing filters
    const medianFiltered = this.medianFilter.filter(rawPitch)
    const finalPitch = this.kalmanFilter.filter(medianFiltered)
    
    // Monitor performance
    const processingTime = performance.now() - startTime
    this.performanceMonitor.record(processingTime)
    
    // Auto-fallback if performance degrades
    if (processingTime > 16 && this.useCREPE) {
      console.warn('CREPE too slow, switching to YIN')
      this.useCREPE = false
    }
    
    return finalPitch
  }
}
```

## 🚨 **Common Issues**

### **CREPE Fails on Low-End Mobile**
**Problem**: ONNX runtime too slow  
**Solution**: Auto-fallback to YIN algorithm

### **Octave Errors**
**Problem**: Pitch jumps by octave (2x frequency)  
**Solution**: Kalman filter with octave error detection

### **Noisy Pitch Data**
**Problem**: Rapid pitch fluctuations  
**Solution**: Median filter + Kalman smoothing

## 🎯 **Workarounds**

### **If CREPE Too Slow**
1. Monitor processing time
2. Auto-fallback to YIN
3. Reduce model complexity
4. Use Web Workers

### **If Octave Errors**
1. Implement Kalman filter
2. Detect large pitch jumps
3. Use previous valid pitch
4. Apply confidence thresholds

### **If YIN Inaccurate**
1. Adjust threshold parameter
2. Improve interpolation
3. Use longer analysis windows
4. Combine with CREPE when possible

## 📋 **Testing Checklist**

- [ ] CREPE loads successfully
- [ ] YIN fallback works
- [ ] Median filter reduces noise
- [ ] Kalman filter prevents octave errors
- [ ] Performance monitoring active
- [ ] Auto-fallback triggers correctly
- [ ] Pitch accuracy within ±5 cents

## 🔧 **Configuration**

### **CREPE Settings**
```typescript
const crepeConfig = {
  modelPath: '/models/crepe-tiny.onnx',
  inputSize: 1024,
  sampleRate: 48000,
  hopLength: 160,
  confidenceThreshold: 0.7
}
```

### **YIN Settings**
```typescript
const yinConfig = {
  threshold: 0.15,
  sampleRate: 48000,
  minFrequency: 80,
  maxFrequency: 2000
}
```

### **Filter Settings**
```typescript
const filterConfig = {
  medianWindow: 5,
  kalmanProcessNoise: 0.01,
  kalmanMeasurementNoise: 0.1,
  octaveErrorThreshold: 0.5
}
```

---

**Remember**: Always have a fallback! CREPE is great but YIN is more reliable on low-end devices.
