#!/usr/bin/env tsx

/**
 * ECRR Roadmap Automation - REPORT Phase
 * 
 * Generates Markdown documentation from cleaned roadmap data.
 * Creates heatmap tables, Kanban boards, and timeline views.
 * 
 * Usage:
 *   tsx scripts/roadmap/report.ts [--clean-result path]
 */

import * as fs from 'fs';
import * as path from 'path';
import type { CleanedRoadmap } from './clean.js';

function generateHeatmapTable(cleaned: CleanedRoadmap): string {
  let md = '# 📊 Resonai Roadmap Heatmap\n\n';
  md += '| Feature | Stage | Status |\n';
  md += '|---------|-------|--------|\n';

  for (const [milestoneKey, milestone] of Object.entries(cleaned.milestones)) {
    for (const [featureKey, feature] of Object.entries(milestone.features)) {
      const statusEmoji = feature.status === 'green' ? '✅ Green' : 
                         feature.status === 'yellow' ? '🟨 Yellow' : '🟥 Red';
      md += `| ${feature.name} | ${milestone.label} | ${statusEmoji} |\n`;
    }
  }

  md += '\n---\n\n';
  md += '**Legend:**\n\n';
  md += '- ✅ **Green** = complete and stable\n';
  md += '- 🟨 **Yellow** = partial/in progress\n';
  md += '- 🟥 **Red** = not yet started / failing\n\n';

  return md;
}

function generateKanbanBoard(cleaned: CleanedRoadmap): string {
  let md = '# 📋 Resonai Roadmap — Kanban Board\n\n';

  const greenFeatures: string[] = [];
  const yellowFeatures: string[] = [];
  const redFeatures: string[] = [];

  for (const milestone of Object.values(cleaned.milestones)) {
    for (const feature of Object.values(milestone.features)) {
      const featureWithReason = `${feature.name} → ${feature.statusReason}`;
      
      if (feature.status === 'green') {
        greenFeatures.push(featureWithReason);
      } else if (feature.status === 'yellow') {
        yellowFeatures.push(featureWithReason);
      } else {
        redFeatures.push(featureWithReason);
      }
    }
  }

  md += '## ✅ Green (Complete & Stable)\n\n';
  if (greenFeatures.length > 0) {
    greenFeatures.forEach(f => md += `- ${f}\n`);
  } else {
    md += '_No features in this category_\n';
  }

  md += '\n---\n\n';
  md += '## 🟨 Yellow (In Progress / Partial)\n\n';
  if (yellowFeatures.length > 0) {
    yellowFeatures.forEach(f => md += `- ${f}\n`);
  } else {
    md += '_No features in this category_\n';
  }

  md += '\n---\n\n';
  md += '## 🟥 Red (Not Yet Started / Future)\n\n';
  if (redFeatures.length > 0) {
    redFeatures.forEach(f => md += `- ${f}\n`);
  } else {
    md += '_No features in this category_\n';
  }

  md += '\n---\n\n';
  md += '**Focus Areas:**\n\n';
  md += '- ✅ **Green** = maintain & polish\n';
  md += '- 🟨 **Yellow** = contributor focus now (M2)\n';
  md += '- 🟥 **Red** = backlog for M3 milestone\n\n';

  return md;
}

function generateSummarySection(cleaned: CleanedRoadmap): string {
  let md = '# 🗺️ Roadmap Status Summary\n\n';
  md += `**Last Updated:** ${new Date(cleaned.timestamp).toLocaleString()}\n\n`;
  md += `**Roadmap Version:** ${cleaned.roadmapVersion}\n\n`;

  md += '## Milestone Overview\n\n';
  
  for (const [milestoneKey, milestone] of Object.entries(cleaned.milestones)) {
    const milestoneEmoji = milestone.status === 'green' ? '✅' : 
                          milestone.status === 'yellow' ? '🟨' : '🟥';
    
    md += `### ${milestoneEmoji} ${milestone.label}\n\n`;

    const greenCount = Object.values(milestone.features).filter(f => f.status === 'green').length;
    const yellowCount = Object.values(milestone.features).filter(f => f.status === 'yellow').length;
    const redCount = Object.values(milestone.features).filter(f => f.status === 'red').length;
    const total = Object.keys(milestone.features).length;

    md += `**Progress:** ${greenCount} green, ${yellowCount} yellow, ${redCount} red (${total} total)\n\n`;

    for (const feature of Object.values(milestone.features)) {
      const featureEmoji = feature.status === 'green' ? '✅' : 
                          feature.status === 'yellow' ? '🟨' : '🟥';
      md += `- ${featureEmoji} **${feature.name}**: ${feature.statusReason}\n`;
    }

    md += '\n';
  }

  return md;
}

