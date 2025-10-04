import { captureError } from './capture';

/**
 * Error Radar - Global error detection and capture system
 * Bootstraps error handlers for Node.js runtime environments
 */

/**
 * Initialize global error handlers for Node.js
 */
export function bootstrapErrorRadar(options: {
    serviceName?: string;
    enableProcessWarnings?: boolean;
    enableUnhandledRejections?: boolean;
    enableUncaughtExceptions?: boolean;
} = {}): void {
    const {
        serviceName = process.env.SERVICE_NAME || 'otel-app',
        enableProcessWarnings = true,
        enableUnhandledRejections = true,
        enableUncaughtExceptions = true
    } = options;

    console.log(`🚀 Error Radar bootstrapped for service: ${serviceName}`);

    // Capture uncaught exceptions
    if (enableUncaughtExceptions) {
        process.on('uncaughtException', (err) => {
            captureError(err, {
                origin: 'uncaughtException',
                service: serviceName,
                severity: 'fatal'
            });
            
            // Log to console as well for immediate visibility
            console.error('🚨 Uncaught Exception:', err.message);
            console.error(err.stack);
            
            // Give time for error to be published before exit
            setTimeout(() => {
                process.exit(1);
            }, 1000);
        });
    }

    // Capture unhandled promise rejections
    if (enableUnhandledRejections) {
        process.on('unhandledRejection', (reason: any, promise) => {
            const err = reason instanceof Error ? reason : new Error(String(reason));
            captureError(err, {
                origin: 'unhandledRejection',
                service: serviceName,
                severity: 'error',
                promise: promise.toString()
            });
            
            console.error('🚨 Unhandled Promise Rejection:', reason);
        });
    }

    // Capture process warnings
    if (enableProcessWarnings) {
        process.on('warning', (warning) => {
            const err = new Error(`Process Warning: ${warning.name} - ${warning.message}`);
            err.stack = warning.stack;
            
            captureError(err, {
                origin: 'processWarning',
                service: serviceName,
                severity: 'warn',
                warningName: warning.name
            });
            
            console.warn('⚠️ Process Warning:', warning.message);
        });
    }

    console.log('✅ Error Radar handlers installed');
}

/**
 * Guard function for wrapping promises with error capture
 */
export function guard<T>(
    promise: Promise<T>,
    context: { origin?: string; service?: string; route?: string; testId?: string } = {}
): Promise<T> {
    return promise.catch((error) => {
        captureError(error, {
            origin: context.origin || 'promise-guard',
            service: context.service || process.env.SERVICE_NAME || 'app',
            route: context.route,
            testId: context.testId
        });
        throw error; // Re-throw to maintain promise chain behavior
    });
}

/**
 * Guard function for wrapping async functions
 */
export function guardAsync<T extends any[], R>(
    fn: (...args: T) => Promise<R>,
    context: { origin?: string; service?: string; route?: string } = {}
): (...args: T) => Promise<R> {
    return async (...args: T): Promise<R> => {
        try {
            return await fn(...args);
        } catch (error) {
            captureError(error, {
                origin: context.origin || 'async-guard',
                service: context.service || process.env.SERVICE_NAME || 'app',
                route: context.route
            });
            throw error;
        }
    };
}

/**
 * Guard function for wrapping synchronous functions
 */
export function guardSync<T extends any[], R>(
    fn: (...args: T) => R,
    context: { origin?: string; service?: string; route?: string } = {}
): (...args: T) => R {
    return (...args: T): R => {
        try {
            return fn(...args);
        } catch (error) {
            captureError(error, {
                origin: context.origin || 'sync-guard',
                service: context.service || process.env.SERVICE_NAME || 'app',
                route: context.route
            });
            throw error;
        }
    };
}

/**
 * HTTP middleware for capturing 500 errors
 */
export function createErrorMiddleware(options: {
    serviceName?: string;
    capture4xx?: boolean;
    capture5xx?: boolean;
} = {}) {
    const {
        serviceName = process.env.SERVICE_NAME || 'http-service',
        capture4xx = false,
        capture5xx = true
    } = options;

    return (req: any, res: any, next: any) => {
        const originalSend = res.send;
        
        res.send = function(data: any) {
            const statusCode = res.statusCode;
            
            if (statusCode >= 500 && capture5xx) {
                const err = new Error(`HTTP ${statusCode} Error`);
                captureError(err, {
                    origin: 'http500',
                    service: serviceName,
                    route: req.route?.path || req.url,
                    method: req.method,
                    statusCode,
                    userAgent: req.get('User-Agent'),
                    correlationId: req.get('X-Correlation-ID')
                });
            } else if (statusCode >= 400 && statusCode < 500 && capture4xx) {
                const err = new Error(`HTTP ${statusCode} Client Error`);
                captureError(err, {
                    origin: 'http400',
                    service: serviceName,
                    route: req.route?.path || req.url,
                    method: req.method,
                    statusCode,
                    userAgent: req.get('User-Agent'),
                    correlationId: req.get('X-Correlation-ID')
                });
            }
            
            return originalSend.call(this, data);
        };
        
        next();
    };
}

/**
 * Test function for error radar
 */
export function testErrorRadar(): void {
    console.log('Testing Error Radar...');
    
    // Bootstrap error radar
    bootstrapErrorRadar({ serviceName: 'test-service' });
    
    // Test unhandled rejection
    setTimeout(() => {
        Promise.reject(new Error('Test unhandled rejection'));
    }, 100);
    
    // Test guarded promise
    const guardedPromise = guard(
        Promise.reject(new Error('Test guarded promise')),
        { origin: 'test-guard', service: 'test-service' }
    );
    
    guardedPromise.catch(() => {
        console.log('Guarded promise caught error as expected');
    });
    
    console.log('Error Radar tests initiated (check logs for results)');
}

// Auto-bootstrap if called directly
if (require.main === module) {
    testErrorRadar();
}
