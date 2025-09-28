/**
 * Listen Page - Intuitive Voice Analysis Interface
 * 
 * UI-01: Clean, intuitive interface with clear visual feedback
 * Replaces confusing barebones interface with user-friendly design
 */

'use client';

import { useState, useEffect } from 'react';
import { useMicManager, MicSettingsDisplay } from '../../src/components/MicManager';
import { useAudioContext, AudioContextDisplay } from '../../src/components/AudioContextManager';
import { useWorkletManager, WorkletDataDisplay } from '../../src/components/WorkletManager';
import Link from 'next/link';

export default function ListenPage() {
  const [isScienceMode, setIsScienceMode] = useState(false);
  const [latency, setLatency] = useState(0);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const micManager = useMicManager();
  const audioContext = useAudioContext();
  const workletManager = useWorkletManager(audioContext.context);

  // Measure latency
  useEffect(() => {
    if (workletManager.isActive) {
      const startTime = performance.now();
      const interval = setInterval(() => {
        const currentTime = performance.now();
        const measuredLatency = currentTime - startTime;
        setLatency(measuredLatency);
      }, 100);

      return () => clearInterval(interval);
    }
  }, [workletManager.isActive]);

  const handleStartListening = async () => {
    setIsAnalyzing(true);
    
    try {
      // Create audio context
      await audioContext.createContext();
      
      // Request microphone
      await micManager.requestMic();
      
      if (micManager.stream && audioContext.context) {
        // Connect mic to audio context
        const source = audioContext.connectMic(micManager.stream);
        
        if (source) {
          // Connect worklets
          workletManager.connectWorklets(source);
        }
      }
    } catch (error) {
      console.error('Failed to start listening:', error);
      setIsAnalyzing(false);
    }
  };

  const handleStopListening = () => {
    workletManager.disconnectWorklets();
    micManager.stopMic();
    audioContext.closeContext();
    setIsAnalyzing(false);
  };

  const getPitchColor = (pitch: number) => {
    if (pitch < 100) return 'text-red-500';
    if (pitch < 200) return 'text-orange-500';
    if (pitch < 300) return 'text-yellow-500';
    if (pitch < 400) return 'text-green-500';
    return 'text-blue-500';
  };

  const getConfidenceColor = (confidence: number) => {
    if (confidence < 0.3) return 'text-red-500';
    if (confidence < 0.6) return 'text-yellow-500';
    return 'text-green-500';
  };

  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (!isAnalyzing) {
        handleStartListening();
      } else {
        handleStopListening();
      }
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Skip link for keyboard navigation */}
      <a 
        href="#main-content" 
        className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-blue-600 text-white px-4 py-2 rounded-md z-50"
      >
        Skip to main content
      </a>
      
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Link href="/" className="flex items-center space-x-3 hover:opacity-80 transition-opacity">
                <div className="w-8 h-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">R</span>
                </div>
                <span className="text-lg font-semibold text-gray-900">Resonai</span>
              </Link>
            </div>
            
            <div className="flex items-center space-x-4">
              <Link 
                href="/practice" 
                className="px-4 py-2 text-blue-600 hover:text-blue-700 font-medium transition-colors"
              >
                Practice Session
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

      <main id="main-content" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">🎤 Voice Analysis</h1>
          <p className="text-lg text-gray-600 max-w-3xl">
            Real-time voice analysis with live pitch, energy, and formant tracking. 
            Perfect for monitoring your voice characteristics and getting instant feedback.
          </p>
        </div>

        {/* Main Control Panel */}
        <div className="bg-white rounded-xl shadow-sm p-8 mb-8 border border-gray-200">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Audio Pipeline</h2>
            
            <div className="flex items-center space-x-4">
              <label className="flex items-center space-x-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isScienceMode}
                  onChange={(e) => setIsScienceMode(e.target.checked)}
                  className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                />
                <span className="text-sm font-medium text-gray-700">Science Mode</span>
              </label>
              
              {!isAnalyzing ? (
                <button
                  onClick={handleStartListening}
                  disabled={!micManager.isSupported || !audioContext.isSupported}
                  className="px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg hover:from-blue-700 hover:to-purple-700 disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed font-medium transition-all duration-200 shadow-sm hover:shadow-md focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  aria-label="Start voice analysis and begin recording"
                >
                  🎤 Start Analysis
                </button>
              ) : (
                <button
                  onClick={handleStopListening}
                  className="px-6 py-3 bg-gradient-to-r from-red-600 to-pink-600 text-white rounded-lg hover:from-red-700 hover:to-pink-700 font-medium transition-all duration-200 shadow-sm hover:shadow-md focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                  aria-label="Stop voice analysis and end recording"
                >
                  ⏹️ Stop Analysis
                </button>
              )}
            </div>
          </div>

          {/* Status Indicators */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            <div 
              className={`p-4 rounded-lg border-2 transition-all duration-200 ${
                micManager.isActive 
                  ? 'bg-green-50 border-green-200 text-green-800' 
                  : 'bg-gray-50 border-gray-200 text-gray-600'
              }`}
              role="status"
              aria-live="polite"
              aria-atomic="true"
            >
              <div className="flex items-center space-x-3">
                <div className="text-2xl">🎤</div>
                <div>
                  <div className="font-medium">Microphone</div>
                  <div className="text-sm">{micManager.isActive ? 'Active & Recording' : 'Ready to Start'}</div>
                </div>
              </div>
            </div>
            
            <div 
              className={`p-4 rounded-lg border-2 transition-all duration-200 ${
                audioContext.contextState === 'running' 
                  ? 'bg-green-50 border-green-200 text-green-800' 
                  : 'bg-gray-50 border-gray-200 text-gray-600'
              }`}
              role="status"
              aria-live="polite"
              aria-atomic="true"
            >
              <div className="flex items-center space-x-3">
                <div className="text-2xl">🎵</div>
                <div>
                  <div className="font-medium">Audio Engine</div>
                  <div className="text-sm">{audioContext.contextState === 'running' ? 'Processing Audio' : 'Standby'}</div>
                </div>
              </div>
            </div>
            
            <div 
              className={`p-4 rounded-lg border-2 transition-all duration-200 ${
                workletManager.isActive 
                  ? 'bg-green-50 border-green-200 text-green-800' 
                  : 'bg-gray-50 border-gray-200 text-gray-600'
              }`}
              role="status"
              aria-live="polite"
              aria-atomic="true"
            >
              <div className="flex items-center space-x-3">
                <div className="text-2xl">⚡</div>
                <div>
                  <div className="font-medium">Analysis Engine</div>
                  <div className="text-sm">{workletManager.isActive ? 'Real-time Analysis' : 'Waiting'}</div>
                </div>
              </div>
            </div>
          </div>

          {/* Latency Display */}
          {workletManager.isActive && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex justify-between items-center">
                <div className="flex items-center space-x-3">
                  <div className="text-2xl">⚡</div>
                  <div>
                    <div className="font-medium text-blue-900">Processing Latency</div>
                    <div className="text-sm text-blue-700">Real-time audio analysis speed</div>
                  </div>
                </div>
                <div className={`text-2xl font-bold ${latency < 100 ? 'text-green-600' : 'text-red-600'}`}>
                  {latency.toFixed(1)} ms
                </div>
              </div>
              <div className="mt-2 text-xs text-blue-600">
                Target: &lt;100ms for optimal real-time feedback
              </div>
            </div>
          )}
        </div>

        {/* Live Voice Analysis Display */}
        {workletManager.isActive && (
          <div className="bg-white rounded-xl shadow-sm p-8 mb-8 border border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">📊 Live Voice Analysis</h2>
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Pitch Display */}
              <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">🎵 Pitch Analysis</h3>
                <div className="text-center">
                  <div className={`text-5xl font-bold mb-2 ${getPitchColor(workletManager.data.pitch)}`}>
                    {workletManager.data.pitch.toFixed(0)}
                  </div>
                  <div className="text-lg text-gray-600 mb-4">Hz</div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-600">Confidence:</span>
                    <span className={`font-semibold ${getConfidenceColor(workletManager.data.confidence)}`}>
                      {(workletManager.data.confidence * 100).toFixed(1)}%
                    </span>
                  </div>
                </div>
              </div>

              {/* Energy Display */}
              <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">⚡ Energy Analysis</h3>
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">RMS Energy:</span>
                    <span className="font-semibold text-gray-900">
                      {workletManager.data.rms.toFixed(3)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">High Frequency:</span>
                    <span className="font-semibold text-gray-900">
                      {workletManager.data.highFreq.toFixed(3)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-600">Low Frequency:</span>
                    <span className="font-semibold text-gray-900">
                      {workletManager.data.lowFreq.toFixed(3)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Science Mode Details */}
        {isScienceMode && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
            <MicSettingsDisplay settings={micManager.settings} />
            <AudioContextDisplay state={audioContext} />
            <WorkletDataDisplay data={workletManager.data} />
            
            {/* Cross-Origin Isolation Check */}
            <div className="bg-white rounded-lg shadow-sm p-6 border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">🔒 Security Status</h3>
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-gray-600">Cross-Origin Isolation:</span>
                  <span className={`font-semibold ${window.crossOriginIsolated ? 'text-green-600' : 'text-red-600'}`}>
                    {window.crossOriginIsolated ? '✅ Enabled' : '❌ Disabled'}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-600">SharedArrayBuffer:</span>
                  <span className={`font-semibold ${typeof SharedArrayBuffer !== 'undefined' ? 'text-green-600' : 'text-red-600'}`}>
                    {typeof SharedArrayBuffer !== 'undefined' ? '✅ Available' : '❌ Unavailable'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Error Display */}
        {(micManager.error || audioContext.error || workletManager.error) && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <h3 className="font-semibold text-red-800 mb-3">⚠️ Issues Detected</h3>
            <div className="space-y-2">
              {micManager.error && <div className="text-red-700">🎤 Microphone: {micManager.error}</div>}
              {audioContext.error && <div className="text-red-700">🎵 Audio Engine: {audioContext.error}</div>}
              {workletManager.error && <div className="text-red-700">⚡ Analysis Engine: {workletManager.error}</div>}
            </div>
          </div>
        )}

        {/* Help Section */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="font-semibold text-blue-900 mb-3">💡 How to Use Voice Analysis</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-800">
            <div>
              <strong>1. Start Analysis:</strong> Click "Start Analysis" and allow microphone access when prompted.
            </div>
            <div>
              <strong>2. Speak Normally:</strong> Talk naturally - the system will analyze your voice in real-time.
            </div>
            <div>
              <strong>3. Monitor Feedback:</strong> Watch the live pitch and energy displays for instant feedback.
            </div>
            <div>
              <strong>4. Science Mode:</strong> Enable for detailed technical information and advanced metrics.
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
