/**
 * Shadow vs Canonical Verification Script
 * Compares shadow and canonical artifacts to ensure they're byte-identical
 * before flipping from shadow to canonical writes
 */

import { compareShadowVsCanonical, readShadowArtifact } from './io';
import { existsSync, readFileSync } from 'fs';

export interface VerificationResult {
  artifact: string;
  identical: boolean;
  canonicalExists: boolean;
  shadowExists: boolean;
  differences?: string[];
  canonicalSize?: number;
  shadowSize?: number;
}

export interface VerificationReport {
  timestamp: string;
  totalArtifacts: number;
  identicalArtifacts: number;
  differentArtifacts: number;
  missingCanonical: number;
  missingShadow: number;
  results: VerificationResult[];
  summary: string;
}

export class ShadowCanonicalVerifier {
  private artifacts: string[] = [
    '.agent/status.json',
    '.agent/agent_queue.json',
    '.agent/runs.json',
    '.agent/config.json',
    '.agent/state.json',
  ];

  /**
   * Verify all artifacts between shadow and canonical
   */
  verifyAll(): VerificationReport {
    const results: VerificationResult[] = [];
    let identicalCount = 0;
    let differentCount = 0;
    let missingCanonicalCount = 0;
    let missingShadowCount = 0;

    console.log('=== Shadow vs Canonical Verification ===\n');

    for (const artifact of this.artifacts) {
      const result = this.verifyArtifact(artifact);
      results.push(result);

      if (result.identical) {
        identicalCount++;
        console.log(`✓ ${artifact}: IDENTICAL`);
      } else if (!result.canonicalExists) {
        missingCanonicalCount++;
        console.log(`⚠ ${artifact}: MISSING CANONICAL`);
      } else if (!result.shadowExists) {
        missingShadowCount++;
        console.log(`⚠ ${artifact}: MISSING SHADOW`);
      } else {
        differentCount++;
        console.log(`✗ ${artifact}: DIFFERENT`);
        if (result.differences) {
          result.differences.slice(0, 3).forEach(diff => {
            console.log(`  - ${diff}`);
          });
        }
      }
    }

    const report: VerificationReport = {
      timestamp: new Date().toISOString(),
      totalArtifacts: this.artifacts.length,
      identicalArtifacts: identicalCount,
      differentArtifacts: differentCount,
      missingCanonical: missingCanonicalCount,
      missingShadow: missingShadowCount,
      results,
      summary: this.generateSummary(identicalCount, differentCount, missingCanonicalCount, missingShadowCount),
    };

    console.log(`\n${report.summary}`);
    return report;
  }

  /**
   * Verify a single artifact
   */
  private verifyArtifact(artifact: string): VerificationResult {
    const comparison = compareShadowVsCanonical(artifact);
    
    let canonicalSize: number | undefined;
    let shadowSize: number | undefined;

    if (comparison.canonicalExists) {
      try {
        const canonicalContent = readFileSync(artifact, 'utf8');
        canonicalSize = canonicalContent.length;
      } catch (error) {
        console.warn(`Failed to read canonical ${artifact}:`, error);
      }
    }

    if (comparison.shadowExists) {
      try {
        const shadowContent = readShadowArtifact(artifact);
        if (shadowContent) {
          shadowSize = shadowContent.length;
        }
      } catch (error) {
        console.warn(`Failed to read shadow ${artifact}:`, error);
      }
    }

    return {
      artifact,
      identical: comparison.identical,
      canonicalExists: comparison.canonicalExists,
      shadowExists: comparison.shadowExists,
      differences: comparison.differences,
      canonicalSize,
      shadowSize,
    };
  }

  /**
   * Generate verification summary
   */
  private generateSummary(
    identical: number,
    different: number,
    missingCanonical: number,
    missingShadow: number
  ): string {
    const total = this.artifacts.length;
    const identicalPercent = Math.round((identical / total) * 100);
    
    if (identical === total) {
      return `🎉 ALL ARTIFACTS IDENTICAL (${identical}/${total}) - Ready for canonical flip!`;
    } else if (different === 0 && missingCanonical === 0) {
      return `✅ Shadow artifacts complete (${identical}/${total}) - Ready for canonical flip!`;
    } else if (different > 0) {
      return `❌ ${different} artifacts differ - NOT ready for canonical flip`;
    } else {
      return `⚠️ ${missingCanonical} canonical artifacts missing - Run shadow mode first`;
    }
  }

