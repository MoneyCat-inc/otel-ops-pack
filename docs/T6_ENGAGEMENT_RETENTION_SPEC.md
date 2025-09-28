# 🎯 T6: Engagement & Retention - Comprehensive Specification

## 📊 Executive Summary

**Objective**: Build foundational engagement systems (streaks, badges, progress tracking) and narrative practice layer to achieve >35% 4-week retention rate for Resonai beta.

**Strategic Scope**: Balance foundational features (2-3 weeks) with narrative enhancement (4-6 weeks total) for optimal user engagement and retention.

**Key Success Metrics**:
- >35% 4-week retention rate
- >60% daily active users
- >80% achievement completion rate
- <5% privacy opt-out rate

---

## 🏗️ Architecture Overview

### **Current State Analysis**
- ✅ **IndexedDB Foundation**: `ResonaiDatabase` with `SessionSummary` schema
- ✅ **Session Management**: `SessionManager` with MEMX integration
- ✅ **Flow System**: `FlowV1` with drill/reflection steps
- ❓ **Missing**: Engagement tracking, achievement system, narrative flows

### **Engagement System Architecture**
```typescript
// Extended database schema for engagement
export interface EngagementProfile {
  id?: number;
  userId: string;
  createdAt: number;
  lastActiveAt: number;
  
  // Streak tracking
  currentStreak: number;
  longestStreak: number;
  streakStartDate: number;
  lastPracticeDate: number;
  
  // Achievement system
  unlockedBadges: string[];
  totalPracticeTime: number;
  totalSessions: number;
  
  // Progress tracking
  level: number;
  experience: number;
  milestones: string[];
  
  // Privacy settings
  shareProgress: boolean;
  shareAchievements: boolean;
  shareStreaks: boolean;
}

export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  category: 'streak' | 'practice' | 'skill' | 'community';
  requirements: AchievementRequirement[];
  unlockedAt?: number;
  rarity: 'common' | 'uncommon' | 'rare' | 'epic';
}

export interface NarrativeFlow {
  id: string;
  title: string;
  description: string;
  chapters: NarrativeChapter[];
  unlockRequirements: string[];
  estimatedDuration: number;
}
```

---

## 📋 Implementation Plan

### **Phase 1: Foundational Engagement (Weeks 1-2)**

#### **Task 1.1: Streak Mechanics**
```typescript
export class StreakManager {
  private db: ResonaiDatabase;
  
  async updateStreak(sessionId: number): Promise<StreakUpdate> {
    const today = this.getToday();
    const profile = await this.getEngagementProfile();
    
    if (this.isConsecutiveDay(profile.lastPracticeDate, today)) {
      // Continue streak
      profile.currentStreak++;
      profile.lastPracticeDate = today;
    } else if (this.isNewDay(profile.lastPracticeDate, today)) {
      // Start new streak
      profile.currentStreak = 1;
      profile.streakStartDate = today;
      profile.lastPracticeDate = today;
    }
    
    // Update longest streak
    if (profile.currentStreak > profile.longestStreak) {
      profile.longestStreak = profile.currentStreak;
    }
    
    await this.saveProfile(profile);
    return this.generateStreakUpdate(profile);
  }
  
  private generateStreakUpdate(profile: EngagementProfile): StreakUpdate {
    const streakMessages = {
      1: "Great start! Your practice journey begins today.",
      3: "Three days strong! You're building a great habit.",
      7: "One week! You're developing real consistency.",
      14: "Two weeks! Your dedication is inspiring.",
      30: "One month! You're a practice champion.",
      100: "100 days! You're a voice training legend."
    };
    
    return {
      currentStreak: profile.currentStreak,
      longestStreak: profile.longestStreak,
      message: streakMessages[profile.currentStreak] || 
               `Amazing! ${profile.currentStreak} days of practice.`,
      isNewRecord: profile.currentStreak === profile.longestStreak,
      nextMilestone: this.getNextMilestone(profile.currentStreak)
    };
  }
}
```

