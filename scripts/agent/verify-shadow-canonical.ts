/**
 * Shadow vs Canonical Verification Script
 * 
 * PR-D Preparation: Establishes baseline for byte-identical verification
 * between shadow and canonical artifacts before flipping to canonical writes.
 * 
 * Usage:
 *   pnpm agent:verify-shadow-canonical
 *   
 * This script compares the last N shadow artifacts with their canonical
 * counterparts to ensure zero drift before the canonical write flip.
 */

import { promises as fs } from 'fs';
import { join, dirname } from 'path';
import { createHash } from 'crypto';
import { writeFileAtomicIfChanged } from './io';

interface VerificationResult {
  timestamp: string;
  shadowArtifacts: string[];
  canonicalArtifacts: string[];
  matches: Array<{
    path: string;
    shadowHash: string;
    canonicalHash: string;
    identical: boolean;
  }>;
  summary: {
    totalArtifacts: number;
    identicalCount: number;
    driftCount: number;
    verificationPassed: boolean;
  };
}

interface VerificationConfig {
  shadowBasePath: string;
  canonicalBasePath: string;
  maxArtifactsToCheck: number;
  artifactPatterns: string[];
}

const DEFAULT_CONFIG: VerificationConfig = {
  shadowBasePath: '.agent/shadow',
  canonicalBasePath: '.agent',
  maxArtifactsToCheck: 10,
  artifactPatterns: [
    'status.json',
    'agent_queue.json',
    'queue.db',
    '*.json',
    'docs/**/*.md'
  ]
};

async function calculateFileHash(filePath: string): Promise<string> {
  try {
    const content = await fs.readFile(filePath);
    return createHash('sha256').update(content).digest('hex');
  } catch (error: any) {
    if (error.code === 'ENOENT') {
      return 'FILE_NOT_FOUND';
    }
    throw error;
  }
}

async function findArtifacts(basePath: string, patterns: string[]): Promise<string[]> {
  const artifacts: string[] = [];
  
  for (const pattern of patterns) {
    try {
      // Simple glob-like pattern matching
      if (pattern.includes('**')) {
        // Recursive directory search
        const recursivePattern = pattern.replace('**', '');
        const walkDir = async (dir: string): Promise<void> => {
          try {
            const entries = await fs.readdir(dir, { withFileTypes: true });
            for (const entry of entries) {
              const fullPath = join(dir, entry.name);
              if (entry.isDirectory()) {
                await walkDir(fullPath);
              } else if (entry.isFile()) {
                const relativePath = fullPath.replace(basePath + '/', '');
                if (relativePath.match(pattern.replace('**', '.*'))) {
                  artifacts.push(relativePath);
                }
              }
            }
          } catch (error: any) {
            if (error.code !== 'ENOENT') {
              console.warn(`Warning: Could not read directory ${dir}: ${error.message}`);
            }
          }
        };
        await walkDir(basePath);
      } else if (pattern.includes('*')) {
        // Simple wildcard matching
        try {
          const dir = dirname(pattern);
          const files = await fs.readdir(join(basePath, dir));
          const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
          for (const file of files) {
            if (regex.test(file)) {
              artifacts.push(join(dir, file));
            }
          }
        } catch (error: any) {
          // Directory doesn't exist, skip
        }
      } else {
        // Exact file match
        try {
          await fs.access(join(basePath, pattern));
          artifacts.push(pattern);
        } catch (error: any) {
          // File doesn't exist, skip
        }
      }
    } catch (error: any) {
      console.warn(`Warning: Error processing pattern ${pattern}: ${error.message}`);
    }
  }
  
  return [...new Set(artifacts)]; // Remove duplicates
}

