# Cursor-First Rollout Plan: Safe Queue + Isolation Refactor

## Overview
This document outlines a four-stage rollout plan for implementing a safe queue system with enhanced isolation capabilities, designed for Cursor IDE implementation with comprehensive guardrails and verification.

## Current State Analysis
- **Queue System**: Basic JSON-based task queue in `.agent/task_queue/` with pending/processing/completed/failed states
- **Isolation**: Service worker with COOP/COEP header preservation, cross-origin isolation for WASM/SharedArrayBuffer
- **Architecture**: Next.js 14 + React 18 + TypeScript + Tailwind + AudioWorklets
- **Guardrails**: ECRR methodology, strict CSP/COOP/COEP, local-first operations

---

## PR-A: SQLite Queue Foundation + Feature Flags

### Branch: `feature/sqlite-queue-foundation`
### Scope: Database-backed queue with feature flags

**Implementation Steps:**
1. **Add SQLite Dependencies**
   ```bash
   pnpm add better-sqlite3 @types/better-sqlite3
   ```

2. **Create Queue Schema**
   ```typescript
   // lib/queue/schema.sql
   CREATE TABLE IF NOT EXISTS tasks (
     id TEXT PRIMARY KEY,
     type TEXT NOT NULL,
     priority INTEGER NOT NULL,
     status TEXT NOT NULL DEFAULT 'pending',
     created_at INTEGER NOT NULL,
     updated_at INTEGER NOT NULL,
     assigned_to TEXT,
     payload TEXT NOT NULL,
     retry_count INTEGER DEFAULT 0,
     max_retries INTEGER DEFAULT 3
   );
   
   CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
   CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority DESC);
   ```

3. **Implement Queue Manager**
   ```typescript
   // lib/queue/QueueManager.ts
   export class QueueManager {
     private db: Database;
     
     constructor(dbPath: string = '.agent/queue.db') {
       this.db = new Database(dbPath);
       this.initSchema();
     }
     
     async enqueue(task: Task): Promise<string> {
       // Implementation with SQLite
     }
     
     async dequeue(workerId: string): Promise<Task | null> {
       // Atomic dequeue with status update
     }
   }
   ```

4. **Add Feature Flags**
   ```typescript
   // lib/config/features.ts
   export const FEATURES = {
     SQLITE_QUEUE: process.env.NEXT_PUBLIC_FEATURE_SQLITE_QUEUE === 'true',
     ENHANCED_ISOLATION: process.env.NEXT_PUBLIC_FEATURE_ENHANCED_ISOLATION === 'true',
     OFFLINE_FIRST: process.env.NEXT_PUBLIC_FEATURE_OFFLINE_FIRST === 'true'
   };
   ```

**Acceptance Criteria:**
- [ ] SQLite queue operational with atomic operations
- [ ] Feature flags control queue implementation
- [ ] Backward compatibility with JSON queue
- [ ] Unit tests for queue operations
- [ ] Performance benchmarks (< 10ms per operation)

**Cursor Prompt:**
```
Implement SQLite-backed queue system with feature flags. Create QueueManager class with atomic enqueue/dequeue operations, add feature flag configuration, and maintain backward compatibility with existing JSON queue. Include comprehensive unit tests and performance benchmarks.
```

---

## PR-B: Runner Shadow Mode + Queue Migration

### Branch: `feature/runner-shadow-mode`
### Scope: Shadow runner with gradual migration

**Implementation Steps:**
1. **Create Shadow Runner**
   ```typescript
   // lib/runner/ShadowRunner.ts
   export class ShadowRunner {
     private queueManager: QueueManager;
     private jsonQueue: JsonQueueManager;
     
     async processTask(task: Task): Promise<void> {
       // Process with both systems
       const sqliteResult = await this.queueManager.process(task);
       const jsonResult = await this.jsonQueue.process(task);
       
       // Compare results for validation
       this.validateResults(sqliteResult, jsonResult);
     }
   }
   ```

