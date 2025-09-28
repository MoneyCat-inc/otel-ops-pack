/**
 * Root Layout - MEMX Demo
 * 
 * PR-0: Basic layout with navigation and MEMX integration
 */

import type { Metadata } from 'next';
import './globals.css';
import { PerfOverlay } from '../src/components/PerfOverlay';
import { ServiceWorkerProvider } from '../src/components/ServiceWorkerProvider';

export const metadata: Metadata = {
  title: 'Resonai - Voice Practice',
  description: 'Local-first voice feminization trainer with MEMX memory observation',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased">
        <ServiceWorkerProvider>
          <nav className="bg-white shadow-sm border-b">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16">
              <div className="flex items-center">
                <h1 className="text-xl font-semibold text-gray-900">
                  Resonai
                </h1>
              </div>
              <div className="flex items-center space-x-4">
                <a
                  href="/"
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Home
                </a>
                <a
                  href="/listen"
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Listen
                </a>
                <a
                  href="/practice"
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Practice
                </a>
                <a
                  href="/labs/memx"
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  MEMX Labs
                </a>
              </div>
            </div>
          </div>
        </nav>
          <main>{children}</main>
          {process.env.NEXT_PUBLIC_PERF_OVERLAY === '1' && <PerfOverlay />}
        </ServiceWorkerProvider>
      </body>
    </html>
  );
}
