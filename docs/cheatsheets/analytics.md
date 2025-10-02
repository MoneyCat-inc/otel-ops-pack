# Instant Practice Rollout Cheat Sheet

**Issue**: Need to test different user flows and collect analytics without data loss  
**Solution**: A/B testing framework with ring buffer analytics and sendBeacon

## 🧪 **A/B Test Framework**

### **Experiment Configuration**
```typescript
interface Experiment {
  id: string
  name: string
  variants: Variant[]
  trafficAllocation: number  // 0-1, percentage of users
  startDate: string
  endDate: string
  metrics: string[]
}

interface Variant {
  id: string
  name: string
  weight: number  // 0-1, relative weight
  config: Record<string, any>
}

// Example experiments
const experiments: Experiment[] = [
  {
    id: 'E1',
    name: 'Signup Timing',
    variants: [
      {
        id: 'lesson-first',
        name: 'Lesson First',
        weight: 0.5,
        config: { showLessonBeforeSignup: true }
      },
      {
        id: 'signup-first', 
        name: 'Signup First',
        weight: 0.5,
        config: { showLessonBeforeSignup: false }
      }
    ],
    trafficAllocation: 1.0,
    startDate: '2025-10-01',
    endDate: '2025-10-31',
    metrics: ['activation', 'signup_completion', 'lesson_completion']
  },
  {
    id: 'E2',
    name: 'Permission Primer',
    variants: [
      {
        id: 'primer',
        name: 'With Primer',
        weight: 0.5,
        config: { showPermissionPrimer: true }
      },
      {
        id: 'native',
        name: 'Native Only',
        weight: 0.5,
        config: { showPermissionPrimer: false }
      }
    ],
    trafficAllocation: 0.8,
    startDate: '2025-10-01',
    endDate: '2025-10-31',
    metrics: ['permission_granted', 'mic_session_start', 'activation']
  }
]
```

### **Experiment Assignment**
```typescript
class ExperimentManager {
  private userId: string
  private assignedExperiments: Map<string, string> = new Map()
  
  constructor(userId: string) {
    this.userId = userId
    this.loadAssignedExperiments()
  }
  
  private loadAssignedExperiments() {
    // Load from localStorage or server
    const stored = localStorage.getItem('assigned_experiments')
    if (stored) {
      this.assignedExperiments = new Map(JSON.parse(stored))
    } else {
      this.assignExperiments()
    }
  }
  
  private assignExperiments() {
    experiments.forEach(experiment => {
      if (this.shouldParticipate(experiment)) {
        const variant = this.assignVariant(experiment)
        this.assignedExperiments.set(experiment.id, variant.id)
      }
    })
    
    this.saveAssignedExperiments()
  }
  
  private shouldParticipate(experiment: Experiment): boolean {
    const now = new Date()
    const startDate = new Date(experiment.startDate)
    const endDate = new Date(experiment.endDate)
    
    if (now < startDate || now > endDate) return false
    
    // Use user ID hash for consistent assignment
    const hash = this.hashUserId(this.userId + experiment.id)
    return hash < experiment.trafficAllocation
  }
  
  private assignVariant(experiment: Experiment): Variant {
    const hash = this.hashUserId(this.userId + experiment.id)
    let cumulativeWeight = 0
    
    for (const variant of experiment.variants) {
      cumulativeWeight += variant.weight
      if (hash < cumulativeWeight) {
        return variant
      }
    }
    
    return experiment.variants[0] // Fallback
  }
  
  private hashUserId(input: string): number {
    let hash = 0
    for (let i = 0; i < input.length; i++) {
      const char = input.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32-bit integer
    }
    return Math.abs(hash) / 2147483647 // Normalize to [0, 1]
  }
  
  getVariant(experimentId: string): string | null {
    return this.assignedExperiments.get(experimentId) || null
  }
}
```

## 📊 **Analytics Events**