2. **Implement Migration Script**
   ```typescript
   // scripts/migrate-queue.ps1
   # Migrate existing JSON tasks to SQLite
   $jsonTasks = Get-Content .agent/task_queue/pending/*.json
   foreach ($task in $jsonTasks) {
     # Convert and insert into SQLite
   }
   ```

3. **Add Monitoring Dashboard**
   ```typescript
   // components/QueueMonitor.tsx
   export function QueueMonitor() {
     const [sqliteStats, setSqliteStats] = useState(null);
     const [jsonStats, setJsonStats] = useState(null);
     
     return (
       <div className="grid grid-cols-2 gap-4">
         <QueueStats title="SQLite Queue" stats={sqliteStats} />
         <QueueStats title="JSON Queue" stats={jsonStats} />
       </div>
     );
   }
   ```

**Acceptance Criteria:**
- [ ] Shadow runner processes tasks in both systems
- [ ] Migration script converts existing tasks
- [ ] Monitoring dashboard shows both queue states
- [ ] No performance degradation during shadow mode
- [ ] Rollback capability to JSON-only mode

**Cursor Prompt:**
```
Create shadow runner system that processes tasks in both SQLite and JSON queues simultaneously. Implement migration script for existing tasks, add monitoring dashboard to compare both systems, and ensure rollback capability. Include comprehensive validation and performance monitoring.
```

---

## PR-C: Service Worker Offline Isolation Enhancement

### Branch: `feature/sw-offline-isolation`
### Scope: Enhanced offline isolation with queue persistence

**Implementation Steps:**
1. **Enhanced Service Worker**
   ```typescript
   // public/enhanced-sw.js
   const CACHE_NAME = 'resonai-v1';
   const QUEUE_CACHE = 'queue-cache-v1';
   
   self.addEventListener('fetch', (event) => {
     if (event.request.url.includes('/api/queue/')) {
       event.respondWith(handleQueueRequest(event.request));
     } else {
       event.respondWith(handleRegularRequest(event.request));
     }
   });
   
   async function handleQueueRequest(request) {
     // Offline queue operations with COOP/COEP preservation
     const response = await fetch(request);
     const clonedResponse = response.clone();
     
     // Preserve headers for offline use
     const headers = new Headers(clonedResponse.headers);
     headers.set('Cross-Origin-Opener-Policy', 'same-origin');
     headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
     
     return new Response(clonedResponse.body, {
       status: clonedResponse.status,
       statusText: clonedResponse.statusText,
       headers: headers
     });
   }
   ```

2. **Offline Queue Manager**
   ```typescript
   // lib/queue/OfflineQueueManager.ts
   export class OfflineQueueManager {
     private db: Database;
     
     async syncWhenOnline(): Promise<void> {
       if (navigator.onLine) {
         const pendingTasks = await this.getPendingTasks();
         await this.syncToServer(pendingTasks);
       }
     }
   }
   ```

3. **Cross-Origin Isolation Tests**
   ```typescript
   // playwright/tests/offline-isolation.spec.ts
   test('offline queue maintains cross-origin isolation', async ({ page }) => {
     await page.goto('/try');
     await page.evaluate(() => {
       // Test offline queue operations
       return window.crossOriginIsolated;
     });
   });
   ```

**Acceptance Criteria:**
- [ ] Service worker preserves COOP/COEP headers offline
- [ ] Queue operations work offline with sync on reconnect
- [ ] Cross-origin isolation maintained in offline mode
- [ ] Comprehensive offline testing coverage
- [ ] Graceful degradation when isolation unavailable

**Cursor Prompt:**
```
Enhance service worker for offline queue operations while preserving cross-origin isolation headers. Implement offline queue manager with sync capabilities, add comprehensive offline testing, and ensure graceful degradation when isolation is unavailable. Maintain COOP/COEP headers in all offline scenarios.
```

---

## PR-D: Production Flip + Monitoring

