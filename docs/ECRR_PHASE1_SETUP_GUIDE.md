# ECRR Phase 1 Setup Guide
## Automated Task Generation & Workflow Automation

This guide walks you through setting up the complete ECRR Phase 1 automation system, including automated task generation, workflow automation, notifications, and dashboard.

## 🎯 What You'll Get

- **Automated Task Generation**: Reports automatically spawn prioritized tasks with assignees and due dates
- **Event-Driven Workflow**: State machine manages task lifecycle with automated transitions
- **Smart Notifications**: Intelligent routing with batching and deduplication
- **Real-Time Dashboard**: KPIs, trends, and alerts for system health
- **Migration Tools**: Seamless migration of existing 29 open reports

## 📋 Prerequisites

- Node.js 18+ with TypeScript
- PostgreSQL 14+ (or compatible database)
- SMTP server for email notifications (optional)
- Slack workspace for notifications (optional)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install express cors helmet morgan
npm install -D typescript @types/node @types/express
npm install -D ts-node nodemon
```

### 2. Database Setup

```bash
# Create database
createdb ecrr_automation

# Run schema migration
psql ecrr_automation < src/database/schema.sql
```

### 3. Environment Configuration

Create `.env` file:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/ecrr_automation

# Notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@company.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@company.com

SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
SLACK_ECRR_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/ECRR/WEBHOOK

# API
PORT=3000
API_KEY=your-secure-api-key
```

### 4. Run Migration

```bash
# Migrate existing reports
npx ts-node scripts/migrate-ecrr-reports.ts
```

### 5. Start the System

```bash
# Development
npm run dev

# Production
npm run build
npm start
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Reports API   │───▶│  Event Bus      │───▶│ Notification    │
│                 │    │                 │    │ Router          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Tasks API     │◀───│  State Machine  │───▶│   Dashboard     │
│                 │    │                 │    │   API           │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   Database      │    │   KPI Calculator│
│   (PostgreSQL)  │    │                 │
└─────────────────┘    └─────────────────┘
```

## 📊 Key Components

### 1. Database Schema

The system uses PostgreSQL with the following main tables:

- **`reports`**: Source reports from ECRR process
- **`tasks`**: Generated tasks with priority, assignment, and SLA
- **`task_events`**: Audit trail for task state changes
- **`workflow_events`**: Event bus for system automation
- **`notification_queue`**: Batched notification system
- **`users`**: User management with skills and WIP limits

### 2. Priority Engine

Automatically calculates task priority based on:

```typescript
priority_score = 
  400 * impact_weight(severity) +
  3   * report_age_days +
  15  * is_blocked +
  25  * missing_owner +
  10  * (open_tasks_on_report > 5)
```

**Priority Levels:**
- P1 (Critical): 2 business days SLA
- P2 (High): 5 business days SLA  
- P3 (Medium): 10 business days SLA
- P4 (Low): 20 business days SLA
- P5 (Backlog): 30 business days SLA

### 3. Assignment Engine

Intelligent task assignment with:

- **Skill Matching**: Assigns based on required skills from category/labels
- **WIP Management**: Respects user work-in-progress limits
- **On-Call Priority**: Prefers on-call users for urgent tasks
- **Round-Robin Fallback**: Fair distribution when skills match

### 4. State Machine

Formalized task lifecycle:

```
NEW → TRIAGE → IN_PROGRESS → REVIEW → DONE
             ↘ BLOCKED ↗
```

**Automated Transitions:**
- `NEW → TRIAGE`: Auto on creation
- `BLOCKED → TRIAGE`: Auto when dependencies cleared
- `IN_PROGRESS → REVIEW`: When assignee marks complete
- `REVIEW → DONE`: When reviewer approves

### 5. Notification System

Smart notifications with:

- **Multi-Channel**: Email, Slack, Webhooks, SMS
- **Batching**: Groups similar notifications to reduce noise
- **Deduplication**: Prevents duplicate alerts
- **Rate Limiting**: Respects channel limits
- **Template System**: Customizable message templates

## 🔧 Configuration

### Task Templates

Edit `config/task-templates.yaml` to customize task generation:

```yaml
templates:
  security:
    category: security
    required_skills: ['security', 'compliance']
    tasks:
      - kind: analysis
        title: "Triage security report: {{title}}"
        default_assignee: "sec-triage"
        priority_boost: 2
        sla_override: 24 # hours
```

### Notification Matrix

Configure notification routing in `src/notifications/notification-router.ts`:

```typescript
this.matrix = {
  'TaskCreated': {
    channels: ['email-primary', 'slack-ops'],
    templates: ['task-created'],
    conditions: { assignee: true }
  },
  'SLAWarning': {
    channels: ['slack-ops', 'email-primary'],
    templates: ['sla-warning'],
    conditions: { priority: [1, 2, 3] }
  }
};
```

