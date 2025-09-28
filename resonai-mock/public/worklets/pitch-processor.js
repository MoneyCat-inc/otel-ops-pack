/**
 * Pitch Processor Worklet - ACF/YIN-lite Implementation
 * 
 * INV-03A: Basic pitch detection worklet stub
 * Uses Autocorrelation Function (ACF) for pitch estimation
 */

class PitchProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    
    this.bufferSize = 1024;
    this.buffer = new Float32Array(this.bufferSize);
    this.bufferIndex = 0;
    
    // Pitch detection parameters
    this.minPitch = 80;    // Hz
    this.maxPitch = 400;   // Hz
    this.sampleRate = 16000;
    
    // Message port for UI updates
    this.port.onmessage = (event) => {
      if (event.data.type === 'configure') {
        this.minPitch = event.data.minPitch || 80;
        this.maxPitch = event.data.maxPitch || 400;
      }
    };
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];
    const output = outputs[0];
    
    if (input.length > 0) {
      const inputChannel = input[0];
      
      // Copy input to output (passthrough for now)
      if (output.length > 0) {
        output[0].set(inputChannel);
      }
      
      // Fill buffer for pitch analysis
      for (let i = 0; i < inputChannel.length; i++) {
        this.buffer[this.bufferIndex] = inputChannel[i];
        this.bufferIndex = (this.bufferIndex + 1) % this.bufferSize;
      }
      
      // Analyze pitch every 128 samples (8ms at 16kHz)
      if (this.bufferIndex % 128 === 0) {
        const pitch = this.detectPitch();
        const confidence = this.calculateConfidence();
        
        // Send pitch data to main thread
        this.port.postMessage({
          type: 'pitch',
          pitch: pitch,
          confidence: confidence,
          timestamp: currentTime
        });
      }
    }
    
    return true; // Keep processor alive
  }

  detectPitch() {
    // Simple ACF-based pitch detection
    const minPeriod = Math.floor(this.sampleRate / this.maxPitch);
    const maxPeriod = Math.floor(this.sampleRate / this.minPitch);
    
    let bestPitch = 0;
    let maxCorrelation = 0;
    
    for (let period = minPeriod; period <= maxPeriod; period++) {
      let correlation = 0;
      
      for (let i = 0; i < this.bufferSize - period; i++) {
        correlation += this.buffer[i] * this.buffer[i + period];
      }
      
      if (correlation > maxCorrelation) {
        maxCorrelation = correlation;
        bestPitch = this.sampleRate / period;
      }
    }
    
    return bestPitch;
  }

  calculateConfidence() {
    // Simple confidence based on signal energy
    let energy = 0;
    for (let i = 0; i < this.bufferSize; i++) {
      energy += this.buffer[i] * this.buffer[i];
    }
    
    const avgEnergy = energy / this.bufferSize;
    return Math.min(avgEnergy * 100, 1.0); // Normalize to 0-1
  }
}

registerProcessor('pitch-processor', PitchProcessor);