### Branch: `feature/production-flip`
### Scope: Production deployment with comprehensive monitoring

**Implementation Steps:**
1. **Production Configuration**
   ```typescript
   // lib/config/production.ts
   export const PRODUCTION_CONFIG = {
     QUEUE_TYPE: 'sqlite',
     ISOLATION_ENFORCED: true,
     OFFLINE_FIRST: true,
     MONITORING_ENABLED: true
   };
   ```

2. **Monitoring Integration**
   ```typescript
   // lib/monitoring/QueueMonitor.ts
   export class QueueMonitor {
     async reportMetrics(): Promise<void> {
       const metrics = await this.collectMetrics();
       await this.sendToSigNoz(metrics);
     }
   }
   ```

3. **Rollback Mechanism**
   ```typescript
   // lib/rollback/RollbackManager.ts
   export class RollbackManager {
     async rollbackToJson(): Promise<void> {
       // Switch back to JSON queue
       // Migrate SQLite tasks back to JSON
       // Update feature flags
     }
   }
   ```

**Acceptance Criteria:**
- [ ] Production configuration deployed
- [ ] Monitoring dashboard operational
- [ ] Rollback mechanism tested and ready
- [ ] Performance metrics within targets
- [ ] Zero-downtime deployment achieved

**Cursor Prompt:**
```
Deploy production configuration for SQLite queue with enhanced isolation. Implement comprehensive monitoring integration with SigNoz, add rollback mechanism for emergency situations, and ensure zero-downtime deployment. Include performance metrics and alerting for queue health.
```

---

## TASKS.md Entries

### Epic: Safe Queue + Isolation Refactor
**Priority**: High (P1)
**Status**: Ready for Implementation
**Agent**: Cursor Agent

#### Tickets:

**TASK-QUEUE-001: SQLite Queue Foundation**
- [ ] Implement SQLite-backed queue system with atomic operations
- [ ] Add feature flags for gradual rollout
- [ ] Create QueueManager class with comprehensive API
- [ ] Add unit tests and performance benchmarks
- [ ] Maintain backward compatibility with JSON queue
- [ ] **Acceptance**: SQLite queue operational, < 10ms per operation, feature flags working

**TASK-QUEUE-002: Runner Shadow Mode**
- [ ] Create shadow runner processing both SQLite and JSON queues
- [ ] Implement migration script for existing tasks
- [ ] Add monitoring dashboard for queue comparison
- [ ] Ensure rollback capability to JSON-only mode
- [ ] **Acceptance**: Shadow mode operational, migration complete, monitoring active

**TASK-QUEUE-003: Service Worker Offline Isolation**
- [ ] Enhance service worker for offline queue operations
- [ ] Implement offline queue manager with sync capabilities
- [ ] Add comprehensive offline testing coverage
- [ ] Ensure COOP/COEP header preservation offline
- [ ] **Acceptance**: Offline operations working, isolation maintained, tests passing

**TASK-QUEUE-004: Production Flip + Monitoring**
- [ ] Deploy production configuration for SQLite queue
- [ ] Implement monitoring integration with SigNoz
- [ ] Add rollback mechanism for emergency situations
- [ ] Ensure zero-downtime deployment
- [ ] **Acceptance**: Production deployed, monitoring active, rollback tested

---

## Cursor Prompts

### PR-A Prompt:
```
Implement SQLite-backed queue system with feature flags. Create QueueManager class with atomic enqueue/dequeue operations, add feature flag configuration, and maintain backward compatibility with existing JSON queue. Include comprehensive unit tests and performance benchmarks. Focus on atomic operations and error handling.
```

### PR-B Prompt:
```
Create shadow runner system that processes tasks in both SQLite and JSON queues simultaneously. Implement migration script for existing tasks, add monitoring dashboard to compare both systems, and ensure rollback capability. Include comprehensive validation and performance monitoring. Focus on data consistency and migration safety.
```

