/**
 * Home Page - MEMX Demo
 * 
 * PR-0: Basic landing page with MEMX status
 */

import Link from 'next/link';

export default function HomePage() {
  const isMemxEnabled = process.env.NEXT_PUBLIC_FEATURE_MEMX === '1';

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Resonai Voice Practice
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Local-first voice feminization trainer with real-time memory observation
          </p>
          
          <div className="bg-white rounded-lg shadow p-8 mb-8">
            <h2 className="text-2xl font-semibold mb-4">MEMX Status</h2>
            <div className="flex items-center justify-center space-x-4">
              <div className={`w-4 h-4 rounded-full ${isMemxEnabled ? 'bg-green-400' : 'bg-gray-400'}`}></div>
              <span className="text-lg">
                Memory Observation Layer: {isMemxEnabled ? 'Enabled' : 'Disabled'}
              </span>
            </div>
            {!isMemxEnabled && (
              <p className="text-sm text-gray-500 mt-2">
                Set NEXT_PUBLIC_FEATURE_MEMX=1 to enable
              </p>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-3">Voice Practice</h3>
              <p className="text-gray-600 mb-4">
                Real-time audio analysis with CREPE-tiny ONNX and YIN fallback
              </p>
              <button className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                Start Practice
              </button>
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold mb-3">Memory Diagnostics</h3>
              <p className="text-gray-600 mb-4">
                Monitor WASM heap, SAB usage, and AudioWorklet performance
              </p>
              <Link
                href="/labs/memx"
                className="block w-full bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors text-center"
              >
                Open MEMX Labs
              </Link>
            </div>
          </div>

          <div className="mt-12 bg-blue-50 rounded-lg p-6">
            <h3 className="text-lg font-semibold mb-3">Features</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <h4 className="font-medium mb-1">Privacy-First</h4>
                <p className="text-gray-600">All processing happens locally</p>
              </div>
              <div>
                <h4 className="font-medium mb-1">Real-Time Feedback</h4>
                <p className="text-gray-600">Low-latency audio analysis</p>
              </div>
              <div>
                <h4 className="font-medium mb-1">Memory Monitoring</h4>
                <p className="text-gray-600">Optional SigNoz integration</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
