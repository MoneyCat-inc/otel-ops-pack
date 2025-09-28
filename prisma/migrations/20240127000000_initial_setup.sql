-- Resonai Backend - Database Migration Scripts
-- Initial database setup and schema creation

-- =============================================================================
-- INITIAL MIGRATION: Create all tables
-- =============================================================================

-- Enable UUID extension for PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- CORE USER MANAGEMENT
-- =============================================================================

-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    email TEXT UNIQUE,
    consent_share_metrics BOOLEAN DEFAULT FALSE,
    consent_share_clips BOOLEAN DEFAULT FALSE,
    consent_coach_portal BOOLEAN DEFAULT FALSE,
    user_id_hash TEXT UNIQUE NOT NULL
);

-- Sessions table
CREATE TABLE sessions (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT
);

-- Magic links table
CREATE TABLE magic_links (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    email TEXT NOT NULL,
    token TEXT UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    redirect_url TEXT,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- ENGAGEMENT & PROGRESS TRACKING
-- =============================================================================

-- Engagement profiles table
CREATE TABLE engagement_profiles (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    streak_days INTEGER DEFAULT 0,
    last_practice_at TIMESTAMP WITH TIME ZONE,
    last_sync_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reduced_motion BOOLEAN DEFAULT FALSE,
    theme TEXT DEFAULT 'auto',
    preferred_language TEXT DEFAULT 'en'
);

-- Badges table
CREATE TABLE badges (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_type TEXT NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB,
    UNIQUE(user_id, badge_type)
);

-- =============================================================================
-- COHORT ANALYTICS (PRIVACY-SAFE)
-- =============================================================================

-- Events table
CREATE TABLE events (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ts TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    kind TEXT NOT NULL,
    props JSONB NOT NULL,
    schema TEXT DEFAULT 'v1',
    cohort TEXT NOT NULL
);

-- =============================================================================
-- NARRATIVE CONTENT (STATIC, VERSIONED)
-- =============================================================================

-- Story chapters table
CREATE TABLE story_chapters (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    chapter_id TEXT UNIQUE NOT NULL,
    version TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    choices JSONB NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(chapter_id, version)
);

-- Story progress table
CREATE TABLE story_progress (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chapter_id TEXT NOT NULL REFERENCES story_chapters(id),
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    choices JSONB,
    UNIQUE(user_id, chapter_id)
);

-- =============================================================================
-- COACH PORTAL (E2E ENCRYPTED)
-- =============================================================================

-- Coach grants table
CREATE TABLE coach_grants (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coach_id TEXT NOT NULL,
    scope TEXT NOT NULL CHECK (scope IN ('METRICS', 'NOTES')),
    encrypted_blob TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- =============================================================================
-- CONSENT & PRIVACY AUDIT
-- =============================================================================

-- Consent audit log table
CREATE TABLE consent_audit_log (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    field TEXT NOT NULL,
    old_value BOOLEAN NOT NULL,
    new_value BOOLEAN NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT
);

-- =============================================================================
-- FEEDBACK & MODERATION
-- =============================================================================

-- Feedback reports table
CREATE TABLE feedback_reports (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    type TEXT NOT NULL CHECK (type IN ('GENERAL', 'BUG_REPORT', 'FEATURE_REQUEST', 'ACCESSIBILITY', 'PRIVACY_CONCERN')),
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'))
);

-- =============================================================================
-- FEATURE FLAGS & COHORTS
-- =============================================================================

-- Feature flags table
CREATE TABLE feature_flags (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    rollout DECIMAL(3,2) DEFAULT 0.0 CHECK (rollout >= 0.0 AND rollout <= 1.0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cohort assignments table
CREATE TABLE cohort_assignments (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id_hash TEXT NOT NULL,
    cohort TEXT NOT NULL,
    feature_flags JSONB NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id_hash, cohort)
);

-- =============================================================================
-- DATA EXPORT & DELETION TRACKING
-- =============================================================================

-- Data exports table
CREATE TABLE data_exports (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'EXPIRED')),
    file_path TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Deletion log table
CREATE TABLE deletion_log (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    user_id TEXT NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reason TEXT,
    data_types JSONB NOT NULL
);

-- =============================================================================
-- BACKGROUND JOB TRACKING
-- =============================================================================

-- Background jobs table
CREATE TABLE background_jobs (
    id TEXT PRIMARY KEY DEFAULT ulid(),
    type TEXT NOT NULL CHECK (type IN ('SESSION_CLEANUP', 'COACH_GRANT_CLEANUP', 'DATA_EXPORT_CLEANUP', 'EVENT_RETENTION_CLEANUP', 'MAGIC_LINK_CLEANUP', 'ENGAGEMENT_ROLLUP', 'COHORT_ANALYTICS', 'HEALTH_CHECK')),
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'RETRYING')),
    payload JSONB,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    error TEXT,
    retry_count INTEGER DEFAULT 0
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_id_hash ON users(user_id_hash);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Session indexes
CREATE INDEX idx_sessions_token ON sessions(token);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);

