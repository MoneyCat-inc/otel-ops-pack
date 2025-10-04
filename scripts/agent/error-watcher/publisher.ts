import { context, trace, diag, SpanStatusCode } from '@opentelemetry/api';

/**
 * Error event model for structured error reporting
 */
export type ErrorEvent = {
    fingerprint: string;            // fp id
    known: boolean;                 // new vs known
    severity: 'error'|'fatal'|'warn';
    origin: 'uncaughtException'|'unhandledRejection'|'pageerror'|'console.error'|'http500'|'processWarning'|string;
    service: string;                // app name
    route?: string;
    testId?: string;
    buildSha?: string;
    message: string;
    frames: {file:string; line?:number; col?:number; fn?:string}[];
    count?: number;                 // aggregated repeats
    suppressed?: number;            // how many we muted
};

/**
 * Parse stack trace into structured frames
 */
function parseStackFrames(stack?: string): Array<{file:string; line?:number; col?:number; fn?:string}> {
    if (!stack) return [];
    
    const frames: Array<{file:string; line?:number; col?:number; fn?:string}> = [];
    const lines = stack.split('\n').slice(1); // Skip error message line
    
    for (const line of lines) {
        // Match: "    at FunctionName (file:line:col)" or "    at file:line:col"
        const match = line.match(/^\s*at\s+(?:([^(]+)\s+\()?([^(]+):(\d+):(\d+)\)?/);
        if (match) {
            frames.push({
                fn: match[1]?.trim(),
                file: match[2]?.trim(),
                line: parseInt(match[3]),
                col: parseInt(match[4])
            });
        }
    }
    
    return frames.slice(0, 8); // Limit to first 8 frames
}

/**
 * Publish error event to OpenTelemetry
 */
export function publishToOtel(error: Error, ctx: any = {}): void {
    try {
        // Parse stack frames
        const frames = parseStackFrames(error.stack);
        
        // Create error event
        const errorEvent: ErrorEvent = {
            fingerprint: ctx.fingerprint || 'unknown',
            known: ctx.known || false,
            severity: ctx.severity || 'error',
            origin: ctx.origin || 'unknown',
            service: ctx.service || process.env.SERVICE_NAME || 'otel-app',
            route: ctx.route,
            testId: ctx.testId,
            buildSha: ctx.buildSha || process.env.GIT_SHA || 'dev',
            message: error.message || String(error),
            frames,
            count: ctx.count || 1,
            suppressed: ctx.suppressed || 0
        };

        // Try to use OpenTelemetry logger if available
        try {
            const { logs, SeverityNumber } = require('@opentelemetry/api-logs');
            const logger = logs.getLogger('error-watcher');
            
            logger.emit({
                body: errorEvent.message,
                severityNumber: errorEvent.known ? SeverityNumber.ERROR : SeverityNumber.FATAL,
                attributes: {
                    'error.fp': errorEvent.fingerprint,
                    'error.known': errorEvent.known,
                    'error.origin': errorEvent.origin,
                    'error.frames': JSON.stringify(errorEvent.frames.slice(0, 4)),
                    'error.count': errorEvent.count,
                    'error.suppressed': errorEvent.suppressed,
                    'service.name': errorEvent.service,
                    'build.sha': errorEvent.buildSha,
                    'error.route': errorEvent.route || '',
                    'error.testId': errorEvent.testId || '',
                    'error.severity': errorEvent.severity
                }
            });

            // Annotate current span if available
            const span = trace.getSpan(context.active());
            if (span) {
                span.addEvent('app.error', {
                    'error.fp': errorEvent.fingerprint,
                    'error.known': errorEvent.known,
                    'error.origin': errorEvent.origin,
                    'error.count': errorEvent.count
                });
                
                if (!errorEvent.known) {
                    span.setStatus({ 
                        code: SpanStatusCode.ERROR, 
                        message: errorEvent.message 
                    });
                }
            }

        } catch (otelError) {
            // Guaranteed console fallback
            fallbackToJsonLog(errorEvent);
        }

    } catch (publishError) {
        // Last resort - just log the original error
        console.error('Failed to publish error event:', publishError);
        console.error('Original error:', error);
    }
}

/**
 * Fallback console logging when OTEL is not available
 */
function fallbackToConsole(errorEvent: ErrorEvent): void {
    const logLevel = errorEvent.known ? 'warn' : 'error';
    const prefix = errorEvent.known ? '🔄' : '🚨';
    
    console[logLevel](`${prefix} [${errorEvent.fingerprint}] ${errorEvent.message}`, {
        fingerprint: errorEvent.fingerprint,
        known: errorEvent.known,
        origin: errorEvent.origin,
        service: errorEvent.service,
        count: errorEvent.count,
        suppressed: errorEvent.suppressed,
        frames: errorEvent.frames.slice(0, 3)
    });
}

/**
 * JSON log fallback for structured logging
 */
function fallbackToJsonLog(errorEvent: ErrorEvent): void {
    // eslint-disable-next-line no-console
    console.log(JSON.stringify({
        ts: Date.now(),
        level: errorEvent.known ? 'warn' : 'error',
        msg: errorEvent.message,
        'error.fp': errorEvent.fingerprint,
        'error.known': errorEvent.known,
        'error.origin': errorEvent.origin,
        'error.count': errorEvent.count,
        'error.suppressed': errorEvent.suppressed,
        'service.name': errorEvent.service,
        'build.sha': errorEvent.buildSha || 'dev',
        'error.severity': errorEvent.severity,
        'error.frames': errorEvent.frames.slice(0, 4)
    }));
}

/**
 * JSON log line fallback for structured logging
 */
export function publishToJsonLog(error: Error, ctx: any = {}): void {
    const errorEvent: ErrorEvent = {
        fingerprint: ctx.fingerprint || 'unknown',
        known: ctx.known || false,
        severity: ctx.severity || 'error',
        origin: ctx.origin || 'unknown',
        service: ctx.service || process.env.SERVICE_NAME || 'otel-app',
        message: error.message || String(error),
        frames: parseStackFrames(error.stack),
        count: ctx.count || 1,
        suppressed: ctx.suppressed || 0
    };

    console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        level: errorEvent.severity,
        type: 'error-event',
        ...errorEvent
    }));
}

/**
 * Test function for publisher functionality
 */
export function testPublisher(): void {
    console.log('Testing error publisher...');
    
    const testError = new Error('Test database connection failed');
    testError.stack = `Error: Test database connection failed
    at Database.connect (C:\\otel\\src\\database.ts:45:12)
    at UserService.createUser (C:\\otel\\src\\services.ts:123:8)`;

    // Test new error
    publishToOtel(testError, {
        fingerprint: 'test123',
        known: false,
        origin: 'uncaughtException',
        service: 'test-service'
    });

    // Test known error with aggregation
    publishToOtel(testError, {
        fingerprint: 'test123',
        known: true,
        origin: 'uncaughtException',
        service: 'test-service',
        count: 5,
        suppressed: 4
    });

    console.log('Publisher tests completed');
}

// Run tests if called directly
if (require.main === module) {
    testPublisher();
}
