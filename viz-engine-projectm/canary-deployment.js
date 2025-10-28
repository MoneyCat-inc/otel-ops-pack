// Gate #020 - Job CNY1 - Audio Canary State Machine
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Production-safe audio rollout with auto-halt on breach
// BOSSCAT-021A: Fixed reset logic to clear halted state + drive AudioSwitch
// GATE-020-R1: Cluster façade integration (async disable/enable for Redis pub/sub)

const EventEmitter = require('events');
const { audioSwitch } = require('./lib/audio-switch-cluster');

class CanaryDeployment extends EventEmitter {
  constructor(config = {}) {
    super();
    this.phases = [
      { name: 'INIT', target: 0, durationMs: 0 },
      { name: 'RAMP_10', target: 10, durationMs: 5 * 60 * 1000 },  // 5 minutes
      { name: 'RAMP_50', target: 50, durationMs: 2 * 60 * 1000 },  // 2 minutes
      { name: 'RAMP_100', target: 100, durationMs: 2 * 60 * 1000 }, // 2 minutes
      { name: 'COMPLETE', target: 100, durationMs: 0 }
    ];
    
    this.currentPhaseIdx = 0;
    this.startTime = null;
    this.phaseStartTime = null;
    this.halted = false;
    this.haltReason = null;
    this._tickHandle = null;
    
    // KPI thresholds
    this.thresholds = {
      underrunRatio: config.maxUnderrun || 0.005,  // 0.5%
      tickJitterMs: config.maxJitter || 8,
      minCorrelation: config.minR || 0.78  // For transients
    };
    
    // Callbacks
    this.onPhaseChange = config.onPhaseChange || (() => {});
    this.onBreach = config.onBreach || (() => {});
    this.onComplete = config.onComplete || (() => {});
  }
  
  start() {
    this.startTime = Date.now();
    this.phaseStartTime = Date.now();
    this.currentPhaseIdx = 0;
    console.log('[canary] Starting deployment');
    this.onPhaseChange(this.getCurrentPhase());
  }
  
  getCurrentPhase() {
    return this.phases[this.currentPhaseIdx];
  }
  
  getProgress() {
    if (this.halted) {
      return {
        phase: this.getCurrentPhase().name,
        target: this.getCurrentPhase().target,
        halted: true,
        reason: this.haltReason,
        elapsedMs: Date.now() - this.startTime
      };
    }
    
    const phase = this.getCurrentPhase();
    const phaseElapsed = Date.now() - this.phaseStartTime;
    const phaseProgress = phase.durationMs > 0 
      ? Math.min(1.0, phaseElapsed / phase.durationMs)
      : 1.0;
    
    return {
      phase: phase.name,
      target: phase.target,
      phaseProgress: phaseProgress,
      phaseElapsedMs: phaseElapsed,
      totalElapsedMs: Date.now() - this.startTime,
      halted: false
    };
  }
  
  async tick(kpis = {}) {
    if (this.halted) return { halted: true, reason: this.haltReason };
    
    // Check KPIs for breach
    const breach = this.checkBreach(kpis);
    if (breach) {
      await this.halt(breach);
      return { halted: true, reason: breach };
    }
    
    // Check phase progression
    const phase = this.getCurrentPhase();
    const phaseElapsed = Date.now() - this.phaseStartTime;
    
    if (phaseElapsed >= phase.durationMs && this.currentPhaseIdx < this.phases.length - 1) {
      // Advance to next phase
      this.currentPhaseIdx++;
      this.phaseStartTime = Date.now();
      
      const newPhase = this.getCurrentPhase();
      console.log(`[canary] Phase transition: ${phase.name} → ${newPhase.name} (${newPhase.target}%)`);
      this.onPhaseChange(newPhase);
      
      // Check if complete
      if (newPhase.name === 'COMPLETE') {
        console.log('[canary] Deployment COMPLETE');
        this.onComplete();
      }
    }
    
    return { halted: false, progress: this.getProgress() };
  }
  
  checkBreach(kpis) {
    // Check underrun ratio
    if (kpis.underrunRatio !== undefined && kpis.underrunRatio > this.thresholds.underrunRatio) {
      return `Underrun breach: ${(kpis.underrunRatio * 100).toFixed(2)}% > ${(this.thresholds.underrunRatio * 100).toFixed(2)}%`;
    }
    
    // Check jitter
    if (kpis.tickJitterMs !== undefined && kpis.tickJitterMs > this.thresholds.tickJitterMs) {
      return `Jitter breach: ${kpis.tickJitterMs.toFixed(2)}ms > ${this.thresholds.tickJitterMs}ms`;
    }
    
    // Check correlation (if available)
    if (kpis.correlation !== undefined && kpis.correlation < this.thresholds.minCorrelation) {
      return `Correlation breach: r=${kpis.correlation.toFixed(4)} < ${this.thresholds.minCorrelation}`;
    }
    
    return null;
  }
  
  async halt(reason) {
    this.halted = true;
    this.haltReason = reason;
    console.error(`[canary] HALTED: ${reason}`);
    this._clearTimers();
    try { 
      await audioSwitch.disable(`canary-breach: ${reason}`); 
      console.log('[canary] Audio disabled via AudioSwitch (cluster-wide)');
    } catch (err) {
      console.error('[canary] Failed to disable audio:', err.message);
    }
    this.onBreach(reason, this.getCurrentPhase());
    this.emit('breach', { reason, at: new Date().toISOString() });
  }
  
  async reset() {
    // BOSSCAT-021A: Clear halted state and re-enable audio
    // GATE-020-R1: Cluster façade async enable for Redis propagation
    console.log('[canary] RESET triggered - clearing halted state');
    this._clearTimers();
    this.halted = false;
    this.haltReason = null;
    this.currentPhaseIdx = 0;
    this.startTime = null;
    this.phaseStartTime = null;
    try { 
      await audioSwitch.enable('canary-reset'); 
      console.log('[canary] Audio re-enabled via AudioSwitch (cluster-wide)');
    } catch (err) {
      console.error('[canary] Failed to enable audio:', err.message);
    }
    this.emit('reset');
    console.log('[canary] Reset complete - ready to restart');
  }
  
  _clearTimers() {
    if (this._tickHandle) {
      clearInterval(this._tickHandle);
      this._tickHandle = null;
    }
  }
  
  getStatus() {
    return {
      running: !this.halted,
      halted: this.halted,
      haltReason: this.haltReason,
      currentPhase: this.getCurrentPhase().name,
      targetPercent: this.getCurrentPhase().target,
      progress: this.getProgress(),
      startTime: this.startTime,
      elapsedMs: this.startTime ? Date.now() - this.startTime : 0
    };
  }
  
  // Emergency rollback
  async emergencyStop() {
    await this.halt('Emergency stop triggered');
    return { halted: true, reason: 'Emergency stop' };
  }
}

module.exports = { CanaryDeployment };

