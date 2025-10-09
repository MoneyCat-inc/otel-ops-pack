import { trace } from '@opentelemetry/api';

export async function checkOTelHealth(): Promise<{
  status: 'healthy' | 'unhealthy';
  error?: string;
}> {
  const span = trace.getActiveSpan();

  try {
    const otelEndpoint = process.env['OTEL_EXPORTER_OTLP_ENDPOINT'];

    if (!otelEndpoint) {
      return {
        status: 'unhealthy',
        error: 'OTEL_EXPORTER_OTLP_ENDPOINT not configured',
      };
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    try {
      const response = await fetch(`${otelEndpoint}/v1/traces`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ resourceSpans: [] }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok || response.status === 400) {
        span?.setAttributes({
          'otel.health_check': 'success',
          'otel.endpoint': otelEndpoint,
        });

        return { status: 'healthy' };
      }

      return {
        status: 'unhealthy',
        error: `OTel endpoint returned ${response.status}`,
      };
    } catch (fetchError) {
      clearTimeout(timeoutId);
      throw fetchError;
    }
  } catch (error) {
    span?.setAttributes({
      'otel.health_check': 'failed',
      'otel.error': error instanceof Error ? error.message : 'Unknown error',
    });

    return {
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown OTel error',
    };
  }
}

export function checkEnvironmentHealth(): {
  status: 'healthy' | 'unhealthy';
  missing: string[];
} {
  const requiredEnvVars = [
    'DATABASE_URL',
    'NEXTAUTH_SECRET',
    'NEXTAUTH_URL',
    'USER_HASH_SALT',
    'ALLOWED_ORIGIN',
    'OTEL_EXPORTER_OTLP_ENDPOINT',
  ];

  const missing = requiredEnvVars.filter(key => !process.env[key]);

  return {
    status: missing.length === 0 ? 'healthy' : 'unhealthy',
    missing,
  };
}
