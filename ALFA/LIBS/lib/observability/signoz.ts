// Resonai Backend - SigNoz API Integration
// Enhanced observability integration with SigNoz API key

import { trace, metrics as metricsApi } from '@opentelemetry/api';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { MeterProvider, PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

// SigNoz configuration
const SIGNOZ_API_KEY = process.env['SIGNOZ_API_KEY'] || process.env['OTEL_EXPORTER_OTLP_HEADERS']?.split('=')[1] || '';
const SIGNOZ_ENDPOINT = process.env['OTEL_EXPORTER_OTLP_ENDPOINT'] || 'http://localhost:4317';
const SERVICE_NAME = process.env['OTEL_SERVICE_NAME'] || 'resonai-backend';
const SERVICE_VERSION = process.env['OTEL_SERVICE_VERSION'] || '1.0.0';
const ENVIRONMENT = process.env['OTEL_ENVIRONMENT'] || 'development';

let meterProvider: MeterProvider | undefined;
let instrumentationsRegistered = false;
let initializingPromise: Promise<void> | undefined;

// Initialize SigNoz integration using HTTP exporters only (no gRPC dependency)
export function initializeSigNoz(): Promise<void> {
  if (typeof window !== 'undefined') {
    return Promise.resolve();
  }

  if (meterProvider) {
    return Promise.resolve();
  }

  if (initializingPromise) {
    return initializingPromise;
  }

  initializingPromise = (async () => {
    const resource = resourceFromAttributes({
      [SemanticResourceAttributes.SERVICE_NAME]: SERVICE_NAME,
      [SemanticResourceAttributes.SERVICE_VERSION]: SERVICE_VERSION,
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: ENVIRONMENT,
      [SemanticResourceAttributes.SERVICE_INSTANCE_ID]:
        process.env['VERCEL_REGION'] || 'local',
    });

    meterProvider = new MeterProvider({
      resource,
      readers: [
        new PeriodicExportingMetricReader({
          exporter: new OTLPMetricExporter({
            url: `${SIGNOZ_ENDPOINT}/v1/metrics`,
            headers: {
              Authorization: `Bearer ${SIGNOZ_API_KEY}`,
              'Content-Type': 'application/json',
            },
          }),
          exportIntervalMillis: 10000,
        }),
      ],
    });

    metricsApi.setGlobalMeterProvider(meterProvider);

    if (!instrumentationsRegistered) {
      registerInstrumentations({
        instrumentations: [
          getNodeAutoInstrumentations({
            '@opentelemetry/instrumentation-fs': {
              enabled: false,
            },
            '@opentelemetry/instrumentation-dns': {
              enabled: false,
            },
            '@opentelemetry/instrumentation-http': {
              enabled: true,
              requestHook: (span, request) => {
                span.setAttributes({
                  'http.request.method': request.method,
                  'http.request.url': (request as any).url || '',
                  'http.request.user_agent': (request as any).headers?.['user-agent'] || '',
                });
              },
              responseHook: (span, response) => {
                span.setAttributes({
                  'http.response.status_code': response.statusCode,
                  'http.response.status_text': response.statusMessage || '',
                });
              },
            },
            '@opentelemetry/instrumentation-express': {
              enabled: true,
            },
          }),
        ],
      });
      instrumentationsRegistered = true;
    }
  })()
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Failed to initialize SigNoz metrics exporters', error);
      throw error;
    });

  return initializingPromise;
}

export async function shutdownSigNoz(): Promise<void> {
  if (!meterProvider) return;

  try {
    await meterProvider.shutdown();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to shutdown SigNoz metrics provider', error);
  } finally {
    meterProvider = undefined;
    initializingPromise = undefined;
    if (typeof metricsApi.disable === 'function') {
      metricsApi.disable();
    }
  }
}

// SigNoz API client for custom queries and dashboards
export class SigNozAPIClient {
  private baseUrl: string;
  private apiKey: string;

  constructor() {
    this.baseUrl = process.env['SIGNOZ_API_URL'] || 'http://localhost:8080/api/v1';
    this.apiKey = SIGNOZ_API_KEY;
  }

