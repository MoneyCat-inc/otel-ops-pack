#!/usr/bin/env tsx
/**
 * QA Summary Helper
 * 
 * C3: QA Release Runbook
 * Reads Playwright JSON report and provides a concise summary of test results.
 */

import fs from 'node:fs';
import path from 'node:path';

// Configuration
const JSON_REPORT = process.env.QA_JSON ?? 'playwright-report.json';
const REQUIRED_TAGS = ['@progress', '@data-control', '@prosody-scenarios', '@strain', '@isolation-offline', '@a11y-smokes'];

interface TestResult {
  name: string;
  error?: string;
  duration: number;
  status: 'passed' | 'failed' | 'skipped';
  tags: string[];
}

interface TestSuite {
  name: string;
  tests: TestResult[];
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  duration: number;
}

interface QAReport {
  suites: TestSuite[];
  total: number;
  passed: number;
  failed: number;
  skipped: number;
  duration: number;
  slowestTests: TestResult[];
  failures: TestResult[];
  tagCoverage: Record<string, { total: number; passed: number; failed: number }>;
}

function parsePlaywrightReport(reportPath: string): QAReport {
  try {
    const raw = fs.readFileSync(reportPath, 'utf-8');
    const report = JSON.parse(raw);
    
    const suites: TestSuite[] = [];
    const allTests: TestResult[] = [];
    let totalDuration = 0;
    
    // Parse Playwright report structure
    for (const project of report.projects ?? []) {
      for (const suite of project.suites ?? []) {
        const suiteTests: TestResult[] = [];
        let suiteDuration = 0;
        
        for (const spec of suite.specs ?? []) {
          const testName = spec.titlePath?.join(' › ') ?? spec.title ?? 'Unknown Test';
          const duration = spec.results?.[0]?.duration ?? 0;
          const status = spec.ok ? 'passed' : 'failed';
          const error = spec.results?.[0]?.error?.message;
          
          // Extract tags from test name
          const tags = extractTags(testName);
          
          const testResult: TestResult = {
            name: testName,
            error,
            duration,
            status,
            tags
          };
          
          suiteTests.push(testResult);
          allTests.push(testResult);
          suiteDuration += duration;
        }
        
        const suiteResult: TestSuite = {
          name: suite.title ?? 'Unknown Suite',
          tests: suiteTests,
          total: suiteTests.length,
          passed: suiteTests.filter(t => t.status === 'passed').length,
          failed: suiteTests.filter(t => t.status === 'failed').length,
          skipped: suiteTests.filter(t => t.status === 'skipped').length,
          duration: suiteDuration
        };
        
        suites.push(suiteResult);
        totalDuration += suiteDuration;
      }
    }
    
    // Calculate tag coverage
    const tagCoverage: Record<string, { total: number; passed: number; failed: number }> = {};
    for (const tag of REQUIRED_TAGS) {
      const tagTests = allTests.filter(t => t.tags.includes(tag));
      tagCoverage[tag] = {
        total: tagTests.length,
        passed: tagTests.filter(t => t.status === 'passed').length,
        failed: tagTests.filter(t => t.status === 'failed').length
      };
    }
    
    // Find slowest tests
    const slowestTests = [...allTests]
      .sort((a, b) => b.duration - a.duration)
      .slice(0, 5);
    
    // Find failures
    const failures = allTests.filter(t => t.status === 'failed');
    
    return {
      suites,
      total: allTests.length,
      passed: allTests.filter(t => t.status === 'passed').length,
      failed: allTests.filter(t => t.status === 'failed').length,
      skipped: allTests.filter(t => t.status === 'skipped').length,
      duration: totalDuration,
      slowestTests,
      failures,
      tagCoverage
    };
    
  } catch (error) {
    console.error(`Error parsing report: ${(error as Error).message}`);
    process.exit(2);
  }
}

function extractTags(testName: string): string[] {
  const tags: string[] = [];
  
  // Extract tags from test name (e.g., "should work @progress @a11y")
  const tagMatches = testName.match(/@\w+/g);
  if (tagMatches) {
    tags.push(...tagMatches);
  }
  
  // Extract tags from test file path
  if (testName.includes('progress')) tags.push('@progress');
  if (testName.includes('data-control')) tags.push('@data-control');
  if (testName.includes('prosody-scenarios')) tags.push('@prosody-scenarios');
  if (testName.includes('strain')) tags.push('@strain');
  if (testName.includes('isolation-offline')) tags.push('@isolation-offline');
  if (testName.includes('a11y-smokes')) tags.push('@a11y-smokes');
  
  return [...new Set(tags)]; // Remove duplicates
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  return `${(ms / 60000).toFixed(1)}m`;
}

function printSummary(report: QAReport): void {
  console.log('\n📊 QA SUMMARY');
  console.log('='.repeat(50));
  
  // Overall stats
  console.log(`Total: ${report.total}  Passed: ${report.passed}  Failed: ${report.failed}  Skipped: ${report.skipped}`);
  console.log(`Duration: ${formatDuration(report.duration)}`);
  
  // Tag coverage
  console.log('\n🏷️  Tag Coverage:');
  for (const [tag, coverage] of Object.entries(report.tagCoverage)) {
    const status = coverage.failed > 0 ? '❌' : coverage.total > 0 ? '✅' : '⚠️';
    console.log(`  ${status} ${tag}: ${coverage.passed}/${coverage.total} passed`);
  }
  
  // Suite summary
  console.log('\n📋 Test Suites:');
  for (const suite of report.suites) {
    const status = suite.failed > 0 ? '❌' : '✅';
    console.log(`  ${status} ${suite.name}: ${suite.passed}/${suite.total} passed (${formatDuration(suite.duration)})`);
  }
  
  // Slowest tests
  if (report.slowestTests.length > 0) {
    console.log('\n🐌 Slowest Tests:');
    for (const test of report.slowestTests) {
      console.log(`  ${formatDuration(test.duration)}  ${test.name}`);
    }
  }
  
  // Failures
  if (report.failures.length > 0) {
    console.log('\n❌ Failures:');
    for (const failure of report.failures) {
      console.log(`  ✖ ${failure.name}`);
      if (failure.error) {
        console.log(`    ${failure.error}`);
      }
      console.log('');
    }
  }
  
  // Final status
  console.log('\n' + '='.repeat(50));
  if (report.failed === 0) {
    console.log('🎉 All tests passed! ✅');
  } else {
    console.log(`❌ ${report.failed} test(s) failed`);
  }
  
  // Required tag check
  const missingTags = REQUIRED_TAGS.filter(tag => report.tagCoverage[tag]?.total === 0);
  if (missingTags.length > 0) {
    console.log(`⚠️  Missing required tags: ${missingTags.join(', ')}`);
  }
}

function main(): void {
  if (!fs.existsSync(JSON_REPORT)) {
    console.error(`QA report not found: ${JSON_REPORT}`);
    console.log('Run tests with JSON reporter first:');
    console.log('  pnpm test:e2e --reporter=json > playwright-report.json || true');
    process.exit(1);
  }
  
  const report = parsePlaywrightReport(JSON_REPORT);
  printSummary(report);
  
  // Exit with error code if any tests failed
  if (report.failed > 0) {
    process.exit(1);
  }
  
  // Exit with warning if required tags are missing
  const missingTags = REQUIRED_TAGS.filter(tag => report.tagCoverage[tag]?.total === 0);
  if (missingTags.length > 0) {
    process.exit(2);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
