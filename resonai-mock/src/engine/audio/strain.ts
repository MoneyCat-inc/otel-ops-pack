/**
 * Strain Detection Engine - Safety Guardrails v1
 * 
 * T3: Safety Guardrails
 * Detects early signs of vocal strain using loudness and jitter trends.
 * Auto-inserts supportive SOVT cooldown when strain is detected.
 */

export interface AudioFrame {
  timestamp: number;
  rms: number;           // Root Mean Square energy (0-1)
  pitch: number;         // Fundamental frequency (Hz)
  confidence: number;    // Pitch confidence (0-1)
  voiced: boolean;       // Whether frame contains voiced speech
}

export interface StrainMetrics {
  loudnessDB: number;        // RMS converted to dBFS
  jitterEma: number;         // Exponential moving average of jitter (cents)
  jitterTrend: number;       // Trend slope over window (cents/ms)
  voicedMs: number;         // Total voiced duration (ms)
  strainFlag: boolean;       // Whether strain is detected
  strainReasons: string[];   // Reasons for strain detection
}

export interface StrainConfig {
  LOUD_DB_THRESH: number;    // Loudness threshold in dBFS
  LOUD_MS: number;           // Duration threshold for loudness (ms)
  JITTER_DELTA_CENTS: number; // Jitter change threshold (cents)
  JITTER_WINDOW_MS: number;   // Window for jitter trend analysis (ms)
  MIN_VOICED_MS: number;     // Minimum voiced duration for detection (ms)
  COOLDOWN_SEC: number;      // Cooldown duration (seconds)
  EWMA_ALPHA: number;        // Exponential moving average smoothing factor
}

export interface StrainEvent {
  event: 'strain_triggered';
  timestamp: number;
  loudnessDB: number;
  jitterEma: number;
  voicedMs: number;
  cooldownSec: number;
  strainReasons: string[];
  build: string;
  eventVersion: number;
}

export class StrainDetector {
  private frames: AudioFrame[] = [];
  private isActive = false;
  private config: StrainConfig;
  private strainStartTime: number | null = null;
  private lastStrainTime: number | null = null;

  // Default configuration - can be overridden
  static readonly DEFAULT_CONFIG: StrainConfig = {
    LOUD_DB_THRESH: -12,        // -12 dBFS threshold
    LOUD_MS: 1200,              // 1.2 seconds
    JITTER_DELTA_CENTS: 20,     // 20 cents change
    JITTER_WINDOW_MS: 1500,     // 1.5 second window
    MIN_VOICED_MS: 800,         // 800ms minimum voiced
    COOLDOWN_SEC: 45,           // 45 second cooldown
    EWMA_ALPHA: 0.1             // Smoothing factor
  };

  constructor(config?: Partial<StrainConfig>) {
    this.config = { ...StrainDetector.DEFAULT_CONFIG, ...config };
  }

  /**
   * Start strain detection
   */
  startDetection(): void {
    this.isActive = true;
    this.frames = [];
    this.strainStartTime = null;
    this.lastStrainTime = null;
  }

  /**
   * Stop strain detection
   */
  stopDetection(): void {
    this.isActive = false;
  }

  /**
   * Add a new audio frame for analysis
   */
  addFrame(frame: AudioFrame): void {
    if (!this.isActive) return;
    
    this.frames.push(frame);
    
    // Keep only recent frames (last 5 seconds)
    const maxAge = 5000; // 5 seconds
    const cutoffTime = frame.timestamp - maxAge;
    this.frames = this.frames.filter(f => f.timestamp > cutoffTime);
  }

  /**
   * Get current strain metrics
   */
  getStrainMetrics(): StrainMetrics {
    if (this.frames.length === 0) {
      return {
        loudnessDB: -Infinity,
        jitterEma: 0,
        jitterTrend: 0,
        voicedMs: 0,
        strainFlag: false,
        strainReasons: []
      };
    }

    const loudnessDB = this.calculateLoudnessDB();
    const jitterEma = this.calculateJitterEMA();
    const jitterTrend = this.calculateJitterTrend();
    const voicedMs = this.calculateVoicedDuration();
    
    const strainFlag = this.detectStrain(loudnessDB, jitterEma, jitterTrend, voicedMs);
    const strainReasons = this.getStrainReasons(loudnessDB, jitterEma, jitterTrend, voicedMs);

    return {
      loudnessDB,
      jitterEma,
      jitterTrend,
      voicedMs,
      strainFlag,
      strainReasons
    };
  }

