#!/usr/bin/env node

/**
 * ECRR Compliance Engine - Automated compliance checking and reporting
 * 
 * This module enforces ECRR (Examine → Clean → Report → Role) methodology
 * across all agents and generates compliance reports.
 */

import { promises as fs } from 'fs';
import path from 'path';
import crypto from 'crypto';

interface ECRRReport {
  id: string;
  taskId: string;
  agentId: string;
  examine: ECRRExamine;
  clean: ECRRClean;
  report: ECRRReport;
  role: ECRRRole;
  compliance: boolean;
  createdAt: string;
  validatedAt?: string;
}

interface ECRRExamine {
  timestamp: string;
  environment: any;
  state: any;
  evidence: string[];
  artifacts: string[];
}

interface ECRRClean {
  actions: string[];
  changes: any[];
  rollback: any[];
  guardrails: string[];
  budget: {
    files: number;
    lines: number;
    jobs: number;
  };
}

interface ECRRReport {
  artifacts: string[];
  metrics: any;
  compliance: boolean;
  violations: string[];
  recommendations: string[];
}

interface ECRRRole {
  actor: string;
  responsibility: string;
  signature: string;
  accountability: string[];
}

interface ComplianceRule {
  id: string;
  name: string;
  description: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  check: (report: ECRRReport) => boolean;
  message: string;
}

class ECRRComplianceEngine {
  private rules: Map<string, ComplianceRule> = new Map();
  private reports: Map<string, ECRRReport> = new Map();
  private complianceHistory: ECRRReport[] = [];

  constructor() {
    this.initializeRules();
    this.loadExistingReports();
  }

  private initializeRules(): void {
    const rules: ComplianceRule[] = [
      {
        id: 'examine-required',
        name: 'Examine Section Required',
        description: 'All ECRR reports must have an examine section',
        severity: 'critical',
        check: (report) => report.examine && report.examine.timestamp && report.examine.evidence.length > 0,
        message: 'ECRR report missing examine section or evidence'
      },
      {
        id: 'clean-required',
        name: 'Clean Section Required',
        description: 'All ECRR reports must have a clean section',
        severity: 'critical',
        check: (report) => report.clean && report.clean.actions.length > 0,
        message: 'ECRR report missing clean section or actions'
      },
      {
        id: 'report-required',
        name: 'Report Section Required',
        description: 'All ECRR reports must have a report section',
        severity: 'critical',
        check: (report) => report.report && report.report.artifacts.length > 0,
        message: 'ECRR report missing report section or artifacts'
      },
      {
        id: 'role-required',
        name: 'Role Section Required',
        description: 'All ECRR reports must have a role section',
        severity: 'critical',
        check: (report) => report.role && report.role.actor && report.role.signature,
        message: 'ECRR report missing role section or signature'
      },
      {
        id: 'budget-compliance',
        name: 'Budget Compliance',
        description: 'Changes must respect budget limits',
        severity: 'high',
        check: (report) => {
          const budget = report.clean.budget;
          return budget.files <= 10 && budget.lines <= 200 && budget.jobs <= 2;
        },
        message: 'ECRR report exceeds budget limits'
      },
      {
        id: 'guardrails-enforced',
        name: 'Guardrails Enforced',
        description: 'All guardrails must be documented',
        severity: 'high',
        check: (report) => report.clean.guardrails.length > 0,
        message: 'ECRR report missing guardrails documentation'
      },
      {
        id: 'rollback-planned',
        name: 'Rollback Plan',
        description: 'All changes must have rollback plans',
        severity: 'medium',
        check: (report) => report.clean.rollback.length > 0,
        message: 'ECRR report missing rollback plan'
      },
      {
        id: 'artifacts-generated',
        name: 'Artifacts Generated',
        description: 'All changes must generate artifacts',
        severity: 'medium',
        check: (report) => report.report.artifacts.length > 0,
        message: 'ECRR report missing generated artifacts'
      },
      {
        id: 'metrics-collected',
        name: 'Metrics Collected',
        description: 'All changes must collect metrics',
        severity: 'low',
        check: (report) => report.report.metrics && Object.keys(report.report.metrics).length > 0,
        message: 'ECRR report missing metrics collection'
      },
      {
        id: 'signature-valid',
        name: 'Valid Signature',
        description: 'All reports must have valid signatures',
        severity: 'critical',
        check: (report) => {
          const signature = report.role.signature;
          return signature && signature.includes(report.agentId) && signature.includes('agent-');
        },
        message: 'ECRR report has invalid signature'
      }
    ];

    rules.forEach(rule => {
      this.rules.set(rule.id, rule);
    });
  }

