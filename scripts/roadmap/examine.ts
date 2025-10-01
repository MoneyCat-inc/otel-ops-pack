#!/usr/bin/env tsx

/**
 * ECRR Roadmap Automation - EXAMINE Phase
 * 
 * Parses CI test results and maps them to roadmap features.
 * Reads Playwright JSON reports and extracts pass/fail/skip status.
 * 
 * Usage:
 *   tsx scripts/roadmap/examine.ts [--pr-report path] [--nightly-report path]
 */

import * as fs from 'fs';
import * as path from 'path';

interface TestResult {
  status: 'passed' | 'failed' | 'skipped' | 'timedOut';
  tags: string[];
  file: string;
  title: string;
  duration?: number;
}

interface PlaywrightReport {
  suites: Array<{
    title: string;
    file: string;
    specs: Array<{
      title: string;
      tags: string[];
      tests: Array<{
        status: string;
        results: Array<{
          status: string;
          duration: number;
        }>;
      }>;
    }>;
  }>;
}

interface ExaminationResult {
  timestamp: string;
  prTestsPath?: string;
  nightlyTestsPath?: string;
  testsByTag: Record<string, TestResult[]>;
  summary: {
    total: number;
    passed: number;
    failed: number;
    skipped: number;
    timedOut: number;
  };
}

function parseTestReport(reportPath: string): TestResult[] {
  if (!fs.existsSync(reportPath)) {
    console.warn(`⚠️  Test report not found: ${reportPath}`);
    return [];
  }

  const rawData = fs.readFileSync(reportPath, 'utf-8');
  const report: PlaywrightReport = JSON.parse(rawData);
  const results: TestResult[] = [];

  for (const suite of report.suites || []) {
    for (const spec of suite.specs || []) {
      for (const test of spec.tests || []) {
        const lastResult = test.results?.[test.results.length - 1];
        if (lastResult) {
          results.push({
            status: lastResult.status as any,
            tags: spec.tags || [],
            file: suite.file,
            title: spec.title,
            duration: lastResult.duration,
          });
        }
      }
    }
  }

  return results;
}

function groupTestsByTag(tests: TestResult[]): Record<string, TestResult[]> {
  const byTag: Record<string, TestResult[]> = {};

  for (const test of tests) {
    for (const tag of test.tags) {
      const cleanTag = tag.replace('@', '');
      if (!byTag[cleanTag]) {
        byTag[cleanTag] = [];
      }
      byTag[cleanTag].push(test);
    }
  }

  return byTag;
}

function calculateSummary(tests: TestResult[]) {
  return {
    total: tests.length,
    passed: tests.filter(t => t.status === 'passed').length,
    failed: tests.filter(t => t.status === 'failed').length,
    skipped: tests.filter(t => t.status === 'skipped').length,
    timedOut: tests.filter(t => t.status === 'timedOut').length,
  };
}

async function examine(): Promise<ExaminationResult> {
  const args = process.argv.slice(2);
  
  // Default test report paths
  let prReportPath = 'test-results-pr.json';
  let nightlyReportPath = 'test-results-nightly.json';

  // Parse command-line arguments
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--pr-report' && args[i + 1]) {
      prReportPath = args[i + 1];
      i++;
    } else if (args[i] === '--nightly-report' && args[i + 1]) {
      nightlyReportPath = args[i + 1];
      i++;
    }
  }

  console.log('🔍 ECRR Roadmap - EXAMINE Phase');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📊 PR Test Report:      ${prReportPath}`);
  console.log(`📊 Nightly Test Report: ${nightlyReportPath}`);
  console.log();

  // Parse test reports
  const prTests = parseTestReport(prReportPath);
  const nightlyTests = parseTestReport(nightlyReportPath);
  const allTests = [...prTests, ...nightlyTests];

  // Group by tags
  const testsByTag = groupTestsByTag(allTests);

  // Calculate summary
  const summary = calculateSummary(allTests);

  console.log(`✅ Passed:    ${summary.passed}/${summary.total}`);
  console.log(`❌ Failed:    ${summary.failed}/${summary.total}`);
  console.log(`⏭️  Skipped:   ${summary.skipped}/${summary.total}`);
  console.log(`⏱️  Timed Out: ${summary.timedOut}/${summary.total}`);
  console.log();

  console.log('📋 Tests by Tag:');
  for (const [tag, tests] of Object.entries(testsByTag)) {
    const tagSummary = calculateSummary(tests);
    console.log(`   @${tag}: ${tagSummary.passed}/${tagSummary.total} passing`);
  }

  const result: ExaminationResult = {
    timestamp: new Date().toISOString(),
    prTestsPath: fs.existsSync(prReportPath) ? prReportPath : undefined,
    nightlyTestsPath: fs.existsSync(nightlyReportPath) ? nightlyReportPath : undefined,
    testsByTag,
    summary,
  };

  // Write examination result
  const outputPath = '.artifacts/roadmap-examine.json';
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2));

  console.log();
  console.log(`💾 Examination result saved: ${outputPath}`);

  return result;
}

// Run if called directly
if (require.main === module) {
  examine()
    .then(() => {
      console.log();
      console.log('✅ EXAMINE phase complete');
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ EXAMINE phase failed:', err);
      process.exit(1);
    });
}

export { examine, ExaminationResult, TestResult };

