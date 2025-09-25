import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env['BASE_URL'] ?? 'http://127.0.0.1:3000';

const firefoxPreferences = {
  'media.navigator.streams.fake': true,
  'media.navigator.permission.disabled': true,
  'media.navigator.audio.full_duplex': true,
  'media.autoplay.default': 0,
  'dom.webnotifications.enabled': false,
  'media.peerconnection.enabled': false,
  'browser.cache.disk.enable': false,
  'browser.cache.memory.enable': false,
  'network.http.use-cache': false,
};

const chromePreferences = {
  'autoplay-policy': 'no-user-gesture-required',
  'disable-web-security': false,
  'disable-features': 'VizDisplayCompositor',
  'disable-background-timer-throttling': true,
  'disable-backgrounding-occluded-windows': true,
  'disable-renderer-backgrounding': true,
  'disable-ipc-flooding-protection': true,
};

const safariPreferences = {
  'webkit.webprefs.media_capture_enabled': false,
  'webkit.webprefs.media_stream_enabled': false,
};

export default defineConfig({
  testDir: 'tests/smoke',
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
  webServer: {
    command: 'npm run preview:dev',
    url: baseURL,
    reuseExistingServer: !process.env['CI'],
    timeout: 60_000,
    stdout: 'pipe',
    stderr: 'pipe',
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
    {
      name: 'chrome-deterministic',
      use: {
        ...devices['Desktop Chrome'],
        launchOptions: {
          args: Object.entries(chromePreferences).map(([key, value]) => `--${key}=${value}`),
        },
      },
    },
    {
      name: 'webkit-deterministic',
      use: {
        ...devices['Desktop Safari'],
        launchOptions: {
          webkitArgs: Object.entries(safariPreferences).map(([key, value]) => `--${key}=${value}`),
        },
      },
    },
    {
      name: 'mobile-chrome',
      use: {
        ...devices['Pixel 5'],
        launchOptions: {
          args: Object.entries(chromePreferences).map(([key, value]) => `--${key}=${value}`),
        },
      },
    },
    {
      name: 'mobile-safari',
      use: {
        ...devices['iPhone 12'],
        launchOptions: {
          webkitArgs: Object.entries(safariPreferences).map(([key, value]) => `--${key}=${value}`),
        },
      },
    },
  ],
});

