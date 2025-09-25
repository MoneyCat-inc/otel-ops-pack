/**
 * ECRR Reports API
 * RESTful endpoints for report management and task generation
 */

import { Request, Response } from 'express';
import { EventBus, EventBuilder, DomainEvents } from '../events/event-bus';
import { computePriority, computeSlaDueAt } from '../rules/priority-calculator';
import { assignTask, inferRequiredSkills } from '../rules/assignment-engine';

export interface ReportCreateRequest {
  title: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  category?: string;
  description?: string;
  labels?: string[];
  discoveredAt?: string;
  metadata?: Record<string, any>;
}

export interface ReportUpdateRequest {
  title?: string;
  severity?: 'low' | 'medium' | 'high' | 'critical';
  category?: string;
  description?: string;
  labels?: string[];
  status?: 'Open' | 'In-Progress' | 'Review' | 'Done' | 'Archived';
  metadata?: Record<string, any>;
}

export interface ReportResponse {
  id: string;
  title: string;
  severity: string;
  category?: string;
  description?: string;
  labels: string[];
  status: string;
  discoveredAt: string;
  updatedAt: string;
  metadata?: Record<string, any>;
  taskCount: number;
  openTaskCount: number;
}

interface DatabaseInterface {
  saveReport(report: any): Promise<void>;
  getReport(id: string): Promise<any>;
  updateReport(id: string, report: any): Promise<void>;
  deleteReport(id: string): Promise<void>;
  listReports(options: any): Promise<any[]>;
  getReportCount(filter?: any): Promise<number>;
  getTaskCountByReport(reportId: string): Promise<number>;
  getOpenTaskCountByReport(reportId: string): Promise<number>;
  getTasksByReport(reportId: string): Promise<any[]>;
  getUsers(): Promise<any[]>;
  saveTask(task: any): Promise<void>;
  logTaskEvent(taskId: string, eventType: string, payload: any): Promise<void>;
}

export class ReportsAPI {
  constructor(
    private eventBus: EventBus,
    private db: DatabaseInterface
  ) {}

