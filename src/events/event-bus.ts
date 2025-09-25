/**
 * ECRR Event Bus
 * Central event system for workflow automation and notifications
 */

export interface DomainEvent {
  id: string;
  type: string;
  payload: Record<string, unknown>;
  occurredAt: Date;
  correlationId?: string;
  causationId?: string;
  metadata?: Record<string, unknown>;
}

export interface EventHandler {
  (event: DomainEvent): Promise<void>;
}

export interface EventSubscription {
  eventType: string;
  handler: EventHandler;
  id: string;
}

/**
 * Core domain events for ECRR system
 */
export const DomainEvents = {
  // Report events
  REPORT_CREATED: 'ReportCreated',
  REPORT_UPDATED: 'ReportUpdated',
  REPORT_ARCHIVED: 'ReportArchived',
  
  // Task events
  TASK_CREATED: 'TaskCreated',
  TASK_UPDATED: 'TaskUpdated',
  TASK_ASSIGNED: 'TaskAssigned',
  TASK_STATE_CHANGED: 'TaskStateChanged',
  TASK_COMPLETED: 'TaskCompleted',
  
  // SLA events
  SLA_WARNING: 'SLAWarning',
  SLA_BREACHED: 'SLABreached',
  SLA_ESCALATED: 'SLAEscalated',
  
  // Workflow events
  WORKFLOW_TRIGGERED: 'WorkflowTriggered',
  DEPENDENCY_CLEARED: 'DependencyCleared',
  
  // Notification events
  NOTIFICATION_SENT: 'NotificationSent',
  NOTIFICATION_FAILED: 'NotificationFailed',
} as const;

export type DomainEventType = typeof DomainEvents[keyof typeof DomainEvents];

/**
 * Event Bus Interface
 */
export interface EventBus {
  emit(event: DomainEvent): Promise<void>;
  subscribe(eventType: DomainEventType, handler: EventHandler): string;
  unsubscribe(subscriptionId: string): void;
  getSubscriptions(): EventSubscription[];
}

/**
 * In-Memory Event Bus Implementation
 */
export class InMemoryEventBus implements EventBus {
  private subscriptions: Map<string, EventSubscription> = new Map();
  private eventLog: DomainEvent[] = [];
  private maxEventLogSize = 10000;

  async emit(event: DomainEvent): Promise<void> {
    // Add to event log
    this.eventLog.push(event);
    
    // Trim event log if it gets too large
    if (this.eventLog.length > this.maxEventLogSize) {
      this.eventLog = this.eventLog.slice(-this.maxEventLogSize);
    }

    // Find all handlers for this event type
    const handlers = Array.from(this.subscriptions.values())
      .filter(sub => sub.eventType === event.type)
      .map(sub => sub.handler);

    // Execute all handlers
    await Promise.allSettled(
      handlers.map(handler => 
        handler(event).catch(error => 
          console.error(`Error in event handler for ${event.type}:`, error)
        )
      )
    );
  }

  subscribe(eventType: DomainEventType, handler: EventHandler): string {
    const subscriptionId = this.generateSubscriptionId();
    const subscription: EventSubscription = {
      eventType,
      handler,
      id: subscriptionId
    };
    
    this.subscriptions.set(subscriptionId, subscription);
    return subscriptionId;
  }

  unsubscribe(subscriptionId: string): void {
    this.subscriptions.delete(subscriptionId);
  }

  getSubscriptions(): EventSubscription[] {
    return Array.from(this.subscriptions.values());
  }

  getEventLog(): DomainEvent[] {
    return [...this.eventLog];
  }

  getEventLogByType(eventType: DomainEventType): DomainEvent[] {
    return this.eventLog.filter(event => event.type === eventType);
  }

