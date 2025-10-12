#!/usr/bin/env tsx
// JS Signature Guard - Enforce inline JS ban + registry match
// Lane: COMP | Owner: AUTO-BOTS-COMP-ALFA  
// Authority: BossCat OEM P1-C Job C-2

import { readFileSync, existsSync } from 'fs';
import { createHash } from 'crypto';
import { glob } from 'glob';

console.log('🔐 JS Signature Guard - Validating asset integrity...\n');

// Load signature registry
const REGISTRY_PATH = 'ALFA/APPS/signature-registry.json';
if (!existsSync(REGISTRY_PATH)) {
  console.log('❌ signature-registry.json not found at ALFA/APPS/');
  console.log('   Run: pnpm guard:signatures first\n');
  process.exit(1);
}

const registry = JSON.parse(readFileSync(REGISTRY_PATH, 'utf-8'));
const assetMap = new Map(
  registry.assets.map((a: any) => [a.path, a.sha256])
);

let violations = 0;

// Scan HTML files for script tags
const htmlFiles = glob.sync('**/*.html', {
  ignore: ['node_modules/**', 'out/**', '.next/**', 'coverage/**']
});

for (const htmlFile of htmlFiles) {
  const content = readFileSync(htmlFile, 'utf-8');
  
  // Check for inline scripts (CSP violation)
  const inlineScriptMatch = content.match(/<script(?!\s+src=)[^>]*>/gi);
  if (inlineScriptMatch) {
    console.log(`❌ ${htmlFile}: Inline script detected (CSP violation)`);
    inlineScriptMatch.forEach(m => console.log(`   ${m.substring(0, 60)}...`));
    violations++;
  }
  
  // Extract script src references
  const scriptRefs = content.matchAll(/<script\s+src=["']([^"']+)["']/gi);
  for (const match of scriptRefs) {
    const srcPath = match[1];
    
    // Normalize path
    const normalizedPath = srcPath.replace(/^\//, '').replace(/\\/g, '/');
    
    // Check if in registry
    if (!assetMap.has(normalizedPath)) {
      console.log(`❌ ${htmlFile}: Script not in registry: ${srcPath}`);
      violations++;
    } else {
      // Verify hash match (optional - requires file read)
      if (existsSync(normalizedPath)) {
        const actualHash = createHash('sha256')
          .update(readFileSync(normalizedPath))
          .digest('hex');
        const expectedHash = assetMap.get(normalizedPath);
        
        if (actualHash !== expectedHash) {
          console.log(`❌ ${htmlFile}: Hash mismatch for ${srcPath}`);
          console.log(`   Expected: ${expectedHash}`);
          console.log(`   Actual:   ${actualHash}`);
          violations++;
        }
      }
    }
  }
}

// Summary
if (violations === 0) {
  console.log('✅ All JS assets validated - no inline scripts, all registered\n');
  process.exit(0);
} else {
  console.log(`\n❌ Found ${violations} violation(s)`);
  console.log('   Fix: Remove inline scripts, regenerate registry\n');
  process.exit(1);
}

