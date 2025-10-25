// Gate #016 Job V1 - Brightness Guard
// Low-luminance floor with auto-recovery

class BrightnessGuard {
  constructor(config = {}) {
    this.lMin = config.lMin || 0.07;  // Normalized luma threshold (0-1)
    this.guardWindowMs = config.guardWindowMs || 120;  // Time before triggering
    this.guardMode = config.guardMode || 'auto_switch';  // 'auto_switch' or 'overlay'
    this.enabled = config.enabled !== false;
    
    // State tracking
    this.lowLumaStartMs = null;
    this.triggerCount = 0;
    this.lastLuma = 0;
    this.frameCount = 0;
    this.lowLumaFrames = 0;
    this.maxBlackoutGapMs = 0;
    this.currentBlackoutStartMs = null;
    
    console.log(`[brightness-guard] Initialized: L_min=${this.lMin}, window=${this.guardWindowMs}ms, mode=${this.guardMode}`);
  }
  
  // Process a frame's luma measurement
  checkFrame(luma) {
    if (!this.enabled) return { triggered: false };
    
    this.frameCount++;
    this.lastLuma = luma;
    
    const now = Date.now();
    const isLowLuma = luma < this.lMin;
    
    if (isLowLuma) {
      this.lowLumaFrames++;
      
      // Track blackout gap start
      if (this.currentBlackoutStartMs === null) {
        this.currentBlackoutStartMs = now;
      }
      
      // Track low-luma duration
      if (this.lowLumaStartMs === null) {
        this.lowLumaStartMs = now;
      } else {
        const duration = now - this.lowLumaStartMs;
        
        // Trigger guard if threshold exceeded
        if (duration >= this.guardWindowMs) {
          this.triggerCount++;
          this.lowLumaStartMs = now;  // Reset to avoid immediate re-trigger
          
          console.log(`[brightness-guard] TRIGGERED (count=${this.triggerCount}): luma=${luma.toFixed(4)} < ${this.lMin} for ${duration}ms`);
          
          return {
            triggered: true,
            reason: 'low_luma_duration',
            luma,
            duration,
            mode: this.guardMode
          };
        }
      }
    } else {
      // Recovered from low luma
      if (this.currentBlackoutStartMs !== null) {
        const gapMs = now - this.currentBlackoutStartMs;
        if (gapMs > this.maxBlackoutGapMs) {
          this.maxBlackoutGapMs = gapMs;
        }
        this.currentBlackoutStartMs = null;
      }
      this.lowLumaStartMs = null;
    }
    
    return { triggered: false, luma };
  }
  
  // Get statistics for reporting
  getStats() {
    const blackoutRatio = this.frameCount > 0 
      ? (this.lowLumaFrames / this.frameCount) * 100 
      : 0;
    
    return {
      enabled: this.enabled,
      lMin: this.lMin,
      guardWindowMs: this.guardWindowMs,
      guardMode: this.guardMode,
      frameCount: this.frameCount,
      lowLumaFrames: this.lowLumaFrames,
      blackoutRatio: Math.round(blackoutRatio * 100) / 100,  // 2 decimal places
      maxBlackoutGapMs: this.maxBlackoutGapMs,
      triggerCount: this.triggerCount,
      lastLuma: Math.round(this.lastLuma * 10000) / 10000  // 4 decimal places
    };
  }
  
  // Reset statistics (for new test runs)
  reset() {
    this.lowLumaStartMs = null;
    this.triggerCount = 0;
    this.lastLuma = 0;
    this.frameCount = 0;
    this.lowLumaFrames = 0;
    this.maxBlackoutGapMs = 0;
    this.currentBlackoutStartMs = null;
    console.log('[brightness-guard] Statistics reset');
  }
}

module.exports = { BrightnessGuard };