  private generateSubscriptionId(): string {
    return `sub_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * Event Builder for creating domain events
 */
export class EventBuilder {
  private event: Partial<DomainEvent>;

  constructor() {
    this.event = {
      id: this.generateEventId(),
      occurredAt: new Date(),
      metadata: {}
    };
  }

  static create(): EventBuilder {
    return new EventBuilder();
  }

  type(eventType: DomainEventType): EventBuilder {
    this.event.type = eventType;
    return this;
  }

  payload(payload: Record<string, unknown>): EventBuilder {
    this.event.payload = payload;
    return this;
  }

  correlationId(correlationId: string): EventBuilder {
    this.event.correlationId = correlationId;
    return this;
  }

  causationId(causationId: string): EventBuilder {
    this.event.causationId = causationId;
    return this;
  }

  metadata(metadata: Record<string, unknown>): EventBuilder {
    this.event.metadata = { ...this.event.metadata, ...metadata };
    return this;
  }

  build(): DomainEvent {
    if (!this.event.type) {
      throw new Error('Event type is required');
    }
    if (!this.event.payload) {
      throw new Error('Event payload is required');
    }

    return this.event as DomainEvent;
  }

  private generateEventId(): string {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * Event Store for persistence
 */
export interface EventStore {
  save(event: DomainEvent): Promise<void>;
  getById(eventId: string): Promise<DomainEvent | null>;
  getByType(eventType: DomainEventType, limit?: number): Promise<DomainEvent[]>;
  getByCorrelationId(correlationId: string): Promise<DomainEvent[]>;
  getSince(timestamp: Date, limit?: number): Promise<DomainEvent[]>;
}

/**
 * In-Memory Event Store
 */
export class InMemoryEventStore implements EventStore {
  private events: Map<string, DomainEvent> = new Map();

  async save(event: DomainEvent): Promise<void> {
    this.events.set(event.id, event);
  }

  async getById(eventId: string): Promise<DomainEvent | null> {
    return this.events.get(eventId) || null;
  }

  async getByType(eventType: DomainEventType, limit = 100): Promise<DomainEvent[]> {
    return Array.from(this.events.values())
      .filter(event => event.type === eventType)
      .sort((a, b) => b.occurredAt.getTime() - a.occurredAt.getTime())
      .slice(0, limit);
  }

  async getByCorrelationId(correlationId: string): Promise<DomainEvent[]> {
    return Array.from(this.events.values())
      .filter(event => event.correlationId === correlationId)
      .sort((a, b) => a.occurredAt.getTime() - b.occurredAt.getTime());
  }

  async getSince(timestamp: Date, limit = 100): Promise<DomainEvent[]> {
    return Array.from(this.events.values())
      .filter(event => event.occurredAt >= timestamp)
      .sort((a, b) => b.occurredAt.getTime() - a.occurredAt.getTime())
      .slice(0, limit);
  }
}

/**
 * Event Bus Factory
 */
export function createEventBus(): EventBus {
  return new InMemoryEventBus();
}

export function createEventStore(): EventStore {
  return new InMemoryEventStore();
}

/**
 * Common event payloads
 */
export const EventPayloads = {
  reportCreated: (reportId: string, title: string, severity: string, category?: string) => ({
    reportId,
    title,
    severity,
    category,
    timestamp: new Date().toISOString()
  }),

  taskCreated: (taskId: string, reportId: string, title: string, priority: number, assignee?: string) => ({
    taskId,
    reportId,
    title,
    priority,
    assignee,
    timestamp: new Date().toISOString()
  }),

  taskStateChanged: (taskId: string, fromState: string, toState: string, actor: string) => ({
    taskId,
    fromState,
    toState,
    actor,
    timestamp: new Date().toISOString()
  }),

  slaWarning: (taskId: string, dueAt: string, hoursRemaining: number) => ({
    taskId,
    dueAt,
    hoursRemaining,
    timestamp: new Date().toISOString()
  }),

  slaBreached: (taskId: string, dueAt: string, hoursOverdue: number) => ({
    taskId,
    dueAt,
    hoursOverdue,
    timestamp: new Date().toISOString()
  })
};
