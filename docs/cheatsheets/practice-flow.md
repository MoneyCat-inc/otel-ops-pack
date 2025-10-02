# Practice Flow JSON Cheat Sheet

**Issue**: Practice flow data needs to be local-first with offline capability  
**Solution**: JSON schema with IndexedDB storage and 60 FPS metrics computation

## 📋 **Schema Definition**

### **Core Schema Keys**
```typescript
interface PracticeFlowItem {
  id: string                    // Unique identifier
  type: 'drill' | 'exercise' | 'assessment'
  title: string                 // Display title
  copy: string                  // Instructions/description
  metrics: string[]             // Metrics to track
  successThreshold: Record<string, number>  // Success criteria
  next?: string                 // Next item ID
  duration?: number             // Expected duration (seconds)
  difficulty?: 'beginner' | 'intermediate' | 'advanced'
}
```

### **Example Drill**
```json
{
  "id": "glide",
  "type": "drill",
  "title": "Pitch Glide",
  "copy": "Sustain a steady pitch, then glide smoothly to the target note",
  "metrics": ["timeInTargetPct", "pitchAccuracy", "smoothness"],
  "successThreshold": {
    "timeInTargetPct": 0.7,
    "pitchAccuracy": 0.8,
    "smoothness": 0.6
  },
  "next": "phrase",
  "duration": 30,
  "difficulty": "beginner"
}
```

## 🗄️ **Local-First Storage**

### **IndexedDB Implementation**
```typescript
class PracticeFlowStorage {
  private db: IDBDatabase
  
  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open('PracticeFlow', 1)
      
      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result
        
        // Practice items store
        if (!db.objectStoreNames.contains('practiceItems')) {
          const store = db.createObjectStore('practiceItems', { keyPath: 'id' })
          store.createIndex('type', 'type', { unique: false })
          store.createIndex('difficulty', 'difficulty', { unique: false })
        }
        
        // Session data store
        if (!db.objectStoreNames.contains('sessions')) {
          const store = db.createObjectStore('sessions', { keyPath: 'id', autoIncrement: true })
          store.createIndex('timestamp', 'timestamp', { unique: false })
          store.createIndex('itemId', 'itemId', { unique: false })
        }
        
        // Metrics store
        if (!db.objectStoreNames.contains('metrics')) {
          const store = db.createObjectStore('metrics', { keyPath: 'id', autoIncrement: true })
          store.createIndex('sessionId', 'sessionId', { unique: false })
          store.createIndex('timestamp', 'timestamp', { unique: false })
        }
      }
      
      request.onsuccess = () => {
        this.db = request.result
        resolve(this.db)
      }
      
      request.onerror = () => reject(request.error)
    })
  }
  
  async savePracticeItem(item: PracticeFlowItem): Promise<void> {
    const transaction = this.db.transaction(['practiceItems'], 'readwrite')
    const store = transaction.objectStore('practiceItems')
    await store.put(item)
  }
  
  async getPracticeItem(id: string): Promise<PracticeFlowItem> {
    const transaction = this.db.transaction(['practiceItems'], 'readonly')
    const store = transaction.objectStore('practiceItems')
    return new Promise((resolve, reject) => {
      const request = store.get(id)
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })
  }
}
```

## 📊 **60 FPS Metrics Computation**

### **Real-time Metrics Engine**
```typescript
class MetricsEngine {
  private metrics: Map<string, number[]> = new Map()
  private sessionId: string
  private frameRate = 60
  private frameInterval = 1000 / this.frameRate
  
  constructor(sessionId: string) {
    this.sessionId = sessionId
    this.startMetricsLoop()
  }
  
  private startMetricsLoop() {
    setInterval(() => {
      this.computeMetrics()
    }, this.frameInterval)
  }
  
  private computeMetrics() {
    const timestamp = Date.now()
    
    // Compute each metric
    this.metrics.forEach((values, metricName) => {
      const computedValue = this.computeMetric(metricName, values)
      
      // Store computed metric
      this.storeMetric(metricName, computedValue, timestamp)
    })
  }
  
  private computeMetric(metricName: string, values: number[]): number {
    switch (metricName) {
      case 'timeInTargetPct':
        return this.computeTimeInTarget(values)
      case 'pitchAccuracy':
        return this.computePitchAccuracy(values)
      case 'smoothness':
        return this.computeSmoothness(values)
      default:
        return 0
    }
  }
  
  private computeTimeInTarget(pitchValues: number[]): number {
    const targetPitch = 440 // A4
    const tolerance = 20 // cents
    
    const inTarget = pitchValues.filter(pitch => 
      Math.abs(pitch - targetPitch) <= tolerance
    ).length
    
    return inTarget / pitchValues.length
  }
  
  private computePitchAccuracy(pitchValues: number[]): number {
    const targetPitch = 440
    const errors = pitchValues.map(pitch => 
      Math.abs(pitch - targetPitch) / targetPitch
    )
    
    const avgError = errors.reduce((sum, error) => sum + error, 0) / errors.length
    return Math.max(0, 1 - avgError)
  }
  
  private computeSmoothness(pitchValues: number[]): number {
    if (pitchValues.length < 2) return 0
    
    const deltas = []
    for (let i = 1; i < pitchValues.length; i++) {
      deltas.push(Math.abs(pitchValues[i] - pitchValues[i-1]))
    }
    
    const avgDelta = deltas.reduce((sum, delta) => sum + delta, 0) / deltas.length
    const maxDelta = Math.max(...deltas)
    
    return Math.max(0, 1 - (avgDelta / maxDelta))
  }
  
  addMetricValue(metricName: string, value: number) {
    if (!this.metrics.has(metricName)) {
      this.metrics.set(metricName, [])
    }
    
    const values = this.metrics.get(metricName)!
    values.push(value)
    
    // Keep only last 60 values (1 second at 60 FPS)
    if (values.length > 60) {
      values.shift()
    }
  }
}
```

