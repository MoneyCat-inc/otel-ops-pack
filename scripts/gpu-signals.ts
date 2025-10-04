#!/usr/bin/env tsx
/**
 * 🐾 BossCat GPU Health Signals for SigNoz
 * Observability integration for GPU Pattern-Sifter EPIC
 * Lane T6 - GPU health monitoring and fallback detection
 */

import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

interface GPUHealthSignal {
  timestamp: string;
  source: string;
  level: 'info' | 'warning' | 'error';
  message: string;
  metrics: {
    gpu_available: boolean;
    fallback_triggered: boolean;
    performance_ratio: number;
    algorithm: string;
    provider: string;
  };
  tags: {
    environment: string;
    epic: string;
    lane: string;
  };
}

interface GPUHealthReport {
  timestamp: string;
  summary: {
    total_signals: number;
    warnings: number;
    errors: number;
    fallback_events: number;
    avg_performance: number;
  };
  signals: GPUHealthSignal[];
}

class SigNozGPUHealthMonitor {
  private signalsDir: string;
  private reportDir: string;

  constructor() {
    this.signalsDir = 'docs/ecrr/ECRR_REPORTS';
    this.reportDir = 'docs/observability';
    
    // Ensure directories exist
    this.ensureDirectories();
  }

  private ensureDirectories(): void {
    if (!fs.existsSync(this.signalsDir)) {
      fs.mkdirSync(this.signalsDir, { recursive: true });
    }
    if (!fs.existsSync(this.reportDir)) {
      fs.mkdirSync(this.reportDir, { recursive: true });
    }
  }

  private detectEnvironment(): string {
    try {
      const version = fs.readFileSync('/proc/version', 'utf8');
      if (version.toLowerCase().includes('microsoft')) {
        return 'wsl';
      }
    } catch {
      // Not WSL
    }
    
    return process.platform === 'win32' ? 'windows' : 'linux';
  }

  private async runRollingStatsCheck(): Promise<GPUHealthSignal> {
    try {
      console.log('🔍 Checking rolling stats health...');
      
      // Run rolling stats harness
      const output = execSync('python rolling_run.py', { encoding: 'utf8', timeout: 30000 });
      
      // Parse evidence
      const evidenceFile = path.join(this.signalsDir, 'rolling_stats_evidence.json');
      const evidence = JSON.parse(fs.readFileSync(evidenceFile, 'utf8'));
      
      const performanceRatio = evidence.timings.cpuMs / evidence.timings.gpuMs;
      const level = evidence.run.fellBackToCpu ? 'warning' : 'info';
      
      return {
        timestamp: evidence.ts,
        source: 'rolling_stats_harness',
        level,
        message: evidence.run.fellBackToCpu 
          ? `GPU fallback triggered for rolling stats - using CPU provider`
          : `Rolling stats running on GPU - ${performanceRatio.toFixed(1)}x speedup`,
        metrics: {
          gpu_available: evidence.env.providers.includes('cuda'),
          fallback_triggered: evidence.run.fellBackToCpu,
          performance_ratio: performanceRatio,
          algorithm: evidence.algo,
          provider: evidence.run.providerFinal
        },
        tags: {
          environment: this.detectEnvironment(),
          epic: 'gpu-pattern-sifter',
          lane: 't1-rolling-stats'
        }
      };
    } catch (error) {
      return {
        timestamp: new Date().toISOString(),
        source: 'rolling_stats_harness',
        level: 'error',
        message: `Rolling stats health check failed: ${error.message}`,
        metrics: {
          gpu_available: false,
          fallback_triggered: true,
          performance_ratio: 0,
          algorithm: 'rolling',
          provider: 'cpu'
        },
        tags: {
          environment: this.detectEnvironment(),
          epic: 'gpu-pattern-sifter',
          lane: 't1-rolling-stats'
        }
      };
    }
  }

