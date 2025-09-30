/**
 * Queue Configuration Flags
 * 
 * These flags control the behavior of the background job queue system.
 * They can be set via environment variables or configuration files.
 */

export interface QueueConfig {
  /** Driver to use: 'json' (default) or 'sqlite' */
  driver: 'json' | 'sqlite';
  
  /** Enable WAL mode for SQLite (default: false) */
  wal: boolean;
  
  /** Enable shadow mode - write to shadow artifacts instead of canonical (default: true) */
  shadow: boolean;
  
  /** Enable queue processing (default: true) */
  enabled: boolean;
  
  /** Maximum number of jobs to process per pass (default: 10) */
  maxJobs: number;
  
  /** Maximum number of concurrent jobs (default: 2 in prod, 3 in dev) */
  maxConcurrency: number;
  
  /** Maximum number of retry attempts (default: 3) */
  maxAttempts: number;
  
  /** Base delay for exponential backoff in milliseconds (default: 1000) */
  baseDelayMs: number;
  
  /** Jitter factor for backoff (default: 0.15 = ±15%) */
  jitterFactor: number;
}

/**
 * Get queue configuration from environment variables
 */
export function getQueueConfig(): QueueConfig {
  const isDev = process.env.NODE_ENV === 'development';
  
  return {
    driver: (process.env.QUEUE_DRIVER as 'json' | 'sqlite') || 'json',
    wal: process.env.QUEUE_WAL === '1' || process.env.QUEUE_WAL === 'true',
    shadow: process.env.QUEUE_SHADOW === '1' || process.env.QUEUE_SHADOW === 'true' || true, // Default to true for safety
    enabled: process.env.QUEUE_ENABLED !== '0' && process.env.QUEUE_ENABLED !== 'false',
    maxJobs: parseInt(process.env.QUEUE_MAX_JOBS || '10', 10),
    maxConcurrency: parseInt(process.env.QUEUE_MAX_CONCURRENCY || (isDev ? '3' : '2'), 10),
    maxAttempts: parseInt(process.env.QUEUE_MAX_ATTEMPTS || '3', 10),
    baseDelayMs: parseInt(process.env.QUEUE_BASE_DELAY_MS || '1000', 10),
    jitterFactor: parseFloat(process.env.QUEUE_JITTER_FACTOR || '0.15'),
  };
}

/**
 * Validate queue configuration
 */
export function validateQueueConfig(config: QueueConfig): string[] {
  const errors: string[] = [];
  
  if (!['json', 'sqlite'].includes(config.driver)) {
    errors.push(`Invalid driver: ${config.driver}. Must be 'json' or 'sqlite'`);
  }
  
  if (config.maxJobs <= 0) {
    errors.push(`maxJobs must be positive, got ${config.maxJobs}`);
  }
  
  if (config.maxConcurrency <= 0) {
    errors.push(`maxConcurrency must be positive, got ${config.maxConcurrency}`);
  }
  
  if (config.maxAttempts < 0) {
    errors.push(`maxAttempts must be non-negative, got ${config.maxAttempts}`);
  }
  
  if (config.baseDelayMs <= 0) {
    errors.push(`baseDelayMs must be positive, got ${config.baseDelayMs}`);
  }
  
  if (config.jitterFactor < 0 || config.jitterFactor > 1) {
    errors.push(`jitterFactor must be between 0 and 1, got ${config.jitterFactor}`);
  }
  
  return errors;
}

/**
 * Get a human-readable description of the current queue configuration
 */
export function describeQueueConfig(config: QueueConfig): string {
  const parts = [
    `Driver: ${config.driver}`,
    `WAL: ${config.wal ? 'enabled' : 'disabled'}`,
    `Shadow: ${config.shadow ? 'enabled' : 'disabled'}`,
    `Enabled: ${config.enabled ? 'yes' : 'no'}`,
    `Max Jobs: ${config.maxJobs}`,
    `Max Concurrency: ${config.maxConcurrency}`,
    `Max Attempts: ${config.maxAttempts}`,
    `Base Delay: ${config.baseDelayMs}ms`,
    `Jitter: ±${(config.jitterFactor * 100).toFixed(1)}%`,
  ];
  
  return parts.join(', ');
}
