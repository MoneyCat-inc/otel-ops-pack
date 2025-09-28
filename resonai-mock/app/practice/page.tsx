/**
 * Practice Page - Intuitive Practice Session Interface
 * 
 * UI-01: Clean, intuitive practice flow with clear guidance
 * Replaces confusing interface with user-friendly design
 */

'use client';

import { useState, useEffect } from 'react';
import { useMicManager } from '../../src/components/MicManager';
import { useAudioContext } from '../../src/components/AudioContextManager';
import { useWorkletManager } from '../../src/components/WorkletManager';
import Link from 'next/link';

interface PracticeSession {
  id: string;
  startTime: number;
  endTime?: number;
  phases: {
    warmup: { start: number; end?: number; metrics: any };
    practice: { start: number; end?: number; metrics: any };
    reflection: { start: number; end?: number; metrics: any };
  };
  summary: {
    totalTime: number;
    voicedTimePct: number;
    jitterEma: number;
    tiltEma: number;
  };
}

type PracticePhase = 'idle' | 'warmup' | 'practice' | 'reflection' | 'complete';

export default function PracticePage() {
  const [phase, setPhase] = useState<PracticePhase>('idle');
  const [session, setSession] = useState<PracticeSession | null>(null);
  const [metrics, setMetrics] = useState({
    voicedTimePct: 0,
    jitterEma: 0,
    tiltEma: 0,
  });
  const [isStarting, setIsStarting] = useState(false);
  const [announcement, setAnnouncement] = useState('');

  const micManager = useMicManager();
  const audioContext = useAudioContext();
  const workletManager = useWorkletManager(audioContext.context);

  // Get phase instructions function
  const getPhaseInstructions = () => {
    switch (phase) {
      case 'warmup':
        return {
          title: '🌅 Warmup Phase',
          instruction: 'Take a few deep breaths and gently hum to warm up your voice. This helps prepare your vocal cords for practice.',
          duration: '2-3 minutes',
          tips: ['Breathe deeply from your diaphragm', 'Start with gentle humming', 'Don\'t strain your voice', 'Focus on relaxation']
        };
      case 'practice':
        return {
          title: '🎯 Practice Phase',
          instruction: 'Now practice the specific techniques. Focus on the feedback and make adjustments as needed.',
          duration: '5-10 minutes',
          tips: ['Listen to the real-time feedback', 'Make small adjustments', 'Stay relaxed and confident', 'Take breaks if needed']
        };
      case 'reflection':
        return {
          title: '🤔 Reflection Phase',
          instruction: 'Take a moment to reflect on your practice. What felt good? What would you like to work on next time?',
          duration: '1-2 minutes',
          tips: ['Note what went well', 'Identify areas for improvement', 'Set goals for next session', 'Celebrate your progress']
        };
      default:
        return {
          title: '🎤 Voice Practice',
          instruction: 'Ready to start your practice session? Click the button below to begin.',
          duration: '10-15 minutes total',
          tips: ['Ensure good microphone quality', 'Find a quiet environment', 'Have water nearby', 'Take your time']
        };
    }
  };

  // Get phase instructions
  const instructions = getPhaseInstructions();

  // Announce phase changes to screen readers
  useEffect(() => {
    if (phase !== 'idle') {
      const phaseNames = {
        warmup: 'Warmup phase',
        practice: 'Practice phase', 
        reflection: 'Reflection phase',
        complete: 'Practice session complete'
      };
      setAnnouncement(`${phaseNames[phase]} started. ${instructions.instruction}`);
    }
  }, [phase, instructions.instruction]);

  // Update metrics from worklet data
  useEffect(() => {
    if (workletManager.isActive && workletManager.data) {
      const data = workletManager.data;
      
      // Calculate voiced time percentage (simplified)
      const voicedTimePct = data.confidence > 0.3 ? 100 : 0;
      
      // Calculate jitter (pitch variation)
      const jitterEma = Math.abs(data.pitch - 200) / 200; // Normalized to 200Hz baseline
      
      // Calculate tilt (energy distribution)
      const tiltEma = data.highFreq / (data.lowFreq + 0.001); // Avoid division by zero
      
      setMetrics({
        voicedTimePct,
        jitterEma,
        tiltEma,
      });
    }
  }, [workletManager.data, workletManager.isActive]);

  const startSession = async () => {
    setIsStarting(true);
    
    try {
      const sessionId = `session_${Date.now()}`;
      const newSession: PracticeSession = {
        id: sessionId,
        startTime: Date.now(),
        phases: {
          warmup: { start: Date.now(), metrics: {} },
          practice: { start: 0, metrics: {} },
          reflection: { start: 0, metrics: {} },
        },
        summary: {
          totalTime: 0,
          voicedTimePct: 0,
          jitterEma: 0,
          tiltEma: 0,
        },
      };

      setSession(newSession);
      setPhase('warmup');

      // Start audio pipeline
      await audioContext.createContext();
      await micManager.requestMic();
      
      if (micManager.stream && audioContext.context) {
        const source = audioContext.connectMic(micManager.stream);
        if (source) {
          workletManager.connectWorklets(source);
        }
      }
    } catch (error) {
      console.error('Failed to start session:', error);
    } finally {
      setIsStarting(false);
    }
  };

  const nextPhase = () => {
    if (!session) return;

    const now = Date.now();
    const updatedSession = { ...session };

    switch (phase) {
      case 'warmup':
        updatedSession.phases.warmup.end = now;
        updatedSession.phases.practice.start = now;
        setPhase('practice');
        break;
      case 'practice':
        updatedSession.phases.practice.end = now;
        updatedSession.phases.reflection.start = now;
        setPhase('reflection');
        break;
      case 'reflection':
        updatedSession.phases.reflection.end = now;
        updatedSession.endTime = now;
        updatedSession.summary = {
          totalTime: now - session.startTime,
          voicedTimePct: metrics.voicedTimePct,
          jitterEma: metrics.jitterEma,
          tiltEma: metrics.tiltEma,
        };
        setPhase('complete');
        break;
    }

    setSession(updatedSession);
  };

  // Handle keyboard navigation
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (phase === 'idle') {
        startSession();
      } else if (phase !== 'complete') {
        nextPhase();
      } else {
        saveSession();
      }
    }
  };

  const saveSession = async () => {
    if (!session) return;

    try {
      // Save to IndexedDB
      const db = await openDB();
      const transaction = db.transaction(['sessions'], 'readwrite');
      const store = transaction.objectStore('sessions');
      
      return new Promise<void>((resolve, reject) => {
        const request = store.add(session);
        request.onsuccess = () => {
          console.log('Session saved to IndexedDB:', session);
          
          // Reset for next session
          setSession(null);
          setPhase('idle');
          
          // Stop audio pipeline
          workletManager.disconnectWorklets();
          micManager.stopMic();
          audioContext.closeContext();
          
          resolve();
        };
        request.onerror = () => reject(request.error);
      });
      
    } catch (error) {
      console.error('Failed to save session:', error);
    }
  };

  const openDB = async () => {
    return new Promise<IDBDatabase>((resolve, reject) => {
      const request = indexedDB.open('ResonaiPractice', 1);
      
      request.onerror = () => reject(request.error);
      request.onsuccess = () => resolve(request.result);
      
      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        
        if (!db.objectStoreNames.contains('sessions')) {
          const store = db.createObjectStore('sessions', { keyPath: 'id' });
          store.createIndex('startTime', 'startTime', { unique: false });
        }
      };
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-100">
      {/* Screen reader announcements */}
      <div 
        aria-live="polite" 
        aria-atomic="true" 
        className="sr-only"
        role="status"
      >
        {announcement}
      </div>

      {/* Skip link for keyboard users */}
      <a 
        href="#main-content" 
        className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-blue-600 text-white px-4 py-2 rounded z-50"
      >
        Skip to main content
      </a>

      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Link href="/" className="flex items-center space-x-3 hover:opacity-80 transition-opacity">
                <div className="w-8 h-8 bg-gradient-to-r from-green-600 to-emerald-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">R</span>
                </div>
                <span className="text-lg font-semibold text-gray-900">Resonai</span>
              </Link>
            </div>
            
            <div className="flex items-center space-x-4">
              <Link 
                href="/listen" 
                className="px-4 py-2 text-green-600 hover:text-green-700 font-medium transition-colors"
              >
                Voice Analysis
              </Link>
              <Link 
                href="/labs/memx" 
                className="px-4 py-2 text-gray-600 hover:text-gray-700 font-medium transition-colors"
              >
                Memory Labs
              </Link>
            </div>
          </div>
        </div>
      </header>

      <main id="main-content" className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">🎯 Practice Session</h1>
          <p className="text-lg text-gray-600 max-w-3xl">
            Guided voice practice with structured warmup, practice, and reflection phases. 
            Get real-time feedback and track your progress over time.
          </p>
        </div>

        {/* Phase Display */}
        <div className="bg-white rounded-xl shadow-sm p-8 mb-8 border border-gray-200">
          <div className="text-center mb-6">
            <h2 className="text-2xl font-semibold text-gray-900 mb-2">
              {instructions.title}
            </h2>
            <p className="text-gray-600 mb-4">{instructions.instruction}</p>
            <p className="text-sm text-gray-500">Duration: {instructions.duration}</p>
          </div>

          {/* Phase Progress */}
          <div className="flex justify-center mb-6">
            <div className="flex space-x-4" role="progressbar" aria-label="Practice session progress">
              {['warmup', 'practice', 'reflection'].map((phaseName, index) => {
                const isActive = phase === phaseName;
                const isCompleted = phase === 'complete' || (phase === 'reflection' && index < 2) || (phase === 'practice' && index < 1);
                const isCurrent = phase === phaseName;
                
                return (
                  <div
                    key={phaseName}
                    className={`w-12 h-12 rounded-full flex items-center justify-center text-sm font-medium transition-all duration-200 ${
                      isActive
                        ? 'bg-green-600 text-white scale-110'
                        : isCompleted
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-300 text-gray-600'
                    }`}
                    role="img"
                    aria-label={`Phase ${index + 1}: ${phaseName} ${isActive ? '(current)' : isCompleted ? '(completed)' : '(pending)'}`}
                    tabIndex={isCurrent ? 0 : -1}
                  >
                    {index + 1}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Tips */}
          <div className="bg-gray-50 rounded-lg p-4 mb-6">
            <h4 className="font-medium text-gray-900 mb-2">💡 Tips for this phase:</h4>
            <ul className="text-sm text-gray-600 space-y-1">
              {instructions.tips.map((tip, index) => (
                <li key={index} className="flex items-start">
                  <span className="text-green-500 mr-2">•</span>
                  {tip}
                </li>
              ))}
            </ul>
          </div>

          {/* Control Buttons */}
          <div className="flex justify-center space-x-4">
            {phase === 'idle' && (
              <button
                onClick={startSession}
                onKeyDown={handleKeyDown}
                disabled={isStarting}
                aria-label={isStarting ? 'Starting practice session' : 'Start practice session'}
                className="px-8 py-4 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg hover:from-green-700 hover:to-emerald-700 disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed font-medium transition-all duration-200 shadow-sm hover:shadow-md focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
              >
                {isStarting ? '🔄 Starting...' : '🚀 Start Practice Session'}
              </button>
            )}
            
            {phase !== 'idle' && phase !== 'complete' && (
              <button
                onClick={nextPhase}
                onKeyDown={handleKeyDown}
                aria-label={`Move to next phase from ${phase}`}
                className="px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg hover:from-blue-700 hover:to-purple-700 font-medium transition-all duration-200 shadow-sm hover:shadow-md focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              >
                ➡️ Next Phase
              </button>
            )}
            
            {phase === 'complete' && (
              <button
                onClick={saveSession}
                onKeyDown={handleKeyDown}
                aria-label="Save practice session data"
                className="px-8 py-4 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg hover:from-purple-700 hover:to-pink-700 font-medium transition-all duration-200 shadow-sm hover:shadow-md focus:ring-2 focus:ring-purple-500 focus:ring-offset-2"
              >
                💾 Save Session
              </button>
            )}
          </div>
        </div>

        {/* Live Metrics */}
        {workletManager.isActive && (
          <div className="bg-white rounded-xl shadow-sm p-8 mb-8 border border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">📊 Live Practice Metrics</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div 
                className="text-center p-6 bg-blue-50 rounded-lg"
                role="status"
                aria-live="polite"
                aria-atomic="true"
              >
                <div className="text-3xl font-bold text-blue-600 mb-2">
                  {metrics.voicedTimePct.toFixed(1)}%
                </div>
                <div className="text-sm text-gray-600">Voiced Time</div>
                <div className="text-xs text-gray-500 mt-1">Percentage of time with voice activity</div>
              </div>
              
              <div 
                className="text-center p-6 bg-green-50 rounded-lg"
                role="status"
                aria-live="polite"
                aria-atomic="true"
              >
                <div className="text-3xl font-bold text-green-600 mb-2">
                  {metrics.jitterEma.toFixed(3)}
                </div>
                <div className="text-sm text-gray-600">Jitter (EMA)</div>
                <div className="text-xs text-gray-500 mt-1">Pitch stability over time</div>
              </div>
              
              <div 
                className="text-center p-6 bg-purple-50 rounded-lg"
                role="status"
                aria-live="polite"
                aria-atomic="true"
              >
                <div className="text-3xl font-bold text-purple-600 mb-2">
                  {metrics.tiltEma.toFixed(3)}
                </div>
                <div className="text-sm text-gray-600">Tilt (EMA)</div>
                <div className="text-xs text-gray-500 mt-1">Energy distribution</div>
              </div>
            </div>
          </div>
        )}

        {/* Session Progress */}
        {session && (
          <div className="bg-white rounded-xl shadow-sm p-8 border border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">📈 Session Progress</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                  <span className="font-medium text-gray-700">Session ID:</span>
                  <span className="font-mono text-sm text-gray-600">{session.id}</span>
                </div>
                
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                  <span className="font-medium text-gray-700">Total Time:</span>
                  <span className="font-semibold text-gray-900">
                    {Math.round((Date.now() - session.startTime) / 1000)}s
                  </span>
                </div>
                
                <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                  <span className="font-medium text-gray-700">Current Phase:</span>
                  <span className="capitalize font-semibold text-gray-900">{phase}</span>
                </div>
              </div>

              <div className="space-y-4">
                <div className="p-3 bg-green-50 rounded-lg">
                  <div className="font-medium text-green-800 mb-2">✅ Completed Phases</div>
                  <div className="text-sm text-green-700">
                    {phase === 'complete' ? 'All phases completed!' : 
                     phase === 'reflection' ? 'Warmup, Practice' :
                     phase === 'practice' ? 'Warmup' : 'None yet'}
                  </div>
                </div>
                
                <div className="p-3 bg-blue-50 rounded-lg">
                  <div className="font-medium text-blue-800 mb-2">🎯 Current Focus</div>
                  <div className="text-sm text-blue-700">
                    {phase === 'warmup' ? 'Voice preparation and relaxation' :
                     phase === 'practice' ? 'Active voice exercises' :
                     phase === 'reflection' ? 'Review and planning' :
                     'Ready to begin'}
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Help Section */}
        <div className="bg-green-50 border border-green-200 rounded-lg p-6">
          <h3 className="font-semibold text-green-900 mb-3">💡 Practice Session Guide</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-green-800">
            <div>
              <strong>🌅 Warmup:</strong> Prepare your voice with gentle exercises and breathing.
            </div>
            <div>
              <strong>🎯 Practice:</strong> Focus on specific voice techniques with real-time feedback.
            </div>
            <div>
              <strong>🤔 Reflection:</strong> Review your performance and plan improvements.
            </div>
            <div>
              <strong>💾 Save:</strong> Store your session data for tracking progress over time.
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
