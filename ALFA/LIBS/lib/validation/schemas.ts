// Resonai Backend - Validation Schemas
// Shared between client and server for type safety

import { z } from 'zod';

// =============================================================================
// AUTHENTICATION SCHEMAS
// =============================================================================

export const MagicLinkRequestSchema = z.object({
  email: z.string().email('Invalid email address'),
  redirectUrl: z.string().url().optional(),
});

export const AuthCallbackSchema = z.object({
  token: z.string().min(1, 'Token is required'),
  state: z.string().optional(),
});

export const PasskeyRegistrationSchema = z.object({
  credential: z.object({
    id: z.string(),
    rawId: z.string(),
    response: z.object({
      clientDataJSON: z.string(),
      attestationObject: z.string(),
    }),
    type: z.literal('public-key'),
  }),
  email: z.string().email().optional(),
});

export const PasskeyAuthenticationSchema = z.object({
  credential: z.object({
    id: z.string(),
    rawId: z.string(),
    response: z.object({
      clientDataJSON: z.string(),
      authenticatorData: z.string(),
      signature: z.string(),
      userHandle: z.string().optional(),
    }),
    type: z.literal('public-key'),
  }),
});

// =============================================================================
// CONSENT & PROFILE SCHEMAS
// =============================================================================

export const ConsentUpdateSchema = z.object({
  shareMetrics: z.boolean().optional(),
  shareClips: z.boolean().optional(),
  coachPortal: z.boolean().optional(),
}).refine(
  (data) => Object.keys(data).length > 0,
  { message: 'At least one consent field must be provided' }
);

export const EngagementProfileSchema = z.object({
  streakDays: z.number().int().min(0, 'streakDays must be >= 0').max(365, 'streakDays cannot exceed 365').optional(),
  lastPracticeAt: z.string().datetime().optional(),
  reducedMotion: z.boolean().optional(),
  theme: z.enum(['light', 'dark', 'auto'], {
    message: 'theme must be light, dark, or auto',
  }).optional(),
  preferredLanguage: z.string().length(2).optional(), // ISO 639-1
});

export const BadgeUnlockSchema = z.object({
  badgeType: z.string().min(1).max(50),
  metadata: z.record(z.string(), z.any()).optional(),
});

// =============================================================================
// EVENTS SCHEMAS (PRIVACY-SAFE)
// =============================================================================

export const EventKindSchema = z.enum([
  'session_start',
  'session_end',
  'streak_tick',
  'badge_unlock',
  'a11y_toggle',
  'consent_change',
  'feature_flag_toggle',
]);

const AUDIO_KEY_TOKENS = ['audio', 'voice', 'speech'] as const;

const PII_KEY_TOKENS = [
  'email',
  'name',
  'phone',
  'address',
  'ssn',
  'socialsecurity',
  'credit',
  'birth',
  'dob',
  'ipv4',
  'ipv6',
  'ipaddress',
  'geo',
  'latitude',
  'longitude',
  'coordinate',
  'location',
  'country',
  'region',
  'state',
  'city',
  'zipcode',
  'zip',
  'postal',
  'networklocation',
] as const;

function normalizePropKey(key: string): string {
  return key.toLowerCase().replace(/[^a-z0-9]/g, '');
}

function isAudioPropKey(normalized: string): boolean {
  return AUDIO_KEY_TOKENS.some((token) => normalized.includes(token));
}

function isPiiPropKey(normalized: string): boolean {
  if (normalized === 'ip') return true;
  return PII_KEY_TOKENS.some((token) => normalized.includes(token));
}

export const EventPropsSchema = z.record(z.string(), z.any()).superRefine((props, ctx) => {
  const keys = Object.keys(props);
  if (keys.length > 10) {
    ctx.addIssue({
      code: 'custom',
      message: 'Event properties cannot exceed 10 fields',
    });
  }

  for (const key of keys) {
    const normalized = normalizePropKey(key);
    if (isAudioPropKey(normalized)) {
      ctx.addIssue({
        code: 'custom',
        message: `Event properties cannot contain audio data (${key})`,
      });
      continue;
    }
    if (isPiiPropKey(normalized)) {
      ctx.addIssue({
        code: 'custom',
        message: `Event properties cannot contain PII (${key})`,
      });
      continue;
    }
    const value = props[key];
    if (
      typeof value !== 'string' &&
      typeof value !== 'number' &&
      typeof value !== 'boolean'
    ) {
      ctx.addIssue({
        code: 'custom',
        message: `Event property ${key} must be string, number, or boolean`,
      });
    }
  }
});

export const EventSchema = z.object({
  id: z.string().optional(), // Client can provide or server generates
  ts: z.number().int().positive().optional(), // Unix timestamp
  kind: EventKindSchema,
  props: EventPropsSchema.optional(),
  schema: z.literal('v1').optional(),
}).superRefine((event, ctx) => {
  if (event.props === undefined) {
    ctx.addIssue({
      code: 'custom',
      path: ['props'],
      message: 'props is required',
    });
  }
});

export const EventsBatchSchema = z.object({
  events: z.array(EventSchema).min(1).max(50, 'Batch cannot exceed 50 events'),
}).refine(
  (data) => {
    // Ensure batch doesn't exceed rate limits
    const now = Date.now();
    const oneHour = 60 * 60 * 1000;
    return data.events.every(event => 
      !event.ts || (now - event.ts) <= oneHour
    );
  },
  { message: 'Events cannot be older than 1 hour' }
);

// =============================================================================
// NARRATIVE SCHEMAS
// =============================================================================

export const StoryChapterRequestSchema = z.object({
  version: z.string().regex(/^\d{8}$/, 'Version must be YYYYMMDD format').optional(),
});

