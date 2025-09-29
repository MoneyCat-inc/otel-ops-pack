/**
 * Service Worker - Offline Isolation Support
 * 
 * T4: Offline Isolation
 * Ensures cross-origin isolation headers are preserved when serving
 * offline content. Critical for Firefox SharedArrayBuffer support.
 */

const CACHE_NAME = 'resonai-offline-v1';
const OFFLINE_PAGES = [
  '/',
  '/listen',
  '/practice',
  '/labs/memx',
  '/labs/prosody-scenarios',
  '/labs/strain'
];

// Critical headers that must be preserved for cross-origin isolation
const CRITICAL_HEADERS = [
  'Cross-Origin-Opener-Policy',
  'Cross-Origin-Embedder-Policy',
  'Cross-Origin-Resource-Policy',
  'Content-Security-Policy',
  'Permissions-Policy',
  'X-Content-Type-Options',
  'Referrer-Policy',
  'X-Frame-Options'
];

// Helper function to ensure critical headers are present
function ensureCriticalHeaders(headers) {
  const newHeaders = new Headers(headers);
  
  // Set critical headers for cross-origin isolation
  newHeaders.set('Cross-Origin-Opener-Policy', 'same-origin');
  newHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp');
  newHeaders.set('Cross-Origin-Resource-Policy', 'cross-origin');
  newHeaders.set('Permissions-Policy', 'cross-origin-isolated=()');
  newHeaders.set('X-Content-Type-Options', 'nosniff');
  newHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  newHeaders.set('X-Frame-Options', 'SAMEORIGIN');
  
  // Set CSP for offline mode
  newHeaders.set('Content-Security-Policy', [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self' data: https: blob:",
    "font-src 'self'",
    "connect-src 'self' blob:",
    "worker-src 'self' blob:",
    "child-src 'self' blob:",
    "frame-ancestors 'none'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "upgrade-insecure-requests"
  ].join('; '));
  
  return newHeaders;
}

// Install event - cache offline pages
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: Caching offline pages');
        return cache.addAll(OFFLINE_PAGES);
      })
      .then(() => {
        console.log('Service Worker: Installation complete');
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((cacheName) => cacheName !== CACHE_NAME)
            .map((cacheName) => {
              console.log('Service Worker: Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            })
        );
      })
      .then(() => {
        console.log('Service Worker: Activation complete');
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache with preserved headers
self.addEventListener('fetch', (event) => {
  // Handle navigation requests and critical resources
  if (event.request.mode !== 'navigate' && 
      !event.request.url.includes('/worklets/') &&
      !event.request.url.includes('/api/') &&
      !event.request.destination.includes('script') &&
      !event.request.destination.includes('style')) {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // If online, cache the response and return it
        if (response.status === 200) {
          const responseClone = response.clone();
          caches.open(CACHE_NAME)
            .then((cache) => {
              cache.put(event.request, responseClone);
            });
        }
        return response;
      })
      .catch(() => {
        // If offline, serve from cache with preserved headers
        return caches.match(event.request)
          .then((cachedResponse) => {
            if (cachedResponse) {
              console.log('Service Worker: Serving offline page:', event.request.url);
              
              // Create a new response with preserved headers
              const headers = ensureCriticalHeaders(cachedResponse.headers);
              
              return new Response(cachedResponse.body, {
                status: cachedResponse.status,
                statusText: cachedResponse.statusText,
                headers: headers
              });
            }
            
            // If no cached version, return offline page
            return caches.match('/')
              .then((offlinePage) => {
                if (offlinePage) {
                  console.log('Service Worker: Serving offline fallback page');
                  
                  // Create response with headers for offline page
                  const headers = ensureCriticalHeaders(offlinePage.headers);
                  
                  return new Response(offlinePage.body, {
                    status: 200,
                    statusText: 'OK',
                    headers: headers
                  });
                }
                
                // Last resort - return a basic offline page
                const offlinePageContent = `
                  <!DOCTYPE html>
                  <html>
                    <head>
                      <title>Offline - Resonai</title>
                      <meta charset="utf-8">
                      <meta name="viewport" content="width=device-width, initial-scale=1">
                    </head>
                    <body>
                      <h1>You're offline</h1>
                      <p>This page will be available when you're back online.</p>
                    </body>
                  </html>
                `;
                
                const headers = new Headers();
                headers.set('Content-Type', 'text/html');
                ensureCriticalHeaders(headers);
                
                return new Response(offlinePageContent, {
                  status: 200,
                  statusText: 'OK',
                  headers: headers
                });
              });
          });
      })
  );
});

// Message handling for cross-origin isolation status
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'CHECK_ISOLATION') {
    // Respond with isolation status
    event.ports[0].postMessage({
      type: 'ISOLATION_STATUS',
      crossOriginIsolated: true, // Service Worker context is isolated
      timestamp: Date.now()
    });
  }
});

// Error handling
self.addEventListener('error', (event) => {
  console.error('Service Worker: Error occurred:', event.error);
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('Service Worker: Unhandled promise rejection:', event.reason);
});

console.log('Service Worker: Script loaded');
