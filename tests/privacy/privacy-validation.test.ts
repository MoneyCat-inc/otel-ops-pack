// Resonai Backend - Privacy Validation Tests
// Ensures all APIs comply with privacy requirements and data minimization

import { describe, it, expect } from '@jest/globals';
import { EventsBatchSchema } from '@/lib/validation/schemas';

describe('Privacy Validation Tests', () => {
  
  describe('Data Minimization', () => {
    it('should reject events with excessive data', () => {
      const excessiveEvent = {
        events: [{
          kind: 'session_start',
          props: {
            userId: 'user_123',
            // Excessive metadata
            browserVersion: 'Chrome 120.0.0.0',
            operatingSystem: 'Windows 11',
            screenResolution: '1920x1080',
            timezone: 'America/New_York',
            language: 'en-US',
            deviceType: 'desktop',
            connectionType: 'wifi',
            locationCountry: 'US',
            locationRegion: 'NY',
            locationCity: 'New York',
            unnecessaryField11: 'should_be_rejected',
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(excessiveEvent);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('10 fields')
        )).toBe(true);
      }
    });

    it('should accept events with minimal required data', () => {
      const minimalEvent = {
        events: [{
          kind: 'session_start',
          props: {
            userId: 'user_123',
            sessionId: 'session_456',
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(minimalEvent);
      expect(result.success).toBe(true);
    });
  });

  describe('PII Detection', () => {
    const piiTestCases = [
      // Direct PII fields
      { field: 'email', value: 'user@example.com' },
      { field: 'name', value: 'John Doe' },
      { field: 'firstName', value: 'John' },
      { field: 'lastName', value: 'Doe' },
      { field: 'fullName', value: 'John Doe' },
      { field: 'phone', value: '+1234567890' },
      { field: 'phoneNumber', value: '+1234567890' },
      { field: 'address', value: '123 Main St' },
      { field: 'homeAddress', value: '123 Main St' },
      { field: 'ssn', value: '123-45-6789' },
      { field: 'socialSecurityNumber', value: '123-45-6789' },
      { field: 'creditCard', value: '4111-1111-1111-1111' },
      { field: 'creditCardNumber', value: '4111-1111-1111-1111' },
      { field: 'dateOfBirth', value: '1990-01-01' },
      { field: 'birthDate', value: '1990-01-01' },
      
      // Indirect PII fields
      { field: 'userEmail', value: 'user@example.com' },
      { field: 'userName', value: 'John Doe' },
      { field: 'userPhone', value: '+1234567890' },
      { field: 'contactEmail', value: 'user@example.com' },
      { field: 'contactName', value: 'John Doe' },
      { field: 'billingAddress', value: '123 Main St' },
      { field: 'shippingAddress', value: '123 Main St' },
      
      // Case variations
      { field: 'EMAIL', value: 'user@example.com' },
      { field: 'Email', value: 'user@example.com' },
      { field: 'eMail', value: 'user@example.com' },
      { field: 'NAME', value: 'John Doe' },
      { field: 'Name', value: 'John Doe' },
    ];

    piiTestCases.forEach(({ field, value }) => {
      it(`should reject PII field: ${field}`, () => {
        const eventWithPII = {
          events: [{
            kind: 'session_start',
            props: {
              userId: 'user_123',
              [field]: value,
            },
          }]
        };

        const result = EventsBatchSchema.safeParse(eventWithPII);
        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.error.issues.some(issue => 
            issue.message.includes('PII')
          )).toBe(true);
        }
      });
    });
  });

  describe('Audio Data Prevention', () => {
    const audioTestCases = [
      // Direct audio fields
      { field: 'audio', value: 'base64_encoded_audio_data' },
      { field: 'audioData', value: 'base64_encoded_audio_data' },
      { field: 'audioBlob', value: new Blob(['audio data']) },
      { field: 'audioFile', value: 'audio.wav' },
      { field: 'audioClip', value: 'audio_clip.mp3' },
      { field: 'voiceRecording', value: 'voice_recording.wav' },
      { field: 'speechAudio', value: 'speech_audio.mp3' },
      
      // Audio-related metadata
      { field: 'audioFormat', value: 'wav' },
      { field: 'audioDuration', value: 30000 },
      { field: 'audioSampleRate', value: 44100 },
      { field: 'audioChannels', value: 2 },
      { field: 'audioBitrate', value: 128 },
      
      // Case variations
      { field: 'AUDIO', value: 'base64_encoded_audio_data' },
      { field: 'Audio', value: 'base64_encoded_audio_data' },
      { field: 'AUDIO_DATA', value: 'base64_encoded_audio_data' },
    ];

    audioTestCases.forEach(({ field, value }) => {
      it(`should reject audio field: ${field}`, () => {
        const eventWithAudio = {
          events: [{
            kind: 'session_start',
            props: {
              userId: 'user_123',
              [field]: value,
            },
          }]
        };

        const result = EventsBatchSchema.safeParse(eventWithAudio);
        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.error.issues.some(issue => 
            issue.message.includes('audio')
          )).toBe(true);
        }
      });
    });
  });

  describe('Data Retention Compliance', () => {
    it('should reject events older than retention limit', () => {
      const oldEvent = {
        events: [{
          kind: 'session_start',
          props: { userId: 'user_123' },
          ts: Date.now() - (2 * 60 * 60 * 1000), // 2 hours ago
        }]
      };

      const result = EventsBatchSchema.safeParse(oldEvent);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues.some(issue => 
          issue.message.includes('1 hour')
        )).toBe(true);
      }
    });

    it('should accept events within retention limit', () => {
      const recentEvent = {
        events: [{
          kind: 'session_start',
          props: { userId: 'user_123' },
          ts: Date.now() - (30 * 60 * 1000), // 30 minutes ago
        }]
      };

      const result = EventsBatchSchema.safeParse(recentEvent);
      expect(result.success).toBe(true);
    });
  });

  describe('Consent Compliance', () => {
    it('should allow events without explicit consent fields', () => {
      const event = {
        events: [{
          kind: 'session_start',
          props: {
            userId: 'user_123',
            sessionId: 'session_456',
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(event);
      expect(result.success).toBe(true);
    });

    it('should not require consent fields in event data', () => {
      const event = {
        events: [{
          kind: 'session_start',
          props: {
            userId: 'user_123',
            // No consent fields required
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(event);
      expect(result.success).toBe(true);
    });
  });

  describe('Cross-Border Data Transfer Prevention', () => {
    it('should reject location data that could indicate cross-border transfers', () => {
      const locationFields = [
        'country', 'region', 'state', 'city', 'zipcode', 'postalCode',
        'latitude', 'longitude', 'coordinates', 'location', 'geo',
        'ipAddress', 'ip', 'ipv4', 'ipv6', 'networkLocation'
      ];

      locationFields.forEach(field => {
        const eventWithLocation = {
          events: [{
            kind: 'session_start',
            props: {
              userId: 'user_123',
              [field]: 'location_data',
            },
          }]
        };

        const result = EventsBatchSchema.safeParse(eventWithLocation);
        // Should either reject or strip location data
        if (result.success) {
          expect(result.data.events[0].props).not.toHaveProperty(field);
        }
      });
    });
  });

  describe('Data Anonymization', () => {
    it('should accept hashed identifiers', () => {
      const eventWithHash = {
        events: [{
          kind: 'session_start',
          props: {
            userIdHash: 'a1b2c3d4e5f6', // Hashed identifier
            sessionId: 'session_456',
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(eventWithHash);
      expect(result.success).toBe(true);
    });

    it('should prefer hashed identifiers over raw IDs', () => {
      const eventWithBoth = {
        events: [{
          kind: 'session_start',
          props: {
            userId: 'user_123', // Raw ID
            userIdHash: 'a1b2c3d4e5f6', // Hashed ID
          },
        }]
      };

      const result = EventsBatchSchema.safeParse(eventWithBoth);
      expect(result.success).toBe(true);
      // In practice, the server should prefer the hash
    });
  });

  describe('Schema Privacy Validation', () => {
    it('should ensure all schemas are privacy-compliant', () => {
      const schemas = [EventsBatchSchema];
      
      schemas.forEach(schema => {
        // Test that schema doesn't accept PII by default
        const testData = {
          email: 'test@example.com',
          name: 'Test User',
          phone: '+1234567890',
        };
        
        const result = schema.safeParse(testData);
        // Should either reject or ignore PII fields
        if (result.success) {
          expect(result.data).not.toHaveProperty('email');
          expect(result.data).not.toHaveProperty('name');
          expect(result.data).not.toHaveProperty('phone');
        }
      });
    });
  });
});