-- Magic link indexes
CREATE INDEX idx_magic_links_token ON magic_links(token);
CREATE INDEX idx_magic_links_expires_at ON magic_links(expires_at);
CREATE INDEX idx_magic_links_email ON magic_links(email);

-- Engagement indexes
CREATE INDEX idx_engagement_profiles_user_id ON engagement_profiles(user_id);
CREATE INDEX idx_engagement_profiles_last_practice_at ON engagement_profiles(last_practice_at);
CREATE INDEX idx_engagement_profiles_last_sync_at ON engagement_profiles(last_sync_at);

-- Badge indexes
CREATE INDEX idx_badges_user_id ON badges(user_id);
CREATE INDEX idx_badges_badge_type ON badges(badge_type);
CREATE INDEX idx_badges_unlocked_at ON badges(unlocked_at);

-- Event indexes
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_cohort_ts ON events(cohort, ts);
CREATE INDEX idx_events_kind_ts ON events(kind, ts);
CREATE INDEX idx_events_ts ON events(ts);

-- Story chapter indexes
CREATE INDEX idx_story_chapters_chapter_id ON story_chapters(chapter_id);
CREATE INDEX idx_story_chapters_version ON story_chapters(version);
CREATE INDEX idx_story_chapters_published_at ON story_chapters(published_at);
CREATE INDEX idx_story_chapters_is_active ON story_chapters(is_active);

-- Story progress indexes
CREATE INDEX idx_story_progress_user_id ON story_progress(user_id);
CREATE INDEX idx_story_progress_chapter_id ON story_progress(chapter_id);
CREATE INDEX idx_story_progress_completed_at ON story_progress(completed_at);

-- Coach grant indexes
CREATE INDEX idx_coach_grants_user_id ON coach_grants(user_id);
CREATE INDEX idx_coach_grants_coach_id ON coach_grants(coach_id);
CREATE INDEX idx_coach_grants_expires_at ON coach_grants(expires_at);
CREATE INDEX idx_coach_grants_is_active ON coach_grants(is_active);

-- Consent audit indexes
CREATE INDEX idx_consent_audit_log_user_id ON consent_audit_log(user_id);
CREATE INDEX idx_consent_audit_log_changed_at ON consent_audit_log(changed_at);

-- Feedback report indexes
CREATE INDEX idx_feedback_reports_user_id ON feedback_reports(user_id);
CREATE INDEX idx_feedback_reports_type ON feedback_reports(type);
CREATE INDEX idx_feedback_reports_status ON feedback_reports(status);
CREATE INDEX idx_feedback_reports_created_at ON feedback_reports(created_at);

-- Feature flag indexes
CREATE INDEX idx_feature_flags_name ON feature_flags(name);
CREATE INDEX idx_feature_flags_is_active ON feature_flags(is_active);

-- Cohort assignment indexes
CREATE INDEX idx_cohort_assignments_user_id_hash ON cohort_assignments(user_id_hash);
CREATE INDEX idx_cohort_assignments_cohort ON cohort_assignments(cohort);

-- Data export indexes
CREATE INDEX idx_data_exports_user_id ON data_exports(user_id);
CREATE INDEX idx_data_exports_status ON data_exports(status);
CREATE INDEX idx_data_exports_expires_at ON data_exports(expires_at);

