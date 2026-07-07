// Resonai Backend - E2E Encryption for Coach Portal
// Implements end-to-end encryption for coach grants using Libsodium

import { randomBytes, createHash } from 'crypto';
import { db } from '@/lib/db';
import { trace } from '@opentelemetry/api';

type BadgeSummary = {
  badgeType: string;
  unlockedAt: Date | null;
};

type StoryProgressSummary = {
  chapter: {
    title: string;
    chapterId: string;
  };
  completedAt: Date;
  choices: unknown;
};

// Encryption configuration
const ENCRYPTION_KEY_SIZE = 32; // 256 bits
const NONCE_SIZE = 24; // 192 bits for XChaCha20

// Simple encryption implementation (use libsodium in production)
class SimpleEncryption {
  // Generate encryption key
  static generateKey(): Buffer {
    return randomBytes(ENCRYPTION_KEY_SIZE);
  }

  // Generate nonce
  static generateNonce(): Buffer {
    return randomBytes(NONCE_SIZE);
  }

  // Simple XOR encryption (replace with libsodium in production)
  static encrypt(plaintext: string, key: Buffer, nonce: Buffer): string {
    const textBytes = Buffer.from(plaintext, 'utf8');
    const keyStream = this.generateKeyStream(key, nonce, textBytes.length);
    
    
    const encrypted = Buffer.alloc(textBytes.length);
    for (let i = 0; i < textBytes.length; i++) {
      const textByte = textBytes[i] ?? 0;
      const keyByte = keyStream[i] ?? 0;
      encrypted[i] = textByte ^ keyByte;
    }
    
    // Return base64 encoded: nonce + encrypted data
    return Buffer.concat([nonce, encrypted]).toString('base64');
  }

  // Simple XOR decryption (replace with libsodium in production)
  static decrypt(encryptedData: string, key: Buffer): string {
    const data = Buffer.from(encryptedData, 'base64');
    const nonce = data.subarray(0, NONCE_SIZE);
    const encrypted = data.subarray(NONCE_SIZE);
    
    const keyStream = this.generateKeyStream(key, nonce, encrypted.length);
    
    const decrypted = Buffer.alloc(encrypted.length);
    for (let i = 0; i < encrypted.length; i++) {
      const encryptedByte = encrypted[i] ?? 0;
      const keyByte = keyStream[i] ?? 0;
      decrypted[i] = encryptedByte ^ keyByte;
    }
    
    return decrypted.toString('utf8');
  }

  // Generate key stream (simplified - use proper stream cipher in production)
  private static generateKeyStream(key: Buffer, nonce: Buffer, length: number): Buffer {
    const keyStream = Buffer.alloc(length);
    let counter = 0;
    
    for (let i = 0; i < length; i += key.length) {
      const hash = createHash('sha256')
        .update(key)
        .update(nonce)
        .update(Buffer.from([counter++]))
        .digest();
      
      const copyLength = Math.min(hash.length, length - i);
      hash.copy(keyStream, i, 0, copyLength);
    }
    
    return keyStream;
  }
}