async function verifyShadowVsCanonical(config: VerificationConfig = DEFAULT_CONFIG): Promise<VerificationResult> {
  console.log('🔍 Starting Shadow vs Canonical Verification...');
  console.log(`📁 Shadow base path: ${config.shadowBasePath}`);
  console.log(`📁 Canonical base path: ${config.canonicalBasePath}`);
  
  // Find all artifacts in shadow directory
  const shadowArtifacts = await findArtifacts(config.shadowBasePath, config.artifactPatterns);
  console.log(`📋 Found ${shadowArtifacts.length} shadow artifacts`);
  
  // Find corresponding canonical artifacts
  const canonicalArtifacts = await findArtifacts(config.canonicalBasePath, config.artifactPatterns);
  console.log(`📋 Found ${canonicalArtifacts.length} canonical artifacts`);
  
  // Compare artifacts
  const matches: VerificationResult['matches'] = [];
  let identicalCount = 0;
  let driftCount = 0;
  
  // Limit to most recent artifacts
  const artifactsToCheck = shadowArtifacts.slice(0, config.maxArtifactsToCheck);
  
  for (const artifactPath of artifactsToCheck) {
    const shadowPath = join(config.shadowBasePath, artifactPath);
    const canonicalPath = join(config.canonicalBasePath, artifactPath);
    
    const shadowHash = await calculateFileHash(shadowPath);
    const canonicalHash = await calculateFileHash(canonicalPath);
    
    const identical = shadowHash === canonicalHash && shadowHash !== 'FILE_NOT_FOUND';
    
    matches.push({
      path: artifactPath,
      shadowHash,
      canonicalHash,
      identical
    });
    
    if (identical) {
      identicalCount++;
      console.log(`✅ ${artifactPath} - IDENTICAL`);
    } else {
      driftCount++;
      console.log(`❌ ${artifactPath} - DRIFT DETECTED`);
      console.log(`   Shadow hash:    ${shadowHash}`);
      console.log(`   Canonical hash: ${canonicalHash}`);
    }
  }
  
  const verificationPassed = driftCount === 0;
  
  const result: VerificationResult = {
    timestamp: new Date().toISOString(),
    shadowArtifacts,
    canonicalArtifacts,
    matches,
    summary: {
      totalArtifacts: artifactsToCheck.length,
      identicalCount,
      driftCount,
      verificationPassed
    }
  };
  
  // Save verification report
  const reportPath = '.agent/shadow-canonical-verification.json';
  await writeFileAtomicIfChanged(reportPath, JSON.stringify(result, null, 2));
  
  // Print summary
  console.log('\n📊 Verification Summary:');
  console.log(`   Total artifacts checked: ${result.summary.totalArtifacts}`);
  console.log(`   Identical: ${result.summary.identicalCount}`);
  console.log(`   Drift detected: ${result.summary.driftCount}`);
  console.log(`   Verification ${verificationPassed ? '✅ PASSED' : '❌ FAILED'}`);
  console.log(`   Report saved: ${reportPath}`);
  
  if (!verificationPassed) {
    console.log('\n⚠️  WARNING: Drift detected between shadow and canonical artifacts!');
    console.log('   This may indicate issues with the shadow write implementation.');
    console.log('   Review the artifacts above before proceeding with canonical flip.');
  } else {
    console.log('\n🎯 All artifacts are byte-identical - ready for canonical flip!');
  }
  
  return result;
}

// Main execution
async function main() {
  try {
    const config = DEFAULT_CONFIG;
    
    // Override config from environment variables if present
    if (process.env.SHADOW_BASE_PATH) {
      config.shadowBasePath = process.env.SHADOW_BASE_PATH;
    }
    if (process.env.CANONICAL_BASE_PATH) {
      config.canonicalBasePath = process.env.CANONICAL_BASE_PATH;
    }
    if (process.env.MAX_ARTIFACTS_TO_CHECK) {
      config.maxArtifactsToCheck = parseInt(process.env.MAX_ARTIFACTS_TO_CHECK, 10);
    }
    
    const result = await verifyShadowVsCanonical(config);
    
    // Exit with appropriate code
    process.exit(result.summary.verificationPassed ? 0 : 1);
    
  } catch (error) {
    console.error('❌ Verification failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { verifyShadowVsCanonical, VerificationResult, VerificationConfig };