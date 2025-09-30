/**
 * Strain Labs Page - Safety Guardrails Tuning
 * 
 * T3: Safety Guardrails
 * Provides tuning controls for strain detection thresholds and
 * live monitoring of RMS and jitter metrics with deterministic fixtures.
 */

'use client';

import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import { StrainDetector, AudioFrame, StrainMetrics } from '../../../src/engine/audio/strain';
import { STRAIN_CONSTANTS, CONSERVATIVE_STRAIN_CONSTANTS, RELAXED_STRAIN_CONSTANTS, StrainPreset } from '../../../src/engine/audio/constants';
import Link from 'next/link';

interface StrainFixture {
  description: string;
  frames: AudioFrame[];
  expectedStrain: boolean;
  expectedReasons: string[];
  duration: number;
}

export default function StrainLabsPage() {
  const [detector, setDetector] = useState<StrainDetector | null>(null);
  const [metrics, setMetrics] = useState<StrainMetrics | null>(null);
  const [isMonitoring, setIsMonitoring] = useState(false);
  const [mockData, setMockData] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [announcement, setAnnouncement] = useState('');
  
  // Configuration state
  const [config, setConfig] = useState(STRAIN_CONSTANTS);
  const [preset, setPreset] = useState<StrainPreset>('default');
  
  // Mock fixtures
  const [fixtures, setFixtures] = useState<Record<string, StrainFixture>>({});
  const [currentFixture, setCurrentFixture] = useState<string | null>(null);

  // Get mock parameter from URL
  const searchParams = useSearchParams();
  
  useEffect(() => {
    // Check for reduced motion preference
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    setReducedMotion(prefersReducedMotion);

    // Check for mock parameter
    const mockParam = searchParams.get('mock');
    if (mockParam === 'loud' || mockParam === 'rising-jitter' || mockParam === 'neutral') {
      setMockData(true);
      setCurrentFixture(mockParam);
    }

    // Load fixtures
    loadFixtures();
    
    // Initialize detector
    const newDetector = new StrainDetector(config);
    setDetector(newDetector);
  }, [searchParams]);

  const loadFixtures = async () => {
    try {
      const response = await fetch('/fixtures/strain/patterns.json');
      const data = await response.json();
      setFixtures(data);
    } catch (error) {
      console.error('Failed to load strain fixtures:', error);
    }
  };

  const updateConfig = (newConfig: Partial<typeof STRAIN_CONSTANTS>) => {
    const updatedConfig = { ...config, ...newConfig };
    setConfig(updatedConfig);
    
    if (detector) {
      detector.updateConfig(updatedConfig);
    }
  };

  const selectPreset = (newPreset: StrainPreset) => {
    setPreset(newPreset);
    
    let presetConfig;
    switch (newPreset) {
      case 'conservative':
        presetConfig = CONSERVATIVE_STRAIN_CONSTANTS;
        break;
      case 'relaxed':
        presetConfig = RELAXED_STRAIN_CONSTANTS;
        break;
      default:
        presetConfig = STRAIN_CONSTANTS;
    }
    
    setConfig(presetConfig);
    if (detector) {
      detector.updateConfig(presetConfig);
    }
  };

  const startMonitoring = () => {
    if (!detector) return;
    
    detector.startDetection();
    setIsMonitoring(true);
    setAnnouncement('Strain monitoring started');
    
    // Start mock data simulation if enabled
    if (mockData && currentFixture && fixtures[currentFixture]) {
      simulateFixture(currentFixture);
    }
  };

  const stopMonitoring = () => {
    if (!detector) return;
    
    detector.stopDetection();
    setIsMonitoring(false);
    setMetrics(null);
    setAnnouncement('Strain monitoring stopped');
  };

  const simulateFixture = (fixtureName: string) => {
    if (!detector || !fixtures[fixtureName]) return;
    
    const fixture = fixtures[fixtureName];
    let frameIndex = 0;
    
    const interval = setInterval(() => {
      if (frameIndex >= fixture.frames.length) {
        clearInterval(interval);
        return;
      }
      
      const frame = fixture.frames[frameIndex];
      detector.addFrame(frame);
      
      const currentMetrics = detector.getStrainMetrics();
      setMetrics(currentMetrics);
      
      if (currentMetrics.strainFlag) {
        setAnnouncement(`Strain detected: ${currentMetrics.strainReasons.join(', ')}`);
        clearInterval(interval);
      }
      
      frameIndex++;
    }, 100); // 100ms intervals
  };

  const testFixture = (fixtureName: string) => {
    if (!detector || !fixtures[fixtureName]) return;
    
    setCurrentFixture(fixtureName);
    setMockData(true);
    
    if (isMonitoring) {
      stopMonitoring();
    }
    
    setTimeout(() => {
      startMonitoring();
    }, 100);
  };

  const resetDetector = () => {
    if (detector) {
      detector.reset();
      setMetrics(null);
      setAnnouncement('Detector reset');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-red-100">
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
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Link href="/" className="flex items-center space-x-3 hover:opacity-80 transition-opacity">
                <div className="w-8 h-8 bg-gradient-to-r from-orange-600 to-red-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">R</span>
                </div>
                <span className="text-lg font-semibold text-gray-900">Resonai</span>
              </Link>
              <span className="text-gray-400">•</span>
              <span className="text-sm text-gray-600">Strain Guardrails</span>
            </div>
            
            <div className="flex items-center space-x-4">
              <Link 
                href="/labs/prosody-scenarios" 
                className="px-4 py-2 text-orange-600 hover:text-orange-700 font-medium transition-colors"
              >
                Prosody Scenarios
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

      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            🛡️ Safety Guardrails Lab
          </h1>
          <p className="text-lg text-gray-600 max-w-3xl">
            Tune strain detection thresholds and monitor vocal safety metrics in real-time. 
            Test with deterministic fixtures to verify detection accuracy.
          </p>
        </div>

        {/* Controls */}
        <div className="bg-white rounded-xl shadow-sm p-6 mb-8 border border-gray-200">
          <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <label htmlFor="mock-toggle" className="text-sm font-medium text-gray-700">
                  Mock Mode
                </label>
                <button
                  id="mock-toggle"
                  onClick={() => setMockData(!mockData)}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    mockData ? 'bg-orange-600' : 'bg-gray-200'
                  }`}
                  aria-label={`${mockData ? 'Disable' : 'Enable'} mock mode`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      mockData ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>
              
              {reducedMotion && (
                <div className="flex items-center space-x-2 text-sm text-gray-600">
                  <span>♿</span>
                  <span>Reduced motion enabled</span>
                </div>
              )}
            </div>

            <div className="flex items-center space-x-3">
              <div className="flex space-x-2">
                <button
                  onClick={isMonitoring ? stopMonitoring : startMonitoring}
                  className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                    isMonitoring 
                      ? 'bg-red-600 text-white hover:bg-red-700' 
                      : 'bg-green-600 text-white hover:bg-green-700'
                  }`}
                >
                  {isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'}
                </button>
                <button
                  onClick={resetDetector}
                  className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium transition-colors"
                >
                  Reset
                </button>
              </div>
            </div>
          </div>

          {/* Preset Selection */}
          <div className="mb-6">
            <h3 className="text-lg font-medium text-gray-900 mb-3">Detection Presets</h3>
            <div className="flex space-x-4">
              {(['default', 'conservative', 'relaxed'] as StrainPreset[]).map((presetName) => (
                <button
                  key={presetName}
                  onClick={() => selectPreset(presetName)}
                  className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                    preset === presetName
                      ? 'bg-orange-600 text-white'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  {presetName.charAt(0).toUpperCase() + presetName.slice(1)}
                </button>
              ))}
            </div>
          </div>

          {/* Threshold Controls */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Loudness Threshold (dBFS)
              </label>
              <input
                type="number"
                value={config.LOUD_DB_THRESH}
                onChange={(e) => updateConfig({ LOUD_DB_THRESH: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                step="1"
                min="-30"
                max="0"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Loud Duration (ms)
              </label>
              <input
                type="number"
                value={config.LOUD_MS}
                onChange={(e) => updateConfig({ LOUD_MS: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                step="100"
                min="500"
                max="3000"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Jitter Threshold (cents)
              </label>
              <input
                type="number"
                value={config.JITTER_DELTA_CENTS}
                onChange={(e) => updateConfig({ JITTER_DELTA_CENTS: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                step="5"
                min="10"
                max="50"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Cooldown (sec)
              </label>
              <input
                type="number"
                value={config.COOLDOWN_SEC}
                onChange={(e) => updateConfig({ COOLDOWN_SEC: Number(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                step="5"
                min="15"
                max="120"
              />
            </div>
          </div>
        </div>

        {/* Live Metrics */}
        {isMonitoring && (
          <div className="bg-white rounded-xl shadow-sm p-6 mb-8 border border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">📊 Live Strain Metrics</h2>
            
            {metrics ? (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="text-center p-4 bg-blue-50 rounded-lg">
                  <div className="text-2xl font-bold text-blue-600 mb-1">
                    {metrics.loudnessDB.toFixed(1)} dBFS
                  </div>
                  <div className="text-sm text-gray-600">Loudness</div>
                  <div className={`text-xs mt-1 ${
                    metrics.loudnessDB > config.LOUD_DB_THRESH ? 'text-red-600' : 'text-green-600'
                  }`}>
                    {metrics.loudnessDB > config.LOUD_DB_THRESH ? 'Above threshold' : 'Normal'}
                  </div>
                </div>
                
                <div className="text-center p-4 bg-green-50 rounded-lg">
                  <div className="text-2xl font-bold text-green-600 mb-1">
                    {metrics.jitterEma.toFixed(1)} cents
                  </div>
                  <div className="text-sm text-gray-600">Jitter EMA</div>
                  <div className={`text-xs mt-1 ${
                    metrics.jitterTrend > 0 ? 'text-orange-600' : 'text-green-600'
                  }`}>
                    {metrics.jitterTrend > 0 ? 'Rising trend' : 'Stable'}
                  </div>
                </div>
                
                <div className="text-center p-4 bg-purple-50 rounded-lg">
                  <div className="text-2xl font-bold text-purple-600 mb-1">
                    {metrics.voicedMs.toFixed(0)} ms
                  </div>
                  <div className="text-sm text-gray-600">Voiced Duration</div>
                  <div className={`text-xs mt-1 ${
                    metrics.voicedMs >= config.MIN_VOICED_MS ? 'text-green-600' : 'text-yellow-600'
                  }`}>
                    {metrics.voicedMs >= config.MIN_VOICED_MS ? 'Sufficient' : 'Building...'}
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center text-gray-500 py-8">
                Waiting for audio data...
              </div>
            )}

            {/* Strain Status */}
            {metrics && (
              <div className="mt-6">
                <div className={`p-4 rounded-lg ${
                  metrics.strainFlag ? 'bg-red-50 border border-red-200' : 'bg-green-50 border border-green-200'
                }`}>
                  <div className="flex items-center">
                    <span className="text-2xl mr-3">
                      {metrics.strainFlag ? '⚠️' : '✅'}
                    </span>
                    <div>
                      <div className={`font-semibold ${
                        metrics.strainFlag ? 'text-red-800' : 'text-green-800'
                      }`}>
                        {metrics.strainFlag ? 'Strain Detected' : 'No Strain Detected'}
                      </div>
                      {metrics.strainReasons.length > 0 && (
                        <div className="text-sm text-red-700 mt-1">
                          {metrics.strainReasons.join(', ')}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Test Fixtures */}
        <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">🧪 Test Fixtures</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Object.entries(fixtures).map(([name, fixture]) => (
              <div key={name} className="border border-gray-200 rounded-lg p-4">
                <h3 className="font-medium text-gray-900 mb-2 capitalize">
                  {name.replace('-', ' ')}
                </h3>
                <p className="text-sm text-gray-600 mb-3">
                  {fixture.description}
                </p>
                <div className="text-xs text-gray-500 mb-3">
                  Expected: {fixture.expectedStrain ? 'Strain' : 'No Strain'}
                </div>
                <button
                  onClick={() => testFixture(name)}
                  className="w-full px-3 py-2 bg-orange-600 text-white rounded hover:bg-orange-700 font-medium transition-colors text-sm"
                >
                  Test {name}
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Help Section */}
        <div className="mt-8 bg-gradient-to-r from-orange-50 to-red-50 border border-orange-200 rounded-lg p-6">
          <h3 className="font-semibold text-orange-900 mb-3">💡 Strain Detection Guide</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-orange-800">
            <div>
              <strong>🔊 Loudness:</strong> Detects sustained loud speech above threshold.
            </div>
            <div>
              <strong>📈 Jitter Trend:</strong> Monitors pitch instability over time.
            </div>
            <div>
              <strong>⏱️ Duration:</strong> Requires minimum voiced time for accuracy.
            </div>
            <div>
              <strong>🛡️ Cooldown:</strong> SOVT exercises help prevent vocal strain.
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
