-- ECRR Phase 1 Database Schema
-- Automated Task Generation & Workflow Automation

-- Reports (existing source; included for FK completeness)
CREATE TABLE IF NOT EXISTS reports (
  id                UUID PRIMARY KEY,
  title             TEXT NOT NULL,
  severity          TEXT CHECK (severity IN ('low','medium','high','critical')),
  category          TEXT,
  discovered_at     TIMESTAMPTZ NOT NULL,
  status            TEXT,     -- open, closed, etc.
  raw               JSONB     -- original payload
);

-- Tasks (new - core of automation system)
CREATE TABLE IF NOT EXISTS tasks (
  id                UUID PRIMARY KEY,
  report_id         UUID REFERENCES reports(id) ON DELETE CASCADE,
  kind              TEXT NOT NULL,         -- e.g. "analysis", "fix", "validation"
  title             TEXT NOT NULL,
  description       TEXT,
  priority          INT NOT NULL,          -- 1 (highest) .. 5 (lowest)
  sla_due_at        TIMESTAMPTZ,
  state             TEXT NOT NULL,         -- see state machine below
  assignee          TEXT,                   -- user handle/email
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now(),
  meta              JSONB                   -- arbitrary (e.g. labels, dependencies)
);

-- Task Events (audit trail and workflow triggers)
CREATE TABLE IF NOT EXISTS task_events (
  id                BIGSERIAL PRIMARY KEY,
  task_id           UUID REFERENCES tasks(id) ON DELETE CASCADE,
  event_type        TEXT NOT NULL,         -- CREATED, STATE_CHANGED, SLA_TICK, ESCALATED, NOTIFIED
  payload           JSONB,
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- Users (for assignment and WIP tracking)
CREATE TABLE IF NOT EXISTS users (
  id                UUID PRIMARY KEY,
  name              TEXT NOT NULL,
  email             TEXT UNIQUE NOT NULL,
  skills            TEXT[],                -- array of skill tags
  max_wip           INT DEFAULT 5,         -- maximum work in progress
  oncall            BOOLEAN DEFAULT false,
  active            BOOLEAN DEFAULT true,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

-- Workflow Events (event bus)
CREATE TABLE IF NOT EXISTS workflow_events (
  id                UUID PRIMARY KEY,
  event_type        TEXT NOT NULL,         -- ReportCreated, ReportUpdated, TaskCompleted, SLAWarning
  payload           JSONB NOT NULL,
  occurred_at       TIMESTAMPTZ DEFAULT now(),
  correlation_id    UUID,                  -- for grouping related events
  processed         BOOLEAN DEFAULT false
);

-- Notification Queue (for batching and deduplication)
CREATE TABLE IF NOT EXISTS notification_queue (
  id                UUID PRIMARY KEY,
  channel           TEXT NOT NULL,         -- email, slack, webhook
  recipient         TEXT NOT NULL,         -- email, user_id, webhook_url
  template          TEXT NOT NULL,
  variables         JSONB,
  digest_key        TEXT,                  -- for batching similar notifications
  status            TEXT DEFAULT 'pending', -- pending, sent, failed
  created_at        TIMESTAMPTZ DEFAULT now(),
  sent_at           TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_report ON tasks(report_id);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_state ON tasks(state);
CREATE INDEX IF NOT EXISTS idx_tasks_sla ON tasks(sla_due_at);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee);

CREATE INDEX IF NOT EXISTS idx_task_events_task ON task_events(task_id);
CREATE INDEX IF NOT EXISTS idx_task_events_type ON task_events(event_type);
CREATE INDEX IF NOT EXISTS idx_task_events_created ON task_events(created_at);

CREATE INDEX IF NOT EXISTS idx_workflow_events_type ON workflow_events(event_type);
CREATE INDEX IF NOT EXISTS idx_workflow_events_processed ON workflow_events(processed);
CREATE INDEX IF NOT EXISTS idx_workflow_events_occurred ON workflow_events(occurred_at);

CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_notification_queue_digest ON notification_queue(digest_key);
CREATE INDEX IF NOT EXISTS idx_notification_queue_created ON notification_queue(created_at);

-- Constraints for state machine
ALTER TABLE tasks ADD CONSTRAINT check_task_state 
  CHECK (state IN ('NEW', 'TRIAGE', 'IN_PROGRESS', 'REVIEW', 'DONE', 'BLOCKED'));

ALTER TABLE tasks ADD CONSTRAINT check_task_priority 
  CHECK (priority >= 1 AND priority <= 5);

-- Views for common queries
CREATE OR REPLACE VIEW task_summary AS
SELECT 
  t.id,
  t.title,
  t.state,
  t.priority,
  t.assignee,
  t.sla_due_at,
  r.title as report_title,
  r.severity,
  CASE 
    WHEN t.sla_due_at < now() THEN 'OVERDUE'
    WHEN t.sla_due_at < now() + interval '24 hours' THEN 'DUE_SOON'
    ELSE 'ON_TRACK'
  END as sla_status
FROM tasks t
JOIN reports r ON t.report_id = r.id
WHERE t.state NOT IN ('DONE');

-- KPI calculation views
CREATE OR REPLACE VIEW automation_coverage AS
SELECT 
  COUNT(*) FILTER (WHERE meta->>'auto_generated' = 'true') as auto_tasks,
  COUNT(*) as total_tasks,
  ROUND(
    COUNT(*) FILTER (WHERE meta->>'auto_generated' = 'true')::numeric / 
    COUNT(*)::numeric * 100, 2
  ) as coverage_percent
FROM tasks
WHERE created_at > now() - interval '30 days';

CREATE OR REPLACE VIEW sla_breach_rate AS
SELECT 
  COUNT(*) FILTER (WHERE sla_due_at < now() AND state NOT IN ('DONE')) as overdue_tasks,
  COUNT(*) FILTER (WHERE sla_due_at IS NOT NULL) as tasks_with_sla,
  ROUND(
    COUNT(*) FILTER (WHERE sla_due_at < now() AND state NOT IN ('DONE'))::numeric / 
    COUNT(*) FILTER (WHERE sla_due_at IS NOT NULL)::numeric * 100, 2
  ) as breach_rate_percent
FROM tasks
WHERE created_at > now() - interval '30 days';