  /**
   * Check if cooldown period has elapsed
   */
  isCooldownActive(): boolean {
    if (!this.lastStrainTime) return false;
    
    const cooldownMs = this.config.COOLDOWN_SEC * 1000;
    const elapsed = Date.now() - this.lastStrainTime;
    
    return elapsed < cooldownMs;
  }

  /**
   * Get remaining cooldown time in seconds
   */
  getRemainingCooldownSec(): number {
    if (!this.lastStrainTime) return 0;
    
    const cooldownMs = this.config.COOLDOWN_SEC * 1000;
    const elapsed = Date.now() - this.lastStrainTime;
    const remaining = Math.max(0, cooldownMs - elapsed);
    
    return Math.ceil(remaining / 1000);
  }

  /**
   * Trigger strain event (called when strain is detected)
   */
  triggerStrain(): StrainEvent {
    const metrics = this.getStrainMetrics();
    this.lastStrainTime = Date.now();
    
    return {
      event: 'strain_triggered',
      timestamp: Date.now(),
      loudnessDB: metrics.loudnessDB,
      jitterEma: metrics.jitterEma,
      voicedMs: metrics.voicedMs,
      cooldownSec: this.config.COOLDOWN_SEC,
      strainReasons: metrics.strainReasons,
      build: 'T3-strain-v1',
      eventVersion: 1
    };
  }

  /**
   * Calculate loudness in dBFS from RMS
   */
  private calculateLoudnessDB(): number {
    if (this.frames.length === 0) return -Infinity;
    
    // Calculate EWMA of RMS
    let emaRMS = 0;
    let hasData = false;
    
    for (let i = 0; i < this.frames.length; i++) {
      if (this.frames[i].voiced) {
        if (!hasData) {
          emaRMS = this.frames[i].rms;
          hasData = true;
        } else {
          emaRMS = this.config.EWMA_ALPHA * this.frames[i].rms + 
                   (1 - this.config.EWMA_ALPHA) * emaRMS;
        }
      }
    }
    
    if (!hasData || emaRMS === 0) return -Infinity;
    
    // Convert RMS to dBFS (assuming full scale = 1.0)
    return 20 * Math.log10(emaRMS);
  }

  /**
   * Calculate jitter EMA in cents
   */
  private calculateJitterEMA(): number {
    if (this.frames.length < 2) return 0;
    
    const voicedFrames = this.frames.filter(f => f.voiced && f.pitch > 0);
    if (voicedFrames.length < 2) return 0;
    
    let emaJitter = 0;
    let hasData = false;
    
    for (let i = 1; i < voicedFrames.length; i++) {
      const prevPitch = voicedFrames[i - 1].pitch;
      const currPitch = voicedFrames[i].pitch;
      
      if (prevPitch > 0 && currPitch > 0) {
        // Calculate jitter in cents
        const jitterCents = 1200 * Math.log2(currPitch / prevPitch);
        
        if (!hasData) {
          emaJitter = Math.abs(jitterCents);
          hasData = true;
        } else {
          emaJitter = this.config.EWMA_ALPHA * Math.abs(jitterCents) + 
                      (1 - this.config.EWMA_ALPHA) * emaJitter;
        }
      }
    }
    
    return hasData ? emaJitter : 0;
  }

  /**
   * Calculate jitter trend over time window
   */
  private calculateJitterTrend(): number {
    if (this.frames.length < 3) return 0;
    
    const windowMs = this.config.JITTER_WINDOW_MS;
    const now = this.frames[this.frames.length - 1].timestamp;
    const windowStart = now - windowMs;
    
    const windowFrames = this.frames.filter(f => 
      f.timestamp >= windowStart && f.voiced && f.pitch > 0
    );
    
    if (windowFrames.length < 3) return 0;
    
    // Calculate jitter values over the window
    const jitterValues: number[] = [];
    for (let i = 1; i < windowFrames.length; i++) {
      const prevPitch = windowFrames[i - 1].pitch;
      const currPitch = windowFrames[i].pitch;
      const jitterCents = 1200 * Math.log2(currPitch / prevPitch);
      jitterValues.push(Math.abs(jitterCents));
    }
    
    if (jitterValues.length < 2) return 0;
    
    // Calculate trend using linear regression
    const n = jitterValues.length;
    const xSum = (n * (n - 1)) / 2; // Sum of indices
    const ySum = jitterValues.reduce((sum, y) => sum + y, 0);
    const xySum = jitterValues.reduce((sum, y, i) => sum + i * y, 0);
    const x2Sum = (n * (n - 1) * (2 * n - 1)) / 6; // Sum of squares
    
    const slope = (n * xySum - xSum * ySum) / (n * x2Sum - xSum * xSum);
    return slope; // Trend in cents per frame
  }

