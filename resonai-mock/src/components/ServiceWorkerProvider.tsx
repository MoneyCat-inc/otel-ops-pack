/**
 * Service Worker Registration Component
 * 
 * T4: Offline Isolation
 * Registers Service Worker and ensures cross-origin isolation
 * is maintained in offline mode.
 */

'use client';

import { useEffect, useState } from 'react';

interface ServiceWorkerStatus {
  isSupported: boolean;
  isRegistered: boolean;
  isActive: boolean;
  crossOriginIsolated: boolean;
  sharedArrayBufferAvailable: boolean;
}

export function ServiceWorkerProvider({ children }: { children: React.ReactNode }) {
  const [swStatus, setSwStatus] = useState<ServiceWorkerStatus>({
    isSupported: false,
    isRegistered: false,
    isActive: false,
    crossOriginIsolated: false,
    sharedArrayBufferAvailable: false,
  });

  useEffect(() => {
    // Check if Service Worker is supported
    if (!('serviceWorker' in navigator)) {
      console.warn('Service Worker not supported');
      return;
    }

    // Check cross-origin isolation status
    const checkIsolationStatus = () => {
      const crossOriginIsolated = window.crossOriginIsolated;
      const sharedArrayBufferAvailable = typeof SharedArrayBuffer !== 'undefined';
      
      setSwStatus(prev => ({
        ...prev,
        crossOriginIsolated,
        sharedArrayBufferAvailable,
      }));
    };

    // Register Service Worker
    const registerServiceWorker = async () => {
      try {
        const registration = await navigator.serviceWorker.register('/sw.js', {
          scope: '/',
        });

        console.log('Service Worker registered:', registration);

        // Check if Service Worker is already active
        if (registration.active) {
          setSwStatus(prev => ({
            ...prev,
            isSupported: true,
            isRegistered: true,
            isActive: true,
          }));
          checkIsolationStatus();
        }

        // Listen for Service Worker updates
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'activated') {
                console.log('Service Worker activated');
                setSwStatus(prev => ({
                  ...prev,
                  isActive: true,
                }));
                checkIsolationStatus();
              }
            });
          }
        });

        // Listen for Service Worker messages
        navigator.serviceWorker.addEventListener('message', (event) => {
          if (event.data && event.data.type === 'ISOLATION_STATUS') {
            console.log('Service Worker isolation status:', event.data);
            checkIsolationStatus();
          }
        });

        setSwStatus(prev => ({
          ...prev,
          isSupported: true,
          isRegistered: true,
        }));

      } catch (error) {
        console.error('Service Worker registration failed:', error);
        setSwStatus(prev => ({
          ...prev,
          isSupported: true,
          isRegistered: false,
        }));
      }
    };

    // Initial status check
    checkIsolationStatus();
    
    // Register Service Worker
    registerServiceWorker();

    // Periodic isolation status check
    const interval = setInterval(checkIsolationStatus, 5000);

    return () => {
      clearInterval(interval);
    };
  }, []);

  // Debug information (only in development)
  if (process.env.NODE_ENV === 'development') {
    console.log('Service Worker Status:', swStatus);
  }

  return (
    <>
      {children}
      
      {/* Service Worker Status Indicator (development only) */}
      {process.env.NODE_ENV === 'development' && (
        <div className="fixed bottom-4 right-4 bg-black bg-opacity-75 text-white text-xs p-2 rounded z-50">
          <div>SW: {swStatus.isActive ? '✅' : '❌'}</div>
          <div>COI: {swStatus.crossOriginIsolated ? '✅' : '❌'}</div>
          <div>SAB: {swStatus.sharedArrayBufferAvailable ? '✅' : '❌'}</div>
        </div>
      )}
    </>
  );
}

/**
 * Hook to get Service Worker status
 */
export function useServiceWorker() {
  const [status, setStatus] = useState<ServiceWorkerStatus>({
    isSupported: false,
    isRegistered: false,
    isActive: false,
    crossOriginIsolated: false,
    sharedArrayBufferAvailable: false,
  });

  useEffect(() => {
    const updateStatus = () => {
      setStatus({
        isSupported: 'serviceWorker' in navigator,
        isRegistered: navigator.serviceWorker.controller !== null,
        isActive: navigator.serviceWorker.controller !== null,
        crossOriginIsolated: window.crossOriginIsolated,
        sharedArrayBufferAvailable: typeof SharedArrayBuffer !== 'undefined',
      });
    };

    updateStatus();

    // Listen for Service Worker events
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.addEventListener('controllerchange', updateStatus);
      navigator.serviceWorker.addEventListener('message', updateStatus);
    }

    return () => {
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.removeEventListener('controllerchange', updateStatus);
        navigator.serviceWorker.removeEventListener('message', updateStatus);
      }
    };
  }, []);

  return status;
}
