/**
 * ECRR Notification Router
 * Intelligent notification routing with batching and deduplication
 */

import { DomainEvent, DomainEventType } from '../events/event-bus';

export interface NotificationChannel {
  id: string;
  type: 'email' | 'slack' | 'webhook' | 'sms';
  config: Record<string, any>;
  enabled: boolean;
  rateLimit?: {
    maxPerHour: number;
    maxPerDay: number;
  };
}

export interface NotificationTemplate {
  id: string;
  eventType: DomainEventType;
  channels: string[];
  subject?: string;
  body: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  batchable: boolean;
  digestKey?: string;
  cooldownMinutes?: number;
}

export interface Notification {
  id: string;
  channelId: string;
  templateId: string;
  recipient: string;
  subject?: string;
  body: string;
  variables: Record<string, any>;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'sent' | 'failed' | 'rate_limited';
  digestKey?: string;
  createdAt: Date;
  sentAt?: Date;
  errorMessage?: string;
  retryCount: number;
  maxRetries: number;
}

export interface NotificationMatrix {
  [eventType: string]: {
    channels: string[];
    templates: string[];
    conditions?: {
      severity?: string[];
      priority?: number[];
      assignee?: boolean;
      oncall?: boolean;
    };
  };
}

/**
 * Notification Router
 */
export class NotificationRouter {
  private channels: Map<string, NotificationChannel> = new Map();
  private templates: Map<string, NotificationTemplate> = new Map();
  private matrix: NotificationMatrix = {};
  private pendingNotifications: Map<string, Notification[]> = new Map();
  private sentNotifications: Map<string, Date> = new Map();

  constructor() {
    this.initializeDefaultChannels();
    this.initializeDefaultTemplates();
    this.initializeNotificationMatrix();
  }

  /**
   * Route an event to appropriate notification channels
   */
  async routeEvent(event: DomainEvent): Promise<void> {
    const matrixEntry = this.matrix[event.type];
    if (!matrixEntry) {
      console.log(`No notification matrix entry for event type: ${event.type}`);
      return;
    }

    // Check conditions
    if (matrixEntry.conditions && !this.evaluateConditions(event, matrixEntry.conditions)) {
      console.log(`Conditions not met for event: ${event.type}`);
      return;
    }

    // Get applicable templates
    const applicableTemplates = matrixEntry.templates
      .map(templateId => this.templates.get(templateId))
      .filter(template => template && this.isEventApplicable(event, template));

    // Generate notifications for each template
    for (const template of applicableTemplates) {
      if (!template) continue;

      const notifications = await this.generateNotifications(event, template);
      for (const notification of notifications) {
        await this.queueNotification(notification);
      }
    }
  }

  /**
   * Process pending notifications (called by scheduler)
   */
  async processPendingNotifications(): Promise<void> {
    const pending = Array.from(this.pendingNotifications.values()).flat();
    
    for (const notification of pending) {
      try {
        await this.sendNotification(notification);
        notification.status = 'sent';
        notification.sentAt = new Date();
        
        // Track for rate limiting
        this.trackSentNotification(notification);
        
      } catch (error) {
        notification.status = 'failed';
        notification.errorMessage = error instanceof Error ? error.message : 'Unknown error';
        notification.retryCount++;
        
        // Retry logic
        if (notification.retryCount < notification.maxRetries) {
          setTimeout(() => this.queueNotification(notification), 60000); // Retry in 1 minute
        }
      }
    }

    // Clear processed notifications
    this.pendingNotifications.clear();
  }

  /**
   * Generate notifications from template and event
   */
  private async generateNotifications(
    event: DomainEvent,
    template: NotificationTemplate
  ): Promise<Notification[]> {
    const notifications: Notification[] = [];

    for (const channelId of template.channels) {
      const channel = this.channels.get(channelId);
      if (!channel || !channel.enabled) continue;

      // Determine recipients
      const recipients = this.getRecipients(event, channel, template);
      
      for (const recipient of recipients) {
        const notification: Notification = {
          id: this.generateNotificationId(),
          channelId,
          templateId: template.id,
          recipient,
          subject: template.subject ? this.renderTemplate(template.subject, event.payload) : undefined,
          body: this.renderTemplate(template.body, event.payload),
          variables: event.payload,
          priority: template.priority,
          status: 'pending',
          digestKey: template.digestKey ? this.renderTemplate(template.digestKey, event.payload) : undefined,
          createdAt: new Date(),
          retryCount: 0,
          maxRetries: 3
        };

        notifications.push(notification);
      }
    }

    return notifications;
  }