  /**
   * Create a new report
   */
  async createReport(req: Request, res: Response): Promise<void> {
    try {
      const request: ReportCreateRequest = req.body;
      
      // Validate required fields
      if (!request.title || !request.severity) {
        res.status(400).json({ error: 'Title and severity are required' });
        return;
      }

      // Create report record
      const report = {
        id: this.generateId(),
        title: request.title,
        severity: request.severity,
        category: request.category,
        description: request.description,
        labels: request.labels || [],
        status: 'Open',
        discoveredAt: request.discoveredAt ? new Date(request.discoveredAt) : new Date(),
        updatedAt: new Date(),
        metadata: request.metadata || {}
      };

      // Save to database
      await this.db.saveReport(report);

      // Emit ReportCreated event
      const event = EventBuilder.create()
        .type(DomainEvents.REPORT_CREATED)
        .payload({
          reportId: report.id,
          title: report.title,
          severity: report.severity,
          category: report.category,
          labels: report.labels,
          timestamp: report.discoveredAt.toISOString()
        })
        .build();

      await this.eventBus.emit(event);

      // Generate response
      const response: ReportResponse = {
        id: report.id,
        title: report.title,
        severity: report.severity,
        category: report.category,
        description: report.description,
        labels: report.labels,
        status: report.status,
        discoveredAt: report.discoveredAt.toISOString(),
        updatedAt: report.updatedAt.toISOString(),
        metadata: report.metadata,
        taskCount: 0,
        openTaskCount: 0
      };

      res.status(201).json(response);

    } catch (error) {
      console.error('Error creating report:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Update an existing report
   */
  async updateReport(req: Request, res: Response): Promise<void> {
    try {
      const reportId = req.params.id;
      const request: ReportUpdateRequest = req.body;

      // Get existing report
      const existingReport = await this.db.getReport(reportId);
      if (!existingReport) {
        res.status(404).json({ error: 'Report not found' });
        return;
      }

      // Update report
      const updatedReport = {
        ...existingReport,
        ...request,
        updatedAt: new Date()
      };

      // Save to database
      await this.db.updateReport(reportId, updatedReport);

      // Emit ReportUpdated event
      const event = EventBuilder.create()
        .type(DomainEvents.REPORT_UPDATED)
        .payload({
          reportId: report.id,
          title: updatedReport.title,
          severity: updatedReport.severity,
          category: updatedReport.category,
          labels: updatedReport.labels,
          status: updatedReport.status,
          changes: request,
          timestamp: updatedReport.updatedAt.toISOString()
        })
        .build();

      await this.eventBus.emit(event);

      // Get task counts
      const taskCount = await this.db.getTaskCountByReport(reportId);
      const openTaskCount = await this.db.getOpenTaskCountByReport(reportId);

      // Generate response
      const response: ReportResponse = {
        id: updatedReport.id,
        title: updatedReport.title,
        severity: updatedReport.severity,
        category: updatedReport.category,
        description: updatedReport.description,
        labels: updatedReport.labels,
        status: updatedReport.status,
        discoveredAt: updatedReport.discoveredAt.toISOString(),
        updatedAt: updatedReport.updatedAt.toISOString(),
        metadata: updatedReport.metadata,
        taskCount,
        openTaskCount
      };

      res.status(200).json(response);

    } catch (error) {
      console.error('Error updating report:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get a specific report
   */
  async getReport(req: Request, res: Response): Promise<void> {
    try {
      const reportId = req.params.id;

      const report = await this.db.getReport(reportId);
      if (!report) {
        res.status(404).json({ error: 'Report not found' });
        return;
      }

      // Get task counts
      const taskCount = await this.db.getTaskCountByReport(reportId);
      const openTaskCount = await this.db.getOpenTaskCountByReport(reportId);

      // Generate response
      const response: ReportResponse = {
        id: report.id,
        title: report.title,
        severity: report.severity,
        category: report.category,
        description: report.description,
        labels: report.labels,
        status: report.status,
        discoveredAt: report.discoveredAt.toISOString(),
        updatedAt: report.updatedAt.toISOString(),
        metadata: report.metadata,
        taskCount,
        openTaskCount
      };

      res.status(200).json(response);

    } catch (error) {
      console.error('Error getting report:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * List reports with filtering and pagination
   */
  async listReports(req: Request, res: Response): Promise<void> {
    try {
      const {
        status,
        severity,
        category,
        labels,
        assignee,
        limit = '50',
        offset = '0',
        sortBy = 'discoveredAt',
        sortOrder = 'desc'
      } = req.query;

      // Build filter
      const filter: any = {};
      if (status) filter.status = status;
      if (severity) filter.severity = severity;
      if (category) filter.category = category;
      if (labels) filter.labels = Array.isArray(labels) ? labels : [labels];
      if (assignee) filter.assignee = assignee;

      // Get reports
      const reports = await this.db.listReports({
        filter,
        limit: parseInt(limit as string),
        offset: parseInt(offset as string),
        sortBy: sortBy as string,
        sortOrder: sortOrder as string
      });

      // Get task counts for each report
      const reportsWithCounts = await Promise.all(
        reports.map(async (report: any) => {
          const taskCount = await this.db.getTaskCountByReport(report.id);
          const openTaskCount = await this.db.getOpenTaskCountByReport(report.id);

          return {
            id: report.id,
            title: report.title,
            severity: report.severity,
            category: report.category,
            description: report.description,
            labels: report.labels,
            status: report.status,
            discoveredAt: report.discoveredAt.toISOString(),
            updatedAt: report.updatedAt.toISOString(),
            metadata: report.metadata,
            taskCount,
            openTaskCount
          };
        })
      );

      res.status(200).json({
        reports: reportsWithCounts,
        pagination: {
          limit: parseInt(limit as string),
          offset: parseInt(offset as string),
          total: await this.db.getReportCount(filter)
        }
      });

    } catch (error) {
      console.error('Error listing reports:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Generate tasks for a report
   */
  async generateTasks(req: Request, res: Response): Promise<void> {
    try {
      const reportId = req.params.id;

      // Get report
      const report = await this.db.getReport(reportId);
      if (!report) {
        res.status(404).json({ error: 'Report not found' });
        return;
      }

      // Check if tasks already exist
      const existingTasks = await this.db.getTasksByReport(reportId);
      if (existingTasks.length > 0) {
        res.status(400).json({ 
          error: 'Tasks already exist for this report',
          existingTaskCount: existingTasks.length
        });
        return;
      }

      // Calculate priority
      const priorityResult = computePriority({
        severity: report.severity,
        discoveredAt: new Date(report.discoveredAt),
        blocksOthers: report.metadata?.blocksOthers,
        labels: report.labels,
        openTasksOnReport: 0,
        hasOwner: !!report.metadata?.owner
      });

      // Infer required skills
      const requiredSkills = inferRequiredSkills(report.category, report.labels);

      // Get users for assignment
      const users = await this.db.getUsers();
      const usersWithWip = await Promise.all(
        users.map(async (user: any) => ({
          ...user,
          currentWip: await this.db.getTaskCountByAssignee(user.id)
        }))
      );

      // Generate tasks based on category
      const tasks = await this.generateTasksFromCategory(report, priorityResult, requiredSkills);

      // Assign tasks
      const assignedTasks = [];
      for (const taskTemplate of tasks) {
        const assignmentResult = await assignTask(usersWithWip, {
          taskId: this.generateId(),
          reportId: report.id,
          requiredSkills: taskTemplate.requiredSkills || requiredSkills,
          priority: priorityResult.priority,
          category: report.category,
          labels: report.labels
        });

        const task = {
          id: this.generateId(),
          reportId: report.id,
          kind: taskTemplate.kind,
          title: taskTemplate.title,
          description: taskTemplate.description,
          priority: priorityResult.priority,
          slaDueAt: computeSlaDueAt(priorityResult.priority),
          state: 'TRIAGE',
          assignee: assignmentResult.assigneeId,
          createdAt: new Date(),
          updatedAt: new Date(),
          meta: {
            autoGenerated: true,
            assignmentStrategy: assignmentResult.assignmentStrategy,
            assignmentReason: assignmentResult.assignmentReason,
            wipRespected: assignmentResult.wipRespected,
            priorityScore: priorityResult.priorityScore,
            rawScore: priorityResult.rawScore,
            breakdown: priorityResult.breakdown
          }
        };

        // Save task
        await this.db.saveTask(task);
        assignedTasks.push(task);

        // Emit TaskCreated event
        const event = EventBuilder.create()
          .type(DomainEvents.TASK_CREATED)
          .payload({
            taskId: task.id,
            reportId: task.reportId,
            title: task.title,
            priority: task.priority,
            assignee: task.assignee,
            timestamp: task.createdAt.toISOString()
          })
          .build();

        await this.eventBus.emit(event);
      }

      res.status(201).json({
        message: `Generated ${assignedTasks.length} tasks for report ${reportId}`,
        tasks: assignedTasks.map(t => ({
          id: t.id,
          title: t.title,
          priority: t.priority,
          assignee: t.assignee,
          state: t.state,
          slaDueAt: t.slaDueAt.toISOString()
        }))
      });

    } catch (error) {
      console.error('Error generating tasks:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Generate tasks based on report category
   */
  private async generateTasksFromCategory(
    report: any,
    priorityResult: any,
    requiredSkills: string[]
  ): Promise<Array<{kind: string; title: string; description: string; requiredSkills?: string[]}>> {
    // This would integrate with the task templates system
    // For now, return a simple default task
    return [{
      kind: 'analysis',
      title: `Triage: ${report.title}`,
      description: `Analyze and triage the report: ${report.title}`,
      requiredSkills
    }];
  }

  /**
   * Delete a report
   */
  async deleteReport(req: Request, res: Response): Promise<void> {
    try {
      const reportId = req.params.id;

      // Check if report exists
      const report = await this.db.getReport(reportId);
      if (!report) {
        res.status(404).json({ error: 'Report not found' });
        return;
      }

      // Check if report has tasks
      const taskCount = await this.db.getTaskCountByReport(reportId);
      if (taskCount > 0) {
        res.status(400).json({ 
          error: 'Cannot delete report with existing tasks',
          taskCount
        });
        return;
      }

      // Delete report
      await this.db.deleteReport(reportId);

      // Emit ReportArchived event
      const event = EventBuilder.create()
        .type(DomainEvents.REPORT_ARCHIVED)
        .payload({
          reportId: report.id,
          title: report.title,
          timestamp: new Date().toISOString()
        })
        .build();

      await this.eventBus.emit(event);

      res.status(204).send();

    } catch (error) {
      console.error('Error deleting report:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private generateId(): string {
    return `rep_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