### **Event Tracking System**
```typescript
interface AnalyticsEvent {
  event: string
  userId: string
  sessionId: string
  timestamp: number
  experimentId?: string
  variantId?: string
  properties: Record<string, any>
}

class AnalyticsTracker {
  private userId: string
  private sessionId: string
  private experimentManager: ExperimentManager
  private ringBuffer: AnalyticsEvent[] = []
  private bufferSize = 100
  
  constructor(userId: string) {
    this.userId = userId
    this.sessionId = this.generateSessionId()
    this.experimentManager = new ExperimentManager(userId)
  }
  
  track(event: string, properties: Record<string, any> = {}) {
    const analyticsEvent: AnalyticsEvent = {
      event,
      userId: this.userId,
      sessionId: this.sessionId,
      timestamp: Date.now(),
      properties
    }
    
    // Add experiment context
    experiments.forEach(experiment => {
      const variantId = this.experimentManager.getVariant(experiment.id)
      if (variantId) {
        analyticsEvent.experimentId = experiment.id
        analyticsEvent.variantId = variantId
      }
    })
    
    this.addToRingBuffer(analyticsEvent)
    this.sendEvent(analyticsEvent)
  }
  
  private addToRingBuffer(event: AnalyticsEvent) {
    this.ringBuffer.push(event)
    
    // Maintain buffer size
    if (this.ringBuffer.length > this.bufferSize) {
      this.ringBuffer.shift()
    }
  }
  
  private async sendEvent(event: AnalyticsEvent) {
    try {
      // Use sendBeacon for reliable delivery
      const blob = new Blob([JSON.stringify(event)], {
        type: 'application/json'
      })
      
      const sent = navigator.sendBeacon('/api/analytics', blob)
      
      if (!sent) {
        // Fallback to fetch if sendBeacon fails
        await fetch('/api/analytics', {
          method: 'POST',
          body: JSON.stringify(event),
          headers: { 'Content-Type': 'application/json' },
          keepalive: true
        })
      }
    } catch (error) {
      console.warn('Analytics event failed to send:', error)
      // Event remains in ring buffer for retry
    }
  }
}
```

### **Key Events to Track**
```typescript
class PracticeAnalytics {
  private tracker: AnalyticsTracker
  
  constructor(tracker: AnalyticsTracker) {
    this.tracker = tracker
  }
  
  // Screen/view events
  trackScreenView(screenName: string, properties: Record<string, any> = {}) {
    this.tracker.track('screen_view', {
      screen_name: screenName,
      ...properties
    })
  }
  
  // Permission events
  trackPermissionRequested(permissionType: string) {
    this.tracker.track('permission_requested', {
      permission_type: permissionType
    })
  }
  
  trackPermissionGranted(permissionType: string) {
    this.tracker.track('permission_granted', {
      permission_type: permissionType
    })
  }
  
  trackPermissionDenied(permissionType: string) {
    this.tracker.track('permission_denied', {
      permission_type: permissionType
    })
  }
  
  // Microphone session events
  trackMicSessionStart() {
    this.tracker.track('mic_session_start', {
      timestamp: Date.now()
    })
  }
  
  trackMicSessionEnd(duration: number, reason: string) {
    this.tracker.track('mic_session_end', {
      duration,
      reason
    })
  }
  
  // Activation events
  trackActivation(activationType: string, properties: Record<string, any> = {}) {
    this.tracker.track('activation', {
      activation_type: activationType,
      ...properties
    })
  }
  
  // Practice flow events
  trackPracticeStart(practiceId: string) {
    this.tracker.track('practice_start', {
      practice_id: practiceId
    })
  }
  
  trackPracticeComplete(practiceId: string, duration: number, success: boolean) {
    this.tracker.track('practice_complete', {
      practice_id: practiceId,
      duration,
      success
    })
  }
}
```

## 🔄 **Ring Buffer Implementation**