  // Get service health from SigNoz
  async getServiceHealth(): Promise<{
    status: 'healthy' | 'unhealthy';
    latency?: number;
    error?: string;
  }> {
    try {
      const startTime = Date.now();
      
      const response = await fetch(`${this.baseUrl}/health`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      });

      const latency = Date.now() - startTime;

      if (response.ok) {
        return {
          status: 'healthy',
          latency,
        };
      } else {
        return {
          status: 'unhealthy',
          latency,
          error: `HTTP ${response.status}`,
        };
      }
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  // Query traces from SigNoz
  async queryTraces(query: {
    serviceName?: string;
    operationName?: string;
    startTime?: number;
    endTime?: number;
    limit?: number;
  }): Promise<any[]> {
    try {
      const params = new URLSearchParams();
      
      if (query.serviceName) params.append('serviceName', query.serviceName);
      if (query.operationName) params.append('operationName', query.operationName);
      if (query.startTime) params.append('startTime', query.startTime.toString());
      if (query.endTime) params.append('endTime', query.endTime.toString());
      if (query.limit) params.append('limit', query.limit.toString());

      const response = await fetch(`${this.baseUrl}/traces?${params}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      return (data as any).traces || [];
    } catch (error) {
      console.error('Failed to query traces from SigNoz:', error);
      return [];
    }
  }

  // Query metrics from SigNoz
  async queryMetrics(query: {
    metricName: string;
    startTime?: number;
    endTime?: number;
    step?: number;
  }): Promise<any> {
    try {
      const params = new URLSearchParams();
      
      params.append('metricName', query.metricName);
      if (query.startTime) params.append('startTime', query.startTime.toString());
      if (query.endTime) params.append('endTime', query.endTime.toString());
      if (query.step) params.append('step', query.step.toString());

      const response = await fetch(`${this.baseUrl}/metrics?${params}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Failed to query metrics from SigNoz:', error);
      return null;
    }
  }

  // Query logs from SigNoz
  async queryLogs(query: {
    query: string;
    startTime?: number;
    endTime?: number;
    limit?: number;
  }): Promise<any[]> {
    try {
      const params = new URLSearchParams();
      
      params.append('query', query.query);
      if (query.startTime) params.append('startTime', query.startTime.toString());
      if (query.endTime) params.append('endTime', query.endTime.toString());
      if (query.limit) params.append('limit', query.limit.toString());

      const response = await fetch(`${this.baseUrl}/logs?${params}`, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      return (data as any).logs || [];
    } catch (error) {
      console.error('Failed to query logs from SigNoz:', error);
      return [];
    }
  }

  // Get service metrics summary
  async getServiceMetrics(_serviceName: string = SERVICE_NAME): Promise<{
    requestRate: number;
    errorRate: number;
    avgLatency: number;
    p95Latency: number;
    p99Latency: number;
  }> {
    try {
      const endTime = Date.now();
      const startTime = endTime - (5 * 60 * 1000); // Last 5 minutes

      const [requestRate, errorRate, latency] = await Promise.all([
        this.queryMetrics({
          metricName: 'http_requests_total',
          startTime,
          endTime,
          step: 60,
        }),
        this.queryMetrics({
          metricName: 'http_requests_total',
          startTime,
          endTime,
          step: 60,
        }),
        this.queryMetrics({
          metricName: 'http_request_duration_seconds',
          startTime,
          endTime,
          step: 60,
        }),
      ]);

      return {
        requestRate: requestRate?.data?.result?.[0]?.values?.[0]?.[1] || 0,
        errorRate: errorRate?.data?.result?.[0]?.values?.[0]?.[1] || 0,
        avgLatency: latency?.data?.result?.[0]?.values?.[0]?.[1] || 0,
        p95Latency: latency?.data?.result?.[0]?.values?.[0]?.[1] || 0,
        p99Latency: latency?.data?.result?.[0]?.values?.[0]?.[1] || 0,
      };
    } catch (error) {
      console.error('Failed to get service metrics:', error);
      return {
        requestRate: 0,
        errorRate: 0,
        avgLatency: 0,
        p95Latency: 0,
        p99Latency: 0,
      };
    }
  }
}

// Custom metrics for Resonai-specific observability
export class ResonaiMetrics {
  private static instance: ResonaiMetrics;
  private signozClient: SigNozAPIClient;

  private constructor() {
    this.signozClient = new SigNozAPIClient();
  }

  static getInstance(): ResonaiMetrics {
    if (!ResonaiMetrics.instance) {
      ResonaiMetrics.instance = new ResonaiMetrics();
    }
    return ResonaiMetrics.instance;
  }

  // Track user engagement events
  trackEngagementEvent(event: {
    userId: string;
    eventType: 'session_start' | 'session_end' | 'badge_unlock' | 'streak_tick';
    metadata?: Record<string, any>;
  }): void {
    const span = trace.getActiveSpan();
    
    span?.setAttributes({
      'resonai.engagement.event_type': event.eventType,
      'resonai.engagement.user_id_hash': event.userId,
      'resonai.engagement.timestamp': Date.now(),
    });

    if (event.metadata) {
      Object.entries(event.metadata).forEach(([key, value]) => {
        span?.setAttribute(`resonai.engagement.${key}`, String(value));
      });
    }
  }

  // Track API performance
  trackAPIPerformance(route: string, duration: number, statusCode: number): void {
    const span = trace.getActiveSpan();
    
    span?.setAttributes({
      'resonai.api.route': route,
      'resonai.api.duration_ms': duration,
      'resonai.api.status_code': statusCode,
      'resonai.api.success': statusCode < 400,
    });
  }

  // Track privacy compliance events
  trackPrivacyEvent(event: {
    eventType: 'consent_change' | 'data_export' | 'data_deletion' | 'pii_detected';
    userId?: string;
    details?: Record<string, any>;
  }): void {
    const span = trace.getActiveSpan();
    
    span?.setAttributes({
      'resonai.privacy.event_type': event.eventType,
      'resonai.privacy.user_id_hash': event.userId || 'anonymous',
      'resonai.privacy.timestamp': Date.now(),
    });

    if (event.details) {
      Object.entries(event.details).forEach(([key, value]) => {
        span?.setAttribute(`resonai.privacy.${key}`, String(value));
      });
    }
  }

  // Track coach portal usage
  trackCoachPortalEvent(event: {
    eventType: 'grant_created' | 'grant_accessed' | 'grant_revoked';
    userId: string;
    coachId: string;
    scope: 'metrics' | 'notes';
  }): void {
    const span = trace.getActiveSpan();
    
    span?.setAttributes({
      'resonai.coach.event_type': event.eventType,
      'resonai.coach.user_id_hash': event.userId,
      'resonai.coach.coach_id': event.coachId,
      'resonai.coach.scope': event.scope,
      'resonai.coach.timestamp': Date.now(),
    });
  }

  // Get engagement analytics from SigNoz
  async getEngagementAnalytics(timeRange: '1h' | '24h' | '7d' | '30d'): Promise<{
    totalSessions: number;
    activeUsers: number;
    avgSessionDuration: number;
    topEvents: Array<{ eventType: string; count: number }>;
  }> {
    try {
      const endTime = Date.now();
      const startTime = endTime - this.getTimeRangeMs(timeRange);

      const logs = await this.signozClient.queryLogs({
        query: 'attributes.dataset = "resonai_analytics"',
        startTime,
        endTime,
        limit: 1000,
      });

      const analytics = this.processEngagementLogs(logs);
      
      return analytics;
    } catch (error) {
      console.error('Failed to get engagement analytics:', error);
      return {
        totalSessions: 0,
        activeUsers: 0,
        avgSessionDuration: 0,
        topEvents: [],
      };
    }
  }

  private getTimeRangeMs(timeRange: string): number {
    switch (timeRange) {
      case '1h': return 60 * 60 * 1000;
      case '24h': return 24 * 60 * 60 * 1000;
      case '7d': return 7 * 24 * 60 * 60 * 1000;
      case '30d': return 30 * 24 * 60 * 60 * 1000;
      default: return 24 * 60 * 60 * 1000;
    }
  }

  private processEngagementLogs(logs: any[]): {
    totalSessions: number;
    activeUsers: number;
    avgSessionDuration: number;
    topEvents: Array<{ eventType: string; count: number }>;
  } {
    const sessions = new Set();
    const users = new Set();
    const eventCounts: Record<string, number> = {};
    let totalDuration = 0;
    let sessionCount = 0;

    logs.forEach(log => {
      const attributes = log.attributes || {};
      
      if (attributes.event === 'session_start') {
        sessions.add(attributes.sessionId);
        users.add(attributes.userIdHash);
        sessionCount++;
      }
      
      if (attributes.event === 'session_end' && attributes.duration) {
        totalDuration += parseInt(attributes.duration);
      }
      
      if (attributes.event) {
        eventCounts[attributes.event] = (eventCounts[attributes.event] || 0) + 1;
      }
    });

    const topEvents = Object.entries(eventCounts)
      .map(([eventType, count]) => ({ eventType, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    return {
      totalSessions: sessions.size,
      activeUsers: users.size,
      avgSessionDuration: sessionCount > 0 ? totalDuration / sessionCount : 0,
      topEvents,
    };
  }
}

// Initialize SigNoz on module load
if (process.env.NODE_ENV !== 'test') {
  initializeSigNoz()
    .then(() => {
      console.log('🔍 SigNoz integration initialized');
      console.log(`   Service: ${SERVICE_NAME} v${SERVICE_VERSION}`);
      console.log(`   Environment: ${ENVIRONMENT}`);
      console.log(`   Endpoint: ${SIGNOZ_ENDPOINT}`);
    })
    .catch(error => {
      console.error('Failed to initialize SigNoz integration', error);
    });

  const handleShutdown = async () => {
    await shutdownSigNoz();
  };

  process.once('SIGTERM', handleShutdown);
  process.once('SIGINT', handleShutdown);
  process.once('beforeExit', handleShutdown);
}

// Export instances
export const signozClient = new SigNozAPIClient();
export const resonaiMetrics = ResonaiMetrics.getInstance();