  /**
   * Queue notification for sending
   */
  private async queueNotification(notification: Notification): Promise<void> {
    // Check rate limiting
    if (this.isRateLimited(notification)) {
      notification.status = 'rate_limited';
      return;
    }

    // Check cooldown
    if (this.isInCooldown(notification)) {
      return;
    }

    // Add to pending queue
    if (!this.pendingNotifications.has(notification.channelId)) {
      this.pendingNotifications.set(notification.channelId, []);
    }
    this.pendingNotifications.get(notification.channelId)!.push(notification);
  }

  /**
   * Send notification via appropriate channel
   */
  private async sendNotification(notification: Notification): Promise<void> {
    const channel = this.channels.get(notification.channelId);
    if (!channel) {
      throw new Error(`Channel not found: ${notification.channelId}`);
    }

    switch (channel.type) {
      case 'email':
        await this.sendEmail(notification, channel);
        break;
      case 'slack':
        await this.sendSlack(notification, channel);
        break;
      case 'webhook':
        await this.sendWebhook(notification, channel);
        break;
      case 'sms':
        await this.sendSms(notification, channel);
        break;
      default:
        throw new Error(`Unsupported channel type: ${channel.type}`);
    }
  }

  /**
   * Email channel implementation
   */
  private async sendEmail(notification: Notification, _channel: NotificationChannel): Promise<void> {
    // Implementation would integrate with email service (SendGrid, SES, etc.)
    console.log(`Sending email to ${notification.recipient}: ${notification.subject || 'No Subject'}`);
    console.log(`Body: ${notification.body}`);
  }

  /**
   * Slack channel implementation
   */
  private async sendSlack(notification: Notification, _channel: NotificationChannel): Promise<void> {
    // Implementation would integrate with Slack API
    console.log(`Sending Slack message to ${notification.recipient}`);
    console.log(`Message: ${notification.body}`);
  }

  /**
   * Webhook channel implementation
   */
  private async sendWebhook(notification: Notification, channel: NotificationChannel): Promise<void> {
    // Implementation would make HTTP POST to webhook URL
    console.log(`Sending webhook to ${channel.config['url']}`);
    console.log(`Payload: ${JSON.stringify(notification)}`);
  }

  /**
   * SMS channel implementation
   */
  private async sendSms(notification: Notification, _channel: NotificationChannel): Promise<void> {
    // Implementation would integrate with SMS service (Twilio, etc.)
    console.log(`Sending SMS to ${notification.recipient}: ${notification.body}`);
  }

  /**
   * Initialize default notification channels
   */
  private initializeDefaultChannels(): void {
    this.channels.set('email-primary', {
      id: 'email-primary',
      type: 'email',
      config: {
        smtpHost: process.env['SMTP_HOST'] || 'localhost',
        smtpPort: parseInt(process.env['SMTP_PORT'] || '587'),
        username: process.env['SMTP_USERNAME'],
        password: process.env['SMTP_PASSWORD'],
        from: process.env['SMTP_FROM'] || 'noreply@company.com'
      },
      enabled: true,
      rateLimit: { maxPerHour: 100, maxPerDay: 1000 }
    });

    this.channels.set('slack-ops', {
      id: 'slack-ops',
      type: 'slack',
      config: {
        webhookUrl: process.env['SLACK_WEBHOOK_URL'],
        channel: '#ops-alerts'
      },
      enabled: true,
      rateLimit: { maxPerHour: 200, maxPerDay: 2000 }
    });

    this.channels.set('slack-ecrr', {
      id: 'slack-ecrr',
      type: 'slack',
      config: {
        webhookUrl: process.env['SLACK_ECRR_WEBHOOK_URL'],
        channel: '#ecrr-updates'
      },
      enabled: true,
      rateLimit: { maxPerHour: 100, maxPerDay: 1000 }
    });
  }

