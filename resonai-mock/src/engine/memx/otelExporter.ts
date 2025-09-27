/**
 * MEMX OTLP Exporter
 * 
 * PR-4: SigNoz streaming - optional OTLP/HTTP export with metrics + logs
 * Minimized volume, off by default
 */

import { MemxMetric, MemxLogEvent, MemxConfig } from './types';
import { getMemxStore } from './store';

export class MemxOtelExporter {
  private config: MemxConfig;
  private exportTimer: NodeJS.Timeout | null = null;
  private isExporting = false;

  constructor(config: Partial<MemxConfig> = {}) {
    this.config = {
      enabled: false,
      streamDefault: false,
      exportIntervalMs: 5000,
      ...config,
    };
  }

  /**
   * Start OTLP export if configured and enabled
   */
  start(): void {
    if (!this.config.enabled || !this.config.otlpEndpoint || this.exportTimer) {
      return;
    }

    // Export immediately, then on interval
    this.exportMetrics();
    this.exportTimer = setInterval(() => {
      this.exportMetrics();
    }, this.config.exportIntervalMs);
  }

  /**
   * Stop OTLP export
   */
  stop(): void {
    if (this.exportTimer) {
      clearInterval(this.exportTimer);
      this.exportTimer = null;
    }
  }

  /**
   * Update configuration
   */
  updateConfig(config: Partial<MemxConfig>): void {
    const wasRunning = this.exportTimer !== null;
    
    if (wasRunning) {
      this.stop();
    }

    this.config = { ...this.config, ...config };

    if (wasRunning && this.config.enabled && this.config.otlpEndpoint) {
      this.start();
    }
  }

  /**
   * Export metrics to OTLP endpoint
   */
  private async exportMetrics(): Promise<void> {
    if (this.isExporting || !this.config.otlpEndpoint) {
      return;
    }

    this.isExporting = true;

    try {
      const store = getMemxStore();
      const sessionAggregates = store.getSessionAggregates();

      // Prepare metrics
      const metrics = this.prepareMetrics(sessionAggregates);
      
      // Prepare log events for strain threshold crossings
      const strainEvents = store.getStrainEvents();
      const logEvents = this.prepareLogEvents(strainEvents);

      // Export metrics
      if (metrics.length > 0) {
        await this.sendOtlpMetrics(metrics);
      }

      // Export log events
      if (logEvents.length > 0) {
        await this.sendOtlpLogs(logEvents);
        store.clearStrainEvents(); // Clear after successful export
      }

    } catch (error) {
      console.error('MEMX: OTLP export failed:', error);
    } finally {
      this.isExporting = false;
    }
  }

  /**
   * Prepare metrics for OTLP export
   */
  private prepareMetrics(sessionAggregates: any): MemxMetric[] {
    const metrics: MemxMetric[] = [];
    const timestamp = Date.now();

    // WASM heap bytes
    if (sessionAggregates.peakWasmHeapBytes !== undefined) {
      metrics.push({
        name: 'memx.wasm_heap.bytes',
        value: sessionAggregates.peakWasmHeapBytes,
        timestamp,
        labels: { type: 'peak' },
      });
    }

    // SAB usage
    if (sessionAggregates.peakSabUsagePct !== undefined) {
      metrics.push({
        name: 'memx.sab.usage.pct',
        value: sessionAggregates.peakSabUsagePct,
        timestamp,
        labels: { type: 'peak' },
      });
    }

    // Worklet lag
    if (sessionAggregates.avgWorkletLagMs !== undefined) {
      metrics.push({
        name: 'memx.worklet.lag.avg.ms',
        value: sessionAggregates.avgWorkletLagMs,
        timestamp,
      });
    }

    if (sessionAggregates.p95WorkletLagMs !== undefined) {
      metrics.push({
        name: 'memx.worklet.lag.p95.ms',
        value: sessionAggregates.p95WorkletLagMs,
        timestamp,
      });
    }

    // Memory strain
    if (sessionAggregates.memoryStrainPct !== undefined) {
      metrics.push({
        name: 'memx.strain.pct',
        value: sessionAggregates.memoryStrainPct,
        timestamp,
      });
    }

    return metrics;
  }

