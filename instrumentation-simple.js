// Simplified OpenTelemetry Instrumentation for Resonai Backend
// This file avoids gRPC issues by using HTTP-only exporters

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// Initialize OpenTelemetry SDK with HTTP-only configuration
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'resonai-backend',
    [SemanticResourceAttributes.SERVICE_VERSION]: process.env.OTEL_SERVICE_VERSION || '1.0.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.OTEL_ENVIRONMENT || 'development',
    [SemanticResourceAttributes.HOST_NAME]: process.env.HOSTNAME || 'localhost',
    [SemanticResourceAttributes.OS_TYPE]: process.platform,
    [SemanticResourceAttributes.OS_VERSION]: process.version,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      // Enable only HTTP-based instrumentations to avoid gRPC issues
      '@opentelemetry/instrumentation-fs': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-http': {
        enabled: true,
        requestHook: (span, request) => {
          // Add custom attributes to HTTP requests
          span.setAttributes({
            'http.request.method': request.method,
            'http.request.url': request.url,
            'http.request.user_agent': request.headers['user-agent'] || 'unknown',
          });
        },
        responseHook: (span, response) => {
          // Add custom attributes to HTTP responses
          span.setAttributes({
            'http.response.status_code': response.statusCode,
            'http.response.status_text': response.statusMessage,
          });
        },
      },
      '@opentelemetry/instrumentation-express': {
        enabled: true,
      },
      '@opentelemetry/instrumentation-next': {
        enabled: true,
      },
      // Disable gRPC-based instrumentations to avoid stream module issues
      '@opentelemetry/instrumentation-grpc': {
        enabled: false,
      },
      '@opentelemetry/instrumentation-grpc-js': {
        enabled: false,
      },
    }),
  ],
});

// Start the SDK
sdk.start();

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('OpenTelemetry terminated'))
    .catch((error) => console.log('Error terminating OpenTelemetry', error))
    .finally(() => process.exit(0));
});

console.log('OpenTelemetry instrumentation initialized for Resonai Backend (HTTP-only)');
