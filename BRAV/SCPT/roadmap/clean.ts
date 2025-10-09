#!/usr/bin/env tsx

/**
 * ECRR Roadmap Automation - CLEAN Phase
 * 
 * Normalizes test results into roadmap feature statuses.
 * Maps test tags to features and determines Green/Yellow/Red status.
 * 
 * Usage:
 *   tsx scripts/roadmap/clean.ts [--examine-result path]
 */

import * as fs from 'fs';
import * as path from 'path';
import type { ExaminationResult, TestResult } from './examine.js';

interface RoadmapSchema {
  version: string;
  lastUpdated: string;
  milestones: Record<string, {
    label: string;
    status: string;
    targetDate: string;
    features: Record<string, {
      name: string;
      description: string;
      testTags: string[];
      testFiles: string[];
      status: 'green' | 'yellow' | 'red';
      completedDate?: string;
      notes?: string;
    }>;
  }>;
  statusMapping: Record<string, any>;
}

interface CleanedRoadmap {
  timestamp: string;
  roadmapVersion: string;
  milestones: Record<string, {
    label: string;
    status: 'green' | 'yellow' | 'red';
    features: Record<string, {
      name: string;
      status: 'green' | 'yellow' | 'red';
      testCoverage: {
        total: number;
        passed: number;
        failed: number;
        skipped: number;
      };
      statusReason: string;
    }>;
  }>;
}

function determineFeatureStatus(
  featureTags: string[],
  testsByTag: Record<string, TestResult[]>
): { status: 'green' | 'yellow' | 'red'; testCoverage: any; reason: string } {
  let totalTests = 0;
  let passedTests = 0;
  let failedTests = 0;
  let skippedTests = 0;

  // Collect all tests for this feature's tags
  for (const tag of featureTags) {
    const cleanTag = tag.replace('@', '');
    const tests = testsByTag[cleanTag] || [];
    
    for (const test of tests) {
      totalTests++;
      if (test.status === 'passed') passedTests++;
      else if (test.status === 'failed') failedTests++;
      else if (test.status === 'skipped') skippedTests++;
    }
  }

  const testCoverage = { total: totalTests, passed: passedTests, failed: failedTests, skipped: skippedTests };

  // No tests found = feature not implemented or tests missing
  if (totalTests === 0) {
    return {
      status: 'red',
      testCoverage,
      reason: 'No tests found for this feature',
    };
  }

  // All tests passing = Green
  if (passedTests === totalTests) {
    return {
      status: 'green',
      testCoverage,
      reason: `All ${totalTests} tests passing`,
    };
  }

  // Some tests failing = Yellow (in progress)
  if (passedTests > 0 && failedTests > 0) {
    return {
      status: 'yellow',
      testCoverage,
      reason: `${passedTests}/${totalTests} tests passing, ${failedTests} failing`,
    };
  }

  // All tests skipped = Yellow (waiting)
  if (skippedTests === totalTests) {
    return {
      status: 'yellow',
      testCoverage,
      reason: `All ${totalTests} tests skipped`,
    };
  }

  // All tests failing = Red
  if (failedTests === totalTests) {
    return {
      status: 'red',
      testCoverage,
      reason: `All ${totalTests} tests failing`,
    };
  }

  // Mixed (passed + skipped) = Yellow
  if (passedTests > 0 && skippedTests > 0) {
    return {
      status: 'yellow',
      testCoverage,
      reason: `${passedTests}/${totalTests} passing, ${skippedTests} skipped`,
    };
  }

  // Default to red
  return {
    status: 'red',
    testCoverage,
    reason: 'Unknown test state',
  };
}

async function clean(): Promise<CleanedRoadmap> {
  const args = process.argv.slice(2);
  
  let examineResultPath = '.artifacts/roadmap-examine.json';

  // Parse command-line arguments
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--examine-result' && args[i + 1]) {
      examineResultPath = args[i + 1];
      i++;
    }
  }

  console.log('🧹 ECRR Roadmap - CLEAN Phase');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📂 Examination Result: ${examineResultPath}`);
  console.log();

  // Load examination result
  if (!fs.existsSync(examineResultPath)) {
    throw new Error(`Examination result not found: ${examineResultPath}`);
  }

  const examineResult: ExaminationResult = JSON.parse(
    fs.readFileSync(examineResultPath, 'utf-8')
  );

  // Load roadmap schema
  const roadmapSchemaPath = 'roadmap.json';
  if (!fs.existsSync(roadmapSchemaPath)) {
    throw new Error(`Roadmap schema not found: ${roadmapSchemaPath}`);
  }

  const roadmapSchema: RoadmapSchema = JSON.parse(
    fs.readFileSync(roadmapSchemaPath, 'utf-8')
  );

  console.log(`📋 Roadmap version: ${roadmapSchema.version}`);
  console.log(`📊 Tests analyzed:  ${examineResult.summary.total}`);
  console.log();

  // Clean: Map tests to features
  const cleaned: CleanedRoadmap = {
    timestamp: new Date().toISOString(),
    roadmapVersion: roadmapSchema.version,
    milestones: {},
  };

  for (const [milestoneKey, milestone] of Object.entries(roadmapSchema.milestones)) {
    console.log(`🗺️  ${milestone.label}`);
    
    cleaned.milestones[milestoneKey] = {
      label: milestone.label,
      status: 'green',
      features: {},
    };

    let milestoneHasRed = false;
    let milestoneHasYellow = false;

    for (const [featureKey, feature] of Object.entries(milestone.features)) {
      const { status, testCoverage, reason } = determineFeatureStatus(
        feature.testTags,
        examineResult.testsByTag
      );

      cleaned.milestones[milestoneKey].features[featureKey] = {
        name: feature.name,
        status,
        testCoverage,
        statusReason: reason,
      };

      // Track milestone-level status
      if (status === 'red') milestoneHasRed = true;
      if (status === 'yellow') milestoneHasYellow = true;

      const statusEmoji = status === 'green' ? '✅' : status === 'yellow' ? '🟨' : '🟥';
      console.log(`   ${statusEmoji} ${feature.name}: ${reason}`);
    }

    // Set overall milestone status
    if (milestoneHasRed) {
      cleaned.milestones[milestoneKey].status = 'red';
    } else if (milestoneHasYellow) {
      cleaned.milestones[milestoneKey].status = 'yellow';
    } else {
      cleaned.milestones[milestoneKey].status = 'green';
    }

    console.log();
  }

  // Write cleaned result
  const outputPath = '.artifacts/roadmap-clean.json';
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(cleaned, null, 2));

  console.log(`💾 Cleaned roadmap saved: ${outputPath}`);

  return cleaned;
}

// Run if called directly
if (require.main === module) {
  clean()
    .then(() => {
      console.log();
      console.log('✅ CLEAN phase complete');
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ CLEAN phase failed:', err);
      process.exit(1);
    });
}

export { clean, CleanedRoadmap };

