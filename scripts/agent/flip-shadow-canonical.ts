/**
 * Shadow to Canonical Flip Script
 * Safely transitions from shadow writes to canonical writes
 * after verification that artifacts are byte-identical
 */

import { ShadowCanonicalVerifier } from './verify-shadow-canonical';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';

export interface FlipResult {
  success: boolean;
  reason?: string;
  artifactsCopied: number;
  artifactsSkipped: number;
  verificationPassed: boolean;
}

export class ShadowToCanonicalFlipper {
  private verifier = new ShadowCanonicalVerifier();

  /**
   * Perform the flip from shadow to canonical
   */
  async flip(): Promise<FlipResult> {
    console.log('=== Shadow to Canonical Flip ===\n');

    // Step 1: Verify shadow vs canonical are identical
    console.log('Step 1: Verifying shadow vs canonical artifacts...');
    const verificationPassed = this.verifier.isReadyForCanonicalFlip();
    
    if (!verificationPassed) {
      return {
        success: false,
        reason: 'Verification failed - shadow and canonical artifacts are not identical',
        artifactsCopied: 0,
        artifactsSkipped: 0,
        verificationPassed: false,
      };
    }

    console.log('✅ Verification passed - artifacts are identical\n');

    // Step 2: Copy shadow artifacts to canonical
    console.log('Step 2: Copying shadow artifacts to canonical...');
    const copyResult = await this.copyShadowToCanonical();
    
    if (!copyResult.success) {
      return {
        success: false,
        reason: copyResult.reason,
        artifactsCopied: copyResult.artifactsCopied,
        artifactsSkipped: copyResult.artifactsSkipped,
        verificationPassed: true,
      };
    }

    console.log(`✅ Copied ${copyResult.artifactsCopied} artifacts, skipped ${copyResult.artifactsSkipped}\n`);

    // Step 3: Update environment to disable shadow mode
    console.log('Step 3: Updating environment configuration...');
    this.updateEnvironmentConfig();

    // Step 4: Final verification
    console.log('Step 4: Final verification...');
    const finalVerification = this.verifier.isReadyForCanonicalFlip();
    
    if (!finalVerification) {
      console.log('⚠️ Final verification failed - rolling back...');
      this.rollback();
      return {
        success: false,
        reason: 'Final verification failed after flip',
        artifactsCopied: copyResult.artifactsCopied,
        artifactsSkipped: copyResult.artifactsSkipped,
        verificationPassed: false,
      };
    }

    console.log('✅ Final verification passed\n');

    // Step 5: Cleanup shadow artifacts
    console.log('Step 5: Cleaning up shadow artifacts...');
    this.cleanupShadowArtifacts();

    console.log('🎉 Shadow to canonical flip completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Set QUEUE_SHADOW=0 in production');
    console.log('2. Monitor canonical artifacts');
    console.log('3. Remove shadow directory when confident');

    return {
      success: true,
      artifactsCopied: copyResult.artifactsCopied,
      artifactsSkipped: copyResult.artifactsSkipped,
      verificationPassed: true,
    };
  }

  /**
   * Copy shadow artifacts to canonical locations
   */
  private async copyShadowToCanonical(): Promise<{
    success: boolean;
    reason?: string;
    artifactsCopied: number;
    artifactsSkipped: number;
  }> {
    const artifacts = [
      '.agent/status.json',
      '.agent/agent_queue.json',
      '.agent/runs.json',
      '.agent/config.json',
      '.agent/state.json',
    ];

    let copied = 0;
    let skipped = 0;

    for (const artifact of artifacts) {
      const shadowPath = this.getShadowPath(artifact);
      
      if (!existsSync(shadowPath)) {
        console.log(`⚠️ Shadow artifact not found: ${shadowPath}`);
        skipped++;
        continue;
      }

      try {
        // Ensure canonical directory exists
        const canonicalDir = dirname(artifact);
        if (!existsSync(canonicalDir)) {
          mkdirSync(canonicalDir, { recursive: true });
        }

        // Read shadow content
        const shadowContent = readFileSync(shadowPath, 'utf8');
        
        // Write to canonical location
        writeFileSync(artifact, shadowContent, 'utf8');
        
        console.log(`✓ Copied: ${artifact}`);
        copied++;
        
      } catch (error) {
        console.error(`✗ Failed to copy ${artifact}:`, error);
        return {
          success: false,
          reason: `Failed to copy ${artifact}: ${error}`,
          artifactsCopied: copied,
          artifactsSkipped: skipped,
        };
      }
    }

    return {
      success: true,
      artifactsCopied: copied,
      artifactsSkipped: skipped,
    };
  }

  /**
   * Get shadow path for canonical path
   */
  private getShadowPath(canonicalPath: string): string {
    if (canonicalPath.startsWith('.agent/')) {
      return canonicalPath.replace('.agent/', '.agent/shadow/');
    }
    
    const parts = canonicalPath.split('/');
    parts.splice(-1, 0, 'shadow');
    return parts.join('/');
  }

