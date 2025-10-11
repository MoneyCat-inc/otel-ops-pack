#!/usr/bin/env tsx
// Gitleaks Wrapper: Secrets scanning integration
// Lane: COMP | Owner: AUTO-BOTS-COMP-ALFA
// Authority: BossCat OEM P1-B

import { execSync } from 'child_process';
import { existsSync } from 'fs';

console.log('🔐 COMP Lane: Secrets Scan (Gitleaks)\n');

// Check if gitleaks is installed
try {
  execSync('gitleaks version', { stdio: 'pipe' });
} catch {
  console.log('⚠️  Gitleaks not installed - skipping secrets scan');
  console.log('   Install: winget install gitleaks');
  console.log('   Status: Non-blocking (install recommended)\n');
  process.exit(0); // Non-blocking if not installed
}

// Run gitleaks detect
try {
  console.log('Running gitleaks detect...');
  execSync('gitleaks detect --no-git --verbose', { stdio: 'inherit' });
  console.log('\n✅ No secrets detected');
  process.exit(0);
} catch (error) {
  console.log('\n❌ Secrets detected! Review and remediate immediately.');
  console.log('   Evidence: Run `gitleaks detect --report-path=artifacts/gitleaks.json`');
  process.exit(1);
}

