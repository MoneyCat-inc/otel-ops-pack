import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    include: ['tests/unit/**/*.test.{ts,tsx}'],
    exclude: [
      'tests/e2e/**',
      'node_modules/**',
      'playwright-report/**',
      'test-results/**'
    ],
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    globals: true,
    reporters: ['dot'],
    env: { NODE_ENV: 'test' },
    passWithNoTests: true
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
});