#### **Task 1.2: Achievement System**
```typescript
export class AchievementManager {
  private achievements: Achievement[] = [
    {
      id: 'first-practice',
      name: 'First Steps',
      description: 'Complete your first practice session',
      icon: '🌱',
      category: 'practice',
      requirements: [{ type: 'sessions', value: 1 }],
      rarity: 'common'
    },
    {
      id: 'week-warrior',
      name: 'Week Warrior',
      description: 'Practice for 7 consecutive days',
      icon: '⚔️',
      category: 'streak',
      requirements: [{ type: 'streak', value: 7 }],
      rarity: 'uncommon'
    },
    {
      id: 'voice-explorer',
      name: 'Voice Explorer',
      description: 'Try 5 different practice scenarios',
      icon: '🗺️',
      category: 'skill',
      requirements: [{ type: 'scenarios', value: 5 }],
      rarity: 'uncommon'
    },
    {
      id: 'consistency-champion',
      name: 'Consistency Champion',
      description: 'Practice for 30 consecutive days',
      icon: '🏆',
      category: 'streak',
      requirements: [{ type: 'streak', value: 30 }],
      rarity: 'rare'
    }
  ];
  
  async checkAchievements(profile: EngagementProfile): Promise<AchievementUnlock[]> {
    const unlocks: AchievementUnlock[] = [];
    
    for (const achievement of this.achievements) {
      if (profile.unlockedBadges.includes(achievement.id)) continue;
      
      if (this.meetsRequirements(achievement, profile)) {
        profile.unlockedBadges.push(achievement.id);
        unlocks.push({
          achievement,
          unlockedAt: Date.now(),
          message: this.generateUnlockMessage(achievement)
        });
      }
    }
    
    if (unlocks.length > 0) {
      await this.saveProfile(profile);
    }
    
    return unlocks;
  }
}
```

#### **Task 1.3: Progress Dashboard**
```typescript
export function ProgressDashboard({ profile }: { profile: EngagementProfile }) {
  const [recentSessions, setRecentSessions] = useState<SessionSummary[]>([]);
  const [achievements, setAchievements] = useState<Achievement[]>([]);
  
  useEffect(() => {
    loadDashboardData();
  }, []);
  
  const loadDashboardData = async () => {
    const sessions = await SessionManager.getRecentSessions(10);
    const unlockedAchievements = await AchievementManager.getUnlockedAchievements(profile);
    setRecentSessions(sessions);
    setAchievements(unlockedAchievements);
  };
  
  return (
    <div className="space-y-6">
      {/* Streak Display */}
      <StreakCard 
        currentStreak={profile.currentStreak}
        longestStreak={profile.longestStreak}
        nextMilestone={getNextMilestone(profile.currentStreak)}
      />
      
      {/* Recent Progress */}
      <ProgressChart 
        sessions={recentSessions}
        timeRange="7d"
      />
      
      {/* Achievements */}
      <AchievementGrid 
        achievements={achievements}
        totalUnlocked={profile.unlockedBadges.length}
      />
      
      {/* Practice Stats */}
      <PracticeStats 
        totalSessions={profile.totalSessions}
        totalTime={profile.totalPracticeTime}
        level={profile.level}
        experience={profile.experience}
      />
    </div>
  );
}
```

### **Phase 2: Narrative Enhancement (Weeks 3-4)**

