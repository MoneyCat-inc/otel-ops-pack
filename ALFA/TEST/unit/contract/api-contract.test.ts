// Resonai Backend - API Contract Tests
// Ensures API contracts remain stable and privacy-compliant

import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { EventsBatchSchema, ConsentUpdateSchema, EngagementProfileSchema } from '@/lib/validation/schemas';

describe('API Contract Tests', () => {
  
  describe('Events Batch API', () => {
    it('should accept valid event batches', () => {
      const validBatch = {
        events: [
          {
            kind: 'session_start',
            props: {
              userId: 'user_123',
              sessionId: 'session_456',
              duration: 30000,
            },
            ts: Date.now(),
            schema: 'v1',
          },
          {
            kind: 'badge_unlock',
            props: {
              userId: 'user_123',
              badgeType: 'first_session',
            },
          }
        ]
      };

      const result = EventsBatchSchema.safeParse(validBatch);
      expect(result.success).toBe(true);
    });

    it('should reject batches with PII in props', () => {
      const invalidBatch = {
        events: [
          {
            kind: 'session_start',
            props: {
              userId: 'user_123',
              email: 'user@example.com', // PII not allowed
              name: 'John Doe', // PII not allowed
            }
          }
        ]
      };

      const result = EventsBatchSchema.safeParse(invalidBatch);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('PII')
        )).toBe(true);
      }
    });

    it('should reject batches exceeding size limits', () => {
      const oversizedBatch = {
        events: Array.from({ length: 51 }, (_, i) => ({
          kind: 'session_start' as const,
          props: { userId: `user_${i}` },
        }))
      };

      const result = EventsBatchSchema.safeParse(oversizedBatch);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('50')
        )).toBe(true);
      }
    });

    it('should reject events with too many properties', () => {
      const excessiveProps = Array.from({ length: 11 }, (_, i) => [
        `prop_${i}`, `value_${i}`
      ]).reduce((acc, [key, value]) => ({ ...acc, [key]: value }), {});

      const invalidEvent = {
        events: [
          {
            kind: 'session_start',
            props: excessiveProps,
          }
        ]
      };

      const result = EventsBatchSchema.safeParse(invalidEvent);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('10 fields')
        )).toBe(true);
      }
    });

    it('should reject events older than 1 hour', () => {
      const oldEvent = {
        events: [
          {
            kind: 'session_start',
            props: { userId: 'user_123' },
            ts: Date.now() - (2 * 60 * 60 * 1000), // 2 hours ago
          }
        ]
      };

      const result = EventsBatchSchema.safeParse(oldEvent);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('1 hour')
        )).toBe(true);
      }
    });
  });

  describe('Consent Update API', () => {
    it('should accept valid consent updates', () => {
      const validUpdate = {
        shareMetrics: true,
        coachPortal: false,
      };

      const result = ConsentUpdateSchema.safeParse(validUpdate);
      expect(result.success).toBe(true);
    });

    it('should reject empty consent updates', () => {
      const emptyUpdate = {};

      const result = ConsentUpdateSchema.safeParse(emptyUpdate);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('At least one consent field')
        )).toBe(true);
      }
    });

    it('should accept partial consent updates', () => {
      const partialUpdate = {
        shareMetrics: true,
      };

      const result = ConsentUpdateSchema.safeParse(partialUpdate);
      expect(result.success).toBe(true);
    });
  });

  describe('Engagement Profile API', () => {
    it('should accept valid engagement profiles', () => {
      const validProfile = {
        streakDays: 7,
        lastPracticeAt: new Date().toISOString(),
        reducedMotion: false,
        theme: 'dark',
        preferredLanguage: 'en',
      };

      const result = EngagementProfileSchema.safeParse(validProfile);
      expect(result.success).toBe(true);
    });

    it('should reject invalid streak days', () => {
      const invalidProfile = {
        streakDays: -1, // Negative streak not allowed
      };

      const result = EngagementProfileSchema.safeParse(invalidProfile);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('0')
        )).toBe(true);
      }
    });

    it('should reject streak days exceeding 365', () => {
      const invalidProfile = {
        streakDays: 400, // Too high
      };

      const result = EngagementProfileSchema.safeParse(invalidProfile);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('365')
        )).toBe(true);
      }
    });

    it('should reject invalid theme values', () => {
      const invalidProfile = {
        theme: 'invalid_theme',
      };

      const result = EngagementProfileSchema.safeParse(invalidProfile);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('light')
        )).toBe(true);
      }
    });

    it('should accept valid theme values', () => {
      const validThemes = ['light', 'dark', 'auto'];
      
      validThemes.forEach(theme => {
        const profile = { theme };
        const result = EngagementProfileSchema.safeParse(profile);
        expect(result.success).toBe(true);
      });
    });
  });

  describe('Privacy Compliance', () => {
    it('should never accept audio data in any schema', () => {
      const schemas = [EventsBatchSchema, ConsentUpdateSchema, EngagementProfileSchema];
      
      schemas.forEach(schema => {
        const testData = {
          audioData: 'base64_encoded_audio',
          audioBlob: new Blob(),
          audioFile: 'audio.wav',
        };
        
        const result = schema.safeParse(testData);
        // Should either reject or ignore audio fields
        if (result.success) {
          expect(result.data).not.toHaveProperty('audioData');
          expect(result.data).not.toHaveProperty('audioBlob');
          expect(result.data).not.toHaveProperty('audioFile');
        }
      });
    });

    it('should reject PII in all schemas', () => {
      const piiFields = [
        'email', 'name', 'phone', 'address', 'ssn', 'creditCard',
        'socialSecurityNumber', 'dateOfBirth', 'fullName'
      ];
      
      piiFields.forEach(field => {
        const testData = { [field]: 'test_value' };
        
        const result = EventsBatchSchema.safeParse({
          events: [{
            kind: 'session_start',
            props: testData,
          }]
        });
        
        expect(result.success).toBe(false);
      });
    });

    it('should enforce data minimization principles', () => {
      // Test that schemas don't accept unnecessary fields
      const excessiveData = {
        events: [{
          kind: 'session_start',
          props: {
            userId: 'user_123',
            unnecessaryField1: 'value1',
            unnecessaryField2: 'value2',
            unnecessaryField3: 'value3',
            unnecessaryField4: 'value4',
            unnecessaryField5: 'value5',
            unnecessaryField6: 'value6',
            unnecessaryField7: 'value7',
            unnecessaryField8: 'value8',
            unnecessaryField9: 'value9',
            unnecessaryField10: 'value10',
            unnecessaryField11: 'value11', // This should be rejected
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(excessiveData);
      expect(result.success).toBe(false);
    });
  });

  describe('Schema Evolution', () => {
    it('should maintain backward compatibility for required fields', () => {
      // Test that removing required fields breaks the schema
      const minimalEvent = {
        kind: 'session_start',
        // Missing props - should fail
      };

      const result = EventsBatchSchema.safeParse({
        events: [minimalEvent]
      });
      
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('props')
        )).toBe(true);
      }
    });

    it('should handle optional fields gracefully', () => {
      const minimalEvent = {
        kind: 'session_start',
        props: { userId: 'user_123' },
        // Missing optional fields - should pass
      };

      const result = EventsBatchSchema.safeParse({
        events: [minimalEvent]
      });
      
      expect(result.success).toBe(true);
    });

    it('should reject unknown event kinds', () => {
      const unknownEvent = {
        kind: 'unknown_event_type',
        props: { userId: 'user_123' },
      };

      const result = EventsBatchSchema.safeParse({
        events: [unknownEvent]
      });
      
      expect(result.success).toBe(false);
    });
  });
});