  /**
   * Prepare log events for OTLP export
   */
  private prepareLogEvents(strainEvents: Array<{ type: string; value: number; timestamp: number }>): MemxLogEvent[] {
    return strainEvents.map(event => ({
      type: event.type as 'SAB_BACKLOG' | 'WASM_GROW' | 'SYS_MEM' | 'GPU',
      value: event.value,
      threshold: this.getThresholdForType(event.type),
      timestamp: event.timestamp,
      message: `${event.type} threshold exceeded: ${event.value}`,
    }));
  }

  /**
   * Get threshold value for strain event type
   */
  private getThresholdForType(type: string): number {
    switch (type) {
      case 'SAB_BACKLOG': return 80;
      case 'WASM_GROW': return 10 * 1024 * 1024; // 10MB
      case 'WORKLET_LAG': return 50; // 50ms
      case 'GPU_STRAIN': return 90;
      default: return 0;
    }
  }

  /**
   * Send metrics to OTLP endpoint
   */
  private async sendOtlpMetrics(metrics: MemxMetric[]): Promise<void> {
    const otlpPayload = {
      resourceLogs: [{
        resource: {
          attributes: [{
            key: 'service.name',
            value: { stringValue: 'resonai-local' }
          }, {
            key: 'dataset',
            value: { stringValue: 'resonai_analytics' }
          }]
        },
        scopeLogs: [{
          scope: {
            name: 'memx-metrics'
          },
          logRecords: metrics.map(metric => ({
            timeUnixNano: metric.timestamp * 1000000,
            severityText: 'INFO',
            body: {
              stringValue: JSON.stringify({
                metric: metric.name,
                value: metric.value,
                labels: metric.labels || {}
              })
            },
            attributes: [{
              key: 'metric.name',
              value: { stringValue: metric.name }
            }, {
              key: 'metric.value',
              value: { doubleValue: metric.value }
            }, ...Object.entries(metric.labels || {}).map(([key, value]) => ({
              key: `metric.label.${key}`,
              value: { stringValue: value }
            }))]
          }))
        }]
      }]
    };

    await this.sendOtlpRequest('/v1/logs', otlpPayload);
  }

  /**
   * Send log events to OTLP endpoint
   */
  private async sendOtlpLogs(logEvents: MemxLogEvent[]): Promise<void> {
    const otlpPayload = {
      resourceLogs: [{
        resource: {
          attributes: [{
            key: 'service.name',
            value: { stringValue: 'resonai-local' }
          }, {
            key: 'dataset',
            value: { stringValue: 'resonai_analytics' }
          }]
        },
        scopeLogs: [{
          scope: {
            name: 'memx-events'
          },
          logRecords: logEvents.map(event => ({
            timeUnixNano: event.timestamp * 1000000,
            severityText: 'WARN',
            body: {
              stringValue: event.message
            },
            attributes: [{
              key: 'event.type',
              value: { stringValue: event.type }
            }, {
              key: 'event.value',
              value: { doubleValue: event.value }
            }, {
              key: 'event.threshold',
              value: { doubleValue: event.threshold }
            }]
          }))
        }]
      }]
    };

    await this.sendOtlpRequest('/v1/logs', otlpPayload);
  }

  /**
   * Send OTLP request with retry/backoff
   */
  private async sendOtlpRequest(endpoint: string, payload: any): Promise<void> {
    const url = `${this.config.otlpEndpoint}${endpoint}`;
    
    // Retry with exponential backoff
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        });

        if (response.ok) {
          return; // Success
        }

        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      } catch (error) {
        if (attempt === 2) {
          throw error; // Final attempt failed
        }

        // Exponential backoff: 250ms, 750ms
        const delay = 250 * Math.pow(3, attempt);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  /**
   * Get current configuration
   */
  getConfig(): MemxConfig {
    return { ...this.config };
  }

  /**
   * Check if export is active
   */
  isActive(): boolean {
    return this.exportTimer !== null;
  }
}

// Singleton instance
let memxOtelExporter: MemxOtelExporter | null = null;

export function getMemxOtelExporter(): MemxOtelExporter {
  if (!memxOtelExporter) {
    memxOtelExporter = new MemxOtelExporter();
  }
  return memxOtelExporter;
}
