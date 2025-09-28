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

    it('should cap expressiveness at 2x baseline', () => {
      // Set baseline with moderate variation
      const baselineFrames = generateModerateVariedFrames(20);
      engine.setBaseline(baselineFrames);
      
      engine.startScenario('voicemail');
      
      // Add frames with very high variation
      const frames = generateHighlyVariedFrames(20);
      frames.forEach(frame => engine.addFrame(frame));
      
      const result = engine.stopScenario();
      expect(result).toBeDefined();
      expect(result?.expressiveness01).toBeLessThanOrEqual(1);
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
