/**
 * IONA Diagnostics Shell
 * 
 * Purpose: Real-time telemetry diagnostics and control panel
 * Features:
 *  - Live metrics visualization
 *  - Trace inspection
 *  - Log streaming
 *  - Instrumentation controls
 *  - Synthetic span emission
 * 
 * Part of: IONA-GATE-002 - Diagnostics Telemetry Shell
 * Service: iona-app
 * Gate: BossCat
 */

import TelemetryShell from '@/components/TelemetryShell';

export const metadata = {
  title: 'IONA Diagnostics | Telemetry Shell',
  description: 'Real-time observability diagnostics and control panel for IONA',
};

export default function DiagnosticsPage() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-8">
        <header className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-2">
            IONA Diagnostics
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Real-time telemetry monitoring and control panel
          </p>
        </header>
        
        <TelemetryShell />
      </div>
    </main>
  );
}