function generateDashboardJSON(cleaned: CleanedRoadmap, examineResultPath: string): {
  roadmap: Record<string, Array<[string, string]>>;
  tests: any;
  ssot: any;
} {
  // Generate simplified roadmap JSON for HTML dashboard
  const roadmapSimple: Record<string, Array<[string, string]>> = {};
  
  for (const [milestoneKey, milestone] of Object.entries(cleaned.milestones)) {
    roadmapSimple[milestone.label] = [];
    for (const feature of Object.values(milestone.features)) {
      roadmapSimple[milestone.label].push([feature.name, feature.status]);
    }
  }

  // Load examination result for test stats
  let examineResult: any = { summary: { total: 0, passed: 0, failed: 0, skipped: 0 }, testsByTag: {} };
  if (fs.existsSync(examineResultPath)) {
    examineResult = JSON.parse(fs.readFileSync(examineResultPath, 'utf-8'));
  }

  // Generate tests JSON with buckets
  const buckets = [];
  for (const [tag, tests] of Object.entries(examineResult.testsByTag || {})) {
    const failedTests = (tests as any[]).filter(t => t.status === 'failed');
    if (failedTests.length > 0) {
      buckets.push({
        tag: `@${tag}`,
        failed: failedTests.length,
        examples: failedTests.slice(0, 3).map(t => t.title)
      });
    }
  }
  buckets.sort((a, b) => b.failed - a.failed);

  const testsJSON = {
    updatedAt: new Date().toISOString(),
    prLane: {
      total: examineResult.summary.total,
      passed: examineResult.summary.passed,
      failed: examineResult.summary.failed,
      skipped: examineResult.summary.skipped
    },
    nightly: {
      total: examineResult.summary.total,
      passed: examineResult.summary.passed,
      failed: examineResult.summary.failed,
      skipped: examineResult.summary.skipped
    },
    buckets
  };

  // Generate SSOT snapshot
  const ssotJSON = {
    buildSha: process.env.GITHUB_SHA || 'dev',
    cohort: process.env.COHORT || 'local',
    when: new Date().toISOString(),
    notes: 'Generated by ECRR roadmap automation'
  };

  return { roadmap: roadmapSimple, tests: testsJSON, ssot: ssotJSON };
}

async function report(): Promise<void> {
  const args = process.argv.slice(2);
  
  let cleanResultPath = '.artifacts/roadmap-clean.json';

  // Parse command-line arguments
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--clean-result' && args[i + 1]) {
      cleanResultPath = args[i + 1];
      i++;
    }
  }

  console.log('📝 ECRR Roadmap - REPORT Phase');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📂 Cleaned Result: ${cleanResultPath}`);
  console.log();

  // Load cleaned result
  if (!fs.existsSync(cleanResultPath)) {
    throw new Error(`Cleaned result not found: ${cleanResultPath}`);
  }

  const cleaned: CleanedRoadmap = JSON.parse(
    fs.readFileSync(cleanResultPath, 'utf-8')
  );

  // Generate reports
  console.log('📊 Generating heatmap table...');
  const heatmapMd = generateHeatmapTable(cleaned);
  
  console.log('📋 Generating Kanban board...');
  const kanbanMd = generateKanbanBoard(cleaned);
  
  console.log('📝 Generating summary section...');
  const summaryMd = generateSummarySection(cleaned);

  // Combine into main roadmap doc
  const mainRoadmapMd = `${summaryMd}\n---\n\n${heatmapMd}\n---\n\n${kanbanMd}`;

  // Write output files
  const docsDir = 'docs';
  fs.mkdirSync(docsDir, { recursive: true });

  const roadmapPath = path.join(docsDir, 'ROADMAP.md');
  const kanbanPath = path.join(docsDir, 'ROADMAP_KANBAN.md');
  const heatmapPath = path.join(docsDir, 'ROADMAP_HEATMAP.md');

  fs.writeFileSync(roadmapPath, mainRoadmapMd);
  fs.writeFileSync(kanbanPath, kanbanMd);
  fs.writeFileSync(heatmapPath, heatmapMd);

  console.log();
  console.log(`✅ Generated: ${roadmapPath}`);
  console.log(`✅ Generated: ${kanbanPath}`);
  console.log(`✅ Generated: ${heatmapPath}`);

  // Generate dashboard JSON files
  console.log('🎨 Generating dashboard JSON files...');
  const dashboardData = generateDashboardJSON(cleaned, '.artifacts/roadmap-examine.json');
  
  const dashboardDir = path.join(docsDir, 'status');
  fs.mkdirSync(dashboardDir, { recursive: true });
  
  fs.writeFileSync(
    path.join(dashboardDir, 'roadmap.json'),
    JSON.stringify(dashboardData.roadmap, null, 2)
  );
  fs.writeFileSync(
    path.join(dashboardDir, 'tests.json'),
    JSON.stringify(dashboardData.tests, null, 2)
  );
  fs.writeFileSync(
    path.join(dashboardDir, 'ssot.json'),
    JSON.stringify(dashboardData.ssot, null, 2)
  );
  
  console.log(`✅ Generated: ${path.join(dashboardDir, 'roadmap.json')}`);
  console.log(`✅ Generated: ${path.join(dashboardDir, 'tests.json')}`);
  console.log(`✅ Generated: ${path.join(dashboardDir, 'ssot.json')}`);

  // Also update SSOT artifact
  const ssotPath = '.artifacts/SSOT.md';
  let existingSsot: string | null = null;
  try { existingSsot = fs.readFileSync(ssotPath, 'utf-8'); } catch {}
  if (existingSsot !== null) {
    let ssot = existingSsot;
    
    // Update roadmap section if it exists
    const roadmapSectionRegex = /## 🗺️ Roadmap Status[\s\S]*?(?=\n## |\n---\n\n|\Z)/;
    const roadmapSection = `## 🗺️ Roadmap Status\n\n${summaryMd}`;
    
    if (roadmapSectionRegex.test(ssot)) {
      ssot = ssot.replace(roadmapSectionRegex, roadmapSection);
    } else {
      ssot += `\n\n${roadmapSection}`;
    }
    
    fs.writeFileSync(ssotPath, ssot);
    console.log(`✅ Updated: ${ssotPath} (roadmap section)`);
  }

  console.log();
  console.log('📦 Report artifacts saved to docs/ and .artifacts/');
}

// Run if called directly
if (require.main === module) {
  report()
    .then(() => {
      console.log();
      console.log('✅ REPORT phase complete');
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ REPORT phase failed:', err);
      process.exit(1);
    });
}

export { report };

