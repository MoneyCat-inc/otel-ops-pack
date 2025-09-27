const { MeterProvider } = require('@opentelemetry/api');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

// Create meter provider
const meterProvider = new MeterProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'flake-gauges',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  }),
  readers: [
    new OTLPMetricExporter({
      url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT + '/v1/metrics',
    }),
  ],
});

const meter = meterProvider.getMeter('flake-gauges');

// Create gauges
const flakyTestsGauge = meter.createUpDownCounter('ci_flaky_tests_count', {
  description: 'Number of quarantined flaky tests',
});

const flakeStatusGauge = meter.createUpDownCounter('test_flake_status', {
  description: 'Status of flaky test detection',
});

// Emit metrics
console.log('Emitting flake gauges...');

// Simulate flake detection (in real implementation, this would query your test system)
const flakyTestCount = Math.floor(Math.random() * 10); // 0-9 flaky tests
const flakeStatus = flakyTestCount > 0 ? 1 : 0; // 1 if flaky tests exist, 0 if none

flakyTestsGauge.add(flakyTestCount, {
  test_suite: 'smoke',
  browser: 'chrome',
  branch: 'main',
});

flakeStatusGauge.add(flakeStatus, {
  status: flakyTestCount > 0 ? 'quarantined' : 'clean',
});

console.log(Emitted metrics:  flaky tests, status: );

// Force flush and close
meterProvider.forceFlush().then(() => {
  console.log('Metrics flushed successfully');
  process.exit(0);
}).catch((error) => {
  console.error('Failed to flush metrics:', error);
  process.exit(1);
});
