/**
 * ECRR Tasks API
 * RESTful endpoints for task management and workflow automation
 */

import { Request, Response } from 'express';
import { EventBus, EventBuilder, DomainEvents } from '../events/event-bus';
import { WorkflowStateMachine, TaskState } from '../workflow/state-machine';

export interface TaskCreateRequest {
  reportId: string;
  kind: string;
  title: string;
  description?: string;
  priority?: 1 | 2 | 3 | 4 | 5;
  assignee?: string;
  slaDueAt?: string;
  metadata?: Record<string, any>;
}

export interface TaskUpdateRequest {
  title?: string;
  description?: string;
  priority?: 1 | 2 | 3 | 4 | 5;
  assignee?: string;
  state?: TaskState;
  slaDueAt?: string;
  metadata?: Record<string, any>;
}

export interface TaskResponse {
  id: string;
  reportId: string;
  kind: string;
  title: string;
  description?: string;
  priority: number;
  slaDueAt?: string;
  state: TaskState;
  assignee?: string;
  createdAt: string;
  updatedAt: string;
  metadata?: Record<string, any>;
  slaStatus: 'ON_TRACK' | 'DUE_SOON' | 'OVERDUE';
  reportTitle?: string;
  reportSeverity?: string;
}

export interface TaskTransitionRequest {
  toState: TaskState;
  actor: string;
  comment?: string;
  metadata?: Record<string, any>;
}

interface DatabaseInterface {
  saveTask(task: any): Promise<void>;
  getTask(id: string): Promise<any>;
  updateTask(id: string, task: any): Promise<void>;
  deleteTask(id: string): Promise<void>;
  listTasks(options: any): Promise<any[]>;
  getTaskCount(filter?: any): Promise<number>;
  getTaskEvents(taskId: string, options: any): Promise<any[]>;
  getTaskEventCount(taskId: string): Promise<number>;
  getReport(id: string): Promise<any>;
  getReportsByIds(ids: string[]): Promise<any[]>;
  logTaskEvent(taskId: string, eventType: string, payload: any): Promise<void>;
}

export class TasksAPI {
  constructor(
    private eventBus: EventBus,
    private stateMachine: WorkflowStateMachine,
    private db: DatabaseInterface
  ) {}