  async validateReport(report: ECRRReport): Promise<{ valid: boolean; violations: string[] }> {
    const violations: string[] = [];
    
    for (const [ruleId, rule] of this.rules) {
      try {
        if (!rule.check(report)) {
          violations.push(`${rule.severity.toUpperCase()}: ${rule.message} (${ruleId})`);
        }
      } catch (error) {
        violations.push(`ERROR: Rule ${ruleId} failed to execute: ${error.message}`);
      }
    }

    const valid = violations.length === 0;
    
    // Update report compliance status
    report.compliance = valid;
    report.report.violations = violations;
    report.validatedAt = new Date().toISOString();

    // Store the report
    this.reports.set(report.id, report);
    this.complianceHistory.push(report);

    // Save to file
    await this.saveReport(report);

    return { valid, violations };
  }

  async generateReport(
    taskId: string,
    agentId: string,
    examine: ECRRExamine,
    clean: ECRRClean,
    report: ECRRReport,
    role: ECRRRole
  ): Promise<ECRRReport> {
    const reportId = this.generateReportId();
    const now = new Date().toISOString();

    const ecrrReport: ECRRReport = {
      id: reportId,
      taskId,
      agentId,
      examine,
      clean,
      report,
      role,
      compliance: false, // Will be set by validation
      createdAt: now
    };

    // Validate the report
    const validation = await this.validateReport(ecrrReport);
    
    if (!validation.valid) {
      console.warn(`⚠️ ECRR compliance violations for report ${reportId}:`, validation.violations);
    }

    return ecrrReport;
  }

  async getComplianceStats(): Promise<any> {
    const totalReports = this.complianceHistory.length;
    const compliantReports = this.complianceHistory.filter(r => r.compliance).length;
    const nonCompliantReports = totalReports - compliantReports;
    const complianceRate = totalReports > 0 ? (compliantReports / totalReports) * 100 : 0;

    // Count violations by severity
    const violationsBySeverity: any = {};
    this.complianceHistory.forEach(report => {
      if (!report.compliance) {
        report.report.violations.forEach(violation => {
          const severity = violation.split(':')[0];
          violationsBySeverity[severity] = (violationsBySeverity[severity] || 0) + 1;
        });
      }
    });

    // Recent compliance trend (last 10 reports)
    const recentReports = this.complianceHistory.slice(-10);
    const recentCompliant = recentReports.filter(r => r.compliance).length;
    const recentComplianceRate = recentReports.length > 0 ? (recentCompliant / recentReports.length) * 100 : 0;

    return {
      totalReports,
      compliantReports,
      nonCompliantReports,
      complianceRate: Math.round(complianceRate * 100) / 100,
      recentComplianceRate: Math.round(recentComplianceRate * 100) / 100,
      violationsBySeverity,
      trend: recentComplianceRate > complianceRate ? 'improving' : 'declining'
    };
  }

  async getAgentComplianceStats(agentId: string): Promise<any> {
    const agentReports = this.complianceHistory.filter(r => r.agentId === agentId);
    const totalReports = agentReports.length;
    const compliantReports = agentReports.filter(r => r.compliance).length;
    const complianceRate = totalReports > 0 ? (compliantReports / totalReports) * 100 : 0;

    // Common violations for this agent
    const commonViolations: any = {};
    agentReports.forEach(report => {
      if (!report.compliance) {
        report.report.violations.forEach(violation => {
          const ruleId = violation.match(/\(([^)]+)\)/)?.[1];
          if (ruleId) {
            commonViolations[ruleId] = (commonViolations[ruleId] || 0) + 1;
          }
        });
      }
    });