#### **Task 2.1: Narrative Flow System**
```typescript
export interface NarrativeChapter {
  id: string;
  title: string;
  story: string;
  practiceScenario: ScenarioConfig;
  choices?: NarrativeChoice[];
  nextChapter?: string;
  unlockConditions?: string[];
}

export interface NarrativeChoice {
  id: string;
  text: string;
  consequence: string;
  nextChapter: string;
  requirements?: string[];
}

export class NarrativeManager {
  private narratives: NarrativeFlow[] = [
    {
      id: 'voice-journey',
      title: 'The Voice Journey',
      description: 'Discover your authentic voice through guided practice',
      chapters: [
        {
          id: 'awakening',
          title: 'The Awakening',
          story: 'You stand before a mirror, ready to discover the voice that truly represents you...',
          practiceScenario: {
            id: 'warmup-discovery',
            name: 'Voice Discovery',
            phrase: 'Hello, this is my authentic voice',
            targetRiseFall: 'neutral',
            expectedDuration: 3,
            expressivenessThreshold: 0.3
          },
          nextChapter: 'first-steps'
        },
        {
          id: 'first-steps',
          title: 'First Steps',
          story: 'With each practice, you feel more confident in expressing your true self...',
          practiceScenario: {
            id: 'confidence-building',
            name: 'Building Confidence',
            phrase: 'I am becoming more confident with each practice',
            targetRiseFall: 'rise',
            expectedDuration: 4,
            expressivenessThreshold: 0.4
          },
          choices: [
            {
              id: 'gentle-approach',
              text: 'Take a gentle, gradual approach',
              consequence: 'You choose patience and steady progress',
              nextChapter: 'gentle-progress'
            },
            {
              id: 'bold-approach',
              text: 'Embrace bold, expressive practice',
              consequence: 'You choose confidence and expression',
              nextChapter: 'bold-progress'
            }
          ]
        }
      ],
      unlockRequirements: ['first-practice'],
      estimatedDuration: 20
    }
  ];
  
  async getAvailableNarratives(profile: EngagementProfile): Promise<NarrativeFlow[]> {
    return this.narratives.filter(narrative => 
      this.meetsUnlockRequirements(narrative, profile)
    );
  }
  
  async startNarrative(narrativeId: string, profile: EngagementProfile): Promise<NarrativeSession> {
    const narrative = this.narratives.find(n => n.id === narrativeId);
    if (!narrative) throw new Error('Narrative not found');
    
    const session: NarrativeSession = {
      id: generateId(),
      narrativeId,
      currentChapter: narrative.chapters[0].id,
      startedAt: Date.now(),
      choices: [],
      progress: 0
    };
    
    await this.saveNarrativeSession(session);
    return session;
  }
}
```

#### **Task 2.2: Narrative Practice Integration**
```typescript
export function NarrativePracticeCard({ 
  narrative, 
  onComplete 
}: { 
  narrative: NarrativeFlow;
  onComplete: (result: NarrativeResult) => void;
}) {
  const [currentChapter, setCurrentChapter] = useState<NarrativeChapter | null>(null);
  const [storyProgress, setStoryProgress] = useState(0);
  const [showChoices, setShowChoices] = useState(false);
  
  useEffect(() => {
    loadCurrentChapter();
  }, [narrative]);
  
  const loadCurrentChapter = async () => {
    const session = await NarrativeManager.getCurrentSession(narrative.id);
    const chapter = narrative.chapters.find(c => c.id === session.currentChapter);
    setCurrentChapter(chapter || null);
    setStoryProgress(session.progress);
  };
  
  const handlePracticeComplete = (result: ScenarioResult) => {
    if (result.pass) {
      setStoryProgress(prev => prev + 1);
      setShowChoices(true);
    }
  };
  
  const handleChoiceSelect = (choice: NarrativeChoice) => {
    setShowChoices(false);
    // Advance to next chapter
    const nextChapter = narrative.chapters.find(c => c.id === choice.nextChapter);
    if (nextChapter) {
      setCurrentChapter(nextChapter);
    } else {
      // Narrative complete
      onComplete({
        narrativeId: narrative.id,
        completedAt: Date.now(),
        choices: [choice],
        finalResult: 'success'
      });
    }
  };
  
  if (!currentChapter) return null;
  
  return (
    <div className="bg-gradient-to-br from-purple-50 to-blue-50 rounded-xl p-6 border border-purple-200">
      {/* Story Display */}
      <div className="mb-6">
        <h3 className="text-xl font-bold text-purple-900 mb-2">
          {currentChapter.title}
        </h3>
        <div className="bg-white rounded-lg p-4 border border-purple-100">
          <p className="text-gray-700 leading-relaxed">
            {currentChapter.story}
          </p>
        </div>
      </div>
      
      {/* Practice Integration */}
      <ScenarioCard
        scenario={currentChapter.practiceScenario}
        isActive={true}
        onResult={handlePracticeComplete}
        onStart={() => {}}
        onStop={() => {}}
        mockData={false}
      />
      
      {/* Choice Display */}
      {showChoices && currentChapter.choices && (
        <div className="mt-6 space-y-3">
          <h4 className="font-semibold text-purple-800">What do you choose?</h4>
          {currentChapter.choices.map(choice => (
            <button
              key={choice.id}
              onClick={() => handleChoiceSelect(choice)}
              className="w-full p-4 bg-white rounded-lg border border-purple-200 hover:border-purple-300 hover:bg-purple-50 transition-colors text-left"
            >
              <div className="font-medium text-purple-900">{choice.text}</div>
              <div className="text-sm text-purple-600 mt-1">{choice.consequence}</div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
```

