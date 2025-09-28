/**
 * Prosody Engine - Applied Scenarios Implementation
 * 
 * T2: Prosody Carry-over Scenarios
 * Implements voicemail and meeting intro scenario evaluation with
 * end-rise/fall detection and expressiveness measurement.
 */

export interface ProsodyFrame {
  timestamp: number;
  pitch: number; // Hz
  confidence: number; // 0-1
  energy: number; // RMS
  spectralCentroid: number; // Hz
}

export interface ScenarioConfig {
  id: string;
  name: string;
  phrase: string;
  targetRiseFall: 'rise' | 'fall' | 'neutral';
  expectedDuration: number; // seconds
  expressivenessThreshold: number; // 0-1
}

export interface ScenarioResult {
  scenarioId: string;
  riseFallLabel: 'rise' | 'fall' | 'neutral';
  expressiveness01: number; // 0-1
  pass: boolean;
  feedback: string[];
  metrics: {
    pitchRange: number;
    pitchVariation: number;
    energyVariation: number;
    duration: number;
  };
}

export class ProsodyEngine {
  private frames: ProsodyFrame[] = [];
  private baselineFrames: ProsodyFrame[] = [];
  private isRecording = false;
  private scenarioConfig: ScenarioConfig | null = null;

  // Scenario configurations
  static readonly SCENARIOS: ScenarioConfig[] = [
    {
      id: 'voicemail',
      name: 'Voicemail Intro',
      phrase: "Hi, this is [your name]. I'm calling about...",
      targetRiseFall: 'fall',
      expectedDuration: 4,
      expressivenessThreshold: 0.3
    },
    {
      id: 'meeting',
      name: 'Meeting Intro',
      phrase: "Good morning everyone, thanks for joining today's call.",
      targetRiseFall: 'rise',
      expectedDuration: 5,
      expressivenessThreshold: 0.4
    }
  ];

  /**
   * Start recording a scenario
   */
  startScenario(scenarioId: string): boolean {
    const config = ProsodyEngine.SCENARIOS.find(s => s.id === scenarioId);
    if (!config) return false;

    this.scenarioConfig = config;
    this.isRecording = true;
    this.frames = [];
    return true;
  }

  /**
   * Stop recording and evaluate scenario
   */
  stopScenario(): ScenarioResult | null {
    if (!this.scenarioConfig || !this.isRecording) return null;

    this.isRecording = false;
    const result = this.evaluateScenario();
    this.scenarioConfig = null;
    return result;
  }

  /**
   * Add a new audio frame for analysis
   */
  addFrame(frame: ProsodyFrame): void {
    if (!this.isRecording) return;
    this.frames.push(frame);
  }

  /**
   * Set baseline frames for expressiveness comparison
   */
  setBaseline(frames: ProsodyFrame[]): void {
    this.baselineFrames = frames;
  }

  /**
   * Evaluate the recorded scenario
   */
  private evaluateScenario(): ScenarioResult {
    if (!this.scenarioConfig || this.frames.length === 0) {
      throw new Error('No scenario configuration or frames available');
    }

    const config = this.scenarioConfig;
    const riseFallLabel = this.classifyRiseFall();
    const expressiveness01 = this.calculateExpressiveness();
    
    // Determine if the scenario passed
    const riseFallCorrect = riseFallLabel === config.targetRiseFall;
    const expressivenessPass = expressiveness01 >= config.expressivenessThreshold;
    const pass = riseFallCorrect && expressivenessPass;

    // Generate feedback
    const feedback = this.generateFeedback(riseFallLabel, expressiveness01, config);

    // Calculate metrics
    const metrics = this.calculateMetrics();

    return {
      scenarioId: config.id,
      riseFallLabel,
      expressiveness01,
      pass,
      feedback,
      metrics
    };
  }

  /**
   * Classify end-rise vs end-fall using slope analysis
   */
  private classifyRiseFall(): 'rise' | 'fall' | 'neutral' {
    if (this.frames.length < 10) return 'neutral';

    // Use last 30% of frames for end classification
    const endStart = Math.floor(this.frames.length * 0.7);
    const endFrames = this.frames.slice(endStart);
    
    if (endFrames.length < 3) return 'neutral';

    // Calculate pitch slope using linear regression
    const slope = this.calculateSlope(endFrames.map(f => f.pitch));
    const confidence = this.calculateSlopeConfidence(endFrames);

    // Threshold-based classification
    if (confidence > 0.7) {
      if (slope > 0.5) return 'rise';
      if (slope < -0.5) return 'fall';
    }

    return 'neutral';
  }

  /**
   * Calculate expressiveness compared to baseline
   */
  private calculateExpressiveness(): number {
    if (this.baselineFrames.length === 0) {
      // No baseline - use absolute measures
      return this.calculateAbsoluteExpressiveness();
    }

    // Compare to baseline
    const currentVariation = this.calculatePitchVariation(this.frames);
    const baselineVariation = this.calculatePitchVariation(this.baselineFrames);
    
    if (baselineVariation === 0) return 0;

    // Expressiveness is the ratio of current to baseline variation
    const ratio = currentVariation / baselineVariation;
    return Math.min(ratio, 2.0) / 2.0; // Cap at 2x and normalize to 0-1
  }

