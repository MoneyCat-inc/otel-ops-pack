#!/usr/bin/env tsx
// Signature Registry Generator
// Lane: COMP | Owner: AUTO-BOTS-COMP-ALFA
// Authority: BossCat OEM P1-C Job C-1

import { createHash } from 'crypto';
import { readdirSync, statSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

interface AssetSignature {
  path: string;
  size: number;
  sha256: string;
  timestamp: string;
}

const registry: AssetSignature[] = [];

// Public asset directories to scan
const PUBLIC_DIRS = ['docs/assets', 'docs/LOGO'];

function hashFile(filePath: string): string {
  const content = readFileSync(filePath);
  return createHash('sha256').update(content).digest('hex');
}

function scanDirectory(dir: string): void {
  try {
    const entries = readdirSync(dir);
    
    for (const entry of entries) {
      const fullPath = join(dir, entry);
      const stat = statSync(fullPath);
      
      if (stat.isDirectory()) {
        scanDirectory(fullPath);
      } else if (stat.isFile()) {
        // Only include assets (CSS, JS, images, fonts)
        if (/\.(css|js|png|jpg|jpeg|svg|woff|woff2|ttf|eot)$/i.test(entry)) {
          registry.push({
            path: fullPath.replace(/\\/g, '/'),
            size: stat.size,
            sha256: hashFile(fullPath),
            timestamp: stat.mtime.toISOString()
          });
        }
      }
    }
  } catch (error) {
    // Directory doesn't exist - skip silently
  }
}

// Main execution
console.log('🔐 Generating Signature Registry...\n');

for (const dir of PUBLIC_DIRS) {
  console.log(`Scanning: ${dir}`);
  scanDirectory(dir);
}

// Sort by path for deterministic output
registry.sort((a, b) => a.path.localeCompare(b.path));

// Generate registry
const output = {
  generated: new Date().toISOString(),
  count: registry.length,
  assets: registry
};

// Write to file
const outputPath = 'ALFA/APPS/signature-registry.json';
writeFileSync(outputPath, JSON.stringify(output, null, 2), 'utf-8');

console.log(`\n✅ Registry generated: ${outputPath}`);
console.log(`   Assets tracked: ${registry.length}`);
console.log(`   Total size: ${(registry.reduce((sum, a) => sum + a.size, 0) / 1024).toFixed(2)} KB\n`);

// Exit 0 on success
process.exit(0);

