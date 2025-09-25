import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "tests/ssot",
  retries: 0,
  workers: 1,
  reporter: [["list"], ["json"]],
  use: {
    headless: true,
    trace: "off",
    video: "off",
    screenshot: "off",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