export const StoryProgressSchema = z.object({
  chapterId: z.string().min(1),
  choices: z.array(z.object({
    id: z.string(),
    label: z.string(),
    next: z.string(),
  })).optional(),
});

// =============================================================================
// COACH PORTAL SCHEMAS
// =============================================================================

export const CoachScopeSchema = z.enum(['metrics', 'notes']);

export const CoachGrantRequestSchema = z.object({
  coachId: z.string().min(1).max(100),
  scope: CoachScopeSchema,
  expiresAt: z.string().datetime(),
  encryptedBlob: z.string().min(1), // E2E encrypted data
});

export const CoachGrantResponseSchema = z.object({
  grantId: z.string(),
  expiresAt: z.string().datetime(),
  scope: CoachScopeSchema,
});

// =============================================================================
// FEEDBACK & MODERATION SCHEMAS
// =============================================================================

export const FeedbackTypeSchema = z.enum([
  'general',
  'bug_report',
  'feature_request',
  'accessibility',
  'privacy_concern',
]);

export const FeedbackReportSchema = z.object({
  type: FeedbackTypeSchema,
  content: z.string().min(1).max(5000),
  metadata: z.record(z.string(), z.any()).optional(),
});

export const AbuseReportSchema = z.object({
  content: z.string().min(1).max(2000),
  context: z.string().max(1000).optional(),
  category: z.enum(['harassment', 'spam', 'inappropriate', 'other']),
});

// =============================================================================
// DATA PROTECTION SCHEMAS
// =============================================================================

export const DataExportRequestSchema = z.object({
  includeEngagement: z.boolean().default(true),
  includeStoryProgress: z.boolean().default(true),
  includeFeedback: z.boolean().default(true),
  format: z.enum(['json', 'csv']).default('json'),
});

export const DataDeletionRequestSchema = z.object({
  reason: z.string().max(500).optional(),
  confirmDeletion: z.literal(true), // Must explicitly confirm
});

// =============================================================================
// FEATURE FLAGS & COHORTS
// =============================================================================

export const FeatureFlagSchema = z.object({
  name: z.string().min(1).max(50),
  description: z.string().max(200).optional(),
  isActive: z.boolean(),
  rollout: z.number().min(0).max(1),
});

export const CohortAssignmentSchema = z.object({
  userIdHash: z.string().min(1),
  cohort: z.string().min(1).max(50),
  featureFlags: z.array(z.string()),
});

// =============================================================================
// RESPONSE SCHEMAS
// =============================================================================

export const SuccessResponseSchema = z.object({
  success: z.literal(true),
  data: z.any().optional(),
  message: z.string().optional(),
});

export const ErrorResponseSchema = z.object({
  success: z.literal(false),
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.any().optional(),
  }),
});

export const PaginatedResponseSchema = z.object({
  data: z.array(z.any()),
  pagination: z.object({
    page: z.number().int().positive(),
    limit: z.number().int().positive(),
    total: z.number().int().nonnegative(),
    hasNext: z.boolean(),
    hasPrev: z.boolean(),
  }),
});

// =============================================================================
// UTILITY SCHEMAS
// =============================================================================

export const PaginationSchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().positive().max(100).default(20),
  sort: z.string().optional(),
  order: z.enum(['asc', 'desc']).default('desc'),
});

export const DateRangeSchema = z.object({
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
}).refine(
  (data) => {
    if (!data.startDate || !data.endDate) return true;
    return new Date(data.startDate) <= new Date(data.endDate);
  },
  { message: 'Start date must be before end date' }
);

// =============================================================================
// TYPE EXPORTS
// =============================================================================

export type MagicLinkRequest = z.infer<typeof MagicLinkRequestSchema>;
export type AuthCallback = z.infer<typeof AuthCallbackSchema>;
export type PasskeyRegistration = z.infer<typeof PasskeyRegistrationSchema>;
export type PasskeyAuthentication = z.infer<typeof PasskeyAuthenticationSchema>;

export type ConsentUpdate = z.infer<typeof ConsentUpdateSchema>;
export type EngagementProfile = z.infer<typeof EngagementProfileSchema>;
export type BadgeUnlock = z.infer<typeof BadgeUnlockSchema>;

export type EventKind = z.infer<typeof EventKindSchema>;
export type EventProps = z.infer<typeof EventPropsSchema>;
export type Event = z.infer<typeof EventSchema>;
export type EventsBatch = z.infer<typeof EventsBatchSchema>;

export type StoryChapterRequest = z.infer<typeof StoryChapterRequestSchema>;
export type StoryProgress = z.infer<typeof StoryProgressSchema>;

export type CoachScope = z.infer<typeof CoachScopeSchema>;
export type CoachGrantRequest = z.infer<typeof CoachGrantRequestSchema>;
export type CoachGrantResponse = z.infer<typeof CoachGrantResponseSchema>;

export type FeedbackType = z.infer<typeof FeedbackTypeSchema>;
export type FeedbackReport = z.infer<typeof FeedbackReportSchema>;
export type AbuseReport = z.infer<typeof AbuseReportSchema>;

export type DataExportRequest = z.infer<typeof DataExportRequestSchema>;
export type DataDeletionRequest = z.infer<typeof DataDeletionRequestSchema>;

export type FeatureFlag = z.infer<typeof FeatureFlagSchema>;
export type CohortAssignment = z.infer<typeof CohortAssignmentSchema>;

export type SuccessResponse = z.infer<typeof SuccessResponseSchema>;
export type ErrorResponse = z.infer<typeof ErrorResponseSchema>;
export type PaginatedResponse = z.infer<typeof PaginatedResponseSchema>;

export type Pagination = z.infer<typeof PaginationSchema>;
export type DateRange = z.infer<typeof DateRangeSchema>;
