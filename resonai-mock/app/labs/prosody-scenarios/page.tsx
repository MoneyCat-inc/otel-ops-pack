/**
 * Prosody Scenarios Lab Page
 * 
 * T2: Prosody Carry-over Scenarios
 * Provides voicemail and meeting intro scenario practice with
 * real-time feedback and accessibility features.
 */

'use client';

import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import { ScenarioCard } from '../../../src/components/cards/ScenarioCard';
import { ProsodyEngine, ScenarioConfig, ScenarioResult } from '../../../src/engine/audio/prosody';
import Link from 'next/link';

export default function ProsodyScenariosPage() {
  const [scenarios, setScenarios] = useState<ScenarioConfig[]>([]);
  const [activeScenario, setActiveScenario] = useState<string | null>(null);
  const [results, setResults] = useState<ScenarioResult[]>([]);
  const [mockData, setMockData] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [announcement, setAnnouncement] = useState('');

  // Get mock parameter from URL
  const searchParams = useSearchParams();
  
  useEffect(() => {
    // Check for reduced motion preference
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    setReducedMotion(prefersReducedMotion);

    // Check for mock parameter
    const mockParam = searchParams.get('mock');
    if (mockParam === 'voicemail' || mockParam === 'meeting') {
      setMockData(true);
      setActiveScenario(mockParam);
    }

    // Load scenarios
    setScenarios(ProsodyEngine.getScenarios());
  }, [searchParams]);

  const handleScenarioStart = (scenarioId: string) => {
    setActiveScenario(scenarioId);
    setAnnouncement(`Started ${scenarioId} scenario`);
  };

  const handleScenarioStop = () => {
    setActiveScenario(null);
    setAnnouncement('Stopped recording');
  };

  const handleScenarioResult = (result: ScenarioResult) => {
    setResults(prev => [...prev, result]);
    setAnnouncement(`Scenario ${result.scenarioId} completed. ${result.pass ? 'Passed' : 'Try again'}`);
  };

  const clearResults = () => {
    setResults([]);
    setAnnouncement('Results cleared');
  };

  const exportResults = () => {
    const exportData = {
      timestamp: new Date().toISOString(),
      results: results,
      summary: {
        totalAttempts: results.length,
        passed: results.filter(r => r.pass).length,
        scenarios: scenarios.map(s => ({
          id: s.id,
          attempts: results.filter(r => r.scenarioId === s.id).length,
          passed: results.filter(r => r.scenarioId === s.id && r.pass).length
        }))
      }
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `prosody-scenarios-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    setAnnouncement('Results exported successfully');
  };

  const getOverallProgress = () => {
    if (results.length === 0) return { completed: 0, total: scenarios.length };
    
    const completedScenarios = new Set(results.filter(r => r.pass).map(r => r.scenarioId));
    return {
      completed: completedScenarios.size,
      total: scenarios.length
    };
  };

  const progress = getOverallProgress();

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-indigo-100">
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
                <div className="w-8 h-8 bg-gradient-to-r from-purple-600 to-indigo-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">R</span>
                </div>
                <span className="text-lg font-semibold text-gray-900">Resonai</span>
              </Link>
              <span className="text-gray-400">•</span>
              <span className="text-sm text-gray-600">Prosody Scenarios</span>
            </div>
            
            <div className="flex items-center space-x-4">
              <Link 
                href="/practice" 
                className="px-4 py-2 text-purple-600 hover:text-purple-700 font-medium transition-colors"
              >
                Practice
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
            🎭 Applied Prosody Scenarios
          </h1>
          <p className="text-lg text-gray-600 max-w-3xl">
            Practice real-world scenarios with voicemail and meeting introductions. 
            Get feedback on end-rise/fall patterns and expressiveness.
          </p>
        </div>

        {/* Controls */}
        <div className="bg-white rounded-xl shadow-sm p-6 mb-8 border border-gray-200">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <label htmlFor="mock-toggle" className="text-sm font-medium text-gray-700">
                  Mock Mode
                </label>
                <button
                  id="mock-toggle"
                  onClick={() => setMockData(!mockData)}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    mockData ? 'bg-purple-600' : 'bg-gray-200'
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
              <div className="text-sm text-gray-600">
                Progress: {progress.completed}/{progress.total} scenarios
              </div>
              
              {results.length > 0 && (
                <div className="flex space-x-2">
                  <button
                    onClick={clearResults}
                    className="px-3 py-1 text-sm bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition-colors"
                  >
                    Clear Results
                  </button>
                  <button
                    onClick={exportResults}
                    className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
                  >
                    Export Results
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Progress Bar */}
          <div className="mt-4">
            <div className="flex items-center space-x-2">
              <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                <div 
                  className={`h-full transition-all duration-500 ${
                    reducedMotion ? '' : 'transition-all duration-500'
                  } bg-gradient-to-r from-purple-500 to-indigo-500`}
                  style={{ width: `${(progress.completed / progress.total) * 100}%` }}
                />
              </div>
              <span className="text-sm text-gray-500 min-w-fit">
                {Math.round((progress.completed / progress.total) * 100)}%
              </span>
            </div>
          </div>
        </div>

        {/* Scenarios Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {scenarios.map((scenario) => (
            <ScenarioCard
              key={scenario.id}
              scenario={scenario}
              isActive={activeScenario === null || activeScenario === scenario.id}
              onResult={handleScenarioResult}
              onStart={handleScenarioStart}
              onStop={handleScenarioStop}
              mockData={mockData}
            />
          ))}
        </div>

        {/* Results Summary */}
        {results.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">📊 Session Results</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
              <div className="text-center p-4 bg-blue-50 rounded-lg">
                <div className="text-2xl font-bold text-blue-600 mb-1">
                  {results.length}
                </div>
                <div className="text-sm text-gray-600">Total Attempts</div>
              </div>
              
              <div className="text-center p-4 bg-green-50 rounded-lg">
                <div className="text-2xl font-bold text-green-600 mb-1">
                  {results.filter(r => r.pass).length}
                </div>
                <div className="text-sm text-gray-600">Passed</div>
              </div>
              
              <div className="text-center p-4 bg-purple-50 rounded-lg">
                <div className="text-2xl font-bold text-purple-600 mb-1">
                  {Math.round((results.filter(r => r.pass).length / results.length) * 100)}%
                </div>
                <div className="text-sm text-gray-600">Success Rate</div>
              </div>
            </div>

            {/* Recent Results */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-3">Recent Attempts</h3>
              <div className="space-y-2">
                {results.slice(-5).reverse().map((result, index) => (
                  <div
                    key={index}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div className="flex items-center space-x-3">
                      <span className={`text-lg ${result.pass ? 'text-green-600' : 'text-orange-600'}`}>
                        {result.pass ? '✅' : '🔄'}
                      </span>
                      <div>
                        <div className="font-medium text-gray-900 capitalize">
                          {result.scenarioId} Scenario
                        </div>
                        <div className="text-sm text-gray-600">
                          Rise/Fall: {result.riseFallLabel} • Expressiveness: {Math.round(result.expressiveness01 * 100)}%
                        </div>
                      </div>
                    </div>
                    <div className="text-sm text-gray-500">
                      {new Date().toLocaleTimeString()}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Help Section */}
        <div className="mt-8 bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-200 rounded-lg p-6">
          <h3 className="font-semibold text-purple-900 mb-3">💡 How to Use Prosody Scenarios</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-purple-800">
            <div>
              <strong>🎤 Voicemail Intro:</strong> Practice ending with a gentle fall for clear, confident statements.
            </div>
            <div>
              <strong>🤝 Meeting Intro:</strong> Practice ending with a slight rise to sound engaging and welcoming.
            </div>
            <div>
              <strong>📊 Expressiveness:</strong> Add pitch variety naturally - avoid exaggerated swoops.
            </div>
            <div>
              <strong>🔄 Mock Mode:</strong> Test the interface without microphone access.
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
