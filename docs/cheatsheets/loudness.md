# Loudness Guardrails Cheat Sheet

**Issue**: Users strain their voice or exceed safe volume levels  
**Solution**: Real-time loudness monitoring with device-specific calibration

## 🚨 **Core Heuristic**

### **Strain Detection**
```typescript
class LoudnessMonitor {
  private rmsThreshold = 0.8        // RMS threshold for strain
  private durationThreshold = 5000  // 5 seconds in milliseconds
  private cooldownPeriod = 30000    // 30 seconds cooldown
  
  private strainStartTime: number | null = null
  private lastStrainTime: number = 0
  
  checkLoudness(rmsValue: number): LoudnessStatus {
    const now = Date.now()
    
    // Check if currently in strain
    if (rmsValue >= this.rmsThreshold) {
      if (this.strainStartTime === null) {
        this.strainStartTime = now
      }
      
      const strainDuration = now - this.strainStartTime
      
      if (strainDuration >= this.durationThreshold) {
        // Strain detected - trigger warning
        this.lastStrainTime = now
        this.strainStartTime = null
        
        return {
          status: 'strain',
          duration: strainDuration,
          needsCooldown: true
        }
      }
      
      return {
        status: 'warning',
        duration: strainDuration,
        needsCooldown: false
      }
    } else {
      // Reset strain tracking
      this.strainStartTime = null
      
      // Check cooldown period
      const timeSinceStrain = now - this.lastStrainTime
      if (timeSinceStrain < this.cooldownPeriod) {
        return {
          status: 'cooldown',
          duration: this.cooldownPeriod - timeSinceStrain,
          needsCooldown: true
        }
      }
      
      return {
        status: 'normal',
        duration: 0,
        needsCooldown: false
      }
    }
  }
}
```

## 🎯 **Device-Specific Calibration**

### **Calibration System**
```typescript
class DeviceCalibration {
  private deviceProfiles = new Map<string, DeviceProfile>()
  
  async calibrateDevice(): Promise<DeviceProfile> {
    const deviceId = await this.getDeviceId()
    
    if (this.deviceProfiles.has(deviceId)) {
      return this.deviceProfiles.get(deviceId)!
    }
    
    // Perform calibration
    const profile = await this.performCalibration()
    this.deviceProfiles.set(deviceId, profile)
    
    return profile
  }
  
  private async performCalibration(): Promise<DeviceProfile> {
    return new Promise((resolve) => {
      const calibrationData: number[] = []
      let calibrationComplete = false
      
      // Collect 10 seconds of normal speaking
      const startTime = Date.now()
      const collectData = (rmsValue: number) => {
        if (!calibrationComplete && Date.now() - startTime < 10000) {
          calibrationData.push(rmsValue)
        } else if (!calibrationComplete) {
          calibrationComplete = true
          
          // Calculate baseline
          const baseline = this.calculateBaseline(calibrationData)
          const profile: DeviceProfile = {
            baseline: baseline,
            threshold: baseline * 1.5,  // 50% above baseline
            maxSafe: baseline * 2.0,    // 100% above baseline
            deviceType: this.detectDeviceType()
          }
          
          resolve(profile)
        }
      }
      
      // Start calibration process
      this.startCalibration(collectData)
    })
  }
  
  private calculateBaseline(data: number[]): number {
    // Use 90th percentile as baseline (ignoring outliers)
    const sorted = data.sort((a, b) => a - b)
    const index = Math.floor(sorted.length * 0.9)
    return sorted[index]
  }
  
  private detectDeviceType(): DeviceType {
    const userAgent = navigator.userAgent.toLowerCase()
    
    if (userAgent.includes('mobile')) {
      return 'mobile'
    } else if (userAgent.includes('tablet')) {
      return 'tablet'
    } else {
      return 'desktop'
    }
  }
}
```

## 🔧 **Bluetooth Microphone Handling**

### **Bluetooth-Specific Issues**
```typescript
class BluetoothMicHandler {
  private isBluetooth = false
  private bluetoothCompensation = 1.0
  
  async detectBluetoothMic(): Promise<boolean> {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices()
      const audioInputs = devices.filter(device => device.kind === 'audioinput')
      
      // Check for Bluetooth indicators in device labels
      this.isBluetooth = audioInputs.some(device => 
        device.label.toLowerCase().includes('bluetooth') ||
        device.label.toLowerCase().includes('bt')
      )
      
      if (this.isBluetooth) {
        // Apply Bluetooth-specific compensation
        this.bluetoothCompensation = 0.8  // Reduce sensitivity by 20%
        console.log('Bluetooth microphone detected, applying compensation')
      }
      
      return this.isBluetooth
    } catch (error) {
      console.warn('Could not detect microphone type:', error)
      return false
    }
  }
  
  applyBluetoothCompensation(rmsValue: number): number {
    if (this.isBluetooth) {
      return rmsValue * this.bluetoothCompensation
    }
    return rmsValue
  }
}
```

## 🎛️ **Real-time Monitoring**