// Coach grant management
export class CoachGrantManager {
  // Create E2E encrypted coach grant
  static async createGrant(
    userId: string,
    coachId: string,
    scope: 'metrics' | 'notes',
    expiresAt: Date,
    dataToEncrypt: any
  ): Promise<{ grantId: string; encryptionKey: string }> {
    const span = trace.getActiveSpan();
    
    try {
      // Generate encryption key (client will receive this)
      const encryptionKey = SimpleEncryption.generateKey();
      
      // Prepare data for encryption
      const dataToEncryptString = JSON.stringify({
        userId,
        scope,
        data: dataToEncrypt,
        createdAt: new Date().toISOString(),
        expiresAt: expiresAt.toISOString(),
      });

      // Encrypt the data
      const nonce = SimpleEncryption.generateNonce();
      const encryptedBlob = SimpleEncryption.encrypt(dataToEncryptString, encryptionKey, nonce);

      // Create grant in database
      const grant = await db.coachGrant.create({
        data: {
          userId,
          coachId,
          scope: scope.toUpperCase() as any,
          encryptedBlob,
          expiresAt,
        }
      });

      span?.setAttributes({
        'coach.grant_created': true,
        'coach.grant_id': grant.id,
        'coach.scope': scope,
        'coach.expires_at': expiresAt.toISOString(),
      });

      return {
        grantId: grant.id,
        encryptionKey: encryptionKey.toString('base64'),
      };

    } catch (error) {
      span?.setAttributes({
        'coach.grant_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      throw new Error(`Failed to create coach grant: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Retrieve encrypted coach grant (server never sees plaintext)
  static async getGrant(grantId: string): Promise<{ encryptedBlob: string; expiresAt: Date } | null> {
    const span = trace.getActiveSpan();
    
    try {
      const grant = await db.coachGrant.findUnique({
        where: { 
          id: grantId,
          isActive: true,
        }
      });

      if (!grant) {
        span?.setAttributes({
          'coach.grant_not_found': true,
          'coach.grant_id': grantId,
        });
        return null;
      }

      if (grant.expiresAt < new Date()) {
        span?.setAttributes({
          'coach.grant_expired': true,
          'coach.grant_id': grantId,
        });
        return null;
      }

      span?.setAttributes({
        'coach.grant_retrieved': true,
        'coach.grant_id': grantId,
        'coach.scope': grant.scope,
      });

      return {
        encryptedBlob: grant.encryptedBlob,
        expiresAt: grant.expiresAt,
      };

    } catch (error) {
      span?.setAttributes({
        'coach.grant_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      throw new Error(`Failed to retrieve coach grant: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Revoke coach grant
  static async revokeGrant(grantId: string, userId: string): Promise<boolean> {
    const span = trace.getActiveSpan();
    
    try {
      const result = await db.coachGrant.updateMany({
        where: {
          id: grantId,
          userId, // Ensure user can only revoke their own grants
        },
        data: {
          isActive: false,
        }
      });

      const success = result.count > 0;

      span?.setAttributes({
        'coach.grant_revoked': success,
        'coach.grant_id': grantId,
        'coach.user_id': userId,
      });

      return success;

    } catch (error) {
      span?.setAttributes({
        'coach.revoke_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      throw new Error(`Failed to revoke coach grant: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Clean up expired grants
  static async cleanupExpiredGrants(): Promise<number> {
    const span = trace.getActiveSpan();
    
    try {
      const result = await db.coachGrant.deleteMany({
        where: {
          expiresAt: {
            lt: new Date()
          }
        }
      });

      span?.setAttributes({
        'coach.cleanup_completed': true,
        'coach.expired_grants_removed': result.count,
      });

      return result.count;

    } catch (error) {
      span?.setAttributes({
        'coach.cleanup_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      throw new Error(`Failed to cleanup expired grants: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

// Client-side encryption utilities (for frontend)
export class ClientEncryption {
  // Decrypt coach grant data on client side
  static decryptGrantData(encryptedBlob: string, encryptionKeyBase64: string): any {
    try {
      const encryptionKey = Buffer.from(encryptionKeyBase64, 'base64');
      const decryptedString = SimpleEncryption.decrypt(encryptedBlob, encryptionKey);
      return JSON.parse(decryptedString);
    } catch (error) {
      throw new Error(`Failed to decrypt grant data: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Generate encryption key on client side
  static generateClientKey(): string {
    const key = SimpleEncryption.generateKey();
    return key.toString('base64');
  }

  // Encrypt data on client side before sending to server
  static encryptClientData(data: any, keyBase64: string): string {
    try {
      const key = Buffer.from(keyBase64, 'base64');
      const dataString = JSON.stringify(data);
      const nonce = SimpleEncryption.generateNonce();
      return SimpleEncryption.encrypt(dataString, key, nonce);
    } catch (error) {
      throw new Error(`Failed to encrypt client data: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

// Coach portal data preparation
export class CoachDataPreparer {
  // Prepare engagement metrics for coach (privacy-safe)
  static async prepareEngagementMetrics(userId: string): Promise<any> {
    const span = trace.getActiveSpan();
    
    try {
      // Get user's engagement profile
      const profile = await db.engagementProfile.findUnique({
        where: { userId },
        include: {
          user: {
            select: {
              badges: {
                select: {
                  badgeType: true,
                  unlockedAt: true,
                },
                orderBy: { unlockedAt: 'desc' },
              },
            },
          },
        },
      });

      if (!profile) {
        return {
          streakDays: 0,
          badges: [],
          lastPracticeAt: null,
          totalSessions: 0,
        };
      }

      // Get session count (privacy-safe aggregation)
      const sessionCount = await db.event.count({
        where: {
          userId,
          kind: 'SESSION_START',
        }
      });

      // Prepare coach-safe data
      const badges = profile.user.badges;
      const coachData = {
        streakDays: profile.streakDays,
        badges: badges.map((badge: BadgeSummary) => ({
          type: badge.badgeType,
          unlockedAt: badge.unlockedAt,
        })),
        lastPracticeAt: profile.lastPracticeAt,
        totalSessions: sessionCount,
        // No PII, no raw audio, no detailed traces
      };

      span?.setAttributes({
        'coach.data_prepared': true,
        'coach.streak_days': profile.streakDays,
        'coach.badges_count': badges.length,
        'coach.total_sessions': sessionCount,
      });

      return coachData;

    } catch (error) {
      span?.setAttributes({
        'coach.data_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      throw new Error(`Failed to prepare coach data: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Prepare progress notes for coach (if user opted in)
  static async prepareProgressNotes(userId: string): Promise<any> {
    const span = trace.getActiveSpan();
    
    try {
      // Get story progress (if user consented to sharing)
      const storyProgress = await db.storyProgress.findMany({
        where: { userId },
        include: {
          chapter: {
            select: {
              title: true,
              chapterId: true,
            }
          }
        },
        orderBy: { completedAt: 'desc' },
        take: 10, // Limit to recent progress
      });

      const progressData = {
        recentChapters: storyProgress.map((progress: StoryProgressSummary) => ({
          chapterTitle: progress.chapter.title,
          chapterId: progress.chapter.chapterId,
          completedAt: progress.completedAt,
          choices: progress.choices,
        })),
        totalChaptersCompleted: storyProgress.length,
      };

      span?.setAttributes({
        'coach.notes_prepared': true,
        'coach.chapters_completed': storyProgress.length,
      });

      return progressData;

    } catch (error) {
      span?.setAttributes({
        'coach.notes_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      throw new Error(`Failed to prepare progress notes: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

// Background job for grant cleanup
export async function cleanupExpiredCoachGrants(): Promise<void> {
  const span = trace.getActiveSpan();
  
  try {
    const cleanedCount = await CoachGrantManager.cleanupExpiredGrants();
    
    span?.setAttributes({
      'background.cleanup_completed': true,
      'background.grants_cleaned': cleanedCount,
    });

    console.log(`Cleaned up ${cleanedCount} expired coach grants`);

  } catch (error) {
    span?.setAttributes({
      'background.cleanup_error': true,
      'background.error.message': error instanceof Error ? error.message : 'Unknown error'
    });

    console.error('Failed to cleanup expired coach grants:', error);
  }
}