  /**
   * Calculate absolute expressiveness without baseline
   */
  private calculateAbsoluteExpressiveness(): number {
    const pitchVariation = this.calculatePitchVariation(this.frames);
    const energyVariation = this.calculateEnergyVariation(this.frames);
    
    // Normalize and combine metrics
    const normalizedPitch = Math.min(pitchVariation / 100, 1); // Assume 100Hz as max meaningful variation
    const normalizedEnergy = Math.min(energyVariation / 0.5, 1); // Assume 0.5 as max energy variation
    
    return (normalizedPitch + normalizedEnergy) / 2;
  }

  /**
   * Calculate pitch variation (standard deviation)
   */
  private calculatePitchVariation(frames: ProsodyFrame[]): number {
    if (frames.length < 2) return 0;

    const pitches = frames.map(f => f.pitch).filter(p => p > 0);
    if (pitches.length < 2) return 0;

    const mean = pitches.reduce((sum, p) => sum + p, 0) / pitches.length;
    const variance = pitches.reduce((sum, p) => sum + Math.pow(p - mean, 2), 0) / pitches.length;
    return Math.sqrt(variance);
  }

  /**
   * Calculate energy variation
   */
  private calculateEnergyVariation(frames: ProsodyFrame[]): number {
    if (frames.length < 2) return 0;

    const energies = frames.map(f => f.energy);
    const mean = energies.reduce((sum, e) => sum + e, 0) / energies.length;
    const variance = energies.reduce((sum, e) => sum + Math.pow(e - mean, 2), 0) / energies.length;
    return Math.sqrt(variance);
  }

  /**
   * Calculate slope using linear regression
   */
  private calculateSlope(values: number[]): number {
    if (values.length < 2) return 0;

    const n = values.length;
    const xSum = (n * (n - 1)) / 2; // Sum of indices 0, 1, 2, ..., n-1
    const ySum = values.reduce((sum, y) => sum + y, 0);
    const xySum = values.reduce((sum, y, i) => sum + i * y, 0);
    const x2Sum = (n * (n - 1) * (2 * n - 1)) / 6; // Sum of squares of indices

    const slope = (n * xySum - xSum * ySum) / (n * x2Sum - xSum * xSum);
    return slope;
  }

  /**
   * Calculate confidence in slope measurement
   */
  private calculateSlopeConfidence(frames: ProsodyFrame[]): number {
    // Use average confidence of frames
    const avgConfidence = frames.reduce((sum, f) => sum + f.confidence, 0) / frames.length;
    return avgConfidence;
  }

  /**
   * Generate constructive feedback
   */
  private generateFeedback(
    riseFallLabel: 'rise' | 'fall' | 'neutral',
    expressiveness01: number,
    config: ScenarioConfig
  ): string[] {
    const feedback: string[] = [];

    // Rise/fall feedback
    if (riseFallLabel === config.targetRiseFall) {
      if (config.targetRiseFall === 'fall') {
        feedback.push('✅ Gentle fall detected — clear statement');
      } else {
        feedback.push('✅ Nice rise detected — engaging question');
      }
    } else {
      if (config.targetRiseFall === 'fall') {
        feedback.push('💡 Try ending with a gentle fall for a clear statement');
      } else {
        feedback.push('💡 Try ending with a slight rise to sound more engaging');
      }
    }

    // Expressiveness feedback
    if (expressiveness01 >= 0.6) {
      feedback.push('✅ Nice variety in pitch — expressive delivery');
    } else if (expressiveness01 >= 0.3) {
      feedback.push('👍 Good expressiveness — keep it natural');
    } else {
      feedback.push('💡 Try adding a bit more pitch variety for expressiveness');
    }

    return feedback;
  }

  /**
   * Calculate detailed metrics
   */
  private calculateMetrics() {
    if (this.frames.length === 0) {
      return {
        pitchRange: 0,
        pitchVariation: 0,
        energyVariation: 0,
        duration: 0
      };
    }

    const pitches = this.frames.map(f => f.pitch).filter(p => p > 0);
    const energies = this.frames.map(f => f.energy);
    
    const pitchRange = pitches.length > 0 ? Math.max(...pitches) - Math.min(...pitches) : 0;
    const pitchVariation = this.calculatePitchVariation(this.frames);
    const energyVariation = this.calculateEnergyVariation(this.frames);
    const duration = (this.frames[this.frames.length - 1].timestamp - this.frames[0].timestamp) / 1000;

    return {
      pitchRange,
      pitchVariation,
      energyVariation,
      duration
    };
  }

  /**
   * Get current recording status
   */
  getRecordingStatus(): { isRecording: boolean; scenarioId: string | null; frameCount: number } {
    return {
      isRecording: this.isRecording,
      scenarioId: this.scenarioConfig?.id || null,
      frameCount: this.frames.length
    };
  }

  /**
   * Get scenario configuration
   */
  getScenarioConfig(scenarioId: string): ScenarioConfig | null {
    return ProsodyEngine.SCENARIOS.find(s => s.id === scenarioId) || null;
  }

  /**
   * Get all available scenarios
   */
  static getScenarios(): ScenarioConfig[] {
    return ProsodyEngine.SCENARIOS;
  }
}
