/**
 * ScenarioCard Component - Applied Prosody Scenarios
 * 
 * T2: Prosody Carry-over Scenarios
 * Implements voicemail and meeting intro scenario cards with
 * real-time feedback and accessibility features.
 */

'use client';

import React, { useState, useEffect, useRef } from 'react';
import { ProsodyEngine, ScenarioConfig, ScenarioResult } from '../../engine/audio/prosody';
import { useReducedMotion } from '../../hooks/useReducedMotion';

interface ScenarioCardProps {
  scenario: ScenarioConfig;
  isActive: boolean;
  onResult: (result: ScenarioResult) => void;
  onStart: (scenarioId: string) => void;
  onStop: () => void;
  mockData?: boolean;
}

export function ScenarioCard({ 
  scenario, 
  isActive, 
  onResult, 
  onStart, 
  onStop, 
  mockData = false 
}: ScenarioCardProps) {
  const [isRecording, setIsRecording] = useState(false);
  const [result, setResult] = useState<ScenarioResult | null>(null);
  const [feedback, setFeedback] = useState<string[]>([]);
  const [announcement, setAnnouncement] = useState('');
  const [countdown, setCountdown] = useState<number | null>(null);
  
  const prosodyEngine = useRef(new ProsodyEngine());
  const countdownInterval = useRef<NodeJS.Timeout | null>(null);
  const recordingTimeout = useRef<NodeJS.Timeout | null>(null);
  const reducedMotion = useReducedMotion();

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (countdownInterval.current) {
        clearInterval(countdownInterval.current);
      }
      if (recordingTimeout.current) {
        clearTimeout(recordingTimeout.current);
      }
    };
  }, []);

  // Deterministic mock data generation using scenario-specific contours
  const generateMockResult = (): ScenarioResult => {
    // Deterministic result based on scenario target
    const targetRiseFall = scenario.targetRiseFall;
    const riseFallLabel = targetRiseFall; // Mock mode always "passes" the target
    
    // Deterministic expressiveness based on scenario threshold
    const baseExpressiveness = scenario.expressivenessThreshold + 0.1; // Slightly above threshold
    const expressiveness01 = Math.min(baseExpressiveness, 0.8); // Cap at 80%
    
    const pass = riseFallLabel === scenario.targetRiseFall && 
                 expressiveness01 >= scenario.expressivenessThreshold;

    const feedback: string[] = [];
    if (riseFallLabel === scenario.targetRiseFall) {
      if (scenario.targetRiseFall === 'fall') {
        feedback.push('✅ Gentle fall detected — clear statement');
      } else {
        feedback.push('✅ Nice rise detected — engaging question');
      }
    } else {
      if (scenario.targetRiseFall === 'fall') {
        feedback.push('💡 Try ending with a gentle fall for a clear statement');
      } else {
        feedback.push('💡 Try ending with a slight rise to sound more engaging');
      }
    }

    if (expressiveness01 >= 0.6) {
      feedback.push('✅ Nice variety in pitch — expressive delivery');
    } else if (expressiveness01 >= 0.3) {
      feedback.push('👍 Good expressiveness — keep it natural');
    } else {
      feedback.push('💡 Try adding a bit more pitch variety for expressiveness');
    }

    return {
      scenarioId: scenario.id,
      riseFallLabel,
      expressiveness01,
      pass,
      feedback,
      metrics: {
        pitchRange: 50 + expressiveness01 * 30, // Deterministic based on expressiveness
        pitchVariation: 15 + expressiveness01 * 20,
        energyVariation: 0.1 + expressiveness01 * 0.15,
        duration: scenario.expectedDuration // Exact duration for deterministic testing
      }
    };
  };

  const startRecording = () => {
    if (mockData) {
      // Mock mode - simulate recording
      setIsRecording(true);
      setCountdown(3);
      
      countdownInterval.current = setInterval(() => {
        setCountdown(prev => {
          if (prev === null || prev <= 1) {
            if (countdownInterval.current) {
              clearInterval(countdownInterval.current);
            }
            setCountdown(null);
            return null;
          }
          return prev - 1;
        });
      }, 1000);

      // Simulate recording duration
      recordingTimeout.current = setTimeout(() => {
        const mockResult = generateMockResult();
        setResult(mockResult);
        setFeedback(mockResult.feedback);
        setIsRecording(false);
        onResult(mockResult);
        setAnnouncement(`Scenario complete. ${mockResult.pass ? 'Passed' : 'Try again'}. ${mockResult.feedback.join('. ')}`);
      }, scenario.expectedDuration * 1000 + 3000); // Countdown + recording time

      setAnnouncement(`Starting ${scenario.name} in 3 seconds. ${scenario.phrase}`);
      onStart(scenario.id);
      return;
    }

    // Real recording mode
    const success = prosodyEngine.current.startScenario(scenario.id);
    if (success) {
      setIsRecording(true);
      setResult(null);
      setFeedback([]);
      setAnnouncement(`Recording ${scenario.name}. Say: "${scenario.phrase}"`);
      onStart(scenario.id);
    }
  };

  const stopRecording = () => {
    if (mockData) {
      // Mock mode cleanup
      if (countdownInterval.current) {
        clearInterval(countdownInterval.current);
      }
      if (recordingTimeout.current) {
        clearTimeout(recordingTimeout.current);
      }
      setIsRecording(false);
      setCountdown(null);
      onStop();
      return;
    }

    // Real recording mode
    const result = prosodyEngine.current.stopScenario();
    if (result) {
      setResult(result);
      setFeedback(result.feedback);
      setAnnouncement(`Scenario complete. ${result.pass ? 'Passed' : 'Try again'}. ${result.feedback.join('. ')}`);
    }
    setIsRecording(false);
    onStop();
  };

  const resetScenario = () => {
    setResult(null);
    setFeedback([]);
    setAnnouncement('');
    setIsRecording(false);
    setCountdown(null);
  };

  const getStatusColor = () => {
    if (isRecording) return 'bg-blue-100 border-blue-300';
    if (result?.pass) return 'bg-green-100 border-green-300';
    if (result && !result.pass) return 'bg-yellow-100 border-yellow-300';
    return 'bg-gray-100 border-gray-300';
  };

  const getStatusIcon = () => {
    if (isRecording) return '🎤';
    if (result?.pass) return '✅';
    if (result && !result.pass) return '🔄';
    return '🎯';
  };

  return (
    <div 
      data-testid="scenario-card"
      className={`rounded-lg border-2 p-6 ${reducedMotion ? '' : 'transition-all duration-200'} ${getStatusColor()}`}
    >
      {/* Screen reader announcements */}
      <div 
        aria-live="polite" 
        aria-atomic="true" 
        className="sr-only"
        role="status"
      >
        {announcement}
      </div>

      {/* Scenario Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center space-x-3">
          <span className="text-2xl" role="img" aria-label={`${scenario.name} scenario`}>
            {getStatusIcon()}
          </span>
          <div>
            <h3 className="text-lg font-semibold text-gray-900">
              {scenario.name}
            </h3>
            <p className="text-sm text-gray-600">
              Target: {scenario.targetRiseFall} • Duration: {scenario.expectedDuration}s
            </p>
          </div>
        </div>
        
        {mockData && (
          <span className="px-2 py-1 bg-purple-100 text-purple-800 text-xs rounded-full">
            Mock Mode
          </span>
        )}
      </div>

      {/* Scenario Phrase */}
      <div className="bg-white rounded-lg p-4 mb-4 border border-gray-200">
        <p className="text-gray-700 font-medium mb-2">Practice phrase:</p>
        <p className="text-lg text-gray-900 italic">
          "{scenario.phrase}"
        </p>
      </div>

      {/* Countdown Display */}
      {countdown !== null && (
        <div className="text-center mb-4">
          <div className="text-4xl font-bold text-blue-600 mb-2">
            {countdown}
          </div>
          <p className="text-sm text-gray-600">Get ready...</p>
        </div>
      )}

      {/* Recording Status */}
      {isRecording && countdown === null && (
        <div className="text-center mb-4">
          <div className="inline-flex items-center space-x-2 text-blue-600">
            <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
            <span className="font-medium">Recording...</span>
          </div>
        </div>
      )}

      {/* Results Display */}
      {result && (
        <div className="mb-4 space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div className="text-center p-3 bg-white rounded-lg border">
              <div className="text-sm text-gray-600 mb-1">Rise/Fall</div>
              <div className={`font-semibold ${
                result.riseFallLabel === scenario.targetRiseFall ? 'text-green-600' : 'text-orange-600'
              }`}>
                {result.riseFallLabel}
              </div>
            </div>
            <div className="text-center p-3 bg-white rounded-lg border">
              <div className="text-sm text-gray-600 mb-1">Expressiveness</div>
              <div className="font-semibold text-blue-600">
                {(result.expressiveness01 * 100).toFixed(0)}%
              </div>
            </div>
          </div>

          {/* Feedback */}
          <div className="bg-white rounded-lg p-4 border border-gray-200">
            <h4 className="font-medium text-gray-900 mb-2">Feedback:</h4>
            <ul className="space-y-1">
              {feedback.map((item, index) => (
                <li key={index} className="text-sm text-gray-700">
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}

      {/* Controls */}
      <div className="flex space-x-3">
        {!isRecording && !result && (
          <button
            onClick={startRecording}
            disabled={!isActive}
            className={`flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-blue-500 focus:ring-offset-2`}
            aria-label={`Start ${scenario.name} scenario`}
          >
            Start Recording
          </button>
        )}

        {isRecording && (
          <button
            onClick={stopRecording}
            className={`flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-red-500 focus:ring-offset-2`}
            aria-label={`Stop recording ${scenario.name}`}
          >
            Stop Recording
          </button>
        )}

        {result && (
          <button
            onClick={resetScenario}
            className={`flex-1 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-gray-500 focus:ring-offset-2`}
            aria-label={`Reset ${scenario.name} scenario`}
          >
            Try Again
          </button>
        )}
      </div>

      {/* Progress Indicator */}
      <div className="mt-4">
        <div className="flex items-center space-x-2">
          <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
            <div 
              className={`h-full ${reducedMotion ? '' : 'transition-all duration-300'} ${
                isRecording ? 'bg-blue-500' : 
                result?.pass ? 'bg-green-500' : 
                result ? 'bg-yellow-500' : 'bg-gray-300'
              }`}
              style={{ width: isRecording ? '100%' : result ? '100%' : '0%' }}
            />
          </div>
          <span className="text-xs text-gray-500">
            {result ? (result.pass ? 'Passed' : 'Try again') : 'Ready'}
          </span>
        </div>
      </div>
    </div>
  );
}