    return {
      agentId,
      totalReports,
      compliantReports,
      complianceRate: Math.round(complianceRate * 100) / 100,
      commonViolations
    };
  }

  async generateComplianceReport(): Promise<string> {
    const stats = await this.getComplianceStats();
    const now = new Date().toISOString();

    const report = `# ECRR Compliance Report

**Generated**: ${now}  
**Total Reports**: ${stats.totalReports}  
**Compliance Rate**: ${stats.complianceRate}%  
**Recent Trend**: ${stats.trend}  

## 📊 Overall Statistics

- **Compliant Reports**: ${stats.compliantReports}
- **Non-Compliant Reports**: ${stats.nonCompliantReports}
- **Recent Compliance Rate**: ${stats.recentComplianceRate}%

## 🚨 Violations by Severity

${Object.entries(stats.violationsBySeverity).map(([severity, count]) => 
  `- **${severity}**: ${count} violations`
).join('\n')}

## 🎯 Recommendations

${this.generateRecommendations(stats)}

## 📋 Recent Reports

${this.complianceHistory.slice(-5).map(report => 
  `- **${report.id}** (${report.agentId}): ${report.compliance ? '✅ Compliant' : '❌ Non-compliant'}`
).join('\n')}

---

*This report is automatically generated by the ECRR Compliance Engine.*
`;

    return report;
  }

  private generateRecommendations(stats: any): string {
    const recommendations: string[] = [];

    if (stats.complianceRate < 95) {
      recommendations.push('⚠️ **Compliance rate below 95%** - Review and fix common violations');
    }

    if (stats.violationsBySeverity.CRITICAL > 0) {
      recommendations.push('🚨 **Critical violations detected** - Address immediately');
    }

    if (stats.trend === 'declining') {
      recommendations.push('📉 **Compliance trend declining** - Implement additional training');
    }

    if (stats.violationsBySeverity.HIGH > stats.totalReports * 0.1) {
      recommendations.push('🔧 **High-severity violations frequent** - Review guardrails');
    }

    if (recommendations.length === 0) {
      recommendations.push('✅ **All systems green** - Maintain current practices');
    }

    return recommendations.join('\n');
  }

  async exportComplianceData(): Promise<any> {
    return {
      reports: Array.from(this.reports.values()),
      history: this.complianceHistory,
      rules: Array.from(this.rules.values()),
      stats: await this.getComplianceStats(),
      exportedAt: new Date().toISOString()
    };
  }

  async importComplianceData(data: any): Promise<void> {
    if (data.reports) {
      data.reports.forEach((report: ECRRReport) => {
        this.reports.set(report.id, report);
      });
    }

    if (data.history) {
      this.complianceHistory = data.history;
    }

    // Save all reports to files
    for (const report of this.reports.values()) {
      await this.saveReport(report);
    }
  }

  private async saveReport(report: ECRRReport): Promise<void> {
    const reportDir = 'docs/ECRR_REPORTS';
    await fs.mkdir(reportDir, { recursive: true });
    
    const filename = `${report.createdAt.split('T')[0]}-${report.id}.md`;
    const filepath = path.join(reportDir, filename);
    
    const reportContent = this.formatReportAsMarkdown(report);
    await fs.writeFile(filepath, reportContent);
  }

  private formatReportAsMarkdown(report: ECRRReport): string {
    return `# ECRR Report: ${report.id}

**Agent**: ${report.agentId}  
**Task**: ${report.taskId}  
**Created**: ${report.createdAt}  
**Compliance**: ${report.compliance ? '✅ Compliant' : '❌ Non-compliant'}  

## 🔍 Examine

**Timestamp**: ${report.examine.timestamp}  
**Environment**: ${JSON.stringify(report.examine.environment, null, 2)}  
**State**: ${JSON.stringify(report.examine.state, null, 2)}  

**Evidence**:
${report.examine.evidence.map(e => `- ${e}`).join('\n')}

**Artifacts**:
${report.examine.artifacts.map(a => `- ${a}`).join('\n')}

## 🧹 Clean

**Actions**:
${report.clean.actions.map(a => `- ${a}`).join('\n')}

**Changes**:
${report.clean.changes.map(c => `- ${JSON.stringify(c)}`).join('\n')}

**Rollback**:
${report.clean.rollback.map(r => `- ${JSON.stringify(r)}`).join('\n')}

**Guardrails**:
${report.clean.guardrails.map(g => `- ${g}`).join('\n')}

**Budget**: ${report.clean.budget.files} files, ${report.clean.budget.lines} lines, ${report.clean.budget.jobs} jobs

## 📝 Report

**Artifacts**:
${report.report.artifacts.map(a => `- ${a}`).join('\n')}

**Metrics**:
${JSON.stringify(report.report.metrics, null, 2)}

**Violations**:
${report.report.violations.map(v => `- ${v}`).join('\n')}

**Recommendations**:
${report.report.recommendations.map(r => `- ${r}`).join('\n')}

## 🎭 Role

**Actor**: ${report.role.actor}  
**Responsibility**: ${report.role.responsibility}  
**Signature**: ${report.role.signature}  

**Accountability**:
${report.role.accountability.map(a => `- ${a}`).join('\n')}

---

*Generated by ECRR Compliance Engine*
`;
  }

  private async loadExistingReports(): Promise<void> {
    try {
      const reportDir = 'docs/ECRR_REPORTS';
      const files = await fs.readdir(reportDir);
      
      for (const file of files) {
        if (file.endsWith('.md')) {
          try {
            const content = await fs.readFile(path.join(reportDir, file), 'utf-8');
            const report = this.parseMarkdownReport(content);
            if (report) {
              this.reports.set(report.id, report);
              this.complianceHistory.push(report);
            }
          } catch (error) {
            console.warn(`Failed to load report ${file}:`, error.message);
          }
        }
      }
    } catch (error) {
      // Directory might not exist yet
    }
  }

  private parseMarkdownReport(content: string): ECRRReport | null {
    try {
      // Simple parsing - in production, use a proper markdown parser
      const lines = content.split('\n');
      const report: Partial<ECRRReport> = {};
      
      // Extract basic info
      const idMatch = content.match(/# ECRR Report: (.+)/);
      const agentMatch = content.match(/\*\*Agent\*\*: (.+)/);
      const taskMatch = content.match(/\*\*Task\*\*: (.+)/);
      const createdAtMatch = content.match(/\*\*Created\*\*: (.+)/);
      const complianceMatch = content.match(/\*\*Compliance\*\*: (.+)/);
      
      if (!idMatch || !agentMatch || !taskMatch || !createdAtMatch) {
        return null;
      }
      
      report.id = idMatch[1];
      report.agentId = agentMatch[1];
      report.taskId = taskMatch[1];
      report.createdAt = createdAtMatch[1];
      report.compliance = complianceMatch?.[1]?.includes('✅') || false;
      
      // This is a simplified parser - in production, implement full parsing
      return report as ECRRReport;
    } catch (error) {
      return null;
    }
  }

  private generateReportId(): string {
    return `ecrr-${Date.now()}-${crypto.randomBytes(8).toString('hex')}`;
  }

  getRules(): ComplianceRule[] {
    return Array.from(this.rules.values());
  }

  getReports(): ECRRReport[] {
    return Array.from(this.reports.values());
  }

  getComplianceHistory(): ECRRReport[] {
    return [...this.complianceHistory];
  }
}

