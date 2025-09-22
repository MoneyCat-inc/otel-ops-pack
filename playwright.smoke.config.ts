import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: 'tests/smoke',
  retries: 0,
  workers: 1,
  timeout: 20_000,
  reporter: [['list']],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3003',
    headless: true,
    trace: 'off',
    video: 'off',
    screenshot: 'off',
  },
  projects: [
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
});
