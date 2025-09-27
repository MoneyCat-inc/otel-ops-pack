/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Enable SharedArrayBuffer support for cross-origin isolation
    crossOriginIsolated: true,
  },
  headers: async () => {
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
          // Security headers
          {
            key: 'X-Frame-Options',
            value: 'SAMEORIGIN',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ];
  },
  // Enhanced CSP for Chromium
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            // More permissive CSP for development, but still secure
            value: [
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
