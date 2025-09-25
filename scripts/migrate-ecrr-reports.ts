/**
 * ECRR Reports Migration Script
 * Migrate existing 29 open reports to new automated system
 */

import { EventBus, EventBuilder, DomainEvents } from '../src/events/event-bus.js';
import { computePriority, computeSlaDueAt } from '../src/rules/priority-calculator.js';
import { assignTask, inferRequiredSkills } from '../src/rules/assignment-engine.js';
import { createWorkflowStateMachine } from '../src/workflow/state-machine.js';
import { NotificationRouter } from '../src/notifications/notification-router.js';

export interface MigrationReport {
  id: string;
  title: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  category?: string;
  description?: string;
  labels: string[];
  status: string;
  discoveredAt: string;
  updatedAt: string;
  metadata?: Record<string, any>;
}

export interface MigrationTask {
  id: string;
  reportId: string;
  kind: string;
  title: string;
  description: string;
  priority: 1 | 2 | 3 | 4 | 5;
  slaDueAt: Date;
  state: 'TRIAGE' | 'IN_PROGRESS' | 'REVIEW' | 'DONE' | 'BLOCKED';
  assignee?: string;
  createdAt: Date;
  updatedAt: Date;
  meta: Record<string, any>;
}

export class ECRRReportsMigration {
  constructor(
    private eventBus: EventBus,
    private _stateMachine: ReturnType<typeof createWorkflowStateMachine>,
    private _notificationRouter: NotificationRouter,
    private db: any // Database interface
  ) {}

  /**
   * Migrate all existing open reports
   */
  async migrateOpenReports(): Promise<{
    reportsMigrated: number;
    tasksCreated: number;
    errors: Array<{ reportId: string; error: string }>;
  }> {
    console.log('🚀 Starting ECRR reports migration...');
    
    const errors: Array<{ reportId: string; error: string }> = [];
    let reportsMigrated = 0;
    let tasksCreated = 0;

    try {
      // Get existing open reports
      const openReports = await this.getExistingOpenReports();
      console.log(`📊 Found ${openReports.length} open reports to migrate`);

      // Get users for assignment
      const users = await this.getUsers();
      const usersWithWip = await this.calculateUsersWip(users);
      console.log(`👥 Loaded ${users.length} users for assignment`);

      // Process each report
      for (const report of openReports) {
        try {
          console.log(`\n📝 Processing report: ${report.title}`);
          
          // Migrate report to new schema
          const migratedReport = await this.migrateReport(report);
          reportsMigrated++;

          // Generate tasks for the report
          const tasks = await this.generateTasksForReport(migratedReport, usersWithWip);
          
          // Save tasks to database
          for (const task of tasks) {
            await this.db.saveTask(task);
            await this.db.logTaskEvent(task.id, 'CREATED', {
              task,
              migration: true,
              actor: 'migration-script',
              timestamp: task.createdAt.toISOString()
            });
            tasksCreated++;

            // Emit TaskCreated event
            const event = EventBuilder.create()
              .type(DomainEvents.TASK_CREATED)
              .payload({
                taskId: task.id,
                reportId: task.reportId,
                title: task.title,
                priority: task.priority,
                assignee: task.assignee,
                migration: true,
                timestamp: task.createdAt.toISOString()
              })
              .build();

            await this.eventBus.emit(event);
          }

          console.log(`✅ Created ${tasks.length} tasks for report ${report.id}`);

        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          console.error(`❌ Error migrating report ${report.id}:`, errorMessage);
          errors.push({ reportId: report.id, error: errorMessage });
        }
      }

      console.log(`\n🎉 Migration completed!`);
      console.log(`📊 Reports migrated: ${reportsMigrated}`);
      console.log(`📋 Tasks created: ${tasksCreated}`);
      console.log(`❌ Errors: ${errors.length}`);

      return {
        reportsMigrated,
        tasksCreated,
        errors
      };

    } catch (error) {
      console.error('💥 Migration failed:', error);
      throw error;
    }
  }

  /**
   * Get existing open reports from current system
   */
  private async getExistingOpenReports(): Promise<MigrationReport[]> {
    // This would integrate with your current ECRR system
    // For now, return mock data representing the 29 open reports
    
    const mockReports: MigrationReport[] = [
      {
        id: 'rep_001',
        title: 'Security vulnerability in authentication system',
        severity: 'high',
        category: 'security',
        description: 'Potential SQL injection vulnerability found in login endpoint',
        labels: ['security', 'authentication', 'production'],
        status: 'Open',
        discoveredAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date().toISOString(),
        metadata: { source: 'security-scan', blocksOthers: true }
      },
      {
        id: 'rep_002',
        title: 'Performance degradation in API responses',
        severity: 'medium',
        category: 'performance',
        description: 'API response times increased by 200% over last week',
        labels: ['performance', 'api', 'customer-impact'],
        status: 'Open',
        discoveredAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date().toISOString(),
        metadata: { source: 'monitoring', component: 'api-gateway' }
      },
      {
        id: 'rep_003',
        title: 'Database connection pool exhaustion',
        severity: 'critical',
        category: 'infrastructure',
        description: 'Database connections reaching maximum limit during peak hours',
        labels: ['database', 'infrastructure', 'production', 'customer-impact'],
        status: 'Open',
        discoveredAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        updatedAt: new Date().toISOString(),
        metadata: { source: 'ops-alert', severity: 'critical' }
      }
      // ... would continue with all 29 reports
    ];

    return mockReports;
  }

