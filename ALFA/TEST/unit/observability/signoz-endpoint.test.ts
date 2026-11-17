/**
 * Unit tests for the SigNoz metric exporter endpoint.
 * signoz.ts exports metrics over OTLP/HTTP, so its default must be the collector's HTTP
 * receiver (4318): the gRPC port (4317) answers an HTTP POST with HTTP/2 and every export fails.
 */

jest.mock('@opentelemetry/exporter-metrics-otlp-http', () => ({
  OTLPMetricExporter: jest.fn().mockImplementation(() => ({
    export: (_metrics: unknown, done: (result: { code: number }) => void) => done({ code: 0 }),
    forceFlush: () => Promise.resolve(),
    shutdown: () => Promise.resolve(),
  })),
}));
jest.mock('@opentelemetry/instrumentation', () => ({ registerInstrumentations: jest.fn() }));
jest.mock('@opentelemetry/auto-instrumentations-node', () => ({
  getNodeAutoInstrumentations: jest.fn(() => []),
}));

const ENDPOINT_VAR = 'OTEL_EXPORTER_OTLP_ENDPOINT';
const savedEndpoint = process.env[ENDPOINT_VAR];

// signoz.ts reads the endpoint at module load, so each case loads a fresh copy
async function exporterUrl(endpoint: string | undefined): Promise<string> {
  if (endpoint === undefined) {
    delete process.env[ENDPOINT_VAR];
  } else {
    process.env[ENDPOINT_VAR] = endpoint;
  }

  let signoz!: typeof import('@/lib/observability/signoz');
  let exporter!: jest.Mock;
  jest.isolateModules(() => {
    signoz = require('@/lib/observability/signoz');
    exporter = require('@opentelemetry/exporter-metrics-otlp-http').OTLPMetricExporter;
  });

  await signoz.initializeSigNoz();
  await signoz.shutdownSigNoz();
  return exporter.mock.calls[0][0].url;
}

describe('SigNoz metric exporter endpoint', () => {
  afterEach(() => {
    if (savedEndpoint === undefined) {
      delete process.env[ENDPOINT_VAR];
    } else {
      process.env[ENDPOINT_VAR] = savedEndpoint;
    }
  });

  it('should default to the OTLP/HTTP port, not the gRPC port', async () => {
    expect(await exporterUrl(undefined)).toBe('http://localhost:4318/v1/metrics');
  });

  it('should append /v1/metrics to a configured base URL, with or without a trailing slash', async () => {
    expect(await exporterUrl('http://collector:4318')).toBe('http://collector:4318/v1/metrics');
    expect(await exporterUrl('http://collector:4318/')).toBe('http://collector:4318/v1/metrics');
  });
});
