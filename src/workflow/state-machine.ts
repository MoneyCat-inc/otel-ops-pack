/**
 * ECRR Workflow State Machine
 * Formalized lifecycle management for reports and tasks
 */

export type TaskState = 'NEW' | 'TRIAGE' | 'IN_PROGRESS' | 'REVIEW' | 'DONE' | 'BLOCKED';
export type ReportState = 'Open' | 'In-Progress' | 'Review' | 'Done' | 'Archived';

export interface StateTransition {
  from: TaskState | ReportState;
  to: TaskState | ReportState;
  trigger: string;
  conditions?: string[];
  autoTransition?: boolean;
  emitEvent?: boolean;
}

export interface WorkflowEvent {
  id: string;
  type: string;
  entityId: string;
  entityType: 'task' | 'report';
  fromState: string;
  toState: string;
  actor: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

/**
 * Task State Machine Rules
 */
export const TASK_TRANSITIONS: StateTransition[] = [
  // Auto-transitions on creation
  { from: 'NEW', to: 'TRIAGE', trigger: 'created', autoTransition: true, emitEvent: true },
  
  // Manual transitions from TRIAGE
  { from: 'TRIAGE', to: 'IN_PROGRESS', trigger: 'assigned', conditions: ['has_assignee'], emitEvent: true },
  { from: 'TRIAGE', to: 'BLOCKED', trigger: 'blocked', conditions: ['has_dependency'], emitEvent: true },
  
  // Transitions from IN_PROGRESS
  { from: 'IN_PROGRESS', to: 'REVIEW', trigger: 'completed', conditions: ['has_assignee'], emitEvent: true },
  { from: 'IN_PROGRESS', to: 'BLOCKED', trigger: 'blocked', conditions: ['has_dependency'], emitEvent: true },
  
  // Transitions from REVIEW
  { from: 'REVIEW', to: 'DONE', trigger: 'approved', conditions: ['has_reviewer'], emitEvent: true },
  { from: 'REVIEW', to: 'IN_PROGRESS', trigger: 'changes_requested', conditions: ['has_assignee'], emitEvent: true },
  
  // Transitions from BLOCKED
  { from: 'BLOCKED', to: 'TRIAGE', trigger: 'unblocked', conditions: ['dependencies_cleared'], autoTransition: true, emitEvent: true },
  { from: 'BLOCKED', to: 'IN_PROGRESS', trigger: 'assigned', conditions: ['has_assignee', 'dependencies_cleared'], emitEvent: true },
  
  // Terminal state
  { from: 'DONE', to: 'DONE', trigger: 'reopen', conditions: ['has_assignee'], emitEvent: true },
];

/**
 * Report State Machine Rules
 */
export const REPORT_TRANSITIONS: StateTransition[] = [
  // Auto-transitions
  { from: 'Open', to: 'In-Progress', trigger: 'task_created', autoTransition: true, emitEvent: true },
  
  // Manual transitions
  { from: 'Open', to: 'Archived', trigger: 'archived', emitEvent: true },
  { from: 'In-Progress', to: 'Review', trigger: 'all_tasks_review', conditions: ['all_tasks_in_review'], emitEvent: true },
  { from: 'In-Progress', to: 'Done', trigger: 'all_tasks_done', conditions: ['all_tasks_done'], autoTransition: true, emitEvent: true },
  { from: 'Review', to: 'Done', trigger: 'approved', emitEvent: true },
  { from: 'Review', to: 'In-Progress', trigger: 'changes_requested', emitEvent: true },
  { from: 'Done', to: 'Archived', trigger: 'archived', emitEvent: true },
  { from: 'Archived', to: 'Open', trigger: 'reopened', emitEvent: true },
];

export class WorkflowStateMachine {
  private eventBus: WorkflowEventBus;
  private conditionEvaluator: ConditionEvaluator;

  constructor(eventBus: WorkflowEventBus, conditionEvaluator: ConditionEvaluator) {
    this.eventBus = eventBus;
    this.conditionEvaluator = conditionEvaluator;
  }

  /**
   * Validate if a state transition is allowed
   */
  canTransition(
    entityType: 'task' | 'report',
    currentState: TaskState | ReportState,
    targetState: TaskState | ReportState,
    trigger: string,
    context?: Record<string, any>
  ): { allowed: boolean; reason?: string } {
    const transitions = entityType === 'task' ? TASK_TRANSITIONS : REPORT_TRANSITIONS;
    const transition = transitions.find(t => 
      t.from === currentState && t.to === targetState && t.trigger === trigger
    );

    if (!transition) {
      return { 
        allowed: false, 
        reason: `No transition found from ${currentState} to ${targetState} with trigger ${trigger}` 
      };
    }

    // Check conditions if they exist
    if (transition.conditions && context) {
      for (const condition of transition.conditions) {
        if (!this.conditionEvaluator.evaluate(condition, context)) {
          return { 
            allowed: false, 
            reason: `Condition not met: ${condition}` 
          };
        }
      }
    }

    return { allowed: true };
  }

  /**
   * Execute a state transition
   */
  async executeTransition(
    entityType: 'task' | 'report',
    entityId: string,
    currentState: TaskState | ReportState,
    targetState: TaskState | ReportState,
    trigger: string,
    actor: string,
    context?: Record<string, any>
  ): Promise<{ success: boolean; event?: WorkflowEvent; error?: string }> {
    
    // Validate transition
    const validation = this.canTransition(entityType, currentState, targetState, trigger, context);
    if (!validation.allowed) {
      return { success: false, error: validation.reason || 'Unknown error' };
    }

    // Create workflow event
    const event: WorkflowEvent = {
      id: this.generateEventId(),
      type: `${entityType.toUpperCase()}_STATE_CHANGED`,
      entityId,
      entityType,
      fromState: currentState,
      toState: targetState,
      actor,
      timestamp: new Date(),
      metadata: context || {}
    };

    // Emit event to event bus
    if (this.eventBus) {
      await this.eventBus.emit(event);
    }

    return { success: true, event };
  }