  /**
   * Update environment configuration
   */
  private updateEnvironmentConfig(): void {
    // Update .env files if they exist
    const envFiles = ['.env', '.env.local', '.env.production'];
    
    for (const envFile of envFiles) {
      if (existsSync(envFile)) {
        try {
          let content = readFileSync(envFile, 'utf8');
          
          // Update QUEUE_SHADOW to 0
          content = content.replace(/QUEUE_SHADOW=1/g, 'QUEUE_SHADOW=0');
          
          // If QUEUE_SHADOW doesn't exist, add it
          if (!content.includes('QUEUE_SHADOW=')) {
            content += '\nQUEUE_SHADOW=0\n';
          }
          
          writeFileSync(envFile, content, 'utf8');
          console.log(`✓ Updated ${envFile}`);
          
        } catch (error) {
          console.warn(`⚠️ Failed to update ${envFile}:`, error);
        }
      }
    }

    // Update package.json scripts if needed
    try {
      const packageJsonPath = 'package.json';
      if (existsSync(packageJsonPath)) {
        const content = readFileSync(packageJsonPath, 'utf8');
        const packageJson = JSON.parse(content);
        
        // Update any scripts that reference shadow mode
        if (packageJson.scripts) {
          for (const [key, value] of Object.entries(packageJson.scripts)) {
            if (typeof value === 'string' && value.includes('QUEUE_SHADOW=1')) {
              packageJson.scripts[key] = value.replace('QUEUE_SHADOW=1', 'QUEUE_SHADOW=0');
            }
          }
          
          writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2), 'utf8');
          console.log('✓ Updated package.json scripts');
        }
      }
    } catch (error) {
      console.warn('⚠️ Failed to update package.json:', error);
    }
  }

  /**
   * Rollback the flip
   */
  private rollback(): void {
    console.log('Rolling back flip...');
    
    // Re-enable shadow mode
    const envFiles = ['.env', '.env.local', '.env.production'];
    
    for (const envFile of envFiles) {
      if (existsSync(envFile)) {
        try {
          let content = readFileSync(envFile, 'utf8');
          content = content.replace(/QUEUE_SHADOW=0/g, 'QUEUE_SHADOW=1');
          writeFileSync(envFile, content, 'utf8');
          console.log(`✓ Rolled back ${envFile}`);
        } catch (error) {
          console.warn(`⚠️ Failed to rollback ${envFile}:`, error);
        }
      }
    }
  }

  /**
   * Cleanup shadow artifacts
   */
  private cleanupShadowArtifacts(): void {
    const shadowDir = '.agent/shadow';
    
    if (existsSync(shadowDir)) {
      try {
        const fs = require('fs');
        fs.rmSync(shadowDir, { recursive: true, force: true });
        console.log('✓ Cleaned up shadow directory');
      } catch (error) {
        console.warn('⚠️ Failed to cleanup shadow directory:', error);
      }
    }
  }

  /**
   * Dry run - show what would be done without actually doing it
   */
  async dryRun(): Promise<void> {
    console.log('=== Shadow to Canonical Flip (DRY RUN) ===\n');

    // Step 1: Verification
    console.log('Step 1: Verification check...');
    const verificationPassed = this.verifier.isReadyForCanonicalFlip();
    console.log(`Verification: ${verificationPassed ? 'PASS' : 'FAIL'}\n`);

    if (!verificationPassed) {
      console.log('❌ Cannot proceed - verification failed');
      return;
    }

    // Step 2: Show what would be copied
    console.log('Step 2: Artifacts that would be copied:');
    const artifacts = [
      '.agent/status.json',
      '.agent/agent_queue.json',
      '.agent/runs.json',
      '.agent/config.json',
      '.agent/state.json',
    ];

    for (const artifact of artifacts) {
      const shadowPath = this.getShadowPath(artifact);
      if (existsSync(shadowPath)) {
        console.log(`✓ Would copy: ${artifact}`);
      } else {
        console.log(`⚠️ Shadow not found: ${shadowPath}`);
      }
    }

    console.log('\nStep 3: Environment changes:');
    console.log('- QUEUE_SHADOW=1 → QUEUE_SHADOW=0');
    console.log('- Update package.json scripts');

    console.log('\nStep 4: Cleanup:');
    console.log('- Remove .agent/shadow/ directory');

    console.log('\n✅ Dry run complete - ready for actual flip');
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const command = args[0] || 'flip';
  
  const flipper = new ShadowToCanonicalFlipper();
  
  switch (command) {
    case 'flip':
      flipper.flip().then(result => {
        if (result.success) {
          console.log('\n🎉 Flip completed successfully!');
          process.exit(0);
        } else {
          console.log(`\n❌ Flip failed: ${result.reason}`);
          process.exit(1);
        }
      });
      break;
      
    case 'dry-run':
      flipper.dryRun();
      break;
      
    default:
      console.log('Usage:');
      console.log('  flip      - Perform the shadow to canonical flip');
      console.log('  dry-run   - Show what would be done without doing it');
      break;
  }
}



