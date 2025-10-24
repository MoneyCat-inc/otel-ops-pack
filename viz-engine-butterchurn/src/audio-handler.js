/**
 * Audio Input Handler for md3-engine
 * ECRR: BossCat Gate #010 - Audio reactivity
 * Authority: BossCat OEM | Executor: Cursor{Implementer}
 * 
 * Receives audio features (not raw PCM) and updates Milkdrop variables
 * POST /audio { sr, rms, fft, bands: {bass, mid, treb}, ts }
 */

// Audio state (circular buffer for last N frames)
const BUFFER_SIZE = 512;
const EMA_ALPHA = 0.5; // Smoothing factor for *_att variables

class AudioHandler {
  constructor() {
    this.buffer = [];
    this.current = {
      bass: 0,
      mid: 0,
      treb: 0,
      bass_att: 0,
      mid_att: 0,
      treb_att: 0,
      rms: 0,
      fft: new Array(64).fill(0),
      timestamp: 0
    };
  }

  /**
   * Update audio state from POST /audio
   * @param {object} audioData - { sr, rms, fft, bands, ts }
   */
  update(audioData) {
    const { rms = 0, fft = [], bands = {}, ts = Date.now() / 1000 } = audioData;

    // Extract band energies
    const bass = bands.bass || 0;
    const mid = bands.mid || 0;
    const treb = bands.treb || 0;

    // Apply EMA smoothing for *_att variables
    this.current.bass_att = this.current.bass_att * (1 - EMA_ALPHA) + bass * EMA_ALPHA;
    this.current.mid_att = this.current.mid_att * (1 - EMA_ALPHA) + mid * EMA_ALPHA;
    this.current.treb_att = this.current.treb_att * (1 - EMA_ALPHA) + treb * EMA_ALPHA;

    // Update instant values
    this.current.bass = bass;
    this.current.mid = mid;
    this.current.treb = treb;
    this.current.rms = rms;
    this.current.fft = fft.slice(0, 64); // Keep first 64 bins
    this.current.timestamp = ts;

    // Add to circular buffer
    this.buffer.push({
      bass,
      mid,
      treb,
      rms,
      timestamp: ts
    });

    // Maintain buffer size
    if (this.buffer.length > BUFFER_SIZE) {
      this.buffer.shift();
    }
  }

  /**
   * Get current audio state for Milkdrop variables
   * @returns {object} Audio variables
   */
  getState() {
    return {
      bass: this.current.bass,
      mid: this.current.mid,
      treb: this.current.treb,
      bass_att: this.current.bass_att,
      mid_att: this.current.mid_att,
      treb_att: this.current.treb_att,
      rms: this.current.rms,
      fft: this.current.fft,
      timestamp: this.current.timestamp
    };
  }

  /**
   * Get audio buffer for reactivity analysis
   * @returns {array} Recent audio frames
   */
  getBuffer() {
    return this.buffer;
  }

  /**
   * Get statistics for last N frames
   * @param {number} n - Number of recent frames
   * @returns {object} Stats
   */
  getStats(n = 60) {
    const recent = this.buffer.slice(-n);
    if (recent.length === 0) {
      return {
        bass_avg: 0,
        mid_avg: 0,
        treb_avg: 0,
        bass_max: 0,
        samples: 0
      };
    }

    const bassValues = recent.map(f => f.bass);
    const midValues = recent.map(f => f.mid);
    const trebValues = recent.map(f => f.treb);

    return {
      bass_avg: bassValues.reduce((a, b) => a + b, 0) / bassValues.length,
      mid_avg: midValues.reduce((a, b) => a + b, 0) / midValues.length,
      treb_avg: trebValues.reduce((a, b) => a + b, 0) / trebValues.length,
      bass_max: Math.max(...bassValues),
      mid_max: Math.max(...midValues),
      treb_max: Math.max(...trebValues),
      samples: recent.length
    };
  }
}

module.exports = AudioHandler;