### **Phase 3: Community Features (Weeks 5-6)**

#### **Task 3.1: Privacy-Preserving Sharing**
```typescript
export interface SharingSettings {
  shareProgress: boolean;
  shareAchievements: boolean;
  shareStreaks: boolean;
  shareLevel: 'public' | 'friends' | 'private';
  allowComments: boolean;
  showRealName: boolean;
}

export class SharingManager {
  async generateShareableContent(
    profile: EngagementProfile, 
    settings: SharingSettings
  ): Promise<ShareableContent> {
    const content: ShareableContent = {
      type: 'progress-update',
      timestamp: Date.now(),
      data: {}
    };
    
    if (settings.shareProgress) {
      content.data.progress = {
        level: profile.level,
        experience: profile.experience,
        totalSessions: profile.totalSessions
      };
    }
    
    if (settings.shareAchievements) {
      content.data.achievements = profile.unlockedBadges.slice(-3); // Last 3
    }
    
    if (settings.shareStreaks) {
      content.data.streak = {
        current: profile.currentStreak,
        longest: profile.longestStreak
      };
    }
    
    return content;
  }
  
  async shareToCommunity(content: ShareableContent): Promise<void> {
    // Local-first: store sharing data locally
    const shareRecord: ShareRecord = {
      id: generateId(),
      content,
      sharedAt: Date.now(),
      privacyLevel: 'local-only'
    };
    
    await this.saveShareRecord(shareRecord);
    
    // Optional: export for external sharing
    if (content.privacyLevel === 'export') {
      const exportData = await this.generateExportData(shareRecord);
      this.downloadShareableFile(exportData);
    }
  }
}
```

---

## 🧪 Test Coverage Requirements

### **Unit Tests (>95% Coverage)**
```typescript
describe('StreakManager', () => {
  test('updates streak for consecutive days', async () => {
    const manager = new StreakManager();
    const profile = await manager.getEngagementProfile();
    
    // Simulate consecutive practice days
    await manager.updateStreak(1);
    await manager.updateStreak(2);
    
    const updatedProfile = await manager.getEngagementProfile();
    expect(updatedProfile.currentStreak).toBe(2);
  });
  
  test('resets streak after gap', async () => {
    const manager = new StreakManager();
    
    // Simulate gap in practice
    await manager.updateStreak(1);
    await manager.simulateDayGap(2);
    await manager.updateStreak(2);
    
    const profile = await manager.getEngagementProfile();
    expect(profile.currentStreak).toBe(1);
  });
});

describe('AchievementManager', () => {
  test('unlocks first practice achievement', async () => {
    const manager = new AchievementManager();
    const profile = await manager.getEngagementProfile();
    
    profile.totalSessions = 1;
    const unlocks = await manager.checkAchievements(profile);
    
    expect(unlocks).toHaveLength(1);
    expect(unlocks[0].achievement.id).toBe('first-practice');
  });
  
  test('prevents duplicate unlocks', async () => {
    const manager = new AchievementManager();
    const profile = await manager.getEngagementProfile();
    
    profile.unlockedBadges = ['first-practice'];
    profile.totalSessions = 1;
    const unlocks = await manager.checkAchievements(profile);
    
    expect(unlocks).toHaveLength(0);
  });
});
```

