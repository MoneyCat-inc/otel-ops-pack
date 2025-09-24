import { defineConfig } from 'vite';

const securityHeaders = {
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',
  'Cross-Origin-Resource-Policy': 'same-origin',
  'Origin-Agent-Cluster': '?1',
  'Content-Security-Policy': [
    "default-src 'self'",
    "base-uri 'self'",
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data:",
    "connect-src 'self'",
    "font-src 'self'",
    "worker-src 'self'",
    "frame-ancestors 'none'",
    "form-action 'self'"
  ].join('; '),
};

export default defineConfig({
  server: {
    port: 3003,
    strictPort: true,
    host: '0.0.0.0',
    headers: securityHeaders,
  },
  preview: {
    port: 3003,
    strictPort: true,
    host: '0.0.0.0',
    headers: securityHeaders,
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
  },
});
