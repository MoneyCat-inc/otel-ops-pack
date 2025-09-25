import { spawnSync } from "node:child_process";
import { mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import process from "node:process";

const outputPath = join(".artifacts", "playwright-report.json");
mkdirSync(dirname(outputPath), { recursive: true });

const env = {
  ...process.env,
  PLAYWRIGHT_JSON_OUTPUT_NAME: outputPath,
};

const command = "pnpm exec playwright test -c playwright.ssot.config.ts --reporter=list,json";

const result = spawnSync(command, {
  stdio: "inherit",
  env,
  shell: true,
});

if (result.error) {
  throw result.error;
}

process.exit(result.status ?? 0);