### PR-C Prompt:
```
Enhance service worker for offline queue operations while preserving cross-origin isolation headers. Implement offline queue manager with sync capabilities, add comprehensive offline testing, and ensure graceful degradation when isolation is unavailable. Maintain COOP/COEP headers in all offline scenarios. Focus on offline-first architecture.
```

### PR-D Prompt:
```
Deploy production configuration for SQLite queue with enhanced isolation. Implement comprehensive monitoring integration with SigNoz, add rollback mechanism for emergency situations, and ensure zero-downtime deployment. Include performance metrics and alerting for queue health. Focus on production readiness and observability.
```

---

## Guardrail Checklist

### Security & Privacy
- [ ] **Local-First**: All queue operations remain local, no external network calls
- [ ] **Safety**: No hardcoded secrets, proper error handling, input validation
- [ ] **Idempotence**: All operations can be safely retried
- [ ] **Verification**: Comprehensive testing and monitoring

### Performance & Reliability
- [ ] **Atomic Operations**: All queue operations are atomic and consistent
- [ ] **Error Handling**: Graceful degradation and proper error recovery
- [ ] **Performance Budgets**: < 10ms per operation, < 100ms for migrations
- [ ] **Monitoring**: Real-time metrics and alerting

### Accessibility & Standards
- [ ] **WCAG AA**: All UI components meet accessibility standards
- [ ] **Cross-Origin Isolation**: COOP/COEP headers preserved in all scenarios
- [ ] **Service Worker**: Proper offline functionality with header preservation
- [ ] **Testing**: Comprehensive test coverage for all scenarios

### Deployment & Operations
- [ ] **Zero Downtime**: Deployment without service interruption
- [ ] **Rollback Ready**: Emergency rollback mechanism tested and ready
- [ ] **Monitoring**: SigNoz integration for observability
- [ ] **Documentation**: Complete documentation and runbooks

---

## Quick Start Actions

### Immediate Next Steps:
1. **Paste Epic/Tickets**: Copy the TASKS.md entries into your TASKS.md file
2. **Start PR-A**: Use the provided Cursor prompt to begin SQLite queue implementation
3. **Set Up Monitoring**: Ensure SigNoz is running and accessible
4. **Create Feature Branch**: `git checkout -b feature/sqlite-queue-foundation`

### Verification Commands:
```bash
# Check SigNoz health
curl -s http://localhost:8080/api/v1/health

# Verify queue system
pnpm test queue

# Check cross-origin isolation
pnpm playwright test offline-isolation.spec.ts

# Monitor performance
pnpm run benchmark:queue
```

### Success Criteria:
- [ ] All four PRs merged successfully
- [ ] SQLite queue operational in production
- [ ] Enhanced offline isolation working
- [ ] Monitoring dashboard showing healthy metrics
- [ ] Rollback mechanism tested and ready
- [ ] Zero performance regression
- [ ] Cross-origin isolation maintained offline

---

## Risk Mitigation

### Technical Risks:
- **SQLite Performance**: Mitigated by comprehensive benchmarking and atomic operations
- **Migration Data Loss**: Mitigated by shadow mode and rollback capability
- **Offline Isolation**: Mitigated by comprehensive testing and header preservation
- **Production Issues**: Mitigated by monitoring and rollback mechanism

### Operational Risks:
- **Deployment Complexity**: Mitigated by staged rollout and feature flags
- **Monitoring Gaps**: Mitigated by SigNoz integration and comprehensive metrics
- **Team Coordination**: Mitigated by clear documentation and Cursor prompts

---

## Conclusion

This rollout plan provides a comprehensive, staged approach to implementing a safe queue system with enhanced isolation capabilities. Each PR is designed for Cursor IDE implementation with clear acceptance criteria, guardrails, and verification steps. The plan ensures zero-downtime deployment while maintaining system reliability and performance.

**Next Action**: Copy the TASKS.md entries and begin PR-A implementation using the provided Cursor prompt.
