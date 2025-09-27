#!/usr/bin/env node
/**
 * OpenTelemetry Bootstrap for Agent Worker
 * Initializes tracing and metrics for the Resonai agent system
 * Part of the observability infrastructure
 */

import { NodeSDK } from '@opentelemetry/auto-instrumentations-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { OTLPMetricExporter } from '@opentelemetry/exporter-otlp-http';
import { OTLPTraceExporter } from '@opentelemetry/exporter-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { trace, metrics, context } from '@opentelemetry/api';
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { MeterProvider } from '@opentelemetry/sdk-metrics';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import * as fs from 'fs/promises';
import * as path from 'path';

// Environment configuration
const OTEL_ENABLED = process.env.OTEL_ENABLED !== '0';
const OTEL_ENDPOINT = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';
const OTEL_SERVICE_NAME = process.env.OTEL_SERVICE_NAME || 'resonai-agent';
const OTEL_ENVIRONMENT = process.env.NODE_ENV || 'development';

// Global instances
let tracer: any;
let meter: any;
let isInitialized = false;

/**
 * Get commit SHA if available
 */
async function getCommitSha(): Promise<string | undefined> {
  try {
    const gitPath = '.git/HEAD';
    const head = await fs.readFile(gitPath, 'utf-8');
    if (head.startsWith('ref: ')) {
      const refPath = head.substring(5).trim();
      const ref = await fs.readFile(`.git/${refPath}`, 'utf-8');
      return ref.trim().substring(0, 7);
    }
    return head.trim().substring(0, 7);
  } catch {
    return undefined;
  }
}

/**
 * Initialize OpenTelemetry SDK
 */
export async function initializeOTel(): Promise<void> {
  if (!OTEL_ENABLED || isInitialized) {
    return;
  }

  try {
    console.log('🔧 Initializing OpenTelemetry for agent worker...');
    
    // Get commit SHA
    const commitSha = await getCommitSha();
    
    // Create resource
    const resource = new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: OTEL_SERVICE_NAME,
      [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: OTEL_ENVIRONMENT,
      ...(commitSha && { 'git.commit.sha': commitSha }),
      'agent.version': '1.0.0',
      'agent.type': 'watchdog'
    });

    // Initialize tracing
    const traceExporter = new OTLPTraceExporter({
      url: `${OTEL_ENDPOINT}/v1/traces`
    });

    const tracerProvider = new NodeTracerProvider({
      resource,
      instrumentations: getNodeAutoInstrumentations({
        '@opentelemetry/instrumentation-fs': { enabled: false },
        '@opentelemetry/instrumentation-net': { enabled: false }
      })
    });

    tracerProvider.addSpanProcessor(new BatchSpanProcessor(traceExporter));
    tracerProvider.register();

    // Initialize metrics
    const metricExporter = new OTLPMetricExporter({
      url: `${OTEL_ENDPOINT}/v1/metrics`
    });

    const metricReader = new PeriodicExportingMetricReader({
      exporter: metricExporter,
      exportIntervalMillis: 10000 // Export every 10 seconds
    });

    const meterProvider = new MeterProvider({
      resource,
      readers: [metricReader]
    });

    // Get global instances
    tracer = trace.getTracer('resonai.agent', '1.0.0');
    meter = metrics.getMeter('resonai.agent', '1.0.0');

    // Create agent-specific metrics
    createAgentMetrics();

    isInitialized = true;
    console.log('✅ OpenTelemetry initialized successfully');
    
  } catch (error) {
    console.error('❌ Failed to initialize OpenTelemetry:', error);
    // Don't throw - agent should continue working without telemetry
  }
}

/**
 * Create agent-specific metrics
 */
function createAgentMetrics(): void {
  if (!meter) return;

  // Job processing metrics
  const jobsProcessedCounter = meter.createCounter('jobs_processed_total', {
    description: 'Total number of jobs processed',
    unit: '1'
  });

  const jobsFailedCounter = meter.createCounter('jobs_failed_total', {
    description: 'Total number of jobs that failed',
    unit: '1'
  });

  const jobRetriesCounter = meter.createCounter('job_retries_total', {
    description: 'Total number of job retries',
    unit: '1'
  });

  const jobDurationHistogram = meter.createHistogram('job_duration_ms', {
    description: 'Duration of job execution in milliseconds',
    unit: 'ms'
  });

  // Queue metrics
  const queueDepthGauge = meter.createObservableGauge('queue_depth', {
    description: 'Current depth of the job queue',
    unit: '1'
  });

  // Flake detection metrics
  const flakeDetectedCounter = meter.createCounter('flake_detected_total', {
    description: 'Total number of flaky tests detected',
    unit: '1'
  });

  const flakeQuarantinedCounter = meter.createCounter('flake_quarantined_total', {
    description: 'Total number of flaky tests quarantined',
    unit: '1'
  });

  const flakeReoffendedCounter = meter.createCounter('flake_reoffended_total', {
    description: 'Total number of quarantined tests that failed again',
    unit: '1'
  });

  const flakeRehabilitatedCounter = meter.createCounter('flake_rehabilitated_total', {
    description: 'Total number of tests rehabilitated from quarantine',
    unit: '1'
  });

  // Flake status gauges
  const flakyTestsCountGauge = meter.createObservableGauge('ci.flaky_tests.count', {
    description: 'Total number of active flaky tests',
    unit: '1'
  });

  const testFlakeStatusGauge = meter.createObservableGauge('test.flake_status', {
    description: 'Flake status of individual tests (0=healthy, 1=flaky)',
    unit: '1'
  });

  const testFlakeAgeGauge = meter.createObservableGauge('test.flake_age_days', {
    description: 'Age of flaky tests in days',
    unit: '1'
  });

  // Store metrics for global access
  (global as any).__otelMetrics = {
    jobsProcessedCounter,
    jobsFailedCounter,
    jobRetriesCounter,
    jobDurationHistogram,
    queueDepthGauge,
    flakeDetectedCounter,
    flakeQuarantinedCounter,
    flakeReoffendedCounter,
    flakeRehabilitatedCounter,
    flakyTestsCountGauge,
    testFlakeStatusGauge,
    testFlakeAgeGauge
  };
}