  /**
   * Get all possible transitions from current state
   */
  getPossibleTransitions(
    entityType: 'task' | 'report',
    currentState: TaskState | ReportState
  ): StateTransition[] {
    const transitions = entityType === 'task' ? TASK_TRANSITIONS : REPORT_TRANSITIONS;
    return transitions.filter(t => t.from === currentState);
  }

  /**
   * Get next states for a given trigger
   */
  getNextStates(
    entityType: 'task' | 'report',
    currentState: TaskState | ReportState,
    trigger: string
  ): Array<TaskState | ReportState> {
    const transitions = entityType === 'task' ? TASK_TRANSITIONS : REPORT_TRANSITIONS;
    return transitions
      .filter(t => t.from === currentState && t.trigger === trigger)
      .map(t => t.to);
  }

  private generateEventId(): string {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * Condition Evaluator for state transitions
 */
export class ConditionEvaluator {
  /**
   * Evaluate a condition against context
   */
  evaluate(condition: string, context: Record<string, any>): boolean {
    switch (condition) {
      case 'has_assignee':
        return !!(context['assignee'] || context['assigneeId']);
      
      case 'has_dependency':
        return !!(context['dependencies'] && context['dependencies'].length > 0);
      
      case 'dependencies_cleared':
        return !(context['dependencies'] && context['dependencies'].length > 0);
      
      case 'has_reviewer':
        return !!(context['reviewer'] || context['reviewerId']);
      
      case 'all_tasks_in_review':
        return context['taskStates'] && context['taskStates'].every((state: string) => state === 'REVIEW');
      
      case 'all_tasks_done':
        return context['taskStates'] && context['taskStates'].every((state: string) => state === 'DONE');
      
      case 'has_priority':
        return !!(context['priority'] && context['priority'] >= 1 && context['priority'] <= 5);
      
      case 'sla_breached':
        return !!(context['slaDueAt'] && new Date(context['slaDueAt']) < new Date());
      
      default:
        console.warn(`Unknown condition: ${condition}`);
        return false;
    }
  }
}

/**
 * Workflow Event Bus Interface
 */
export interface WorkflowEventBus {
  emit(event: WorkflowEvent): Promise<void>;
  subscribe(eventType: string, handler: (event: WorkflowEvent) => Promise<void>): void;
}

/**
 * Simple in-memory event bus implementation
 */
export class InMemoryWorkflowEventBus implements WorkflowEventBus {
  private handlers: Map<string, Array<(event: WorkflowEvent) => Promise<void>>> = new Map();

  async emit(event: WorkflowEvent): Promise<void> {
    const eventHandlers = this.handlers.get(event.type) || [];
    
    // Execute all handlers for this event type
    await Promise.all(
      eventHandlers.map(handler => 
        handler(event).catch(error => 
          console.error(`Error in event handler for ${event.type}:`, error)
        )
      )
    );
  }

  subscribe(eventType: string, handler: (event: WorkflowEvent) => Promise<void>): void {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }
    this.handlers.get(eventType)!.push(handler);
  }
}

/**
 * State machine factory
 */
export function createWorkflowStateMachine(): WorkflowStateMachine {
  const eventBus = new InMemoryWorkflowEventBus();
  const conditionEvaluator = new ConditionEvaluator();
  return new WorkflowStateMachine(eventBus as any, conditionEvaluator);
}

/**
 * Utility functions for state management
 */
export class StateUtils {
  /**
   * Get state color for UI display
   */
  static getStateColor(state: TaskState | ReportState): string {
    switch (state) {
      case 'NEW':
      case 'Open':
        return '#6b7280'; // gray
      case 'TRIAGE':
        return '#f59e0b'; // amber
      case 'IN_PROGRESS':
      case 'In-Progress':
        return '#3b82f6'; // blue
      case 'REVIEW':
      case 'Review':
        return '#8b5cf6'; // purple
      case 'DONE':
      case 'Done':
        return '#10b981'; // green
      case 'BLOCKED':
        return '#ef4444'; // red
      case 'Archived':
        return '#9ca3af'; // gray-400
      default:
        return '#6b7280';
    }
  }

  /**
   * Get state icon for UI display
   */
  static getStateIcon(state: TaskState | ReportState): string {
    switch (state) {
      case 'NEW':
      case 'Open':
        return '📝';
      case 'TRIAGE':
        return '🔍';
      case 'IN_PROGRESS':
      case 'In-Progress':
        return '⚡';
      case 'REVIEW':
      case 'Review':
        return '👀';
      case 'DONE':
      case 'Done':
        return '✅';
      case 'BLOCKED':
        return '🚫';
      case 'Archived':
        return '📦';
      default:
        return '❓';
    }
  }

  /**
   * Check if state is terminal
   */
  static isTerminalState(state: TaskState | ReportState): boolean {
    return ['DONE', 'Done', 'Archived'].includes(state);
  }

  /**
   * Check if state allows new work
   */
  static allowsNewWork(state: TaskState | ReportState): boolean {
    return ['NEW', 'Open', 'TRIAGE'].includes(state);
  }
}