-- Deletion log indexes
CREATE INDEX idx_deletion_log_user_id ON deletion_log(user_id);
CREATE INDEX idx_deletion_log_deleted_at ON deletion_log(deleted_at);

-- Background job indexes
CREATE INDEX idx_background_jobs_type ON background_jobs(type);
CREATE INDEX idx_background_jobs_status ON background_jobs(status);
CREATE INDEX idx_background_jobs_started_at ON background_jobs(started_at);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_engagement_profiles_updated_at BEFORE UPDATE ON engagement_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feature_flags_updated_at BEFORE UPDATE ON feature_flags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- CONSTRAINTS AND VALIDATIONS
-- =============================================================================

-- Add check constraints for data validation
ALTER TABLE events ADD CONSTRAINT check_event_props_size CHECK (jsonb_array_length(jsonb_object_keys(props)) <= 10);
ALTER TABLE story_chapters ADD CONSTRAINT check_version_format CHECK (version ~ '^\d{8}$');
ALTER TABLE engagement_profiles ADD CONSTRAINT check_streak_days_range CHECK (streak_days >= 0 AND streak_days <= 365);
ALTER TABLE engagement_profiles ADD CONSTRAINT check_theme_values CHECK (theme IN ('light', 'dark', 'auto'));
ALTER TABLE engagement_profiles ADD CONSTRAINT check_language_format CHECK (char_length(preferred_language) = 2);

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert default feature flags
INSERT INTO feature_flags (name, description, is_active, rollout) VALUES
('magic_link_auth', 'Enable magic link authentication', TRUE, 1.0),
('passkey_auth', 'Enable passkey authentication', FALSE, 0.0),
('coach_portal', 'Enable coach portal features', TRUE, 1.0),
('story_progress', 'Enable story progress tracking', TRUE, 1.0),
('feedback_system', 'Enable feedback and moderation system', TRUE, 1.0),
('analytics_tracking', 'Enable analytics and cohort tracking', TRUE, 1.0);

-- Insert sample story chapters (for testing)
INSERT INTO story_chapters (chapter_id, version, title, body, choices) VALUES
('welcome', '20240127', 'Welcome to Resonai', 'Welcome to your journey with Resonai! This is where your story begins.', '[]'),
('first_practice', '20240127', 'Your First Practice', 'Ready to start practicing? Let''s begin with some basic exercises.', '[{"id": "continue", "label": "Continue", "next": "practice_exercises"}]'),
('practice_exercises', '20240127', 'Practice Exercises', 'Here are some exercises to help you get started with your practice.', '[{"id": "complete", "label": "Complete Practice", "next": "reflection"}]'),
('reflection', '20240127', 'Reflection', 'Take a moment to reflect on your practice session.', '[{"id": "finish", "label": "Finish Session", "next": "complete"}]');

-- =============================================================================
-- GRANTS AND PERMISSIONS
-- =============================================================================

-- Create application user (adjust username/password as needed)
-- CREATE USER resonai_app WITH PASSWORD 'your_secure_password';
-- GRANT CONNECT ON DATABASE resonai TO resonai_app;
-- GRANT USAGE ON SCHEMA public TO resonai_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO resonai_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO resonai_app;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Log migration completion
INSERT INTO background_jobs (type, status, payload, completed_at) VALUES
('HEALTH_CHECK', 'COMPLETED', '{"migration": "initial", "version": "1.0.0"}', NOW());

-- Display completion message
DO $$
BEGIN
    RAISE NOTICE 'Resonai database migration completed successfully!';
    RAISE NOTICE 'Tables created: users, sessions, magic_links, engagement_profiles, badges, events, story_chapters, story_progress, coach_grants, consent_audit_log, feedback_reports, feature_flags, cohort_assignments, data_exports, deletion_log, background_jobs';
    RAISE NOTICE 'Indexes created: 25+ performance indexes';
    RAISE NOTICE 'Constraints added: Data validation and referential integrity';
    RAISE NOTICE 'Initial data: Feature flags and sample story chapters';
END $$;
