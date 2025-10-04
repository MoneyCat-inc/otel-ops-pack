import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.SIGNOZ_URL || "http://localhost:8080";

export default defineConfig({
  timeout: 60_000,
  expect: {
    timeout: 15_000
  },
  retries: 1,
  reporter: [
    ["list"],
    ["html", { open: "never" }]
  ],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure"
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] }
    }
  ]
});