  private async runPFACCheck(): Promise<GPUHealthSignal> {
    try {
      console.log('🔍 Checking PFAC health...');
      
      // Run PFAC harness
      const output = execSync('python pfac_run.py', { encoding: 'utf8', timeout: 30000 });
      
      // Parse evidence
      const evidenceFile = path.join(this.signalsDir, 'pfac_scan_evidence.json');
      const evidence = JSON.parse(fs.readFileSync(evidenceFile, 'utf8'));
      
      const performanceRatio = evidence.timings.cpuMs / evidence.timings.gpuMs;
      const level = evidence.run.fellBackToCpu ? 'warning' : 'info';
      
      return {
        timestamp: evidence.ts,
        source: 'pfac_scan_harness',
        level,
        message: evidence.run.fellBackToCpu 
          ? `GPU fallback triggered for PFAC - using CPU provider`
          : `PFAC running on GPU - ${performanceRatio.toFixed(1)}x speedup, ${evidence.parity.matches} matches`,
        metrics: {
          gpu_available: evidence.env.providers.includes('cuda'),
          fallback_triggered: evidence.run.fellBackToCpu,
          performance_ratio: performanceRatio,
          algorithm: evidence.algo,
          provider: evidence.run.providerFinal
        },
        tags: {
          environment: this.detectEnvironment(),
          epic: 'gpu-pattern-sifter',
          lane: 't4-pfac-scan'
        }
      };
    } catch (error) {
      return {
        timestamp: new Date().toISOString(),
        source: 'pfac_scan_harness',
        level: 'error',
        message: `PFAC health check failed: ${error.message}`,
        metrics: {
          gpu_available: false,
          fallback_triggered: true,
          performance_ratio: 0,
          algorithm: 'pfac',
          provider: 'cpu'
        },
        tags: {
          environment: this.detectEnvironment(),
          epic: 'gpu-pattern-sifter',
          lane: 't4-pfac-scan'
        }
      };
    }
  }

  private async checkCUDAHealth(): Promise<GPUHealthSignal> {
    try {
      console.log('🔍 Checking CUDA health...');
      
      // Check nvidia-smi
      const output = execSync('nvidia-smi', { encoding: 'utf8', timeout: 10000 });
      
      return {
        timestamp: new Date().toISOString(),
        source: 'cuda_health_check',
        level: 'info',
        message: `CUDA available - GPU health check passed`,
        metrics: {
          gpu_available: true,
          fallback_triggered: false,
          performance_ratio: 1.0,
          algorithm: 'system',
          provider: 'cuda'
        },
        tags: {
          environment: this.detectEnvironment(),
          epic: 'gpu-pattern-sifter',
          lane: 'system'
        }
      };
    } catch (error) {
      return {
        timestamp: new Date().toISOString(),
        source: 'cuda_health_check',
        level: 'warning',
        message: `CUDA not available - ${error.message}`,
        metrics: {
          gpu_available: false,
          fallback_triggered: true,
          performance_ratio: 0,
          algorithm: 'system',
          provider: 'cpu'
        },
        tags: {
          environment: this.detectEnvironment(),
          epic: 'gpu-pattern-sifter',
          lane: 'system'
        }
      };
    }
  }

  async generateHealthReport(): Promise<GPUHealthReport> {
    console.log('🐾 BossCat GPU Health Signal Monitor');
    console.log('Generating SigNoz observability signals...');
    
    const signals: GPUHealthSignal[] = [];
    
    // Run health checks
    signals.push(await this.checkCUDAHealth());
    signals.push(await this.runRollingStatsCheck());
    signals.push(await this.runPFACCheck());
    
    // Calculate summary
    const summary = {
      total_signals: signals.length,
      warnings: signals.filter(s => s.level === 'warning').length,
      errors: signals.filter(s => s.level === 'error').length,
      fallback_events: signals.filter(s => s.metrics.fallback_triggered).length,
      avg_performance: signals.reduce((sum, s) => sum + s.metrics.performance_ratio, 0) / signals.length
    };
    
    const report: GPUHealthReport = {
      timestamp: new Date().toISOString(),
      summary,
      signals
    };
    
    // Save report
    await this.saveHealthReport(report);
    
    // Generate SigNoz dashboard data
    await this.generateSigNozDashboard(report);
    
    return report;
  }

  private async saveHealthReport(report: GPUHealthReport): Promise<void> {
    const filename = `gpu_health_${new Date().toISOString().split('T')[0]}.json`;
    const filepath = path.join(this.reportDir, filename);
    
    fs.writeFileSync(filepath, JSON.stringify(report, null, 2));
    console.log(`📊 Health report saved to: ${filepath}`);
  }

  private async generateSigNozDashboard(report: GPUHealthReport): Promise<void> {
    const dashboardPath = path.join(this.reportDir, 'gpu-health-dashboard.md');
    
    const dashboard = this.createSigNozDashboardMarkdown(report);
    fs.writeFileSync(dashboardPath, dashboard);
    console.log(`📈 SigNoz dashboard updated: ${dashboardPath}`);
  }

