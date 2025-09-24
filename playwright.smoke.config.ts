import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env['BASE_URL'] ?? 'http://localhost:3003';

const firefoxPreferences = {
  'media.navigator.streams.fake': true,
  'media.navigator.permission.disabled': true,
  'media.navigator.audio.full_duplex': true,
  'media.autoplay.default': 0,
};

export default defineConfig({
  testDir: 'tests',
  testMatch: ['smoke/**/*.spec.ts', 'isolation/**/*.spec.ts', 'mic-flow/**/*.spec.ts', 'a11y-min/**/*.spec.ts'],
  retries: 0,
  workers: 1,
  timeout: 20_000,
  reporter: [['list']],
  use: {
    baseURL,
    headless: true,
    trace: 'off',
    video: 'off',
    screenshot: 'off',
  },
  projects: [
    {
      name: 'firefox-deterministic',
      use: {
        ...devices['Desktop Firefox'],
        launchOptions: {
          firefoxUserPrefs: {
            ...firefoxPreferences,
          },
        },
      },
    },
  ],
});
