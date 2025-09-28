/**
 * Unit Tests for Prosody Scenarios
 * 
 * T2: Prosody Carry-over Scenarios
 * Tests for expressiveness delta and slope classification functionality.
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { ProsodyEngine, ProsodyFrame, ScenarioConfig } from '../../src/engine/audio/prosody';

describe('ProsodyEngine', () => {
  let engine: ProsodyEngine;

  beforeEach(() => {
    engine = new ProsodyEngine();
  });

  describe('Scenario Management', () => {
    it('should get all available scenarios', () => {
      const scenarios = ProsodyEngine.getScenarios();
      expect(scenarios).toHaveLength(2);
      expect(scenarios.map(s => s.id)).toContain('voicemail');
      expect(scenarios.map(s => s.id)).toContain('meeting');
    });

    it('should get specific scenario configuration', () => {
      const voicemail = engine.getScenarioConfig('voicemail');
      expect(voicemail).toBeDefined();
      expect(voicemail?.id).toBe('voicemail');
      expect(voicemail?.targetRiseFall).toBe('fall');

      const meeting = engine.getScenarioConfig('meeting');
      expect(meeting).toBeDefined();
      expect(meeting?.id).toBe('meeting');
      expect(meeting?.targetRiseFall).toBe('rise');
    });

    it('should return null for invalid scenario ID', () => {
      const invalid = engine.getScenarioConfig('invalid');
      expect(invalid).toBeNull();
    });
  });

  describe('Recording Management', () => {
    it('should start recording for valid scenario', () => {
      const success = engine.startScenario('voicemail');
      expect(success).toBe(true);
      
      const status = engine.getRecordingStatus();
      expect(status.isRecording).toBe(true);
      expect(status.scenarioId).toBe('voicemail');
      expect(status.frameCount).toBe(0);
    });

    it('should fail to start recording for invalid scenario', () => {
      const success = engine.startScenario('invalid');
      expect(success).toBe(false);
      
      const status = engine.getRecordingStatus();
      expect(status.isRecording).toBe(false);
      expect(status.scenarioId).toBeNull();
    });

    it('should stop recording and return null when no frames recorded', () => {
      engine.startScenario('voicemail');
      const result = engine.stopScenario();
      expect(result).toBeNull();
    });
  });

  describe('Slope Classification', () => {
    it('should classify rising pattern correctly', () => {
      engine.startScenario('meeting');
      
      // Add frames with rising pitch pattern
      const frames = generateRisingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.riseFallLabel).toBe('rise');
    });

    it('should classify falling pattern correctly', () => {
      engine.startScenario('voicemail');
      
      // Add frames with falling pitch pattern
      const frames = generateFallingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.riseFallLabel).toBe('fall');
    });

    it('should classify neutral pattern correctly', () => {
      engine.startScenario('voicemail');
      
      // Add frames with flat pitch pattern
      const frames = generateNeutralFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.riseFallLabel).toBe('neutral');
    });

    it('should require minimum frames for classification', () => {
      engine.startScenario('voicemail');
      
      // Add only 2 frames (below minimum)
      const frames = generateRisingFrames(2);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.riseFallLabel).toBe('neutral');
    });

    it('should handle short utterances (below minimum duration)', () => {
      engine.startScenario('voicemail');
      
      // Add frames with short duration (below 250ms minimum)
      const frames = generateShortDurationFrames(5); // 200ms total
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.riseFallLabel).toBe('neutral');
    });

    it('should handle creaky voice endings (low confidence)', () => {
      engine.startScenario('voicemail');
      
      // Add frames with high confidence except last few with low confidence
      const frames = generateCreakyFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      // Should still classify despite low confidence in ending
      expect(['rise', 'fall', 'neutral']).toContain(result?.riseFallLabel);
    });

    it('should handle flat contours correctly', () => {
      engine.startScenario('meeting');
      
      // Add frames with flat pitch contour
      const frames = generateNeutralFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.riseFallLabel).toBe('neutral');
    });
  });

  describe('Expressiveness Calculation', () => {
    it('should calculate expressiveness without baseline', () => {
      engine.startScenario('voicemail');
      
      // Add frames with varied pitch
      const frames = generateVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBeGreaterThan(0);
      expect(result?.expressiveness01).toBeLessThanOrEqual(1);
    });

    it('should calculate expressiveness with baseline comparison', () => {
      // Set baseline with low variation
      const baselineFrames = generateFlatFrames(20);
      engine.setBaseline(baselineFrames);
      
      engine.startScenario('voicemail');
      
      // Add frames with higher variation
      const frames = generateVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBeGreaterThan(0);
    });

    it('should cap expressiveness at configured multiplier', () => {
      // Set baseline with moderate variation
      const baselineFrames = generateModerateVariedFrames(20);
      engine.setBaseline(baselineFrames);
      
      engine.startScenario('voicemail');
      
      // Add frames with very high variation (should be capped)
      const frames = generateHighlyVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBeLessThanOrEqual(1);
    });

    it('should handle missing baseline gracefully', () => {
      // No baseline set
      engine.startScenario('voicemail');
      
      const frames = generateVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBeGreaterThan(0);
      expect(result?.expressiveness01).toBeLessThanOrEqual(1);
    });

    it('should handle zero baseline variation', () => {
      // Set baseline with zero variation
      const baselineFrames = generateZeroVariationFrames(20);
      engine.setBaseline(baselineFrames);
      
      engine.startScenario('voicemail');
      
      const frames = generateVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBe(0);
    });

    it('should prevent expressiveness gaming with caps', () => {
      // Test that extreme variation doesn't break the cap
      const baselineFrames = generateFlatFrames(20);
      engine.setBaseline(baselineFrames);
      
      engine.startScenario('voicemail');
      
      // Add frames with extreme variation (should be capped)
      const frames = generateExtremeVariationFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBeLessThanOrEqual(1);
      
      // Verify the cap constant is being used
      const cap = ProsodyEngine.CLASSIFICATION_CONSTANTS.EXPRESSIVENESS_CAP_MULTIPLIER;
      expect(cap).toBe(2.0);
    });
  });

  describe('Scenario Evaluation', () => {
    it('should pass voicemail scenario with correct fall and sufficient expressiveness', () => {
      engine.startScenario('voicemail');
      
      const frames = generateFallingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.scenarioId).toBe('voicemail');
      expect(result?.pass).toBe(true);
      expect(result?.feedback).toContain('✅ Gentle fall detected — clear statement');
    });

    it('should fail voicemail scenario with incorrect rise', () => {
      engine.startScenario('voicemail');
      
      const frames = generateRisingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.scenarioId).toBe('voicemail');
      expect(result?.pass).toBe(false);
      expect(result?.feedback).toContain('💡 Try ending with a gentle fall for a clear statement');
    });

    it('should pass meeting scenario with correct rise and sufficient expressiveness', () => {
      engine.startScenario('meeting');
      
      const frames = generateRisingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.scenarioId).toBe('meeting');
      expect(result?.pass).toBe(true);
      expect(result?.feedback).toContain('✅ Nice rise detected — engaging question');
    });
  });

  describe('Metrics Calculation', () => {
    it('should calculate comprehensive metrics', () => {
      engine.startScenario('voicemail');
      
      const frames = generateVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.metrics).toBeDefined();
      expect(result?.metrics.pitchRange).toBeGreaterThan(0);
      expect(result?.metrics.pitchVariation).toBeGreaterThan(0);
      expect(result?.metrics.energyVariation).toBeGreaterThan(0);
      expect(result?.metrics.duration).toBeGreaterThan(0);
    });
  });

  describe('Event Schema Validation', () => {
    it('should produce valid scenario result schema', () => {
      engine.startScenario('voicemail');
      
      const frames = generateFallingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();

      // Validate required fields
      expect(typeof result?.scenarioId).toBe('string');
      expect(['voicemail', 'meeting']).toContain(result?.scenarioId);
      
      expect(['rise', 'fall', 'neutral']).toContain(result?.riseFallLabel);
      
      expect(typeof result?.expressiveness01).toBe('number');
      expect(result?.expressiveness01).toBeGreaterThanOrEqual(0);
      expect(result?.expressiveness01).toBeLessThanOrEqual(1);
      
      expect(typeof result?.pass).toBe('boolean');
      
      expect(Array.isArray(result?.feedback)).toBe(true);
      expect(result?.feedback.length).toBeGreaterThan(0);
      
      // Validate metrics schema
      expect(result?.metrics).toBeDefined();
      expect(typeof result?.metrics.pitchRange).toBe('number');
      expect(typeof result?.metrics.pitchVariation).toBe('number');
      expect(typeof result?.metrics.energyVariation).toBe('number');
      expect(typeof result?.metrics.duration).toBe('number');
    });

    it('should not contain audio data or blobs', () => {
      engine.startScenario('voicemail');
      
      const frames = generateFallingFrames(15);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      const resultJson = JSON.stringify(result);
      
      // Ensure no audio data is persisted
      expect(resultJson).not.toContain('audio');
      expect(resultJson).not.toContain('blob');
      expect(resultJson).not.toContain('buffer');
      expect(resultJson).not.toContain('ArrayBuffer');
      
      // Verify result is serializable (no functions or complex objects)
      expect(() => JSON.parse(resultJson)).not.toThrow();
    });

    it('should have consistent schema across scenarios', () => {
      const scenarios = ['voicemail', 'meeting'];
      const results: any[] = [];

      scenarios.forEach(scenarioId => {
        engine.startScenario(scenarioId);
        
        const frames = scenarioId === 'voicemail' ? generateFallingFrames(15) : generateRisingFrames(15);
        frames.forEach(frame => engine.addFrame(frame));
        
        const result = engine.stopScenario();
        results.push(result);
      });

      // All results should have identical schema structure
      results.forEach(result => {
        expect(result).toBeDefined();
        expect(Object.keys(result).sort()).toEqual([
          'scenarioId', 'riseFallLabel', 'expressiveness01', 'pass', 'feedback', 'metrics'
        ].sort());
        expect(Object.keys(result.metrics).sort()).toEqual([
          'pitchRange', 'pitchVariation', 'energyVariation', 'duration'
        ].sort());
      });
    });
  });
});

// Helper functions to generate test frames
function generateRisingFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 150 + i * 5, // Rising pitch
      confidence: 0.8,
      energy: 0.5 + Math.random() * 0.2,
      spectralCentroid: 1000 + i * 50
    });
  }
  return frames;
}

function generateFallingFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 200 - i * 5, // Falling pitch
      confidence: 0.8,
      energy: 0.5 + Math.random() * 0.2,
      spectralCentroid: 1500 - i * 50
    });
  }
  return frames;
}

function generateNeutralFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 175 + (Math.random() - 0.5) * 10, // Flat with small variation
      confidence: 0.8,
      energy: 0.5 + Math.random() * 0.1,
      spectralCentroid: 1250
    });
  }
  return frames;
}

function generateVariedFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 150 + Math.sin(i * 0.5) * 30 + Math.random() * 20, // Varied pitch
      confidence: 0.8,
      energy: 0.3 + Math.random() * 0.4,
      spectralCentroid: 1000 + Math.random() * 500
    });
  }
  return frames;
}

function generateFlatFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 175 + (Math.random() - 0.5) * 5, // Very flat pitch
      confidence: 0.8,
      energy: 0.5 + (Math.random() - 0.5) * 0.1,
      spectralCentroid: 1250
    });
  }
  return frames;
}

function generateModerateVariedFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 175 + Math.sin(i * 0.3) * 15 + Math.random() * 10,
      confidence: 0.8,
      energy: 0.4 + Math.random() * 0.2,
      spectralCentroid: 1200 + Math.random() * 200
    });
  }
  return frames;
}

function generateHighlyVariedFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 150 + Math.sin(i * 0.8) * 60 + Math.random() * 40, // High variation
      confidence: 0.8,
      energy: 0.2 + Math.random() * 0.6,
      spectralCentroid: 800 + Math.random() * 800
    });
  }
  return frames;
}

function generateZeroVariationFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 175, // Identical pitch (zero variation)
      confidence: 0.8,
      energy: 0.5, // Identical energy
      spectralCentroid: 1250 // Identical spectral centroid
    });
  }
  return frames;
}

function generateExtremeVariationFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 100,
      pitch: 100 + Math.sin(i * 2) * 200 + Math.random() * 100, // Extreme variation
      confidence: 0.8,
      energy: 0.1 + Math.random() * 0.8,
      spectralCentroid: 500 + Math.random() * 1500
    });
  }
  return frames;
}

function generateShortDurationFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    frames.push({
      timestamp: i * 40, // 40ms intervals = 200ms total for 5 frames
      pitch: 150 + i * 5, // Rising pitch
      confidence: 0.9,
      energy: 0.5 + i * 0.1,
      spectralCentroid: 1200 + i * 50
    });
  }
  return frames;
}

function generateCreakyFrames(count: number): ProsodyFrame[] {
  const frames: ProsodyFrame[] = [];
  for (let i = 0; i < count; i++) {
    const isLastThree = i >= count - 3;
    frames.push({
      timestamp: i * 100,
      pitch: 180 - i * 5, // Falling pitch
      confidence: isLastThree ? 0.4 : 0.9, // Low confidence in last 3 frames
      energy: isLastThree ? 0.3 : 0.7,
      spectralCentroid: 1400 - i * 50
    });
  }
  return frames;
}
