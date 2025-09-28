/**
 * CooldownCard Component - SOVT Cooldown Flow
 * 
 * T3: Safety Guardrails
 * Displays supportive SOVT (Semi-Occluded Vocal Tract) exercises
 * when vocal strain is detected. Includes progress tracking and
 * accessibility features.
 */

'use client';

import React, { useState, useEffect, useRef } from 'react';

interface CooldownCardProps {
  isActive: boolean;
  cooldownSec: number;
  strainReasons: string[];
  onComplete: () => void;
  onSkip?: () => void;
  reducedMotion?: boolean;
}

interface SOVTExercise {
  id: string;
  name: string;
  description: string;
  duration: number; // seconds
  instructions: string[];
  icon: string;
}

export function CooldownCard({ 
  isActive, 
  cooldownSec, 
  strainReasons, 
  onComplete, 
  onSkip,
  reducedMotion = false 
}: CooldownCardProps) {
  const [remainingSec, setRemainingSec] = useState(cooldownSec);
  const [currentExercise, setCurrentExercise] = useState<SOVTExercise | null>(null);
  const [announcement, setAnnouncement] = useState('');
  const [progress, setProgress] = useState(0);
  
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const exerciseIndexRef = useRef(0);

  // SOVT exercises for cooldown
  const exercises: SOVTExercise[] = [
    {
      id: 'lip-trill',
      name: 'Lip Trill',
      description: 'Gentle lip trilling to relax vocal cords',
      duration: 15,
      instructions: [
        'Place lips together lightly',
        'Blow air through lips to create trill',
        'Keep it gentle and relaxed',
        'Focus on smooth, even airflow'
      ],
      icon: '👄'
    },
    {
      id: 'straw-phonation',
      name: 'Straw Phonation',
      description: 'Humming through a straw for vocal relaxation',
      duration: 15,
      instructions: [
        'Place straw between lips',
        'Hum gently through the straw',
        'Feel the gentle vibration',
        'Keep volume soft and comfortable'
      ],
      icon: '🥤'
    },
    {
      id: 'breathing',
      name: 'Gentle Breathing',
      description: 'Deep breathing to reset and relax',
      duration: 15,
      instructions: [
        'Breathe in slowly through nose',
        'Hold for 2-3 seconds',
        'Exhale slowly through mouth',
        'Repeat with gentle rhythm'
      ],
      icon: '🫁'
    }
  ];

  // Initialize cooldown
  useEffect(() => {
    if (isActive) {
      setRemainingSec(cooldownSec);
      setProgress(0);
      exerciseIndexRef.current = 0;
      setCurrentExercise(exercises[0]);
      
      // Announce strain detection
      const reasonText = strainReasons.length > 0 
        ? `Detected: ${strainReasons.join(', ')}` 
        : 'Vocal strain detected';
      setAnnouncement(`Safety pause activated. ${reasonText}. Let's reset and keep it comfy.`);
      
      // Start countdown
      intervalRef.current = setInterval(() => {
        setRemainingSec(prev => {
          if (prev <= 1) {
            onComplete();
            return 0;
          }
          return prev - 1;
        });
        
        // Update progress
        setProgress(prev => {
          const newProgress = ((cooldownSec - remainingSec + 1) / cooldownSec) * 100;
          return Math.min(newProgress, 100);
        });
        
        // Rotate exercises every 15 seconds
        const exerciseDuration = 15;
        const currentTime = cooldownSec - remainingSec + 1;
        const newExerciseIndex = Math.floor(currentTime / exerciseDuration) % exercises.length;
        
        if (newExerciseIndex !== exerciseIndexRef.current) {
          exerciseIndexRef.current = newExerciseIndex;
          setCurrentExercise(exercises[newExerciseIndex]);
          
          // Announce exercise change
          setAnnouncement(`Now try: ${exercises[newExerciseIndex].name}. ${exercises[newExerciseIndex].description}`);
        }
      }, 1000);
    } else {
      // Cleanup
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [isActive, cooldownSec, strainReasons, onComplete]);

  // Format time display
  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Get progress ring color based on remaining time
  const getProgressColor = (): string => {
    const percentage = progress / 100;
    if (percentage < 0.33) return 'text-red-500';
    if (percentage < 0.66) return 'text-yellow-500';
    return 'text-green-500';
  };

  if (!isActive) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-2xl p-8 max-w-md mx-4 w-full">
        {/* Screen reader announcements */}
        <div 
          aria-live="polite" 
          aria-atomic="true" 
          className="sr-only"
          role="status"
        >
          {announcement}
        </div>

        {/* Header */}
        <div className="text-center mb-6">
          <div className="text-4xl mb-2" role="img" aria-label="Safety pause">
            🛡️
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Safety Pause
          </h2>
          <p className="text-gray-600">
            Let's reset and keep it comfy
          </p>
        </div>

        {/* Strain Reasons */}
        {strainReasons.length > 0 && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
            <h3 className="font-medium text-yellow-800 mb-2">Detected:</h3>
            <ul className="text-sm text-yellow-700 space-y-1">
              {strainReasons.map((reason, index) => (
                <li key={index} className="flex items-start">
                  <span className="text-yellow-500 mr-2">•</span>
                  {reason}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Current Exercise */}
        {currentExercise && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
            <div className="flex items-center mb-4">
              <span className="text-3xl mr-3" role="img" aria-label={currentExercise.name}>
                {currentExercise.icon}
              </span>
              <div>
                <h3 className="text-lg font-semibold text-blue-900">
                  {currentExercise.name}
                </h3>
                <p className="text-sm text-blue-700">
                  {currentExercise.description}
                </p>
              </div>
            </div>
            
            <div className="space-y-2">
              <h4 className="font-medium text-blue-800 text-sm">Instructions:</h4>
              <ul className="text-sm text-blue-700 space-y-1">
                {currentExercise.instructions.map((instruction, index) => (
                  <li key={index} className="flex items-start">
                    <span className="text-blue-500 mr-2">{index + 1}.</span>
                    {instruction}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}

        {/* Progress Ring */}
        <div className="flex justify-center mb-6">
          <div className="relative w-32 h-32">
            <svg className="w-32 h-32 transform -rotate-90" viewBox="0 0 100 100">
              {/* Background circle */}
              <circle
                cx="50"
                cy="50"
                r="45"
                stroke="currentColor"
                strokeWidth="8"
                fill="none"
                className="text-gray-200"
              />
              {/* Progress circle */}
              <circle
                cx="50"
                cy="50"
                r="45"
                stroke="currentColor"
                strokeWidth="8"
                fill="none"
                strokeDasharray={`${2 * Math.PI * 45}`}
                strokeDashoffset={`${2 * Math.PI * 45 * (1 - progress / 100)}`}
                className={`transition-all ${reducedMotion ? '' : 'duration-1000'} ${getProgressColor()}`}
                strokeLinecap="round"
              />
            </svg>
            
            {/* Time display */}
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <div className="text-2xl font-bold text-gray-900">
                  {formatTime(remainingSec)}
                </div>
                <div className="text-xs text-gray-500">
                  remaining
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Skip Button (optional) */}
        {onSkip && (
          <div className="text-center">
            <button
              onClick={onSkip}
              className="text-sm text-gray-500 hover:text-gray-700 underline transition-colors focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 rounded"
              aria-label="Skip cooldown (not recommended)"
            >
              Skip cooldown
            </button>
          </div>
        )}

        {/* Help Text */}
        <div className="mt-6 bg-gray-50 rounded-lg p-4">
          <h4 className="font-medium text-gray-900 mb-2">💡 Why this helps:</h4>
          <p className="text-sm text-gray-600">
            SOVT exercises gently massage your vocal cords and reduce tension. 
            This cooldown helps prevent vocal strain and keeps your voice healthy.
          </p>
        </div>
      </div>
    </div>
  );
}
