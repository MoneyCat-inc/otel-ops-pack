'use client';

import React, { useState, useEffect } from 'react';

interface DebugInfo {
  crossOriginIsolated: boolean;
  sharedArrayBufferSupported: boolean;
  userAgent: string;
  browserInfo: {
    isChrome: boolean;
    isFirefox: boolean;
    isSafari: boolean;
  };
  errors: string[];
}

export function MemxDebugInfo() {
  const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null);
  const [showDebug, setShowDebug] = useState(false);

  useEffect(() => {
    const checkBrowserSupport = () => {
      const userAgent = navigator.userAgent;
      const errors: string[] = [];
      
      // Check cross-origin isolation
      const crossOriginIsolated = window.crossOriginIsolated;
      if (!crossOriginIsolated) {
        errors.push('Cross-origin isolation is not enabled');
      }
      
      // Check SharedArrayBuffer support
      let sharedArrayBufferSupported = false;
      try {
        if (typeof SharedArrayBuffer !== 'undefined') {
          new SharedArrayBuffer(1024);
          sharedArrayBufferSupported = true;
        } else {
          errors.push('SharedArrayBuffer is not available');
        }
      } catch (error) {
        errors.push(`SharedArrayBuffer error: ${error instanceof Error ? error.message : String(error)}`);
      }
      
      // Detect browser
      const isChrome = userAgent.includes('Chrome') && !userAgent.includes('Edg');
      const isFirefox = userAgent.includes('Firefox');
      const isSafari = userAgent.includes('Safari') && !userAgent.includes('Chrome');
      
      const info: DebugInfo = {
        crossOriginIsolated,
        sharedArrayBufferSupported,
        userAgent,
        browserInfo: {
          isChrome,
          isFirefox,
          isSafari,
        },
        errors,
      };
      
      setDebugInfo(info);
    };
    
    checkBrowserSupport();
  }, []);

  if (!debugInfo) {
    return <div>Loading debug info...</div>;
  }

  const hasErrors = debugInfo.errors.length > 0;
  const isChromeWithIssues = debugInfo.browserInfo.isChrome && hasErrors;

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold">Browser Compatibility</h2>
        <button
          onClick={() => setShowDebug(!showDebug)}
          className="text-sm text-blue-600 hover:text-blue-800"
        >
          {showDebug ? 'Hide' : 'Show'} Debug Info
        </button>
      </div>
      
      {/* Status indicators */}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${
            debugInfo.crossOriginIsolated ? 'bg-green-400' : 'bg-red-400'
          }`}></div>
          <span className="text-sm">
            Cross-Origin Isolation: {debugInfo.crossOriginIsolated ? 'Enabled' : 'Disabled'}
          </span>
        </div>
        
        <div className="flex items-center space-x-2">
          <div className={`w-3 h-3 rounded-full ${
            debugInfo.sharedArrayBufferSupported ? 'bg-green-400' : 'bg-red-400'
          }`}></div>
          <span className="text-sm">
            SharedArrayBuffer: {debugInfo.sharedArrayBufferSupported ? 'Supported' : 'Not Supported'}
          </span>
        </div>
      </div>
      
      {/* Browser-specific warnings */}
      {isChromeWithIssues && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
          <div className="flex items-start">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-yellow-800">
                Chrome Compatibility Issues Detected
              </h3>
              <div className="mt-2 text-sm text-yellow-700">
                <p>Chrome requires additional headers for cross-origin isolation:</p>
                <ul className="list-disc list-inside mt-1 space-y-1">
                  {debugInfo.errors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Detailed debug info */}
      {showDebug && (
        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="text-sm font-medium text-gray-900 mb-2">Debug Information</h3>
          <div className="space-y-2 text-xs text-gray-600">
            <div>
              <strong>Browser:</strong> {debugInfo.browserInfo.isChrome ? 'Chrome' : 
                                        debugInfo.browserInfo.isFirefox ? 'Firefox' : 
                                        debugInfo.browserInfo.isSafari ? 'Safari' : 'Unknown'}
            </div>
            <div>
              <strong>User Agent:</strong> {debugInfo.userAgent}
            </div>
            <div>
              <strong>Cross-Origin Isolated:</strong> {debugInfo.crossOriginIsolated.toString()}
            </div>
            <div>
              <strong>SharedArrayBuffer Supported:</strong> {debugInfo.sharedArrayBufferSupported.toString()}
            </div>
            {debugInfo.errors.length > 0 && (
              <div>
                <strong>Errors:</strong>
                <ul className="list-disc list-inside ml-2 mt-1">
                  {debugInfo.errors.map((error, index) => (
                    <li key={index}>{error}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
