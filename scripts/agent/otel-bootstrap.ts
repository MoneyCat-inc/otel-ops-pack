// OTel Bootstrap - Complete OpenTelemetry Setup
// ECRR Compliance: Examine → Clean → Report → Role

import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-otlp-http';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { createStableResource, logResourceInfo } from './otel-resource-hygiene';

/**
 * OTel configuration interface
 */
export interface OTelConfig {
  serviceName: string;
  serviceVersion: string;
  environment: string;
  otlpEndpoint: string;
  enableAutoInstrumentation: boolean;
  enableMetrics: boolean;
  enableTraces: boolean;
  metricExportInterval: number;
  traceExportTimeout: number;
}

/**
 * Default OTel configuration
 */
export const DEFAULT_OTEL_CONFIG: OTelConfig = {
  serviceName: 'resonai-agent',
  serviceVersion: process.env.GIT_COMMIT_SHA || 'dev',
  environment: process.env.NODE_ENV || 'dev',
  otlpEndpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318',
  enableAutoInstrumentation: true,
  enableMetrics: true,
  enableTraces: true,
  metricExportInterval: 30000, // 30 seconds
  traceExportTimeout: 30000,   // 30 seconds
};

/**
 * Initialize OpenTelemetry SDK
 */
export async function initializeOTel(config: Partial<OTelConfig> = {}): Promise<NodeSDK> {
  const finalConfig = { ...DEFAULT_OTEL_CONFIG, ...config };
  
  console.log('Initializing OpenTelemetry...', {
    serviceName: finalConfig.serviceName,
    serviceVersion: finalConfig.serviceVersion,
    environment: finalConfig.environment,
    otlpEndpoint: finalConfig.otlpEndpoint,
  });

  // Create stable resource
  const resource = await createStableResource();
  logResourceInfo(resource, { info: console.log });

  // Create exporters
  const traceExporter = new OTLPTraceExporter({
    url: `${finalConfig.otlpEndpoint}/v1/traces`,
    timeoutMillis: finalConfig.traceExportTimeout,
  });

  const metricExporter = new OTLPMetricExporter({
    url: `${finalConfig.otlpEndpoint}/v1/metrics`,
    timeoutMillis: finalConfig.traceExportTimeout,
  });

  // Create metric reader
  const metricReader = new PeriodicExportingMetricReader({
    exporter: metricExporter,
    exportIntervalMillis: finalConfig.metricExportInterval,
  });

  // Create SDK
  const sdk = new NodeSDK({
    resource,
    traceExporter: finalConfig.enableTraces ? traceExporter : undefined,
    metricReader: finalConfig.enableMetrics ? metricReader : undefined,
    instrumentations: finalConfig.enableAutoInstrumentation ? [
      getNodeAutoInstrumentations({
        // Disable some instrumentations that might be noisy
        '@opentelemetry/instrumentation-fs': {
          enabled: false,
        },
        '@opentelemetry/instrumentation-net': {
          enabled: false,
        },
        '@opentelemetry/instrumentation-dns': {
          enabled: false,
        },
      }),
    ] : [],
  });

  // Initialize SDK
  await sdk.start();
  
  console.log('OpenTelemetry initialized successfully');
  
  return sdk;
}

/**
 * Shutdown OpenTelemetry SDK
 */
export async function shutdownOTel(sdk: NodeSDK): Promise<void> {
  console.log('Shutting down OpenTelemetry...');
  
  try {
    await sdk.shutdown();
    console.log('OpenTelemetry shutdown complete');
  } catch (error) {
    console.error('Error during OpenTelemetry shutdown:', error);
  }
}

/**
 * Check if OTel is enabled
 */
export function isOTelEnabled(): boolean {
  return process.env.OTEL_ENABLED === '1' || process.env.OTEL_ENABLED === 'true';
}

/**
 * Get OTel configuration from environment
 */
export function getOTelConfigFromEnv(): Partial<OTelConfig> {
  return {
    serviceName: process.env.OTEL_SERVICE_NAME,
    serviceVersion: process.env.OTEL_SERVICE_VERSION || process.env.GIT_COMMIT_SHA,
    environment: process.env.OTEL_ENVIRONMENT || process.env.NODE_ENV,
    otlpEndpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
    enableAutoInstrumentation: process.env.OTEL_AUTO_INSTRUMENTATION !== 'false',
    enableMetrics: process.env.OTEL_METRICS_ENABLED !== 'false',
    enableTraces: process.env.OTEL_TRACES_ENABLED !== 'false',
    metricExportInterval: parseInt(process.env.OTEL_METRIC_EXPORT_INTERVAL || '30000'),
    traceExportTimeout: parseInt(process.env.OTEL_TRACE_EXPORT_TIMEOUT || '30000'),
  };
}

/**
 * Example usage
 */
export async function exampleUsage(): Promise<void> {
  if (!isOTelEnabled()) {
    console.log('OpenTelemetry is disabled');
    return;
  }

  try {
    // Get configuration from environment
    const config = getOTelConfigFromEnv();
    
    // Initialize OTel
    const sdk = await initializeOTel(config);
    
    // Your application code here
    console.log('Application running with OpenTelemetry...');
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
      await shutdownOTel(sdk);
      process.exit(0);
    });
    
    process.on('SIGTERM', async () => {
      await shutdownOTel(sdk);
      process.exit(0);
    });
    
  } catch (error) {
    console.error('Failed to initialize OpenTelemetry:', error);
    process.exit(1);
  }
}

/**
 * Utility function to check OTel health
 */
export async function checkOTelHealth(): Promise<{
  isHealthy: boolean;
  details: Record<string, any>;
}> {
  const details: Record<string, any> = {
    enabled: isOTelEnabled(),
    config: getOTelConfigFromEnv(),
  };

  if (!isOTelEnabled()) {
    return { isHealthy: false, details };
  }

  try {
    // Check if OTLP endpoint is reachable
    const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';
    const response = await fetch(`${endpoint}/v1/traces`, { method: 'HEAD' });
    details.endpointReachable = response.ok;
  } catch (error) {
    details.endpointReachable = false;
    details.endpointError = error.message;
  }

  const isHealthy = details.enabled && details.endpointReachable;
  
  return { isHealthy, details };
}

// Export types
export type { OTelConfig };
