// Resonai Backend - Next.js Configuration
// Optimized for production deployment with privacy and security

/** @type {import('next').NextConfig} */
const nextConfig = {
  // =============================================================================
  // CORE CONFIGURATION
  // =============================================================================
  
  // Enable experimental features
  experimental: {
    serverComponentsExternalPackages: ['@prisma/client'],
  },

  // Output configuration
  output: 'standalone',
  
  // Image optimization
  images: {
    domains: [],
    formats: ['image/webp', 'image/avif'],
  },

  // =============================================================================
  // SECURITY HEADERS
  // =============================================================================
  
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          // Security headers
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
          },
          // Privacy headers
          {
            key: 'X-Privacy-Policy',
            value: 'local-first, consent-first, no-audio-upload',
          },
        ],
      },
      {
        source: '/api/(.*)',
        headers: [
          // API-specific headers
          {
            key: 'X-API-Version',
            value: '1.0.0',
          },
          {
            key: 'X-Privacy-Compliance',
            value: 'GDPR, CCPA',
          },
        ],
      },
    ];
  },

  // =============================================================================
  // CORS CONFIGURATION
  // =============================================================================
  
  async rewrites() {
    return [
      {
        source: '/health',
        destination: '/api/health',
      },
    ];
  },

  // =============================================================================
  // ENVIRONMENT VARIABLES
  // =============================================================================
  
  env: {
    // Make environment variables available to the client
    NEXT_PUBLIC_APP_VERSION: process.env.OTEL_SERVICE_VERSION || '1.0.0',
    NEXT_PUBLIC_ENVIRONMENT: process.env.OTEL_ENVIRONMENT || 'development',
  },

  // =============================================================================
  // BUILD OPTIMIZATION
  // =============================================================================
  
  // Compiler options
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },

  // Webpack configuration
  webpack: (config, { isServer }) => {
    // Optimize for production
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }

    // Add custom webpack plugins
    config.module.rules.push({
      test: /\.svg$/,
      use: ['@svgr/webpack'],
    });

    return config;
  },

  // =============================================================================
  // PRIVACY & COMPLIANCE
  // =============================================================================
  
  // Note: telemetry is disabled by default in Next.js 14+

  // =============================================================================
  // DEVELOPMENT CONFIGURATION
  // =============================================================================
  
  // Development server configuration
  devIndicators: {
    buildActivity: true,
    buildActivityPosition: 'bottom-right',
  },

  // =============================================================================
  // PRODUCTION OPTIMIZATIONS
  // =============================================================================
  
  // Enable compression
  compress: true,

  // Optimize bundle
  swcMinify: true,

  // =============================================================================
  // RUNTIME CONFIGURATION
  // =============================================================================
  
  // Server runtime configuration
  serverRuntimeConfig: {
    // Server-only configuration
    databaseUrl: process.env.DATABASE_URL,
    nextAuthSecret: process.env.NEXTAUTH_SECRET,
    userHashSalt: process.env.USER_HASH_SALT,
  },

  // Public runtime configuration
  publicRuntimeConfig: {
    // Client-accessible configuration
    appName: 'Resonai Backend',
    version: process.env.OTEL_SERVICE_VERSION || '1.0.0',
    environment: process.env.OTEL_ENVIRONMENT || 'development',
  },
};

module.exports = nextConfig;