  /**
   * Initialize default notification templates
   */
  private initializeDefaultTemplates(): void {
    // Task created template
    this.templates.set('task-created', {
      id: 'task-created',
      eventType: 'TaskCreated' as DomainEventType,
      channels: ['email-primary', 'slack-ops'],
      subject: 'New Task Assigned: {{title}}',
      body: `A new task has been assigned to you:

**Task:** {{title}}
**Priority:** {{priority}}
**Due Date:** {{slaDueAt}}
**Report:** {{reportTitle}}

Please review and begin work on this task.`,
      priority: 'medium',
      batchable: false,
      cooldownMinutes: 0
    });

    // SLA warning template
    this.templates.set('sla-warning', {
      id: 'sla-warning',
      eventType: 'SLAWarning' as DomainEventType,
      channels: ['slack-ops', 'email-primary'],
      body: `⚠️ SLA Warning: Task "{{title}}" is due in {{hoursRemaining}} hours

**Assignee:** {{assignee}}
**Priority:** {{priority}}
**Report:** {{reportTitle}}

Please prioritize this task to avoid SLA breach.`,
      priority: 'high',
      batchable: true,
      digestKey: 'assignee:daily',
      cooldownMinutes: 60
    });

    // SLA breach template
    this.templates.set('sla-breach', {
      id: 'sla-breach',
      eventType: 'SLABreached' as DomainEventType,
      channels: ['slack-ops', 'email-primary'],
      body: `🚨 SLA BREACHED: Task "{{title}}" is {{hoursOverdue}} hours overdue

**Assignee:** {{assignee}}
**Priority:** {{priority}}
**Report:** {{reportTitle}}

This task requires immediate attention.`,
      priority: 'urgent',
      batchable: false,
      cooldownMinutes: 0
    });
  }

  /**
   * Initialize notification matrix
   */
  private initializeNotificationMatrix(): void {
    this.matrix = {
      'TaskCreated': {
        channels: ['email-primary', 'slack-ops'],
        templates: ['task-created'],
        conditions: {
          assignee: true
        }
      },
      'SLAWarning': {
        channels: ['slack-ops', 'email-primary'],
        templates: ['sla-warning'],
        conditions: {
          priority: [1, 2, 3] // Only warn for high/medium priority tasks
        }
      },
      'SLABreached': {
        channels: ['slack-ops', 'email-primary'],
        templates: ['sla-breach'],
        conditions: {
          priority: [1, 2] // Only escalate high/critical priority breaches
        }
      },
      'ReportCreated': {
        channels: ['slack-ecrr'],
        templates: ['report-created'],
        conditions: {
          severity: ['high', 'critical']
        }
      }
    };
  }

  // Helper methods
  private evaluateConditions(_event: DomainEvent, _conditions: any): boolean {
    // Implementation for condition evaluation
    return true; // Simplified for now
  }

  private isEventApplicable(event: DomainEvent, template: NotificationTemplate): boolean {
    return template.eventType === event.type;
  }

  private getRecipients(event: DomainEvent, _channel: NotificationChannel, _template: NotificationTemplate): string[] {
    // Implementation would determine recipients based on event and template
    return [event.payload['assignee'] || event.payload['owner'] || 'default@company.com'];
  }

  private renderTemplate(template: string, variables: Record<string, any>): string {
    return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
      return variables[key] || match;
    });
  }

  private generateNotificationId(): string {
    return `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private isRateLimited(notification: Notification): boolean {
    const channel = this.channels.get(notification.channelId);
    if (!channel?.rateLimit) return false;

    // Implementation would check rate limits
    return false; // Simplified for now
  }

  private isInCooldown(notification: Notification): boolean {
    const template = this.templates.get(notification.templateId);
    if (!template?.cooldownMinutes) return false;

    // Implementation would check cooldown
    return false; // Simplified for now
  }

  private trackSentNotification(notification: Notification): void {
    const key = `${notification.channelId}:${notification.recipient}`;
    this.sentNotifications.set(key, new Date());
  }
}
