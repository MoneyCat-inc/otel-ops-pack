/**
 * Lightweight OTEL Logs SDK Bootstrap
 * Safe initialization that falls back gracefully if collector is unavailable
 */

let initialized = false;

export function initLogsSdk() {
  if (initialized) return;
  
  try {
    const { LoggerProvider } = require('@opentelemetry/sdk-logs');
    const { OTLPLogExporter } = require('@opentelemetry/exporter-logs-otlp-http');
    const { SimpleLogRecordProcessor } = require('@opentelemetry/sdk-logs');
    const { logs } = require('@opentelemetry/api-logs');

    const provider = new LoggerProvider();
    
    // Configure OTLP exporter
    const exporter = new OTLPLogExporter({ 
      url: process.env.OTEL_EXPORTER_OTLP_LOGS_ENDPOINT || 
           `${process.env.SIGNOZ_URL || 'http://localhost:4318'}/v1/logs` 
    });
    
    // Add log record processor
    provider.addLogRecordProcessor(new SimpleLogRecordProcessor(exporter));
    
    // Set global logger provider
    logs.setGlobalLoggerProvider(provider);
    
    initialized = true;
    console.log('✅ OTEL Logs SDK initialized successfully');
    
  } catch (error) {
    // Silent fallback: publisher will console.log JSON
    console.warn('⚠️ OTEL Logs SDK initialization failed, using console fallback:', error.message);
    initialized = false;
  }
}

/**
 * Check if logs SDK is initialized
 */
export function isLogsSdkInitialized(): boolean {
  return initialized;
}
