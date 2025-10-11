#!/usr/bin/env tsx
// Security Sweep: Lint for inline scripts/styles and unsafe attributes
// Lane: COMP | Owner: AUTO-BOTS-COMP-ALFA
// Authority: BossCat OEM P1-B

import { readFileSync, readdirSync, statSync } from 'fs';
import { join } from 'path';

interface Finding {
  file: string;
  line: number;
  issue: string;
  severity: 'error' | 'warn';
}

const findings: Finding[] = [];

// Patterns to detect
const INLINE_SCRIPT_PATTERN = /<script(?!\s+src=)[^>]*>/gi;
const INLINE_STYLE_TAG_PATTERN = /<style[^>]*>/gi;
const INLINE_STYLE_ATTR_PATTERN = /\s+style=["'][^"']*["']/gi;
const EVENT_HANDLER_PATTERN = /\s+on\w+\s*=\s*["'][^"']*["']/gi;

function scanFile(filePath: string): void {
  const content = readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  lines.forEach((line, idx) => {
    // Check for inline scripts (without src attribute)
    if (INLINE_SCRIPT_PATTERN.test(line)) {
      findings.push({
        file: filePath,
        line: idx + 1,
        issue: 'Inline script tag (CSP violation)',
        severity: 'error'
      });
    }
    
    // Check for inline style tags
    if (INLINE_STYLE_TAG_PATTERN.test(line)) {
      findings.push({
        file: filePath,
        line: idx + 1,
        issue: 'Inline style tag (CSP recommendation)',
        severity: 'warn'
      });
    }
    
    // Check for inline style attributes
    if (INLINE_STYLE_ATTR_PATTERN.test(line) && !line.includes('style="display:none"')) {
      findings.push({
        file: filePath,
        line: idx + 1,
        issue: 'Inline style attribute',
        severity: 'warn'
      });
    }
    
    // Check for event handlers
    if (EVENT_HANDLER_PATTERN.test(line)) {
      findings.push({
        file: filePath,
        line: idx + 1,
        issue: 'Inline event handler (onclick, onload, etc.)',
        severity: 'error'
      });
    }
  });
}

function scanDirectory(dir: string, extensions: string[]): void {
  const entries = readdirSync(dir);
  
  for (const entry of entries) {
    const fullPath = join(dir, entry);
    const stat = statSync(fullPath);
    
    if (stat.isDirectory() && !entry.startsWith('.') && entry !== 'node_modules') {
      scanDirectory(fullPath, extensions);
    } else if (stat.isFile()) {
      const ext = entry.split('.').pop();
      if (ext && extensions.includes(ext)) {
        scanFile(fullPath);
      }
    }
  }
}

// Main execution
console.log('🔍 COMP Lane: Security Sweep\n');

// Scan HTML and TSX files
scanDirectory('.', ['html', 'tsx']);

// Report findings
if (findings.length === 0) {
  console.log('✅ No inline scripts/styles found - CSP compliant');
  process.exit(0);
} else {
  const errors = findings.filter(f => f.severity === 'error');
  const warns = findings.filter(f => f.severity === 'warn');
  
  console.log(`❌ Found ${findings.length} CSP issues:\n`);
  console.log(`   Errors: ${errors.length}`);
  console.log(`   Warnings: ${warns.length}\n`);
  
  findings.slice(0, 20).forEach(f => {
    const icon = f.severity === 'error' ? '❌' : '⚠️ ';
    console.log(`${icon} ${f.file}:${f.line} - ${f.issue}`);
  });
  
  if (findings.length > 20) {
    console.log(`\n... and ${findings.length - 20} more issues`);
  }
  
  console.log('\n🔧 Remediation: Extract inline scripts to external files');
  process.exit(errors.length > 0 ? 1 : 0);
}