  /**
   * Calculate total voiced duration
   */
  private calculateVoicedDuration(): number {
    if (this.frames.length === 0) return 0;
    
    const voicedFrames = this.frames.filter(f => f.voiced);
    if (voicedFrames.length === 0) return 0;
    
    const firstVoiced = voicedFrames[0].timestamp;
    const lastVoiced = voicedFrames[voicedFrames.length - 1].timestamp;
    
    return lastVoiced - firstVoiced;
  }

  /**
   * Detect strain based on thresholds
   */
  private detectStrain(
    loudnessDB: number,
    jitterEma: number,
    jitterTrend: number,
    voicedMs: number
  ): boolean {
    // Must have minimum voiced duration
    if (voicedMs < this.config.MIN_VOICED_MS) return false;
    
    // Check loudness threshold
    const loudnessExceeded = loudnessDB > this.config.LOUD_DB_THRESH;
    const loudnessDuration = this.checkLoudnessDuration();
    
    // Check jitter trend
    const jitterTrendExceeded = jitterTrend > this.config.JITTER_DELTA_CENTS / this.config.JITTER_WINDOW_MS;
    
    // Strain detected if either condition is met
    return (loudnessExceeded && loudnessDuration) || jitterTrendExceeded;
  }

  /**
   * Check if loudness threshold has been exceeded for required duration
   */
  private checkLoudnessDuration(): boolean {
    const threshold = this.config.LOUD_DB_THRESH;
    const requiredMs = this.config.LOUD_MS;
    
    let consecutiveMs = 0;
    let maxConsecutiveMs = 0;
    
    for (const frame of this.frames) {
      if (frame.voiced) {
        const loudnessDB = 20 * Math.log10(frame.rms);
        if (loudnessDB > threshold) {
          consecutiveMs += 100; // Assuming 100ms frame intervals
          maxConsecutiveMs = Math.max(maxConsecutiveMs, consecutiveMs);
        } else {
          consecutiveMs = 0;
        }
      }
    }
    
    return maxConsecutiveMs >= requiredMs;
  }

  /**
   * Get reasons for strain detection
   */
  private getStrainReasons(
    loudnessDB: number,
    jitterEma: number,
    jitterTrend: number,
    voicedMs: number
  ): string[] {
    const reasons: string[] = [];
    
    if (voicedMs < this.config.MIN_VOICED_MS) {
      return reasons; // No strain if insufficient voiced time
    }
    
    const loudnessExceeded = loudnessDB > this.config.LOUD_DB_THRESH;
    const loudnessDuration = this.checkLoudnessDuration();
    const jitterTrendExceeded = jitterTrend > this.config.JITTER_DELTA_CENTS / this.config.JITTER_WINDOW_MS;
    
    if (loudnessExceeded && loudnessDuration) {
      reasons.push(`Loudness exceeded ${this.config.LOUD_DB_THRESH} dBFS for ${this.config.LOUD_MS}ms`);
    }
    
    if (jitterTrendExceeded) {
      reasons.push(`Jitter trend increased by ${jitterTrend.toFixed(1)} cents/ms`);
    }
    
    return reasons;
  }

  /**
   * Update configuration
   */
  updateConfig(newConfig: Partial<StrainConfig>): void {
    this.config = { ...this.config, ...newConfig };
  }

  /**
   * Get current configuration
   */
  getConfig(): StrainConfig {
    return { ...this.config };
  }

  /**
   * Reset strain detection state
   */
  reset(): void {
    this.frames = [];
    this.strainStartTime = null;
    this.lastStrainTime = null;
  }
}
