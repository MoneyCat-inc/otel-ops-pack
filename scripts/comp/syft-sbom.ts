#!/usr/bin/env tsx
// SBOM Generator: Software Bill of Materials via Syft
// Lane: COMP | Owner: AUTO-BOTS-COMP-ALFA
// Authority: BossCat OEM P1-B

import { execSync } from 'child_process';
import { existsSync, mkdirSync } from 'fs';

console.log('📦 COMP Lane: SBOM Generation (Syft)\n');

// Check if syft is installed
try {
  execSync('syft version', { stdio: 'pipe' });
} catch {
  console.log('⚠️  Syft not installed - skipping SBOM generation');
  console.log('   Install: https://github.com/anchore/syft#installation');
  console.log('   Status: Non-blocking (install recommended)\n');
  process.exit(0); // Non-blocking if not installed
}

// Ensure output directory exists
if (!existsSync('artifacts')) {
  mkdirSync('artifacts', { recursive: true });
}

// Generate SBOM in SPDX JSON format
try {
  console.log('Generating SBOM (SPDX JSON)...');
  execSync('syft dir:. -o spdx-json=artifacts/sbom.spdx.json', { stdio: 'inherit' });
  console.log('\n✅ SBOM generated: artifacts/sbom.spdx.json');
  process.exit(0);
} catch (error) {
  console.log('\n❌ SBOM generation failed');
  process.exit(1);
}