  /**
   * Get users for task assignment
   */
  private async getUsers(): Promise<any[]> {
    // This would integrate with your user management system
    const mockUsers = [
      {
        id: 'user_001',
        name: 'Alice Johnson',
        email: 'alice@company.com',
        skills: ['security', 'backend', 'api'],
        maxWip: 5,
        oncall: true,
        active: true
      },
      {
        id: 'user_002',
        name: 'Bob Smith',
        email: 'bob@company.com',
        skills: ['performance', 'infrastructure', 'monitoring'],
        maxWip: 4,
        oncall: false,
        active: true
      },
      {
        id: 'user_003',
        name: 'Carol Davis',
        email: 'carol@company.com',
        skills: ['frontend', 'ui', 'performance'],
        maxWip: 6,
        oncall: false,
        active: true
      }
    ];

    return mockUsers;
  }

  /**
   * Calculate current WIP for users
   */
  private async calculateUsersWip(users: any[]): Promise<any[]> {
    return Promise.all(
      users.map(async user => ({
        ...user,
        currentWip: await this.db.getTaskCount({ assignee: user.id, state: { $nin: ['DONE'] } })
      }))
    );
  }

  /**
   * Migrate report to new schema
   */
  private async migrateReport(report: MigrationReport): Promise<any> {
    const migratedReport = {
      id: report.id,
      title: report.title,
      severity: report.severity,
      category: report.category,
      description: report.description,
      labels: report.labels,
      status: 'Open', // Ensure status is 'Open' for new system
      discoveredAt: new Date(report.discoveredAt),
      updatedAt: new Date(),
      metadata: {
        ...report.metadata,
        migrated: true,
        originalStatus: report.status,
        migrationDate: new Date().toISOString()
      }
    };

    // Save to database
    await this.db.saveReport(migratedReport);

    // Emit ReportCreated event
    const event = EventBuilder.create()
      .type(DomainEvents.REPORT_CREATED)
      .payload({
        reportId: migratedReport.id,
        title: migratedReport.title,
        severity: migratedReport.severity,
        category: migratedReport.category,
        labels: migratedReport.labels,
        migration: true,
        timestamp: migratedReport.discoveredAt.toISOString()
      })
      .build();

    await this.eventBus.emit(event);

    return migratedReport;
  }

  /**
   * Generate tasks for a migrated report
   */
  private async generateTasksForReport(report: any, users: any[]): Promise<MigrationTask[]> {
    const tasks: MigrationTask[] = [];

    // Calculate priority
    const priorityResult = computePriority({
      severity: report.severity,
      discoveredAt: report.discoveredAt,
      blocksOthers: report.metadata?.blocksOthers,
      labels: report.labels,
      openTasksOnReport: 0,
      hasOwner: !!report.metadata?.owner
    });

    // Infer required skills
    const requiredSkills = inferRequiredSkills(report.category, report.labels);

    // Generate tasks based on category
    const taskTemplates = this.getTaskTemplatesForCategory(report.category, report.labels);

    for (const template of taskTemplates) {
      // Assign task
      const assignmentResult = await assignTask(usersWithWip, {
        taskId: this.generateTaskId(),
        reportId: report.id,
        requiredSkills: template.requiredSkills || requiredSkills,
        priority: priorityResult.priority,
        category: report.category,
        labels: report.labels
      });

      const task: MigrationTask = {
        id: this.generateTaskId(),
        reportId: report.id,
        kind: template.kind,
        title: template.title,
        description: template.description,
        priority: priorityResult.priority,
        slaDueAt: computeSlaDueAt(priorityResult.priority, new Date()),
        state: 'TRIAGE',
        assignee: assignmentResult.assigneeId,
        createdAt: new Date(),
        updatedAt: new Date(),
        meta: {
          autoGenerated: true,
          migration: true,
          assignmentStrategy: assignmentResult.assignmentStrategy,
          assignmentReason: assignmentResult.assignmentReason,
          wipRespected: assignmentResult.wipRespected,
          priorityScore: priorityResult.priorityScore,
          rawScore: priorityResult.rawScore,
          breakdown: priorityResult.breakdown,
          template: template.id
        }
      };

      tasks.push(task);
    }

    return tasks;
  }

