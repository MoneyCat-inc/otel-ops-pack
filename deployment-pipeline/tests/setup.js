/**
 * Jest Test Setup
 * Configuration for Deployment Pipeline API tests
 */

// Increase timeout for integration tests
jest.setTimeout(10000);

// Global test setup
beforeAll(() => {
  console.log('🧪 Starting Deployment Pipeline API Test Suite');
  console.log('🐾 Tetragrammaton YHWH Architecture Testing');
});

// Global test teardown
afterAll(() => {
  console.log('✅ Deployment Pipeline API Test Suite Complete');
});

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
};