### **Complete Loudness System**
```typescript
class LoudnessGuardrails {
  private monitor: LoudnessMonitor
  private calibration: DeviceCalibration
  private bluetoothHandler: BluetoothMicHandler
  private audioContext: AudioContext
  private analyser: AnalyserNode
  private dataArray: Uint8Array
  
  private currentProfile: DeviceProfile | null = null
  private isMonitoring = false
  
  async init() {
    this.monitor = new LoudnessMonitor()
    this.calibration = new DeviceCalibration()
    this.bluetoothHandler = new BluetoothMicHandler()
    
    // Detect Bluetooth mic
    await this.bluetoothHandler.detectBluetoothMic()
    
    // Calibrate device
    this.currentProfile = await this.calibration.calibrateDevice()
    
    // Setup audio analysis
    await this.setupAudioAnalysis()
  }
  
  private async setupAudioAnalysis() {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    this.audioContext = new AudioContext()
    const source = this.audioContext.createMediaStreamSource(stream)
    
    this.analyser = this.audioContext.createAnalyser()
    this.analyser.fftSize = 2048
    this.analyser.smoothingTimeConstant = 0.8
    
    source.connect(this.analyser)
    this.dataArray = new Uint8Array(this.analyser.frequencyBinCount)
  }
  
  startMonitoring() {
    this.isMonitoring = true
    this.monitoringLoop()
  }
  
  private monitoringLoop() {
    if (!this.isMonitoring) return
    
    this.analyser.getByteFrequencyData(this.dataArray)
    
    // Calculate RMS
    const rms = this.calculateRMS(this.dataArray)
    
    // Apply Bluetooth compensation
    const compensatedRMS = this.bluetoothHandler.applyBluetoothCompensation(rms)
    
    // Check loudness with calibrated thresholds
    const status = this.monitor.checkLoudness(compensatedRMS)
    
    // Handle status
    this.handleLoudnessStatus(status)
    
    // Continue monitoring
    requestAnimationFrame(() => this.monitoringLoop())
  }
  
  private calculateRMS(data: Uint8Array): number {
    let sum = 0
    for (let i = 0; i < data.length; i++) {
      sum += data[i] * data[i]
    }
    return Math.sqrt(sum / data.length) / 255.0  // Normalize to [0, 1]
  }
  
  private handleLoudnessStatus(status: LoudnessStatus) {
    switch (status.status) {
      case 'strain':
        this.showStrainWarning(status.duration)
        break
      case 'warning':
        this.showVolumeWarning(status.duration)
        break
      case 'cooldown':
        this.showCooldownMessage(status.duration)
        break
      case 'normal':
        this.hideAllWarnings()
        break
    }
  }
}
```

## 🚨 **User Interface**

### **Warning Messages**
```typescript
class LoudnessUI {
  private warningElement: HTMLElement
  private cooldownElement: HTMLElement
  
  constructor() {
    this.warningElement = document.getElementById('volume-warning')!
    this.cooldownElement = document.getElementById('cooldown-message')!
  }
  
  showStrainWarning(duration: number) {
    this.warningElement.innerHTML = `
      <div class="strain-warning">
        <h3>⚠️ Voice Strain Detected</h3>
        <p>You've been speaking loudly for ${Math.round(duration/1000)} seconds.</p>
        <p>Please take a 30-second break to rest your voice.</p>
        <button onclick="this.parentElement.parentElement.style.display='none'">Got it</button>
      </div>
    `
    this.warningElement.style.display = 'block'
  }
  
  showVolumeWarning(duration: number) {
    this.warningElement.innerHTML = `
      <div class="volume-warning">
        <h3>🔊 Volume Getting High</h3>
        <p>You've been speaking loudly for ${Math.round(duration/1000)} seconds.</p>
        <p>Try speaking a bit softer to avoid strain.</p>
      </div>
    `
    this.warningElement.style.display = 'block'
  }
  
  showCooldownMessage(remainingTime: number) {
    this.cooldownElement.innerHTML = `
      <div class="cooldown-message">
        <h3>⏳ Voice Rest Period</h3>
        <p>Please rest your voice for ${Math.round(remainingTime/1000)} more seconds.</p>
        <p>This helps prevent vocal strain.</p>
      </div>
    `
    this.cooldownElement.style.display = 'block'
  }
  
  hideAllWarnings() {
    this.warningElement.style.display = 'none'
    this.cooldownElement.style.display = 'none'
  }
}
```

## 🎯 **Workarounds**

### **If Bluetooth Mic Mis-triggers**
1. Apply 20% sensitivity reduction
2. Use device-specific calibration
3. Adjust thresholds for Bluetooth devices
4. Test with different Bluetooth headsets

### **If Calibration Fails**
1. Use default thresholds as fallback
2. Allow manual threshold adjustment
3. Provide calibration retry option
4. Use device type defaults

### **If Performance Issues**
1. Reduce monitoring frequency
2. Use Web Workers for RMS calculation
3. Optimize audio analysis settings
4. Implement adaptive monitoring

## 📋 **Testing Checklist**

- [ ] Strain detection works correctly
- [ ] Device calibration completes
- [ ] Bluetooth compensation applied
- [ ] Warning messages display properly
- [ ] Cooldown period enforced
- [ ] Performance remains smooth
- [ ] Works across different devices

---

**Remember**: Never push users to speak louder - always encourage healthy vocal habits!
