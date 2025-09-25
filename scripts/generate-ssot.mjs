#!/usr/bin/env node
/**
 * SSOT Report Generator
 * Part of the push-button automation system
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { execSync } from 'child_process';

class SSOTGenerator {
  constructor() {
    this.report = {
      timestamp: new Date().toISOString(),
      overall_status: 'UNKNOWN',
      summary: { total_tests: 0, passed_tests: 0, failed_tests: 0 },
      components: {},
      system_health: {}
    };
  }

  async generateReport() {
    console.log('🔍 Generating SSOT report...');
    
    try {
      await this.gatherTestResults();
      await this.gatherSystemHealth();
      this.calculateOverallStatus();
      await this.saveReport();
      
      console.log('✅ SSOT report generated successfully');
      
    } catch (error) {
      console.error('❌ Failed to generate SSOT report:', error.message);
      process.exit(1);
    }
  }

  async gatherTestResults() {
    console.log('📊 Gathering test results...');
    
    // Check for Playwright report
    const playwrightReport = 'playwright-report/index.html';
    if (existsSync(playwrightReport)) {
      this.report.components.playwright = { status: 'COMPLETED', report_path: playwrightReport };
    } else {
      this.report.components.playwright = { status: 'NO_REPORT' };
    }
    
    // Check for PowerShell artifacts
    const artifactsDir = 'artifacts';
    if (existsSync(artifactsDir)) {
      this.report.components.powershell = { status: 'COMPLETED', artifacts_dir: artifactsDir };
    } else {
      this.report.components.powershell = { status: 'NO_ARTIFACTS' };
    }
    
    // Check for integration verification
    const verificationFile = 'artifacts/full-stack-verification.json';
    if (existsSync(verificationFile)) {
      const verificationData = JSON.parse(readFileSync(verificationFile, 'utf8'));
      this.report.components.integration = { 
        status: verificationData.overall_status || 'UNKNOWN',
        verification_data: verificationData
      };
    } else {
      this.report.components.integration = { status: 'NO_VERIFICATION' };
    }
    
    this.updateTestSummary();
  }

  updateTestSummary() {
    let totalTests = 0;
    let passedTests = 0;
    let failedTests = 0;
    
    Object.values(this.report.components).forEach(result => {
      totalTests++;
      if (result.status === 'COMPLETED' || result.status === 'PASS') {
        passedTests++;
      } else if (result.status === 'FAIL') {
        failedTests++;
      }
    });
    
    this.report.summary.total_tests = totalTests;
    this.report.summary.passed_tests = passedTests;
    this.report.summary.failed_tests = failedTests;
  }

  async gatherSystemHealth() {
    console.log('🏥 Gathering system health...');
    
    // Docker health
    try {
      execSync('docker info', { encoding: 'utf8' });
      this.report.system_health.docker = { status: 'HEALTHY' };
    } catch (error) {
      this.report.system_health.docker = { status: 'UNHEALTHY', error: error.message };
    }
    
    // SigNoz health
    try {
      const response = await fetch('http://localhost:8080/api/v1/health');
      this.report.system_health.signoz = { 
        status: response.ok ? 'HEALTHY' : 'UNHEALTHY',
        response_code: response.status
      };
    } catch (error) {
      this.report.system_health.signoz = { status: 'UNHEALTHY', error: error.message };
    }
    
    // OTel health
    try {
      const response = await fetch('http://localhost:13134');
      this.report.system_health.otel = { 
        status: response.ok ? 'HEALTHY' : 'UNHEALTHY'
      };
    } catch (error) {
      this.report.system_health.otel = { status: 'UNHEALTHY', error: error.message };
    }
  }

  calculateOverallStatus() {
    const { total_tests, passed_tests, failed_tests } = this.report.summary;
    
    if (total_tests === 0) {
      this.report.overall_status = 'UNKNOWN';
    } else if (failed_tests === 0) {
      this.report.overall_status = 'PASS';
    } else if (failed_tests < total_tests / 2) {
      this.report.overall_status = 'WARN';
    } else {
      this.report.overall_status = 'FAIL';
    }
  }

  async saveReport() {
    const reportPath = 'artifacts/ssot-report.json';
    
    const artifactsDir = 'artifacts';
    if (!existsSync(artifactsDir)) {
      execSync(`mkdir -p ${artifactsDir}`);
    }
    
    writeFileSync(reportPath, JSON.stringify(this.report, null, 2));
    
    const summaryPath = 'artifacts/ssot-summary.txt';
    const summary = this.generateSummary();
    writeFileSync(summaryPath, summary);
    
    console.log(`📄 SSOT report saved: ${reportPath}`);
    console.log(`📄 SSOT summary saved: ${summaryPath}`);
  }

  generateSummary() {
    const { overall_status, summary, system_health } = this.report;
    
    return `SSOT Report Summary
==================
Generated: ${new Date().toISOString()}
Overall Status: ${overall_status}

Test Results:
-------------
Total Tests: ${summary.total_tests}
Passed: ${summary.passed_tests}
Failed: ${summary.failed_tests}

System Health:
--------------
Docker: ${system_health.docker?.status || 'UNKNOWN'}
SigNoz: ${system_health.signoz?.status || 'UNKNOWN'}
OTel: ${system_health.otel?.status || 'UNKNOWN'}
`;
  }
}

async function main() {
  const generator = new SSOTGenerator();
  await generator.generateReport();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { SSOTGenerator };