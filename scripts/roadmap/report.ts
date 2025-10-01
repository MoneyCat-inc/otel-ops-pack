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

  // Also update SSOT artifact
  const ssotPath = '.artifacts/SSOT.md';
  if (fs.existsSync(ssotPath)) {
    let ssot = fs.readFileSync(ssotPath, 'utf-8');
    
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

