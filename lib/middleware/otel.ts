// Resonai Backend - OpenTelemetry Middleware
// Integrates OTel tracing with Next.js API routes for SigNoz observability

import { trace, context, SpanStatusCode } from '@opentelemetry/api';
import { NextRequest, NextResponse } from 'next/server';

// OTel tracer instance
const tracer = trace.getTracer('resonai-backend', '1.0.0');

// Middleware wrapper for OTel tracing
export function withOTel<T extends any[]>(
  handler: (...args: T) => Promise<NextResponse>
) {
  return async (...args: T): Promise<NextResponse> => {
    const [req] = args as [NextRequest];
    
    // Extract route information
    const route = req.nextUrl.pathname;
    const method = req.method;
    const spanName = `${method} ${route}`;
    
    // Create span for the API route
    const span = tracer.startSpan(spanName, {
      attributes: {
        'http.method': method,
        'http.route': route,
        'http.url': req.url,
        'user_agent.original': req.headers.get('user-agent') || '',
        'api.route': route,
      }
    });

    // Set span as active
    return context.with(trace.setSpan(context.active(), span), async () => {
      try {
        // Execute the handler
        const response = await handler(...args);
        
        // Set response attributes
        span.setAttributes({
          'http.status_code': response.status,
          'http.response.status_code': response.status,
        });

        // Set span status based on HTTP status
        if (response.status >= 400) {
          span.setStatus({
            code: SpanStatusCode.ERROR,
            message: `HTTP ${response.status}`,
          });
        } else {
          span.setStatus({ code: SpanStatusCode.OK });
        }

        return response;

      } catch (error) {
        // Set error attributes
        span.setAttributes({
          'error': true,
          'error.message': error instanceof Error ? error.message : 'Unknown error',
          'error.type': error instanceof Error ? error.constructor.name : 'UnknownError',
        });

        span.setStatus({
          code: SpanStatusCode.ERROR,
          message: error instanceof Error ? error.message : 'Unknown error',
        });

        // Re-throw the error
        throw error;

      } finally {
        // End the span
        span.end();
      }
    });
  };
}

// Utility function to add custom attributes to the active span
export function setSpanAttributes(attributes: Record<string, string | number | boolean>) {
  const span = trace.getActiveSpan();
  if (span) {
    span.setAttributes(attributes);
  }
}

// Utility function to add events to the active span
export function addSpanEvent(name: string, attributes?: Record<string, any>) {
  const span = trace.getActiveSpan();
  if (span) {
    span.addEvent(name, attributes);
  }
}

// Utility function to create child spans for specific operations
export async function withChildSpan<T>(
  name: string,
  attributes: Record<string, string | number | boolean>,
  operation: () => Promise<T>
): Promise<T> {
  const span = tracer.startSpan(name, {
    attributes,
  });

  return context.with(trace.setSpan(context.active(), span), async () => {
    try {
      const result = await operation();
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    } finally {
      span.end();
    }
  });
}

// Database operation tracing helper
export async function traceDatabaseOperation<T>(
  operation: string,
  query: string,
  operationFn: () => Promise<T>
): Promise<T> {
  return withChildSpan(
    `db.${operation}`,
    {
      'db.operation': operation,
      'db.statement': query.substring(0, 100), // Truncate long queries
    },
    operationFn
  );
}

// External API call tracing helper
export async function traceExternalCall<T>(
  service: string,
  endpoint: string,
  operationFn: () => Promise<T>
): Promise<T> {
  return withChildSpan(
    `external.${service}`,
    {
      'external.service': service,
      'external.endpoint': endpoint,
    },
    operationFn
  );
}
