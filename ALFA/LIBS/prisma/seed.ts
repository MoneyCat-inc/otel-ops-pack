// Resonai Backend - Database Seed Script
// Populates database with initial data for development and testing

import { PrismaClient } from '@prisma/client';
import { createHash, randomBytes } from 'crypto';

const prisma = new PrismaClient();

// Configuration
const SERVER_SALT = process.env.USER_HASH_SALT || 'default-salt-for-development';

// Helper function to generate user ID hash
function generateUserIdHash(email: string): string {
  return createHash('sha256')
    .update(email + SERVER_SALT)
    .digest('hex')
    .substring(0, 16);
}

// Helper function to generate cohort from user ID hash
function generateCohort(userIdHash: string): string {
  return `cohort_${parseInt(userIdHash.substring(0, 2), 16) % 10}`;
}

async function main() {
  console.log('🌱 Starting database seeding...');

  try {
    // =============================================================================
    // CLEAN EXISTING DATA (for development)
    // =============================================================================
    
    if (process.env.NODE_ENV === 'development') {
      console.log('🧹 Cleaning existing data...');
      
      await prisma.backgroundJob.deleteMany();
      await prisma.dataExport.deleteMany();
      await prisma.deletionLog.deleteMany();
      await prisma.cohortAssignment.deleteMany();
      await prisma.feedbackReport.deleteMany();
      await prisma.consentAuditLog.deleteMany();
      await prisma.coachGrant.deleteMany();
      await prisma.storyProgress.deleteMany();
      await prisma.badge.deleteMany();
      await prisma.engagementProfile.deleteMany();
      await prisma.event.deleteMany();
      await prisma.session.deleteMany();
      await prisma.magicLink.deleteMany();
      await prisma.user.deleteMany();
    }

    // =============================================================================
    // CREATE TEST USERS
    // =============================================================================
    
    console.log('👥 Creating test users...');
    
    const testUsers = [
      {
        email: 'test@resonai.app',
        consentShareMetrics: true,
        consentCoachPortal: true,
      },
      {
        email: 'demo@resonai.app',
        consentShareMetrics: false,
        consentCoachPortal: false,
      },
      {
        email: 'coach@resonai.app',
        consentShareMetrics: true,
        consentCoachPortal: true,
      },
    ];

    const createdUsers = [];
    for (const userData of testUsers) {
      const userIdHash = generateUserIdHash(userData.email);
      const user = await prisma.user.create({
        data: {
          email: userData.email,
          userIdHash,
          consentShareMetrics: userData.consentShareMetrics,
          consentShareClips: false,
          consentCoachPortal: userData.consentCoachPortal,
        }
      });
      createdUsers.push(user);
      console.log(`   ✅ Created user: ${userData.email} (${user.id})`);
    }

    // =============================================================================
    // CREATE ENGAGEMENT PROFILES
    // =============================================================================
    
    console.log('📊 Creating engagement profiles...');
    
    for (const user of createdUsers) {
      const engagementProfile = await prisma.engagementProfile.create({
        data: {
          userId: user.id,
          streakDays: Math.floor(Math.random() * 30),
          lastPracticeAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000),
          reducedMotion: Math.random() > 0.8,
          theme: ['light', 'dark', 'auto'][Math.floor(Math.random() * 3)],
          preferredLanguage: 'en',
        }
      });
      console.log(`   ✅ Created engagement profile for ${user.email}`);
    }

    // =============================================================================
    // CREATE BADGES
    // =============================================================================
    
    console.log('🏆 Creating badges...');
    
    const badgeTypes = [
      'first_session',
      'week_1',
      'week_2',
      'month_1',
      'streak_7',
      'streak_30',
      'story_complete',
      'coach_connected',
    ];

    for (const user of createdUsers) {
      const numBadges = Math.floor(Math.random() * 5) + 1;
      const userBadges = badgeTypes.slice(0, numBadges);
      
      for (const badgeType of userBadges) {
        await prisma.badge.create({
          data: {
            userId: user.id,
            badgeType,
            unlockedAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
            metadata: {
              description: `Earned ${badgeType} badge`,
              category: badgeType.includes('streak') ? 'streak' : 'achievement',
            }
          }
        });
      }
      console.log(`   ✅ Created ${userBadges.length} badges for ${user.email}`);
    }

    // =============================================================================
    // CREATE SAMPLE EVENTS
    // =============================================================================
    
    console.log('📈 Creating sample events...');
    
    const eventTypes = [
      'session_start',
      'session_end',
      'badge_unlock',
      'streak_tick',
      'consent_change',
    ];

    for (const user of createdUsers) {
      const numEvents = Math.floor(Math.random() * 50) + 10;
      const cohort = generateCohort(user.userIdHash);
      
      for (let i = 0; i < numEvents; i++) {
        const eventType = eventTypes[Math.floor(Math.random() * eventTypes.length)];
        const props: any = {
          userId: user.userIdHash,
          sessionId: `session_${randomBytes(8).toString('hex')}`,
        };

        if (eventType === 'session_end') {
          props.duration = Math.floor(Math.random() * 300000) + 30000; // 30s to 5min
        } else if (eventType === 'badge_unlock') {
          props.badgeType = badgeTypes[Math.floor(Math.random() * badgeTypes.length)];
        } else if (eventType === 'streak_tick') {
          props.streakDays = Math.floor(Math.random() * 30);
        }

        await prisma.event.create({
          data: {
            userId: user.id,
            ts: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000),
            kind: eventType.toUpperCase(),
            props,
            schema: 'v1',
            cohort,
          }
        });
      }
      console.log(`   ✅ Created ${numEvents} events for ${user.email}`);
    }

    // =============================================================================
    // CREATE STORY PROGRESS
    // =============================================================================
    
    console.log('📚 Creating story progress...');
    
    const chapters = await prisma.storyChapter.findMany();
    
    for (const user of createdUsers) {
      const numChapters = Math.floor(Math.random() * chapters.length) + 1;
      const userChapters = chapters.slice(0, numChapters);
      
      for (const chapter of userChapters) {
        await prisma.storyProgress.create({
          data: {
            userId: user.id,
            chapterId: chapter.id,
            completedAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
            choices: [
              {
                id: 'continue',
                label: 'Continue',
                next: 'next_chapter',
              }
            ],
          }
        });
      }
      console.log(`   ✅ Created progress for ${userChapters.length} chapters for ${user.email}`);
    }

    // =============================================================================
    // CREATE COACH GRANTS (for testing)
    // =============================================================================
    
    console.log('👨‍🏫 Creating coach grants...');
    
    const coachUser = createdUsers.find(u => u.email === 'coach@resonai.app');
    if (coachUser) {
      for (const user of createdUsers.filter(u => u.email !== 'coach@resonai.app')) {
        if (user.consentCoachPortal) {
          await prisma.coachGrant.create({
            data: {
              userId: user.id,
              coachId: 'coach_123',
              scope: 'METRICS',
              encryptedBlob: 'encrypted_data_placeholder',
              expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
            }
          });
        }
      }
      console.log(`   ✅ Created coach grants for users with consent`);
    }

    // =============================================================================
    // CREATE FEEDBACK REPORTS
    // =============================================================================
    
    console.log('💬 Creating feedback reports...');
    
    const feedbackTypes = [
      'GENERAL',
      'BUG_REPORT',
      'FEATURE_REQUEST',
      'ACCESSIBILITY',
      'PRIVACY_CONCERN',
    ];

    for (let i = 0; i < 10; i++) {
      const user = createdUsers[Math.floor(Math.random() * createdUsers.length)];
      const feedbackType = feedbackTypes[Math.floor(Math.random() * feedbackTypes.length)];
      
      await prisma.feedbackReport.create({
        data: {
          userId: user.id,
          type: feedbackType as any,
          content: `Sample feedback content for ${feedbackType.toLowerCase()}`,
          metadata: {
            category: feedbackType.toLowerCase(),
            priority: Math.random() > 0.7 ? 'high' : 'normal',
          },
          status: ['OPEN', 'IN_REVIEW', 'RESOLVED'][Math.floor(Math.random() * 3)] as any,
        }
      });
    }
    console.log(`   ✅ Created 10 feedback reports`);

    // =============================================================================
    // CREATE COHORT ASSIGNMENTS
    // =============================================================================
    
    console.log('👥 Creating cohort assignments...');
    
    const cohorts = ['cohort_0', 'cohort_1', 'cohort_2', 'cohort_3', 'cohort_4'];
    const featureFlags = await prisma.featureFlag.findMany();
    
    for (const user of createdUsers) {
      const cohort = generateCohort(user.userIdHash);
      const assignedFlags = featureFlags
        .filter(flag => Math.random() > 0.5)
        .map(flag => flag.name);
      
      await prisma.cohortAssignment.create({
        data: {
          userIdHash: user.userIdHash,
          cohort,
          featureFlags: assignedFlags,
        }
      });
    }
    console.log(`   ✅ Created cohort assignments for all users`);

    // =============================================================================
    // CREATE BACKGROUND JOBS
    // =============================================================================
    
    console.log('⚙️ Creating background jobs...');
    
    const jobTypes = [
      'SESSION_CLEANUP',
      'COACH_GRANT_CLEANUP',
      'DATA_EXPORT_CLEANUP',
      'EVENT_RETENTION_CLEANUP',
      'MAGIC_LINK_CLEANUP',
      'ENGAGEMENT_ROLLUP',
      'COHORT_ANALYTICS',
      'HEALTH_CHECK',
    ];

    for (const jobType of jobTypes) {
      await prisma.backgroundJob.create({
        data: {
          type: jobType as any,
          status: 'COMPLETED',
          payload: {
            description: `Sample ${jobType.toLowerCase()} job`,
            processed: Math.floor(Math.random() * 100),
          },
          startedAt: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000),
          completedAt: new Date(Date.now() - Math.random() * 12 * 60 * 60 * 1000),
        }
      });
    }
    console.log(`   ✅ Created ${jobTypes.length} background jobs`);

    // =============================================================================
    // SUMMARY
    // =============================================================================
    
    console.log('\n🎉 Database seeding completed successfully!');
    console.log('\n📊 Summary:');
    console.log(`   👥 Users: ${createdUsers.length}`);
    console.log(`   📊 Engagement Profiles: ${createdUsers.length}`);
    console.log(`   🏆 Badges: ${createdUsers.reduce((acc, user) => acc + Math.floor(Math.random() * 5) + 1, 0)}`);
    console.log(`   📈 Events: ${createdUsers.reduce((acc, user) => acc + Math.floor(Math.random() * 50) + 10, 0)}`);
    console.log(`   📚 Story Progress: ${createdUsers.length * chapters.length}`);
    console.log(`   👨‍🏫 Coach Grants: ${createdUsers.filter(u => u.consentCoachPortal).length}`);
    console.log(`   💬 Feedback Reports: 10`);
    console.log(`   👥 Cohort Assignments: ${createdUsers.length}`);
    console.log(`   ⚙️ Background Jobs: ${jobTypes.length}`);
    
    console.log('\n🔗 Test Accounts:');
    console.log(`   📧 test@resonai.app (with full consent)`);
    console.log(`   📧 demo@resonai.app (minimal consent)`);
    console.log(`   📧 coach@resonai.app (admin/coach account)`);
    
    console.log('\n🚀 Ready for development and testing!');

  } catch (error) {
    console.error('❌ Database seeding failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Run the seed function
main()
  .catch((e) => {
    console.error('Seed script failed:', e);
    process.exit(1);
  });
