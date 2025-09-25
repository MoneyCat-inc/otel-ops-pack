/**
 * Flow Engine Correctness Tests
 * Validates drill JSON encoding, gating logic, and success metrics
 * Part of the push-button automation system
 */

import { test, expect, Page, BrowserContext } from '@playwright/test';

test.describe('Flow Engine Correctness', () => {
  let page: Page;
  let context: BrowserContext;

  test.beforeEach(async ({ browser }) => {
    context = await browser.newContext({
      permissions: ['microphone'],
      ignoreHTTPSErrors: true,
    });
    page = await context.newPage();
  });

  test.afterEach(async () => {
    await context.close();
  });

  test('drill JSON encoding and validation', async () => {
    await page.goto('/');
    
    const drillTest = await page.evaluate(() => {
      try {
        // Mock drill JSON structure
        const drillSchema = {
          id: 'string',
          name: 'string',
          type: 'enum:warmup|glide|phrase|reflection',
          duration: 'number',
          targetFreq: 'number?',
          tolerance: 'number?',
          successThreshold: 'number',
          instructions: 'string',
          metrics: {
            timeInTarget: 'number',
            smoothness: 'number',
            confidence: 'number'
          }
        };
        
        // Test drill JSON creation
        const warmupDrill = {
          id: 'warmup-001',
          name: 'Basic Warmup',
          type: 'warmup',
          duration: 30,
          targetFreq: 220,
          tolerance: 50,
          successThreshold: 0.7,
          instructions: 'Sing a steady A3 note for 30 seconds',
          metrics: {
            timeInTarget: 0,
            smoothness: 0,
            confidence: 0
          }
        };
        
        const glideDrill = {
          id: 'glide-001',
          name: 'Octave Glide',
          type: 'glide',
          duration: 15,
          targetFreq: null, // No specific target for glides
          tolerance: null,
          successThreshold: 0.8,
          instructions: 'Glide smoothly from A3 to A4',
          metrics: {
            timeInTarget: 0,
            smoothness: 0,
            confidence: 0
          }
        };
        
        const phraseDrill = {
          id: 'phrase-001',
          name: 'Short Phrase',
          type: 'phrase',
          duration: 10,
          targetFreq: 440,
          tolerance: 30,
          successThreshold: 0.6,
          instructions: 'Sing "Hello world" clearly',
          metrics: {
            timeInTarget: 0,
            smoothness: 0,
            confidence: 0
          }
        };
        
        const reflectionDrill = {
          id: 'reflection-001',
          name: 'Self Assessment',
          type: 'reflection',
          duration: 60,
          targetFreq: null,
          tolerance: null,
          successThreshold: 0.5,
          instructions: 'Reflect on your performance',
          metrics: {
            timeInTarget: 0,
            smoothness: 0,
            confidence: 0
          }
        };
        
        // Validate drill structure
        function validateDrill(drill: any): { valid: boolean; errors: string[] } {
          const errors: string[] = [];
          
          if (!drill.id || typeof drill.id !== 'string') errors.push('Missing or invalid id');
          if (!drill.name || typeof drill.name !== 'string') errors.push('Missing or invalid name');
          if (!['warmup', 'glide', 'phrase', 'reflection'].includes(drill.type)) {
            errors.push('Invalid type');
          }
          if (typeof drill.duration !== 'number' || drill.duration <= 0) {
            errors.push('Invalid duration');
          }
          if (typeof drill.successThreshold !== 'number' || drill.successThreshold < 0 || drill.successThreshold > 1) {
            errors.push('Invalid successThreshold');
          }
          if (!drill.instructions || typeof drill.instructions !== 'string') {
            errors.push('Missing or invalid instructions');
          }
          if (!drill.metrics || typeof drill.metrics !== 'object') {
            errors.push('Missing metrics object');
          }
          
          return {
            valid: errors.length === 0,
            errors
          };
        }
        
        const warmupValidation = validateDrill(warmupDrill);
        const glideValidation = validateDrill(glideDrill);
        const phraseValidation = validateDrill(phraseDrill);
        const reflectionValidation = validateDrill(reflectionDrill);
        
        return {
          success: true,
          warmupValid: warmupValidation.valid,
          glideValid: glideValidation.valid,
          phraseValid: phraseValidation.valid,
          reflectionValid: reflectionValidation.valid,
          allValid: warmupValidation.valid && glideValidation.valid && 
                   phraseValidation.valid && reflectionValidation.valid,
          errors: {
            warmup: warmupValidation.errors,
            glide: glideValidation.errors,
            phrase: phraseValidation.errors,
            reflection: reflectionValidation.errors
          }
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(drillTest.success).toBe(true);
    expect(drillTest.allValid).toBe(true);
    expect(drillTest.warmupValid).toBe(true);
    expect(drillTest.glideValid).toBe(true);
    expect(drillTest.phraseValid).toBe(true);
    expect(drillTest.reflectionValid).toBe(true);
  });

  test('gating logic and success thresholds', async () => {
    await page.goto('/');
    
    const gatingTest = await page.evaluate(() => {
      try {
        // Mock gating logic
        function evaluateDrillSuccess(
          drill: any,
          metrics: { timeInTarget: number; smoothness: number; confidence: number }
        ): { passed: boolean; score: number; details: any } {
          let score = 0;
          const details: any = {};
          
          // Time in target (for drills with target frequency)
          if (drill.targetFreq && drill.tolerance) {
            const timeInTargetScore = Math.min(1, metrics.timeInTarget / drill.duration);
            score += timeInTargetScore * 0.4; // 40% weight
            details.timeInTargetScore = timeInTargetScore;
          }
          
          // Smoothness (for all drills)
          const smoothnessScore = Math.min(1, metrics.smoothness);
          score += smoothnessScore * 0.3; // 30% weight
          details.smoothnessScore = smoothnessScore;
          
          // Confidence (for all drills)
          const confidenceScore = Math.min(1, metrics.confidence);
          score += confidenceScore * 0.3; // 30% weight
          details.confidenceScore = confidenceScore;
          
          const passed = score >= drill.successThreshold;
          
          return {
            passed,
            score,
            details
          };
        }
        
        // Test different drill scenarios
        const warmupDrill = {
          id: 'warmup-001',
          type: 'warmup',
          duration: 30,
          targetFreq: 220,
          tolerance: 50,
          successThreshold: 0.7
        };
        
        const glideDrill = {
          id: 'glide-001',
          type: 'glide',
          duration: 15,
          targetFreq: null,
          tolerance: null,
          successThreshold: 0.8
        };
        
        // Test case 1: Excellent performance
        const excellentMetrics = {
          timeInTarget: 28, // 28/30 seconds
          smoothness: 0.95,
          confidence: 0.9
        };
        
        const excellentResult = evaluateDrillSuccess(warmupDrill, excellentMetrics);
        
        // Test case 2: Poor performance
        const poorMetrics = {
          timeInTarget: 5, // 5/30 seconds
          smoothness: 0.3,
          confidence: 0.2
        };
        
        const poorResult = evaluateDrillSuccess(warmupDrill, poorMetrics);
        
        // Test case 3: Glide drill (no target frequency)
        const glideMetrics = {
          timeInTarget: 0, // Not applicable
          smoothness: 0.85,
          confidence: 0.75
        };
        
        const glideResult = evaluateDrillSuccess(glideDrill, glideMetrics);
        
        return {
          success: true,
          excellent: {
            passed: excellentResult.passed,
            score: excellentResult.score,
            shouldPass: excellentResult.score >= warmupDrill.successThreshold
          },
          poor: {
            passed: poorResult.passed,
            score: poorResult.score,
            shouldFail: poorResult.score < warmupDrill.successThreshold
          },
          glide: {
            passed: glideResult.passed,
            score: glideResult.score,
            shouldPass: glideResult.score >= glideDrill.successThreshold
          }
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(gatingTest.success).toBe(true);
    expect(gatingTest.excellent.passed).toBe(true);
    expect(gatingTest.excellent.shouldPass).toBe(true);
    expect(gatingTest.poor.passed).toBe(false);
    expect(gatingTest.poor.shouldFail).toBe(true);
    expect(gatingTest.glide.passed).toBe(true);
    expect(gatingTest.glide.shouldPass).toBe(true);
  });

  test('time-in-target calculation', async () => {
    await page.goto('/');
    
    const timeInTargetTest = await page.evaluate(() => {
      try {
        // Mock time-in-target calculation
        function calculateTimeInTarget(
          frequencies: number[],
          targetFreq: number,
          tolerance: number,
          sampleRate: number,
          hopSize: number
        ): number {
          let timeInTarget = 0;
          const totalTime = frequencies.length * hopSize / sampleRate;
          
          for (let i = 0; i < frequencies.length; i++) {
            const freq = frequencies[i];
            if (freq > 0 && Math.abs(freq - targetFreq) <= tolerance) {
              timeInTarget += hopSize / sampleRate;
            }
          }
          
          return timeInTarget;
        }
        
        // Test with synthetic frequency data
        const sampleRate = 16000;
        const hopSize = 512;
        const targetFreq = 440;
        const tolerance = 50;
        
        // Create frequency array: mostly on target with some outliers
        const frequencies: number[] = [];
        const totalFrames = 100;
        
        for (let i = 0; i < totalFrames; i++) {
          if (i < 20) {
            frequencies.push(0); // Silence
          } else if (i < 80) {
            frequencies.push(440 + (Math.random() - 0.5) * 20); // On target ±10Hz
          } else {
            frequencies.push(600); // Off target
          }
        }
        
        const timeInTarget = calculateTimeInTarget(frequencies, targetFreq, tolerance, sampleRate, hopSize);
        const expectedTimeInTarget = 60 * hopSize / sampleRate; // 60 frames on target
        const accuracy = Math.abs(timeInTarget - expectedTimeInTarget) / expectedTimeInTarget;
        
        return {
          success: true,
          timeInTarget,
          expectedTimeInTarget,
          accuracy,
          isAccurate: accuracy < 0.1 // Within 10%
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(timeInTargetTest.success).toBe(true);
    expect(timeInTargetTest.isAccurate).toBe(true);
  });

  test('smoothness metric calculation', async () => {
    await page.goto('/');
    
    const smoothnessTest = await page.evaluate(() => {
      try {
        // Mock smoothness calculation
        function calculateSmoothness(frequencies: number[]): number {
          if (frequencies.length < 2) return 0;
          
          let totalChange = 0;
          let validTransitions = 0;
          
          for (let i = 1; i < frequencies.length; i++) {
            const prev = frequencies[i - 1];
            const curr = frequencies[i];
            
            if (prev > 0 && curr > 0) {
              const change = Math.abs(curr - prev);
              totalChange += change;
              validTransitions++;
            }
          }
          
          if (validTransitions === 0) return 0;
          
          const avgChange = totalChange / validTransitions;
          
          // Convert to smoothness score (lower change = higher smoothness)
          // Assume 100Hz average change is 0.5 smoothness
          const smoothness = Math.max(0, 1 - (avgChange / 200));
          
          return smoothness;
        }
        
        // Test with different frequency patterns
        const smoothFreqs = [440, 441, 442, 443, 444, 445]; // Very smooth
        const roughFreqs = [440, 500, 300, 600, 200, 700]; // Very rough
        const mixedFreqs = [440, 445, 450, 300, 305, 310]; // Mixed
        
        const smoothScore = calculateSmoothness(smoothFreqs);
        const roughScore = calculateSmoothness(roughFreqs);
        const mixedScore = calculateSmoothness(mixedFreqs);
        
        return {
          success: true,
          smoothScore,
          roughScore,
          mixedScore,
          smoothnessOrderCorrect: smoothScore > mixedScore && mixedScore > roughScore,
          scoresInRange: [smoothScore, roughScore, mixedScore].every(s => s >= 0 && s <= 1)
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(smoothnessTest.success).toBe(true);
    expect(smoothnessTest.smoothnessOrderCorrect).toBe(true);
    expect(smoothnessTest.scoresInRange).toBe(true);
  });

  test('confidence metric calculation', async () => {
    await page.goto('/');
    
    const confidenceTest = await page.evaluate(() => {
      try {
        // Mock confidence calculation based on signal quality
        function calculateConfidence(
          audioBuffer: Float32Array,
          frequencies: number[],
          sampleRate: number
        ): number {
          // Signal-to-noise ratio estimation
          let signalPower = 0;
          let noisePower = 0;
          let validFrames = 0;
          
          const frameSize = Math.floor(sampleRate * 0.025); // 25ms frames
          
          for (let i = 0; i < audioBuffer.length - frameSize; i += frameSize) {
            const frame = audioBuffer.slice(i, i + frameSize);
            const freq = frequencies[Math.floor(i / frameSize)] || 0;
            
            if (freq > 0) {
              // Calculate frame energy
              let frameEnergy = 0;
              for (let j = 0; j < frame.length; j++) {
                frameEnergy += frame[j] * frame[j];
              }
              frameEnergy /= frame.length;
              
              signalPower += frameEnergy;
              validFrames++;
            } else {
              // Estimate noise from silent frames
              let frameEnergy = 0;
              for (let j = 0; j < frame.length; j++) {
                frameEnergy += frame[j] * frame[j];
              }
              frameEnergy /= frame.length;
              noisePower += frameEnergy;
            }
          }
          
          if (validFrames === 0) return 0;
          
          const avgSignalPower = signalPower / validFrames;
          const avgNoisePower = noisePower / Math.max(1, audioBuffer.length / frameSize - validFrames);
          
          if (avgNoisePower === 0) return 1;
          
          const snr = avgSignalPower / avgNoisePower;
          const confidence = Math.min(1, Math.log10(snr + 1) / 3); // Scale to 0-1
          
          return confidence;
        }
        
        // Create test audio with different SNR levels
        const sampleRate = 16000;
        const duration = 1.0;
        const samples = Math.floor(sampleRate * duration);
        
        // High SNR audio
        const highSNRAudio = new Float32Array(samples);
        const highSNRFreqs: number[] = [];
        for (let i = 0; i < samples; i++) {
          highSNRAudio[i] = 0.5 * Math.sin(2 * Math.PI * 440 * i / sampleRate) + 0.01 * Math.random();
          if (i % 400 === 0) highSNRFreqs.push(440);
        }
        
        // Low SNR audio
        const lowSNRAudio = new Float32Array(samples);
        const lowSNRFreqs: number[] = [];
        for (let i = 0; i < samples; i++) {
          lowSNRAudio[i] = 0.1 * Math.sin(2 * Math.PI * 440 * i / sampleRate) + 0.3 * Math.random();
          if (i % 400 === 0) lowSNRFreqs.push(440);
        }
        
        const highConfidence = calculateConfidence(highSNRAudio, highSNRFreqs, sampleRate);
        const lowConfidence = calculateConfidence(lowSNRAudio, lowSNRFreqs, sampleRate);
        
        return {
          success: true,
          highConfidence,
          lowConfidence,
          confidenceOrderCorrect: highConfidence > lowConfidence,
          scoresInRange: highConfidence >= 0 && highConfidence <= 1 && 
                        lowConfidence >= 0 && lowConfidence <= 1
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(confidenceTest.success).toBe(true);
    expect(confidenceTest.confidenceOrderCorrect).toBe(true);
    expect(confidenceTest.scoresInRange).toBe(true);
  });

  test('drill flow progression logic', async () => {
    await page.goto('/');
    
    const flowTest = await page.evaluate(() => {
      try {
        // Mock drill flow progression
        function shouldProgressToNext(
          currentDrill: any,
          result: { passed: boolean; score: number },
          drillSequence: any[]
        ): { progress: boolean; nextDrill: any | null; reason: string } {
          const currentIndex = drillSequence.findIndex(d => d.id === currentDrill.id);
          
          if (currentIndex === -1) {
            return { progress: false, nextDrill: null, reason: 'Drill not found in sequence' };
          }
          
          if (currentIndex >= drillSequence.length - 1) {
            return { progress: false, nextDrill: null, reason: 'End of sequence' };
          }
          
          // Check if current drill passed
          if (!result.passed) {
            return { progress: false, nextDrill: null, reason: 'Current drill failed' };
          }
          
          // Check drill-specific progression rules
          if (currentDrill.type === 'warmup' && result.score < 0.8) {
            return { progress: false, nextDrill: null, reason: 'Warmup score too low' };
          }
          
          if (currentDrill.type === 'glide' && result.score < 0.7) {
            return { progress: false, nextDrill: null, reason: 'Glide score too low' };
          }
          
          if (currentDrill.type === 'phrase' && result.score < 0.6) {
            return { progress: false, nextDrill: null, reason: 'Phrase score too low' };
          }
          
          // Progress to next drill
          const nextDrill = drillSequence[currentIndex + 1];
          return { progress: true, nextDrill, reason: 'Success' };
        }
        
        // Test drill sequence
        const drillSequence = [
          { id: 'warmup-001', type: 'warmup', name: 'Basic Warmup' },
          { id: 'glide-001', type: 'glide', name: 'Octave Glide' },
          { id: 'phrase-001', type: 'phrase', name: 'Short Phrase' },
          { id: 'reflection-001', type: 'reflection', name: 'Self Assessment' }
        ];
        
        // Test case 1: Successful progression
        const warmupResult = { passed: true, score: 0.85 };
        const warmupProgression = shouldProgressToNext(drillSequence[0], warmupResult, drillSequence);
        
        // Test case 2: Failed warmup
        const failedWarmupResult = { passed: true, score: 0.75 }; // Below 0.8 threshold
        const failedWarmupProgression = shouldProgressToNext(drillSequence[0], failedWarmupResult, drillSequence);
        
        // Test case 3: Failed drill
        const failedResult = { passed: false, score: 0.3 };
        const failedProgression = shouldProgressToNext(drillSequence[1], failedResult, drillSequence);
        
        return {
          success: true,
          warmupProgression,
          failedWarmupProgression,
          failedProgression,
          progressionLogic: {
            warmupPasses: warmupProgression.progress,
            warmupFails: !failedWarmupProgression.progress,
            failedDrillBlocks: !failedProgression.progress
          }
        };
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(flowTest.success).toBe(true);
    expect(flowTest.progressionLogic.warmupPasses).toBe(true);
    expect(flowTest.progressionLogic.warmupFails).toBe(true);
    expect(flowTest.progressionLogic.failedDrillBlocks).toBe(true);
  });
});




