// Auto-Throttle for Queue Backlog Management
// ECRR Compliance: Examine → Clean → Report → Role

export interface ThrottleConfig {
  maxJobs: number;
  baseSleepMs: number;
  maxSleepMs: number;
  throttleThreshold: number;
  criticalThreshold: number;
}

export interface ThrottleResult {
  maxJobs: number;
  sleepMs: number;
  throttleLevel: 'normal' | 'throttled' | 'critical';
  reason: string;
}

/**
 * Compute throttle settings based on queue depth
 * @param queueDepth Current queue depth
 * @param cfg Throttle configuration
 * @returns Throttle settings for this pass
 */
export function computeThrottle(queueDepth: number, cfg: ThrottleConfig): ThrottleResult {
  // Simple policy: if depth >=3, halve maxJobs (min 1); if >=6, set to 1.
  const decimated =
    queueDepth >= cfg.criticalThreshold ? 1 :
    queueDepth >= cfg.throttleThreshold ? Math.max(1, Math.floor(cfg.maxJobs / 2)) :
    cfg.maxJobs;

  const sleepMs =
    queueDepth >= cfg.criticalThreshold ? cfg.maxSleepMs :
    queueDepth >= cfg.throttleThreshold ? Math.min(cfg.maxSleepMs, cfg.baseSleepMs * 2.5) :
    cfg.baseSleepMs;

  const throttleLevel =
    queueDepth >= cfg.criticalThreshold ? 'critical' :
    queueDepth >= cfg.throttleThreshold ? 'throttled' :
    'normal';

  const reason =
    queueDepth >= cfg.criticalThreshold ? `Queue depth ${queueDepth} >= ${cfg.criticalThreshold} (critical)` :
    queueDepth >= cfg.throttleThreshold ? `Queue depth ${queueDepth} >= ${cfg.throttleThreshold} (throttled)` :
    `Queue depth ${queueDepth} normal`;

  return { 
    maxJobs: decimated, 
    sleepMs, 
    throttleLevel, 
    reason 
  };
}

/**
 * Default throttle configuration
 */
export const DEFAULT_THROTTLE_CONFIG: ThrottleConfig = {
  maxJobs: 10,
  baseSleepMs: 3000,
  maxSleepMs: 15000,
  throttleThreshold: 3,
  criticalThreshold: 6
};

/**
 * Create throttle configuration from environment or defaults
 */
export function createThrottleConfig(): ThrottleConfig {
  return {
    maxJobs: parseInt(process.env.AGENT_MAX_JOBS || '10'),
    baseSleepMs: parseInt(process.env.AGENT_BASE_SLEEP_MS || '3000'),
    maxSleepMs: parseInt(process.env.AGENT_MAX_SLEEP_MS || '15000'),
    throttleThreshold: parseInt(process.env.AGENT_THROTTLE_THRESHOLD || '3'),
    criticalThreshold: parseInt(process.env.AGENT_CRITICAL_THRESHOLD || '6')
  };
}

/**
 * Log throttle decision for observability
 */
export function logThrottleDecision(
  queueDepth: number, 
  result: ThrottleResult, 
  logger: { info: (msg: string, meta?: any) => void }
): void {
  logger.info('Auto-throttle decision', {
    queueDepth,
    maxJobs: result.maxJobs,
    sleepMs: result.sleepMs,
    throttleLevel: result.throttleLevel,
    reason: result.reason
  });
}

/**
 * Emit throttle metrics for monitoring
 */
export function emitThrottleMetrics(
  queueDepth: number,
  result: ThrottleResult,
  metrics: {
    gauge: (name: string, value: number, labels?: Record<string, string>) => void;
    counter: (name: string, value: number, labels?: Record<string, string>) => void;
  }
): void {
  metrics.gauge('agent_queue_depth', queueDepth);
  metrics.gauge('agent_throttle_max_jobs', result.maxJobs, { level: result.throttleLevel });
  metrics.gauge('agent_throttle_sleep_ms', result.sleepMs, { level: result.throttleLevel });
  
  if (result.throttleLevel !== 'normal') {
    metrics.counter('agent_throttle_activations_total', 1, { level: result.throttleLevel });
  }
}

/**
 * Example usage in watchdog loop
 */
export async function exampleUsage(): Promise<void> {
  const cfg = createThrottleConfig();
  
  // In your watchdog loop:
  const queueDepth = 5; // Read from actual queue
  const { maxJobs, sleepMs, throttleLevel, reason } = computeThrottle(queueDepth, cfg);
  
  console.log(`Throttle decision: ${reason}`);
  console.log(`Max jobs: ${maxJobs}, Sleep: ${sleepMs}ms, Level: ${throttleLevel}`);
  
  // Use maxJobs for this pass
  // await processJobs(maxJobs);
  
  // Sleep between passes
  // await sleep(sleepMs);
}

// Utility function for sleep
export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
