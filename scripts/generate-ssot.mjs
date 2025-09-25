import { promises as fs } from "node:fs";
import { dirname, join } from "node:path";

const ARTIFACT_DIR = ".artifacts";
const OUTPUT_FILE = join(ARTIFACT_DIR, "SSOT.md");
const VITEST_PATHS = [join(ARTIFACT_DIR, "vitest-report.json"), "vitest-report.json"];
const PLAYWRIGHT_PATHS = [join(ARTIFACT_DIR, "playwright-report.json"), "playwright-report.json"];

async function ensureDir(path) {
  await fs.mkdir(dirname(path), { recursive: true });
}

async function readFirstExisting(paths, label) {
  for (const file of paths) {
    try {
      const raw = await fs.readFile(file, "utf8");
      return { file, data: JSON.parse(raw) };
    } catch (error) {
      if ((error)?.code !== "ENOENT") {
        throw new Error(`Failed to read ${label} report from ${file}: ${error}`);
      }
    }
  }
  throw new Error(`Missing ${label} report. Looked in: ${paths.join(", ")}`);
}

function summarizeVitest(report) {
  const total = report.numTotalTests ?? 0;
  const passed = report.numPassedTests ?? 0;
  const failed = report.numFailedTests ?? (total - passed - (report.numPendingTests ?? 0));
  const skipped = (report.numPendingTests ?? 0) + (report.numTodoTests ?? 0);
  const durationMs = (report.testResults ?? []).reduce((sum, test) => {
    if (typeof test.startTime === "number" && typeof test.endTime === "number") {
      return sum + Math.max(0, test.endTime - test.startTime);
    }
    return sum;
  }, 0);
  return { name: "Vitest", total, passed, failed, skipped, durationMs };
}

function summarizePlaywright(report) {
  const summary = { name: "Playwright", total: 0, passed: 0, failed: 0, skipped: 0, durationMs: 0 };
  const stack = [...(report.suites ?? [])];
  while (stack.length) {
    const suite = stack.pop();
    if (!suite) continue;
    if (Array.isArray(suite.suites)) {
      stack.push(...suite.suites);
    }
    if (!Array.isArray(suite.specs)) {
      continue;
    }
    for (const spec of suite.specs) {
      for (const test of spec.tests ?? []) {
        summary.total += 1;
        const status = test.status ?? test.results?.[0]?.status ?? "unknown";
        if (status === "expected" || status === "passed") {
          summary.passed += 1;
        } else if (status === "skipped") {
          summary.skipped += 1;
        } else {
          summary.failed += 1;
        }
        for (const result of test.results ?? []) {
          if (typeof result.duration === "number") {
            summary.durationMs += result.duration;
          }
        }
      }
    }
  }

  if (summary.total === 0 && report.stats) {
    const stats = report.stats;
    summary.total = (stats.expected ?? 0) + (stats.unexpected ?? 0);
    summary.failed = stats.unexpected ?? summary.failed;
    summary.skipped = stats.skipped ?? summary.skipped;
    summary.passed = Math.max(0, summary.total - summary.failed - summary.skipped);
    if (typeof stats.duration === "number") {
      summary.durationMs = stats.duration;
    }
  }

  return summary;
}

function formatPercent(part, total) {
  if (!total) return "0%";
  const value = (part / total) * 100;
  return `${value.toFixed(1)}%`;
}

function formatDuration(ms) {
  if (!ms) return "0.0s";
  if (ms < 1000) {
    return `${ms.toFixed(0)}ms`;
  }
  return `${(ms / 1000).toFixed(1)}s`;
}

function buildSummaryTable(entries) {
  const header = "| Suite | Result | Pass | Fail | Skip | Duration |\n|-------|--------|------|------|------|----------|";
  const rows = entries.map(entry => {
    const icon = entry.failed > 0 ? "FAIL" : "PASS";
    const result = `${icon} ${entry.passed}/${entry.total}`;
    return `| ${entry.name} | ${result} | ${entry.passed} | ${entry.failed} | ${entry.skipped} | ${formatDuration(entry.durationMs)} |`;
  });
  return [header, ...rows].join("\n");
}

function buildDetails(entries) {
  return entries.map(entry => {
    const passRate = formatPercent(entry.passed, entry.total);
    const failRate = formatPercent(entry.failed, entry.total);
    return `### ${entry.name}\n- Pass rate: ${passRate}\n- Fail rate: ${failRate}\n- Tests: ${entry.total}\n- Duration: ${formatDuration(entry.durationMs)}`;
  }).join("\n\n");
}

async function main() {
  const vitestReport = await readFirstExisting(VITEST_PATHS, "Vitest");
  const playwrightReport = await readFirstExisting(PLAYWRIGHT_PATHS, "Playwright");

  const summaries = [
    summarizeVitest(vitestReport.data),
    summarizePlaywright(playwrightReport.data),
  ];

  const allGreen = summaries.every(entry => entry.failed === 0 && entry.total > 0);

  const table = buildSummaryTable(summaries);
  const details = buildDetails(summaries);

  const output = `# SSOT Summary\n\n${table}\n\n${allGreen ? "PASS" : "FAIL"} Overall status: ${allGreen ? "All suites passing" : "Failures detected"}.\n\n## Details\n\n${details}\n`;

  await ensureDir(OUTPUT_FILE);
  await fs.writeFile(OUTPUT_FILE, output, "utf8");

  console.log(`SSOT summary written to ${OUTPUT_FILE}`);
  console.log(output.split("\n").slice(0, 6).join("\n"));

  if (!allGreen) {
    process.exitCode = 1;
  }
}

main().catch(error => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});

