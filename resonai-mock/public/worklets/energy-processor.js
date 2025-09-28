/**
 * Energy Processor Worklet - RMS + HF/LF Analysis
 * 
 * INV-03A: Energy analysis worklet stub
 * Calculates RMS energy and high/low frequency components
 */

class EnergyProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    
    this.bufferSize = 1024;
    this.buffer = new Float32Array(this.bufferSize);
    this.bufferIndex = 0;
    
    // Energy analysis parameters
    this.sampleRate = 16000;
    this.lowFreqCutoff = 1000;  // Hz
    this.highFreqCutoff = 4000; // Hz
    
    // Simple high-pass filter state
    this.hpFilterState = 0;
    this.hpAlpha = 0.95; // High-pass filter coefficient
    
    // Message port for UI updates
    this.port.onmessage = (event) => {
      if (event.data.type === 'configure') {
        this.lowFreqCutoff = event.data.lowFreqCutoff || 1000;
        this.highFreqCutoff = event.data.highFreqCutoff || 4000;
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
      
      // Fill buffer for energy analysis
      for (let i = 0; i < inputChannel.length; i++) {
        this.buffer[this.bufferIndex] = inputChannel[i];
        this.bufferIndex = (this.bufferIndex + 1) % this.bufferSize;
      }
      
      // Analyze energy every 64 samples (4ms at 16kHz)
      if (this.bufferIndex % 64 === 0) {
        const energy = this.calculateRMS();
        const hfEnergy = this.calculateHighFreqEnergy();
        const lfEnergy = this.calculateLowFreqEnergy();
        
        // Send energy data to main thread
        this.port.postMessage({
          type: 'energy',
          rms: energy,
          highFreq: hfEnergy,
          lowFreq: lfEnergy,
          timestamp: currentTime
        });
      }
    }
    
    return true; // Keep processor alive
  }

  calculateRMS() {
    let sum = 0;
    for (let i = 0; i < this.bufferSize; i++) {
      sum += this.buffer[i] * this.buffer[i];
    }
    return Math.sqrt(sum / this.bufferSize);
  }

  calculateHighFreqEnergy() {
    // Simple high-pass filter approximation
    let hfSum = 0;
    let prevSample = this.hpFilterState;
    
    for (let i = 0; i < this.bufferSize; i++) {
      const filtered = this.buffer[i] - prevSample * this.hpAlpha;
      hfSum += filtered * filtered;
      prevSample = this.buffer[i];
    }
    
    this.hpFilterState = prevSample;
    return Math.sqrt(hfSum / this.bufferSize);
  }

  calculateLowFreqEnergy() {
    // Simple low-pass filter approximation
    let lfSum = 0;
    let prevSample = 0;
    const lpAlpha = 0.1; // Low-pass filter coefficient
    
    for (let i = 0; i < this.bufferSize; i++) {
      const filtered = prevSample + lpAlpha * (this.buffer[i] - prevSample);
      lfSum += filtered * filtered;
      prevSample = filtered;
    }
    
    return Math.sqrt(lfSum / this.bufferSize);
  }
}

registerProcessor('energy-processor', EnergyProcessor);