### **Integration Tests (>90% Coverage)**
```typescript
describe('Engagement System Integration', () => {
  test('complete practice flow updates engagement', async () => {
    const session = await SessionManager.saveSession({
      ts: Date.now(),
      medianF0: 200,
      comfort: 4
    });
    
    const streakUpdate = await StreakManager.updateStreak(session);
    const achievementUnlocks = await AchievementManager.checkAchievements(profile);
    
    expect(streakUpdate.currentStreak).toBeGreaterThan(0);
    expect(achievementUnlocks.length).toBeGreaterThanOrEqual(0);
  });
  
  test('narrative flow progression', async () => {
    const narrative = await NarrativeManager.getAvailableNarratives(profile);
    const session = await NarrativeManager.startNarrative(narrative[0].id, profile);
    
    expect(session.currentChapter).toBe(narrative[0].chapters[0].id);
    expect(session.progress).toBe(0);
  });
});
```

### **E2E Tests (>80% Coverage)**
```typescript
describe('Engagement E2E', () => {
  test('complete engagement flow', async ({ page }) => {
    await page.goto('/practice');
    
    // Complete practice session
    await page.click('button[aria-label*="Start"]');
    await page.waitForTimeout(3000);
    await page.click('button[aria-label*="Stop"]');
    
    // Check streak update
    await page.goto('/dashboard');
    const streakElement = await page.locator('[data-testid="current-streak"]');
    await expect(streakElement).toContainText('1');
    
    // Check achievement unlock
    const achievementElement = await page.locator('[data-testid="achievement-unlock"]');
    await expect(achievementElement).toBeVisible();
  });
  
  test('narrative practice flow', async ({ page }) => {
    await page.goto('/narratives');
    
    // Start narrative
    await page.click('button[aria-label*="Start Voice Journey"]');
    
    // Complete practice scenario
    await page.click('button[aria-label*="Start Recording"]');
    await page.waitForTimeout(3000);
    await page.click('button[aria-label*="Stop Recording"]');
    
    // Make narrative choice
    const choiceButton = await page.locator('button[data-testid="choice-gentle-approach"]');
    await expect(choiceButton).toBeVisible();
    await choiceButton.click();
    
    // Verify progression
    const nextChapter = await page.locator('[data-testid="narrative-chapter"]');
    await expect(nextChapter).toContainText('First Steps');
  });
});
```

---

## 🎯 Acceptance Criteria

### **Foundational Features (Phase 1)**
- [ ] **Streak Tracking**: Accurate consecutive day counting with gap detection
- [ ] **Achievement System**: 10+ unlockable badges with proper requirements
- [ ] **Progress Dashboard**: Real-time stats with privacy controls
- [ ] **IndexedDB Integration**: Local-first storage with export capabilities
- [ ] **Privacy Controls**: Granular sharing settings with opt-in defaults

### **Narrative Enhancement (Phase 2)**
- [ ] **Narrative Flows**: 3+ story-driven practice scenarios
- [ ] **Choice System**: Branching narratives based on user decisions
- [ ] **Progress Tracking**: Chapter completion and story advancement
- [ ] **Unlock System**: Narrative access based on achievement requirements
- [ ] **Accessibility**: Screen reader support for story content

### **Community Features (Phase 3)**
- [ ] **Sharing System**: Privacy-preserving progress sharing
- [ ] **Export Functionality**: Local data export for external sharing
- [ ] **Privacy Controls**: Granular sharing permissions
- [ ] **Community Guidelines**: Safe sharing policies and moderation
- [ ] **Coach Integration**: SLP portal for progress monitoring

### **Quality Requirements**
- [ ] **Test Coverage**: >95% unit, >90% integration, >80% E2E
- [ ] **Performance**: <100ms engagement updates, <500ms dashboard load
- [ ] **Accessibility**: WCAG 2.2 AA compliance with screen reader support
- [ ] **Privacy**: Local-first with opt-in sharing, no cloud dependencies
- [ ] **Retention**: >35% 4-week retention rate target

