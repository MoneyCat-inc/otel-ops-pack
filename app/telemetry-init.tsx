'use client';

/**
 * IONA Telemetry Initialization Component
 * 
 * Initializes OpenTelemetry on app startup and emits boot span
 * This component should be included in the root layout
 * 
 * Part of: IONA Gate Integration
 * Service: iona-app
 */

import { useEffect } from 'react';
import { initializeTelemetry, emitBootSpan } from '@/lib/telemetry/iona-telemetry';

export function TelemetryInit() {
  useEffect(() => {
    // Initialize telemetry on mount
    initializeTelemetry();

    // Emit boot span when DOM is ready
    if (document.readyState === 'complete') {
      emitBootSpan();
    } else {
      window.addEventListener('load', emitBootSpan);
      return () => window.removeEventListener('load', emitBootSpan);
    }
  }, []);

  // This component renders nothing
  return null;
}