// Main execution for testing
if (require.main === module) {
  const engine = new ECRRComplianceEngine();
  
  // Test the compliance engine
  async function testCompliance() {
    try {
      // Create a test report
      const report = await engine.generateReport(
        'test-task-1',
        'test-agent',
        {
          timestamp: new Date().toISOString(),
          environment: { nodeVersion: process.version },
          state: { test: true },
          evidence: ['Test evidence'],
          artifacts: ['test-artifact.log']
        },
        {
          actions: ['Test action'],
          changes: [{ file: 'test.txt', change: 'modified' }],
          rollback: [{ file: 'test.txt', change: 'restored' }],
          guardrails: ['Test guardrail'],
          budget: { files: 1, lines: 10, jobs: 1 }
        },
        {
          artifacts: ['test-report.md'],
          metrics: { duration: 1000 },
          compliance: false,
          violations: [],
          recommendations: ['Test recommendation']
        },
        {
          actor: 'Test Agent',
          responsibility: 'Test responsibility',
          signature: 'agent-test-agent-1234567890',
          accountability: ['Test accountability']
        }
      );
      
      console.log('Generated report:', report.id);
      console.log('Compliance:', report.compliance);
      
      // Get compliance stats
      const stats = await engine.getComplianceStats();
      console.log('Compliance stats:', stats);
      
      // Generate compliance report
      const complianceReport = await engine.generateComplianceReport();
      console.log('Compliance report generated');
      
    } catch (error) {
      console.error('Test failed:', error);
    }
  }
  
  testCompliance();
}

export { ECRRComplianceEngine, ECRRReport, ECRRExamine, ECRRClean, ECRRRole, ComplianceRule };