---

## 👥 Role Assignments

### **Cursor Agent (Primary Implementer)**
- **Tasks**: All UI/UX components, engagement hooks, narrative flows
- **Deliverables**: React components, hooks, integration logic
- **Timeline**: 6 weeks (Phases 1-3)
- **Success Criteria**: All acceptance criteria met with >95% test coverage

### **ChatGPT Agent (Orchestrator)**
- **Tasks**: Narrative content creation, achievement design, community guidelines
- **Deliverables**: Story content, achievement definitions, sharing policies
- **Timeline**: 6 weeks (Phases 1-3)
- **Success Criteria**: Engaging content with affirming, inclusive language

### **QA Scribe (Validator)**
- **Tasks**: Test execution, user acceptance testing, accessibility validation
- **Deliverables**: Test results, quality reports, user feedback analysis
- **Timeline**: 6 weeks (Phases 1-3)
- **Success Criteria**: All tests passing, user satisfaction >4.0/5.0

### **Codex Agent (Coordinator)**
- **Tasks**: Database schema updates, CI/CD integration, performance monitoring
- **Deliverables**: Database migrations, automated testing, performance benchmarks
- **Timeline**: 6 weeks (Phases 1-3)
- **Success Criteria**: Green CI pipeline, performance targets met

---

## 📦 Deliverables

### **Components**
- `StreakCard`, `AchievementGrid`, `ProgressChart`, `PracticeStats`
- `NarrativePracticeCard`, `NarrativeChapter`, `NarrativeChoice`
- `SharingSettings`, `PrivacyControls`, `CommunityGuidelines`

### **Hooks & Utilities**
- `useEngagementProfile`, `useStreakManager`, `useAchievementManager`
- `useNarrativeManager`, `useSharingManager`, `usePrivacyControls`

### **Database Schema**
- Extended `EngagementProfile` table
- `Achievement` definitions and unlock tracking
- `NarrativeSession` and `ShareRecord` tables

### **Tests**
- `tests/unit/engagement-system.spec.ts`
- `tests/integration/narrative-flows.spec.ts`
- `tests/e2e/engagement-e2e.spec.ts`

### **Documentation**
- `docs/engagement-system-guide.md`
- `docs/narrative-content-guidelines.md`
- `docs/privacy-sharing-policies.md`
- `docs/release-notes/t6-engagement-retention.md`

---

## 🚀 Implementation Timeline

### **Week 1-2: Foundational Features**
- Streak tracking with gap detection
- Achievement system with 10+ badges
- Progress dashboard with real-time stats
- Privacy controls and sharing settings

### **Week 3-4: Narrative Enhancement**
- Narrative flow system with branching choices
- Story-driven practice scenarios
- Chapter progression and unlock system
- Accessibility support for narrative content

### **Week 5-6: Community Features**
- Privacy-preserving sharing system
- Export functionality for external sharing
- Community guidelines and moderation
- Coach/SLP portal integration

---

## ⚠️ Risk Mitigation

### **High-Risk Items**
- **Retention Target**: >35% 4-week retention may be ambitious
- **Mitigation**: Start with conservative targets, iterate based on user feedback
- **Contingency**: Focus on core engagement features if narrative layer delays

### **Medium-Risk Items**
- **Privacy Concerns**: Users may be hesitant about sharing features
- **Mitigation**: Default to private, clear opt-in controls, transparent data usage
- **Contingency**: Disable sharing features if privacy concerns arise

### **Low-Risk Items**
- **Content Creation**: Narrative content may not resonate with all users
- **Mitigation**: A/B test different narrative styles, gather user feedback
- **Contingency**: Fall back to achievement-only engagement if narratives fail

---

*This comprehensive T6 specification provides a complete roadmap for building engagement and retention systems that will drive user adoption and long-term success for the Resonai beta launch.*