## 🎯 **Practice Session Management**

### **Session Controller**
```typescript
class PracticeSession {
  private storage: PracticeFlowStorage
  private metricsEngine: MetricsEngine
  private currentItem: PracticeFlowItem
  private sessionId: string
  
  constructor(storage: PracticeFlowStorage) {
    this.storage = storage
    this.sessionId = this.generateSessionId()
    this.metricsEngine = new MetricsEngine(this.sessionId)
  }
  
  async startPractice(itemId: string) {
    this.currentItem = await this.storage.getPracticeItem(itemId)
    
    // Initialize metrics for this item
    this.currentItem.metrics.forEach(metric => {
      this.metricsEngine.addMetricValue(metric, 0)
    })
    
    // Start practice session
    this.startSession()
  }
  
  private startSession() {
    // Practice session logic
    const startTime = Date.now()
    
    // Monitor success criteria
    setInterval(() => {
      this.checkSuccessCriteria()
    }, 1000) // Check every second
  }
  
  private checkSuccessCriteria() {
    const currentMetrics = this.getCurrentMetrics()
    const thresholds = this.currentItem.successThreshold
    
    let allCriteriaMet = true
    
    Object.entries(thresholds).forEach(([metric, threshold]) => {
      const currentValue = currentMetrics[metric] || 0
      if (currentValue < threshold) {
        allCriteriaMet = false
      }
    })
    
    if (allCriteriaMet) {
      this.completePractice()
    }
  }
  
  private completePractice() {
    // Save session results
    this.saveSessionResults()
    
    // Move to next item if available
    if (this.currentItem.next) {
      this.startPractice(this.currentItem.next)
    }
  }
}
```

## 🚨 **Common Issues**

### **IndexedDB Quota Exceeded**
**Problem**: Too much data stored locally  
**Solution**: Implement data cleanup and compression

```typescript
async cleanupOldData() {
  const cutoffDate = Date.now() - (30 * 24 * 60 * 60 * 1000) // 30 days
  
  const transaction = this.db.transaction(['sessions', 'metrics'], 'readwrite')
  
  // Delete old sessions
  const sessionStore = transaction.objectStore('sessions')
  const sessionIndex = sessionStore.index('timestamp')
  const sessionRange = IDBKeyRange.upperBound(cutoffDate)
  
  await sessionIndex.openCursor(sessionRange).then(cursor => {
    if (cursor) {
      cursor.delete()
      cursor.continue()
    }
  })
}
```

### **Metrics Computation Too Slow**
**Problem**: 60 FPS computation causes frame drops  
**Solution**: Use Web Workers for heavy computation

```typescript
// In Web Worker
self.onmessage = function(e) {
  const { metricName, values } = e.data
  
  let result
  switch (metricName) {
    case 'smoothness':
      result = computeSmoothness(values)
      break
    // ... other metrics
  }
  
  self.postMessage({ metricName, result })
}
```

## 📋 **Testing Checklist**

- [ ] Practice items load from IndexedDB
- [ ] Metrics computed at 60 FPS
- [ ] Success criteria checked correctly
- [ ] Session data persisted locally
- [ ] Offline functionality works
- [ ] Data cleanup prevents quota issues
- [ ] Performance remains smooth

---

**Remember**: All practice data should work offline and sync when connection is available!
