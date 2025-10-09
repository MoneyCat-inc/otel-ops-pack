// Frontend tracing initialization
// This file is imported in the root layout to initialize tracing

'use client';

import { useEffect } from 'react';

// Initialize tracing on client-side only
export default function TracingProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Dynamic import to ensure this only runs on client-side
    import('../lib/tracing').catch((error) => {
      console.warn('Failed to initialize tracing:', error);
    });
  }, []);

  return <>{children}</>;
}