### **Reliable Data Delivery**
```typescript
class RingBufferAnalytics {
  private buffer: AnalyticsEvent[] = []
  private maxSize = 1000
  private retryQueue: AnalyticsEvent[] = []
  private maxRetries = 3
  
  addEvent(event: AnalyticsEvent) {
    this.buffer.push(event)
    
    // Maintain buffer size
    if (this.buffer.length > this.maxSize) {
      this.buffer.shift()
    }
    
    // Try to send immediately
    this.sendEvent(event)
  }
  
  private async sendEvent(event: AnalyticsEvent) {
    try {
      const sent = await this.trySendEvent(event)
      
      if (!sent) {
        this.addToRetryQueue(event)
      }
    } catch (error) {
      console.warn('Event send failed:', error)
      this.addToRetryQueue(event)
    }
  }
  
  private async trySendEvent(event: AnalyticsEvent): Promise<boolean> {
    // Try sendBeacon first
    const blob = new Blob([JSON.stringify(event)], {
      type: 'application/json'
    })
    
    const beaconSent = navigator.sendBeacon('/api/analytics', blob)
    if (beaconSent) return true
    
    // Fallback to fetch
    try {
      const response = await fetch('/api/analytics', {
        method: 'POST',
        body: JSON.stringify(event),
        headers: { 'Content-Type': 'application/json' },
        keepalive: true
      })
      
      return response.ok
    } catch (error) {
      return false
    }
  }
  
  private addToRetryQueue(event: AnalyticsEvent) {
    const retryEvent = { ...event, retryCount: 0 }
    this.retryQueue.push(retryEvent)
  }
  
  // Retry failed events
  async retryFailedEvents() {
    const eventsToRetry = [...this.retryQueue]
    this.retryQueue = []
    
    for (const event of eventsToRetry) {
      const retryCount = (event as any).retryCount || 0
      
      if (retryCount < this.maxRetries) {
        try {
          const sent = await this.trySendEvent(event)
          if (!sent) {
            (event as any).retryCount = retryCount + 1
            this.retryQueue.push(event)
          }
        } catch (error) {
          (event as any).retryCount = retryCount + 1
          this.retryQueue.push(event)
        }
      }
    }
  }
  
  // Flush all events (e.g., on page unload)
  async flushAllEvents() {
    const allEvents = [...this.buffer, ...this.retryQueue]
    
    for (const event of allEvents) {
      await this.trySendEvent(event)
    }
    
    this.buffer = []
    this.retryQueue = []
  }
}
```

## 🎯 **Implementation Example**

### **Complete Rollout System**
```typescript
class PracticeRollout {
  private analytics: PracticeAnalytics
  private experimentManager: ExperimentManager
  private ringBuffer: RingBufferAnalytics
  
  constructor(userId: string) {
    this.ringBuffer = new RingBufferAnalytics()
    const tracker = new AnalyticsTracker(userId)
    this.analytics = new PracticeAnalytics(tracker)
    this.experimentManager = new ExperimentManager(userId)
    
    this.setupEventListeners()
  }
  
  private setupEventListeners() {
    // Track page visibility changes
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        this.ringBuffer.flushAllEvents()
      }
    })
    
    // Track page unload
    window.addEventListener('beforeunload', () => {
      this.ringBuffer.flushAllEvents()
    })
    
    // Retry failed events periodically
    setInterval(() => {
      this.ringBuffer.retryFailedEvents()
    }, 30000) // Every 30 seconds
  }
  
  async startPractice() {
    // Track screen view
    this.analytics.trackScreenView('practice_start')
    
    // Check experiment variants
    const signupVariant = this.experimentManager.getVariant('E1')
    const permissionVariant = this.experimentManager.getVariant('E2')
    
    // Apply experiment logic
    if (signupVariant === 'lesson-first') {
      await this.showLessonFirst()
    } else {
      await this.showSignupFirst()
    }
    
    if (permissionVariant === 'primer') {
      await this.showPermissionPrimer()
    }
    
    // Track activation
    this.analytics.trackActivation('practice_started', {
      signup_variant: signupVariant,
      permission_variant: permissionVariant
    })
  }
}
```

## 📋 **Testing Checklist**

- [ ] A/B test assignment works consistently
- [ ] Analytics events track correctly
- [ ] Ring buffer prevents data loss
- [ ] sendBeacon fallback works
- [ ] Retry mechanism functions
- [ ] Experiment variants apply correctly
- [ ] Data persists across sessions

---

**Remember**: Always use sendBeacon for critical analytics to prevent data loss on page unload!