  /**
   * Check if ready for canonical flip
   */
  isReadyForCanonicalFlip(): boolean {
    const report = this.verifyAll();
    return report.differentArtifacts === 0 && report.missingCanonical === 0;
  }

  /**
   * Generate detailed report
   */
  generateDetailedReport(): string {
    const report = this.verifyAll();
    
    let output = `# Shadow vs Canonical Verification Report\n\n`;
    output += `**Generated:** ${report.timestamp}\n`;
    output += `**Total Artifacts:** ${report.totalArtifacts}\n`;
    output += `**Identical:** ${report.identicalArtifacts}\n`;
    output += `**Different:** ${report.differentArtifacts}\n`;
    output += `**Missing Canonical:** ${report.missingCanonical}\n`;
    output += `**Missing Shadow:** ${report.missingShadow}\n\n`;
    
    output += `## Summary\n\n${report.summary}\n\n`;
    
    output += `## Detailed Results\n\n`;
    
    for (const result of report.results) {
      output += `### ${result.artifact}\n\n`;
      output += `- **Status:** ${result.identical ? 'IDENTICAL' : 'DIFFERENT'}\n`;
      output += `- **Canonical Exists:** ${result.canonicalExists ? 'Yes' : 'No'}\n`;
      output += `- **Shadow Exists:** ${result.shadowExists ? 'Yes' : 'No'}\n`;
      
      if (result.canonicalSize !== undefined) {
        output += `- **Canonical Size:** ${result.canonicalSize} bytes\n`;
      }
      if (result.shadowSize !== undefined) {
        output += `- **Shadow Size:** ${result.shadowSize} bytes\n`;
      }
      
      if (result.differences && result.differences.length > 0) {
        output += `- **Differences:**\n`;
        result.differences.forEach(diff => {
          output += `  - ${diff}\n`;
        });
      }
      
      output += `\n`;
    }
    
    return output;
  }

  /**
   * Run verification cycles to ensure stability
   */
  async runStabilityTest(cycles: number = 3, intervalMs: number = 5000): Promise<boolean> {
    console.log(`Running ${cycles} verification cycles with ${intervalMs}ms intervals...\n`);
    
    const results: VerificationReport[] = [];
    
    for (let i = 0; i < cycles; i++) {
      console.log(`Cycle ${i + 1}/${cycles}:`);
      const report = this.verifyAll();
      results.push(report);
      
      if (i < cycles - 1) {
        console.log(`\nWaiting ${intervalMs}ms before next cycle...\n`);
        await new Promise(resolve => setTimeout(resolve, intervalMs));
      }
    }
    
    // Check if all cycles were identical
    const allIdentical = results.every(report => report.differentArtifacts === 0);
    
    if (allIdentical) {
      console.log(`\n🎉 All ${cycles} cycles were identical - System is stable!`);
    } else {
      console.log(`\n❌ Not all cycles were identical - System may be unstable`);
    }
    
    return allIdentical;
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const command = args[0] || 'verify';
  
  const verifier = new ShadowCanonicalVerifier();
  
  switch (command) {
    case 'verify':
      verifier.verifyAll();
      break;
      
    case 'ready':
      const ready = verifier.isReadyForCanonicalFlip();
      console.log(ready ? '✅ Ready for canonical flip' : '❌ Not ready for canonical flip');
      process.exit(ready ? 0 : 1);
      break;
      
    case 'report':
      const report = verifier.generateDetailedReport();
      console.log(report);
      break;
      
    case 'stability':
      const cycles = parseInt(args[1]) || 3;
      const interval = parseInt(args[2]) || 5000;
      verifier.runStabilityTest(cycles, interval).then(stable => {
        process.exit(stable ? 0 : 1);
      });
      break;
      
    default:
      console.log('Usage:');
      console.log('  verify     - Run verification');
      console.log('  ready      - Check if ready for canonical flip');
      console.log('  report     - Generate detailed report');
      console.log('  stability  - Run stability test');
      break;
  }
}