  /**
   * Get task templates based on report category
   */
  private getTaskTemplatesForCategory(category?: string, _labels?: string[]): Array<{
    id: string;
    kind: string;
    title: string;
    description: string;
    requiredSkills?: string[];
  }> {
    const templates: Array<{
      id: string;
      kind: string;
      title: string;
      description: string;
      requiredSkills?: string[];
    }> = [];

    switch (category) {
      case 'security':
        templates.push(
          {
            id: 'security-analysis',
            kind: 'analysis',
            title: 'Security Analysis',
            description: 'Analyze security vulnerability and assess impact',
            requiredSkills: ['security']
          },
          {
            id: 'security-fix',
            kind: 'fix',
            title: 'Security Remediation',
            description: 'Implement fix for security vulnerability',
            requiredSkills: ['security', 'backend']
          }
        );
        break;

      case 'performance':
        templates.push(
          {
            id: 'performance-analysis',
            kind: 'analysis',
            title: 'Performance Analysis',
            description: 'Investigate performance degradation and identify root cause',
            requiredSkills: ['performance', 'monitoring']
          },
          {
            id: 'performance-fix',
            kind: 'fix',
            title: 'Performance Optimization',
            description: 'Implement performance optimizations',
            requiredSkills: ['performance']
          }
        );
        break;

      case 'infrastructure':
        templates.push(
          {
            id: 'infrastructure-analysis',
            kind: 'analysis',
            title: 'Infrastructure Analysis',
            description: 'Investigate infrastructure issue and assess impact',
            requiredSkills: ['infrastructure', 'ops']
          },
          {
            id: 'infrastructure-fix',
            kind: 'fix',
            title: 'Infrastructure Resolution',
            description: 'Resolve infrastructure issue',
            requiredSkills: ['infrastructure', 'ops']
          }
        );
        break;

      default:
        templates.push({
          id: 'general-analysis',
          kind: 'analysis',
          title: 'General Analysis',
          description: 'Analyze report and determine appropriate action',
          requiredSkills: ['general']
        });
    }

    return templates;
  }

  /**
   * Generate unique task ID
   */
  private generateTaskId(): string {
    return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Validate migration results
   */
  async validateMigration(): Promise<{
    reportsValid: number;
    tasksValid: number;
    issues: string[];
  }> {
    const issues: string[] = [];

    try {
      // Check reports
      const reports = await this.db.getReports({ status: 'Open' });
      const reportsValid = reports.length;

      // Check tasks
      const tasks = await this.db.getTasks({ state: 'TRIAGE' });
      const tasksValid = tasks.length;

      // Validate report-task relationships
      for (const report of reports) {
        const reportTasks = await this.db.getTasks({ reportId: report.id });
        if (reportTasks.length === 0) {
          issues.push(`Report ${report.id} has no tasks`);
        }
      }

      // Validate task assignments
      for (const task of tasks) {
        if (!task.assignee) {
          issues.push(`Task ${task.id} has no assignee`);
        }
        if (!task.slaDueAt) {
          issues.push(`Task ${task.id} has no SLA due date`);
        }
      }

      return {
        reportsValid,
        tasksValid,
        issues
      };

    } catch (error) {
      issues.push(`Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`);
      return {
        reportsValid: 0,
        tasksValid: 0,
        issues
      };
    }
  }
}

/**
 * Main migration function
 */
export async function runMigration(): Promise<void> {
  try {
    console.log('🚀 Starting ECRR Migration Process...');

    // Initialize components
    const eventBus = new (await import('../src/events/event-bus')).InMemoryEventBus();
    const stateMachine = (await import('../src/workflow/state-machine')).createWorkflowStateMachine();
    const notificationRouter = new (await import('../src/notifications/notification-router')).NotificationRouter();
    
    // Mock database - replace with actual database implementation
    const db = {
      saveReport: async (_report: any) => console.log('Saving report:', _report.id),
      saveTask: async (_task: any) => console.log('Saving task:', _task.id),
      logTaskEvent: async (taskId: string, eventType: string, _payload: any) => 
        console.log('Logging task event:', taskId, eventType),
      getTaskCount: async (_filter: any) => 0,
      getReports: async (_filter: any) => [],
      getTasks: async (_filter: any) => []
    };

    // Run migration
    const migration = new ECRRReportsMigration(eventBus, stateMachine, notificationRouter, db);
    const result = await migration.migrateOpenReports();

    // Validate results
    const validation = await migration.validateMigration();

    console.log('\n📊 Migration Summary:');
    console.log(`✅ Reports migrated: ${result.reportsMigrated}`);
    console.log(`✅ Tasks created: ${result.tasksCreated}`);
    console.log(`❌ Errors: ${result.errors.length}`);
    console.log(`✅ Validation - Reports: ${validation.reportsValid}, Tasks: ${validation.tasksValid}`);
    console.log(`⚠️  Issues: ${validation.issues.length}`);

    if (validation.issues.length > 0) {
      console.log('\n⚠️  Validation Issues:');
      validation.issues.forEach(issue => console.log(`  - ${issue}`));
    }

    console.log('\n🎉 Migration completed successfully!');

  } catch (error) {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  }
}

// Run migration if called directly
if (require.main === module) {
  runMigration();
}