### Priority Rules

Customize priority calculation in `src/rules/priority-calculator.ts`:

```typescript
const severityWeights = {
  critical: 10,
  high: 7,
  medium: 4,
  low: 1
};

const manualBoost = (labels || []).reduce((acc, label) => {
  switch (label) {
    case 'compliance': return acc + 3;
    case 'customer_impact': return acc + 2;
    case 'security': return acc + 4;
    default: return acc;
  }
}, 0);
```

## 📈 Dashboard & KPIs

### Key Metrics

- **Automation Coverage**: % of tasks auto-generated (target: ≥90%)
- **SLA Compliance**: % of tasks completed on time (target: ≥95%)
- **Time to Task**: Average time from report to first task (target: <60s)
- **Escalation Rate**: % of tasks that require escalation (target: <10%)
- **Reopen Rate**: % of completed tasks that are reopened (target: <5%)

### Dashboard Endpoints

```bash
# Main dashboard
GET /api/dashboard

# Specific KPIs
GET /api/dashboard/kpi/automation-coverage?days=30
GET /api/dashboard/kpi/sla-compliance?days=30

# Critical alerts
GET /api/dashboard/alerts

# Workload distribution
GET /api/dashboard/workload
```

## 🔄 API Usage

### Create Report

```bash
curl -X POST http://localhost:3000/api/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "title": "Security vulnerability in auth system",
    "severity": "high",
    "category": "security",
    "labels": ["security", "authentication", "production"]
  }'
```

### Generate Tasks

```bash
curl -X POST http://localhost:3000/api/reports/{reportId}/tasks \
  -H "Authorization: Bearer your-api-key"
```

### Transition Task

```bash
curl -X POST http://localhost:3000/api/tasks/{taskId}/transition \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "toState": "IN_PROGRESS",
    "actor": "alice@company.com",
    "comment": "Starting work on this task"
  }'
```

### Get Dashboard Data

```bash
curl -X GET http://localhost:3000/api/dashboard \
  -H "Authorization: Bearer your-api-key"
```

## 🚨 Monitoring & Alerts

### Health Checks

```bash
# System health
GET /api/health

# Database connectivity
GET /api/health/database

# Event bus status
GET /api/health/events
```

### Critical Alerts

The system automatically generates alerts for:

- **Low Automation Coverage** (<90%)
- **SLA Compliance Issues** (<95%)
- **High Escalation Rate** (>10%)
- **High Reopen Rate** (>5%)
- **WIP Overload** (users at capacity)

### Log Monitoring

Key log patterns to monitor:

```bash
# Task generation success
grep "TaskCreated" logs/app.log

# SLA warnings
grep "SLAWarning" logs/app.log

# Assignment failures
grep "No users available" logs/app.log

# Notification failures
grep "NotificationFailed" logs/app.log
```

## 🔧 Troubleshooting

### Common Issues

**1. Tasks not being generated**
- Check event bus connectivity
- Verify report has required fields (title, severity)
- Check task templates configuration

**2. Assignment failures**
- Verify users have correct skills
- Check WIP limits configuration
- Ensure users are active

**3. Notifications not sending**
- Verify SMTP/Slack configuration
- Check rate limiting settings
- Review notification templates

**4. Dashboard showing no data**
- Verify database connectivity
- Check KPI calculation queries
- Ensure tasks are being created

### Debug Commands

```bash
# Check event bus status
curl -X GET http://localhost:3000/api/health/events

# List recent events
curl -X GET http://localhost:3000/api/events?since=2025-01-01T00:00:00Z

# Get task transitions
curl -X GET http://localhost:3000/api/tasks/{taskId}/transitions

# Validate migration
npx ts-node scripts/validate-migration.ts
```

## 📚 Next Steps

After Phase 1 is running smoothly:

1. **Phase 2 Enhancements**:
   - Advanced analytics and ML-based prioritization
   - Integration with external systems (Jira, Linear, etc.)
   - Mobile app for task management
   - Advanced reporting and forecasting

2. **Performance Optimization**:
   - Implement caching for frequent queries
   - Add database indexing for large datasets
   - Optimize notification batching algorithms

3. **Security Hardening**:
   - Implement proper authentication/authorization
   - Add audit logging for compliance
   - Encrypt sensitive data at rest

## 🆘 Support

For issues or questions:

1. Check the troubleshooting section above
2. Review logs in `logs/app.log`
3. Validate configuration with health checks
4. Create an issue in the project repository

---

**🎉 Congratulations!** You now have a fully automated ECRR system that will transform your manual processes into an efficient, scalable workflow automation platform.