  private createSigNozDashboardMarkdown(report: GPUHealthReport): string {
    const timestamp = new Date().toISOString();
    
    return `# 🐾 BossCat GPU Health Dashboard - SigNoz Integration

**Generated:** ${timestamp}  
**Report Date:** ${report.timestamp.split('T')[0]}  
**Epic:** [GPU Pattern-Sifter EPIC](../ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)

## 🚨 **Health Summary**

- **Total Signals:** ${report.summary.total_signals}
- **Warnings:** ${report.summary.warnings} ⚠️
- **Errors:** ${report.summary.errors} ❌
- **Fallback Events:** ${report.summary.fallback_events} 🔄
- **Average Performance:** ${report.summary.avg_performance.toFixed(1)}x

## 📊 **SigNoz Queries**

### **GPU Health Metrics**
\`\`\`
# GPU Availability
gpu_available{epic="gpu-pattern-sifter"}

# Fallback Events
fallback_triggered{epic="gpu-pattern-sifter"}

# Performance Ratio
performance_ratio{epic="gpu-pattern-sifter",algorithm="rolling"}
performance_ratio{epic="gpu-pattern-sifter",algorithm="pfac"}
\`\`\`

### **Alert Rules**
\`\`\`
# Alert on GPU Fallback
ALERT GPUFallbackDetected
  IF fallback_triggered{epic="gpu-pattern-sifter"} == 1
  FOR 5m
  LABELS {severity="warning"}
  ANNOTATIONS {summary="GPU fallback detected", description="GPU Pattern-Sifter fell back to CPU"}

# Alert on Performance Degradation
ALERT GPUPPerformanceDegradation
  IF performance_ratio{epic="gpu-pattern-sifter"} < 1.0
  FOR 10m
  LABELS {severity="warning"}
  ANNOTATIONS {summary="GPU performance degraded", description="GPU is slower than CPU"}
\`\`\`

## 🔍 **Signal Details**

${report.signals.map(signal => `
### ${signal.source}

- **Level:** ${signal.level.toUpperCase()}
- **Message:** ${signal.message}
- **GPU Available:** ${signal.metrics.gpu_available ? '✅' : '❌'}
- **Fallback:** ${signal.metrics.fallback_triggered ? '⚠️ Yes' : '✅ No'}
- **Performance:** ${signal.metrics.performance_ratio.toFixed(1)}x
- **Provider:** ${signal.metrics.provider}
- **Algorithm:** ${signal.metrics.algorithm}
- **Environment:** ${signal.tags.environment}
- **Timestamp:** ${signal.timestamp}
`).join('\n')}

## 🎯 **SigNoz Dashboard Configuration**

### **Metrics to Track**
1. **GPU Availability:** Monitor CUDA health
2. **Fallback Events:** Track CPU fallbacks
3. **Performance Ratios:** GPU vs CPU speedup
4. **Algorithm Health:** Rolling stats and PFAC status

### **Alert Thresholds**
- **Warning:** GPU fallback detected
- **Critical:** Multiple fallbacks or performance < 0.5x
- **Info:** Normal GPU operation

## 📁 **Raw Data**

- **Health Report:** [gpu_health_${report.timestamp.split('T')[0]}.json](./gpu_health_${report.timestamp.split('T')[0]}.json)
- **Evidence Files:** [ECRR Reports](../ecrr/ECRR_REPORTS/)
- **Benchmark Results:** [Performance Dashboard](../bench/index.md)

---

*Generated by BossCat GPU Health Monitor - Lane T6*
`;
  }
}

async function main() {
  const monitor = new SigNozGPUHealthMonitor();
  
  try {
    const report = await monitor.generateHealthReport();
    
    console.log('\n🎉 BossCat GPU Health Monitor Complete!');
    console.log(`📊 Signals: ${report.summary.total_signals}`);
    console.log(`⚠️  Warnings: ${report.summary.warnings}`);
    console.log(`❌ Errors: ${report.summary.errors}`);
    console.log(`🔄 Fallbacks: ${report.summary.fallback_events}`);
    console.log(`🚀 Avg Performance: ${report.summary.avg_performance.toFixed(1)}x`);
    
    console.log('\n✅ SigNoz observability integration ready');
    console.log('📈 Health dashboard generated');
    
  } catch (error) {
    console.error('❌ Health monitor failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { SigNozGPUHealthMonitor, GPUHealthSignal, GPUHealthReport };