/**
 * Get the tracer instance
 */
export function getTracer(): any {
  return tracer;
}

/**
 * Get the meter instance
 */
export function getMeter(): any {
  return meter;
}

/**
 * Get agent metrics
 */
export function getAgentMetrics(): any {
  return (global as any).__otelMetrics;
}

/**
 * Create a span for agent queue tick
 */
export function createQueueTickSpan(queueDepth: number, maxJobs: number, lockPresent: boolean, config: any): any {
  if (!tracer) return null;

  return tracer.startSpan('agent.queue.tick', {
    attributes: {
      'queue.depth': queueDepth,
      'agent.max_jobs': maxJobs,
      'agent.lock_present': lockPresent,
      'agent.config.max_files': config.maxFiles || 0,
      'agent.config.max_lines': config.maxLines || 0,
      'agent.config.max_jobs': config.maxJobs || 0
    }
  });
}

/**
 * Create a span for job execution
 */
export function createJobRunSpan(jobId: string, jobType: string, attempt: number, ttlMs: number): any {
  if (!tracer) return null;

  return tracer.startSpan('agent.job.run', {
    attributes: {
      'job.id': jobId,
      'job.type': jobType,
      'job.attempt': attempt,
      'job.ttl_ms': ttlMs
    }
  });
}

/**
 * Record job metrics
 */
export function recordJobMetrics(jobType: string, duration: number, success: boolean, retry: boolean = false): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  if (success) {
    metrics.jobsProcessedCounter.add(1, { job_type: jobType });
  } else {
    metrics.jobsFailedCounter.add(1, { job_type: jobType });
  }

  if (retry) {
    metrics.jobRetriesCounter.add(1, { job_type: jobType });
  }

  metrics.jobDurationHistogram.record(duration, { job_type: jobType });
}

/**
 * Record queue depth
 */
export function recordQueueDepth(depth: number): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  metrics.queueDepthGauge.add(depth);
}

/**
 * Record flake detection
 */
export function recordFlakeDetected(testId: string, suite: string, browser: string, branch: string, reason: string): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  metrics.flakeDetectedCounter.add(1, {
    test_id: testId,
    suite: suite,
    browser: browser,
    branch: branch,
    reason: reason
  });
}

/**
 * Record flake quarantine
 */
export function recordFlakeQuarantined(testId: string, suite: string, browser: string, branch: string): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  metrics.flakeQuarantinedCounter.add(1, {
    test_id: testId,
    suite: suite,
    browser: browser,
    branch: branch
  });
}

/**
 * Record flake reoffense
 */
export function recordFlakeReoffended(testId: string, suite: string, browser: string, branch: string): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  metrics.flakeReoffendedCounter.add(1, {
    test_id: testId,
    suite: suite,
    browser: browser,
    branch: branch
  });
}

/**
 * Record flake rehabilitation
 */
export function recordFlakeRehabilitated(testId: string, suite: string, browser: string, branch: string): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  metrics.flakeRehabilitatedCounter.add(1, {
    test_id: testId,
    suite: suite,
    browser: browser,
    branch: branch
  });
}

/**
 * Record flake status gauges
 */
export function recordFlakeStatusGauges(flakyTests: Array<{
  testId: string;
  suite: string;
  browser: string;
  branch: string;
  ageDays: number;
}>): void {
  const metrics = getAgentMetrics();
  if (!metrics) return;

  // Record total count
  metrics.flakyTestsCountGauge.add(flakyTests.length);

  // Record individual test status
  flakyTests.forEach(test => {
    metrics.testFlakeStatusGauge.add(1, {
      test_id: test.testId,
      suite: test.suite,
      browser: test.browser,
      branch: test.branch
    });

    metrics.testFlakeAgeGauge.add(test.ageDays, {
      test_id: test.testId,
      suite: test.suite,
      browser: test.browser,
      branch: test.branch
    });
  });
}

/**
 * Shutdown OpenTelemetry
 */
export async function shutdownOTel(): Promise<void> {
  if (!isInitialized) return;

  try {
    console.log('🔄 Shutting down OpenTelemetry...');
    // SDK handles cleanup automatically
    isInitialized = false;
    console.log('✅ OpenTelemetry shutdown complete');
  } catch (error) {
    console.error('❌ Error during OpenTelemetry shutdown:', error);
  }
}

// Auto-initialize if this module is imported
if (OTEL_ENABLED) {
  initializeOTel().catch(error => {
    console.error('Failed to auto-initialize OpenTelemetry:', error);
  });
}

export { OTEL_ENABLED, OTEL_ENDPOINT, OTEL_SERVICE_NAME };