  /**
   * Create a new task
   */
  async createTask(req: Request, res: Response): Promise<void> {
    try {
      const request: TaskCreateRequest = req.body;
      
      // Validate required fields
      if (!request.reportId || !request.kind || !request.title) {
        res.status(400).json({ error: 'Report ID, kind, and title are required' });
        return;
      }

      // Verify report exists
      const report = await this.db.getReport(request.reportId);
      if (!report) {
        res.status(404).json({ error: 'Report not found' });
        return;
      }

      // Create task record
      const task = {
        id: this.generateId(),
        reportId: request.reportId,
        kind: request.kind,
        title: request.title,
        description: request.description,
        priority: request.priority || 3,
        slaDueAt: request.slaDueAt ? new Date(request.slaDueAt) : undefined,
        state: 'TRIAGE' as TaskState,
        assignee: request.assignee,
        createdAt: new Date(),
        updatedAt: new Date(),
        meta: {
          ...request.metadata,
          manualCreation: true
        }
      };

      // Save to database
      await this.db.saveTask(task);

      // Log task event
      await this.db.logTaskEvent(task.id, 'CREATED', {
        task,
        actor: 'api',
        timestamp: task.createdAt.toISOString()
      });

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

      // Generate response
      const response: TaskResponse = {
        id: task.id,
        reportId: task.reportId,
        kind: task.kind,
        title: task.title,
        description: task.description,
        priority: task.priority,
        slaDueAt: task.slaDueAt?.toISOString(),
        state: task.state,
        assignee: task.assignee,
        createdAt: task.createdAt.toISOString(),
        updatedAt: task.updatedAt.toISOString(),
        metadata: task.meta,
        slaStatus: this.calculateSlaStatus(task.slaDueAt, task.state),
        reportTitle: report.title,
        reportSeverity: report.severity
      };

      res.status(201).json(response);

    } catch (error) {
      console.error('Error creating task:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Update an existing task
   */
  async updateTask(req: Request, res: Response): Promise<void> {
    try {
      const taskId = req.params.id;
      const request: TaskUpdateRequest = req.body;

      // Get existing task
      const existingTask = await this.db.getTask(taskId);
      if (!existingTask) {
        res.status(404).json({ error: 'Task not found' });
        return;
      }

      // Update task
      const updatedTask = {
        ...existingTask,
        ...request,
        slaDueAt: request.slaDueAt ? new Date(request.slaDueAt) : existingTask.slaDueAt,
        updatedAt: new Date(),
        meta: {
          ...existingTask.meta,
          ...request.metadata
        }
      };

      // Save to database
      await this.db.updateTask(taskId, updatedTask);

      // Log task event
      await this.db.logTaskEvent(taskId, 'UPDATED', {
        changes: request,
        actor: 'api',
        timestamp: updatedTask.updatedAt.toISOString()
      });

      // Emit TaskUpdated event
      const event = EventBuilder.create()
        .type(DomainEvents.TASK_UPDATED)
        .payload({
          taskId: task.id,
          reportId: updatedTask.reportId,
          title: updatedTask.title,
          priority: updatedTask.priority,
          assignee: updatedTask.assignee,
          state: updatedTask.state,
          changes: request,
          timestamp: updatedTask.updatedAt.toISOString()
        })
        .build();

      await this.eventBus.emit(event);

      // Get report for response
      const report = await this.db.getReport(updatedTask.reportId);

      // Generate response
      const response: TaskResponse = {
        id: updatedTask.id,
        reportId: updatedTask.reportId,
        kind: updatedTask.kind,
        title: updatedTask.title,
        description: updatedTask.description,
        priority: updatedTask.priority,
        slaDueAt: updatedTask.slaDueAt?.toISOString(),
        state: updatedTask.state,
        assignee: updatedTask.assignee,
        createdAt: updatedTask.createdAt.toISOString(),
        updatedAt: updatedTask.updatedAt.toISOString(),
        metadata: updatedTask.meta,
        slaStatus: this.calculateSlaStatus(updatedTask.slaDueAt, updatedTask.state),
        reportTitle: report?.title,
        reportSeverity: report?.severity
      };

      res.status(200).json(response);

    } catch (error) {
      console.error('Error updating task:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get a specific task
   */
  async getTask(req: Request, res: Response): Promise<void> {
    try {
      const taskId = req.params.id;

      const task = await this.db.getTask(taskId);
      if (!task) {
        res.status(404).json({ error: 'Task not found' });
        return;
      }

      // Get report for response
      const report = await this.db.getReport(task.reportId);

      // Generate response
      const response: TaskResponse = {
        id: task.id,
        reportId: task.reportId,
        kind: task.kind,
        title: task.title,
        description: task.description,
        priority: task.priority,
        slaDueAt: task.slaDueAt?.toISOString(),
        state: task.state,
        assignee: task.assignee,
        createdAt: task.createdAt.toISOString(),
        updatedAt: task.updatedAt.toISOString(),
        metadata: task.meta,
        slaStatus: this.calculateSlaStatus(task.slaDueAt, task.state),
        reportTitle: report?.title,
        reportSeverity: report?.severity
      };

      res.status(200).json(response);

    } catch (error) {
      console.error('Error getting task:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * List tasks with filtering and pagination
   */
  async listTasks(req: Request, res: Response): Promise<void> {
    try {
      const {
        reportId,
        state,
        priority,
        assignee,
        kind,
        slaStatus,
        limit = '50',
        offset = '0',
        sortBy = 'createdAt',
        sortOrder = 'desc'
      } = req.query;

      // Build filter
      const filter: any = {};
      if (reportId) filter.reportId = reportId;
      if (state) filter.state = state;
      if (priority) filter.priority = parseInt(priority as string);
      if (assignee) filter.assignee = assignee;
      if (kind) filter.kind = kind;

      // Get tasks
      const tasks = await this.db.listTasks({
        filter,
        limit: parseInt(limit as string),
        offset: parseInt(offset as string),
        sortBy: sortBy as string,
        sortOrder: sortOrder as string
      });

      // Get reports for tasks
      const reportIds = [...new Set(tasks.map((t: any) => t.reportId))];
      const reports = await this.db.getReportsByIds(reportIds);
      const reportMap = new Map(reports.map((r: any) => [r.id, r]));

      // Generate responses
      const responses = tasks.map((task: any) => {
        const report = reportMap.get(task.reportId);
        
        return {
          id: task.id,
          reportId: task.reportId,
          kind: task.kind,
          title: task.title,
          description: task.description,
          priority: task.priority,
          slaDueAt: task.slaDueAt?.toISOString(),
          state: task.state,
          assignee: task.assignee,
          createdAt: task.createdAt.toISOString(),
          updatedAt: task.updatedAt.toISOString(),
          metadata: task.meta,
          slaStatus: this.calculateSlaStatus(task.slaDueAt, task.state),
          reportTitle: report?.title,
          reportSeverity: report?.severity
        };
      });

      // Apply SLA status filter if specified
      const filteredResponses = slaStatus 
        ? responses.filter((r: TaskResponse) => r.slaStatus === slaStatus)
        : responses;

      res.status(200).json({
        tasks: filteredResponses,
        pagination: {
          limit: parseInt(limit as string),
          offset: parseInt(offset as string),
          total: await this.db.getTaskCount(filter)
        }
      });

    } catch (error) {
      console.error('Error listing tasks:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Transition task state
   */
  async transitionTask(req: Request, res: Response): Promise<void> {
    try {
      const taskId = req.params.id;
      const request: TaskTransitionRequest = req.body;

      // Validate required fields
      if (!request.toState || !request.actor) {
        res.status(400).json({ error: 'Target state and actor are required' });
        return;
      }

      // Get existing task
      const existingTask = await this.db.getTask(taskId);
      if (!existingTask) {
        res.status(404).json({ error: 'Task not found' });
        return;
      }

      // Validate transition
      const trigger = this.getTransitionTrigger(request.toState, existingTask.state);
      const validation = this.stateMachine.canTransition(
        'task',
        existingTask.state,
        request.toState,
        trigger,
        {
          assignee: existingTask.assignee,
          hasAssignee: !!existingTask.assignee
        }
      );

      if (!validation.allowed) {
        res.status(400).json({ 
          error: 'Invalid state transition',
          reason: validation.reason,
          currentState: existingTask.state,
          targetState: request.toState
        });
        return;
      }

      // Execute transition
      const result = await this.stateMachine.executeTransition(
        'task',
        taskId,
        existingTask.state,
        request.toState,
        trigger,
        request.actor,
        {
          assignee: existingTask.assignee,
          hasAssignee: !!existingTask.assignee,
          comment: request.comment
        }
      );

      if (!result.success) {
        res.status(400).json({ 
          error: 'Failed to execute transition',
          reason: result.error
        });
        return;
      }

      // Update task state
      const updatedTask = {
        ...existingTask,
        state: request.toState,
        updatedAt: new Date(),
        meta: {
          ...existingTask.meta,
          lastTransition: {
            from: existingTask.state,
            to: request.toState,
            actor: request.actor,
            timestamp: new Date().toISOString(),
            comment: request.comment
          },
          ...request.metadata
        }
      };

      await this.db.updateTask(taskId, updatedTask);

      // Log task event
      await this.db.logTaskEvent(taskId, 'STATE_CHANGED', {
        fromState: existingTask.state,
        toState: request.toState,
        actor: request.actor,
        comment: request.comment,
        timestamp: updatedTask.updatedAt.toISOString()
      });

      // Emit TaskStateChanged event
      const event = EventBuilder.create()
        .type(DomainEvents.TASK_STATE_CHANGED)
        .payload({
          taskId: task.id,
          fromState: existingTask.state,
          toState: request.toState,
          actor: request.actor,
          comment: request.comment,
          timestamp: updatedTask.updatedAt.toISOString()
        })
        .build();

      await this.eventBus.emit(event);

      // Get report for response
      const report = await this.db.getReport(updatedTask.reportId);

      // Generate response
      const response: TaskResponse = {
        id: updatedTask.id,
        reportId: updatedTask.reportId,
        kind: updatedTask.kind,
        title: updatedTask.title,
        description: updatedTask.description,
        priority: updatedTask.priority,
        slaDueAt: updatedTask.slaDueAt?.toISOString(),
        state: updatedTask.state,
        assignee: updatedTask.assignee,
        createdAt: updatedTask.createdAt.toISOString(),
        updatedAt: updatedTask.updatedAt.toISOString(),
        metadata: updatedTask.meta,
        slaStatus: this.calculateSlaStatus(updatedTask.slaDueAt, updatedTask.state),
        reportTitle: report?.title,
        reportSeverity: report?.severity
      };

      res.status(200).json(response);

    } catch (error) {
      console.error('Error transitioning task:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get possible transitions for a task
   */
  async getTaskTransitions(req: Request, res: Response): Promise<void> {
    try {
      const taskId = req.params.id;

      const task = await this.db.getTask(taskId);
      if (!task) {
        res.status(404).json({ error: 'Task not found' });
        return;
      }

      const possibleTransitions = this.stateMachine.getPossibleTransitions('task', task.state);

      res.status(200).json({
        taskId: task.id,
        currentState: task.state,
        possibleTransitions: possibleTransitions.map(t => ({
          toState: t.to,
          trigger: t.trigger,
          conditions: t.conditions,
          autoTransition: t.autoTransition,
          emitEvent: t.emitEvent
        }))
      });

    } catch (error) {
      console.error('Error getting task transitions:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Get task events/history
   */
  async getTaskEvents(req: Request, res: Response): Promise<void> {
    try {
      const taskId = req.params.id;
      const { limit = '50', offset = '0' } = req.query;

      const task = await this.db.getTask(taskId);
      if (!task) {
        res.status(404).json({ error: 'Task not found' });
        return;
      }

      const events = await this.db.getTaskEvents(taskId, {
        limit: parseInt(limit as string),
        offset: parseInt(offset as string)
      });

      res.status(200).json({
        taskId: task.id,
        events: events.map((event: any) => ({
          id: event.id,
          eventType: event.eventType,
          payload: event.payload,
          createdAt: event.createdAt.toISOString()
        })),
        pagination: {
          limit: parseInt(limit as string),
          offset: parseInt(offset as string),
          total: await this.db.getTaskEventCount(taskId)
        }
      });

    } catch (error) {
      console.error('Error getting task events:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * Delete a task
   */
  async deleteTask(req: Request, res: Response): Promise<void> {
    try {
      const taskId = req.params.id;

      const task = await this.db.getTask(taskId);
      if (!task) {
        res.status(404).json({ error: 'Task not found' });
        return;
      }

      // Only allow deletion of NEW or TRIAGE tasks
      if (!['NEW', 'TRIAGE'].includes(task.state)) {
        res.status(400).json({ 
          error: 'Cannot delete task in current state',
          currentState: task.state,
          allowedStates: ['NEW', 'TRIAGE']
        });
        return;
      }

      await this.db.deleteTask(taskId);

      res.status(204).send();

    } catch (error) {
      console.error('Error deleting task:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  }

  // Helper methods
  private getTransitionTrigger(toState: TaskState, _fromState: TaskState): string {
    // Map target states to triggers
    const triggerMap: Record<TaskState, string> = {
      'NEW': 'created',
      'TRIAGE': 'created',
      'IN_PROGRESS': 'assigned',
      'REVIEW': 'completed',
      'DONE': 'approved',
      'BLOCKED': 'blocked'
    };

    return triggerMap[toState] || 'manual';
  }

  private calculateSlaStatus(slaDueAt: Date | null | undefined, state: TaskState): 'ON_TRACK' | 'DUE_SOON' | 'OVERDUE' {
    if (!slaDueAt || state === 'DONE') {
      return 'ON_TRACK';
    }

    const now = new Date();
    const hoursUntilDue = (slaDueAt.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (hoursUntilDue < 0) {
      return 'OVERDUE';
    } else if (hoursUntilDue <= 24) {
      return 'DUE_SOON';
    } else {
      return 'ON_TRACK';
    }
  }

  private generateId(): string {
    return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}
