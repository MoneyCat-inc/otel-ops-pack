# 🎤 Resonai Mic Debug Kit

Quick diagnostic tools for troubleshooting microphone and audio issues in Resonai.

## 🚀 Quick Start

### Option 1: Web Interface
1. Navigate to http://localhost:3003/labs/mic-debug
2. Click "Run Diagnostics" 
3. Grant microphone permissions when prompted
4. Review the color-coded results and fixes

### Option 2: Console Script
1. Open http://localhost:3003 in Firefox
2. Open Developer Tools (F12) → Console
3. Copy and paste the entire contents of `mic-debug-console.js`
4. Press Enter and review the output

## 📊 Reading the Results

### ✅ OK (Green)
- **crossOriginIsolated = true** → Threads/worklets can run
- **RAW constraints applied** → Clean mic input (EC/NS/AGC all false)
- **AudioContext OK** → Low-latency audio path working
- **AudioWorklet loaded** → Real-time processing enabled

### ⚠️ WARN (Yellow)
- **Sample rate mismatch** → Mic and AudioContext don't match
- **Partial RAW constraints** → Some audio processing still enabled

### ❌ FAIL (Red)
- **crossOriginIsolated = false** → Need COOP/COEP headers
- **getUserMedia failed** → Permission or HTTPS issue
- **AudioWorklet failed** → Isolation or module load problem

### ℹ️ INFO (Blue)
- **Device list** → Available microphones
- **RMS values** → Live audio levels (speak to see them rise)

## 🔧 Quick Fixes

### Cross-Origin Isolation Issues
Add to `next.config.js`:
```javascript
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Cross-Origin-Embedder-Policy',
            value: 'require-corp',
          },
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin',
          },
        ],
      },
    ]
  },
}
```

### RAW Constraints Not Applied
Ensure `getUserMedia` explicitly sets:
```javascript
const stream = await navigator.mediaDevices.getUserMedia({
  audio: { 
    echoCancellation: false, 
    noiseSuppression: false, 
    autoGainControl: false 
  }
});
```

### Microphone Access Issues
1. **Check permissions**: Firefox → Settings → Privacy → Permissions → Microphone
2. **Use localhost**: Ensure you're on http://localhost:3003 (not 127.0.0.1)
3. **Close other tabs**: Other apps might be holding the mic
4. **Check HTTPS**: Some features require secure context

## 🎯 Expected Values

- **Sample Rate**: 48000 Hz (preferred)
- **Base Latency**: ~0.005s or lower
- **RMS Level**: 0.001-0.1 (speaking should raise it above 0.01)
- **Cross-Origin Isolation**: true
- **RAW Constraints**: All false (echoCancellation, noiseSuppression, autoGainControl)

## 🐛 Common Issues

### "AudioWorklet failed"
- Usually means cross-origin isolation is off
- Check COOP/COEP headers are properly set
- Ensure all resources (fonts, scripts) satisfy CORS

### "getUserMedia failed"
- Check browser permissions
- Ensure you're on localhost or HTTPS
- Close other applications using the microphone

### "RAW constraints not applied"
- Firefox defaults EC/NS to true unless explicitly disabled
- Check site permissions for microphone
- Verify the code is setting constraints correctly

### RMS not updating
- Speak into the microphone
- Check if AudioWorklet is loaded successfully
- Verify cross-origin isolation is enabled

## 🔍 Advanced Debugging

### Check Audio Context State
```javascript
const ctx = new AudioContext();
console.log('State:', ctx.state);
console.log('Sample Rate:', ctx.sampleRate);
console.log('Base Latency:', ctx.baseLatency);
```

### Monitor Audio Levels
```javascript
// After running the debug script
setInterval(() => {
  console.log('Current RMS:', rmsValue);
}, 1000);
```

### Test Different Sample Rates
```javascript
const ctx = new AudioContext({ sampleRate: 48000 });
// vs
const ctx = new AudioContext({ sampleRate: 44100 });
```

## 📝 Integration Notes

This debug kit is designed for Resonai's voice training application but can be adapted for any web audio project. The key requirements are:

1. **Cross-origin isolation** for AudioWorklets
2. **RAW audio constraints** for clean input
3. **Low-latency AudioContext** for real-time processing
4. **Proper error handling** for graceful degradation

## 🚀 Next Steps

After running diagnostics:
1. Fix any critical issues (isolation, permissions)
2. Optimize sample rates and latency settings
3. Test with actual voice training scenarios
4. Monitor performance in SigNoz dashboards
5. Set up alerts for audio processing failures

---

**Pro Tip**: Keep this debug kit handy during development. Audio issues can be tricky to diagnose, and this tool provides a comprehensive health check for your entire audio pipeline! 🎯



