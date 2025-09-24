import { defineConfig, devices } from '@playwright/test';

const baseUrl = process.env['BASE_URL'] ?? 'http://localhost:3003';

export default defineConfig({
  testDir: 'tests/smoke',
  retries: 0,
  workers: 1,
  timeout: 20_000,
  reporter: [['list']],
  use: {
    baseURL: baseUrl,
    headless: true,
    trace: 'off',
    video: 'off',
    screenshot: 'off',
  },
  webServer: {
    command: 'npm run preview:dev',
    url: baseUrl,
    reuseExistingServer: !process.env['CI'],
    timeout: 60000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
  projects: [
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
});
