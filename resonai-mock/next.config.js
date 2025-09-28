/** @type {import('next').NextConfig} */

// CSP nonce scaffold - set at runtime via middleware if needed
const nonce = undefined; // set at runtime via middleware if needed

const nextConfig = {
  // Note: crossOriginIsolated is handled via headers, not experimental config
  async headers() {
    return [
      {
        // Apply to all routes
        source: '/(.*)',
        headers: [
          // Chromium requires strict COOP/COEP headers for SharedArrayBuffer
          {
            key: 'Cross-Origin-Embedder-Policy',
            value: 'require-corp',
          },
          {
            key: 'Cross-Origin-Opener-Policy',
            value: 'same-origin',
          },
          {
            key: 'Cross-Origin-Resource-Policy',
            value: 'cross-origin',
          },
          // Additional headers for Chromium compatibility
          {
            key: 'Permissions-Policy',
            value: 'cross-origin-isolated=()',
          },
          // Ensure proper MIME types
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          // Extra hardening (optional)
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'X-Frame-Options', value: 'SAMEORIGIN' },
          { key: 'Permissions-Policy', value: 'microphone=(self), camera=(), geolocation=(), payment=()' },
          // Strict CSP for prod; relaxed in dev via Next's overlay
          {
            key: 'Content-Security-Policy',
            value: process.env.NODE_ENV === 'production' 
              ? [
                  "default-src 'self'",
                  `script-src 'self'${nonce ? ` 'nonce-${nonce}'` : ''}`, // add nonce at runtime
                  "style-src 'self'",                               // no inline styles
                  "img-src 'self' data: https: blob:",              // allow images from HTTPS
                  "font-src 'self'",
                  "connect-src 'self' blob:",                       // worklet/ONNX fetch if local
                  "worker-src 'self' blob:",                        // Audio/Worklet compatibility
                  "child-src 'self' blob:",                         // AudioWorklet support
                  "frame-ancestors 'none'",
                  "object-src 'none'",
                  "base-uri 'self'",
                  "form-action 'self'",
                  "upgrade-insecure-requests"
                ].join('; ')
              : [
                  "default-src 'self'",
                  "script-src 'self' 'unsafe-eval' 'unsafe-inline' blob:",
                  "style-src 'self' 'unsafe-inline'",
                  "img-src 'self' data: https: blob:",
                  "connect-src 'self' http://localhost:* https:",
                  "worker-src 'self' blob:",
                  "child-src 'self' blob:",
                  "frame-src 'self'",
                  "object-src 'none'",
                  "base-uri 'self'",
                  "form-action 'self'",
                  "frame-ancestors 'self'",
                  "upgrade-insecure-requests"
                ].join('; '),
          },
        ],
      },
    ];
  },
  // Webpack configuration for better Chromium support
  webpack: (config, { dev, isServer }) => {
    if (!isServer) {
      // Enable SharedArrayBuffer support in webpack
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
      
      // Add support for SharedArrayBuffer in the browser bundle
      config.experiments = {
        ...config.experiments,
        syncWebAssembly: true,
        asyncWebAssembly: true,
      };
    }
    
    return config;
  },
  // Development server configuration
  ...(process.env.NODE_ENV === 'development' && {
    async rewrites() {
      return [
        // Proxy for local development to avoid CORS issues
        {
          source: '/api/otel/:path*',
          destination: 'http://localhost:5318/:path*',
        },
      ];
    },
  }),
};

module.exports = nextConfig;
