import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { fingerprint } from './fingerprint';
import { publishToOtel } from './publisher';

const REG_PATH = '.agent/error_index.json';

type RegEntry = { 
    firstSeen: number; 
    lastSeen: number; 
    count: number; 
    mutedUntil?: number;
    lastMessage?: string;
    lastStack?: string;
};

type Registry = Record<string, RegEntry>;

/**
 * Load error registry from disk
 */
function loadRegistry(): Registry {
    try {
        if (!existsSync(REG_PATH)) {
            return {};
        }
        const content = readFileSync(REG_PATH, 'utf8');
        return JSON.parse(content);
    } catch (error) {
        console.warn('Failed to load error registry:', error);
        return {};
    }
}

/**
 * Save error registry to disk
 */
function saveRegistry(reg: Registry): void {
    try {
        // Ensure directory exists
        const dir = dirname(REG_PATH);
        if (!existsSync(dir)) {
            mkdirSync(dir, { recursive: true });
        }
        
        writeFileSync(REG_PATH, JSON.stringify(reg, null, 2));
    } catch (error) {
        console.warn('Failed to save error registry:', error);
    }
}

/**
 * Clean up old entries from registry
 */
function cleanupRegistry(reg: Registry): Registry {
    const now = Math.floor(Date.now() / 1000);
    const TTL_DAYS = Number(process.env['ERROR_REGISTRY_TTL_DAYS'] || 21);
    const TTL_SECONDS = TTL_DAYS * 24 * 3600;
    
    const cleaned: Registry = {};
    for (const [fp, entry] of Object.entries(reg)) {
        if (now - entry.lastSeen < TTL_SECONDS) {
            cleaned[fp] = entry;
        }
    }
    
    return cleaned;
}

/**
 * Capture and process an error with fingerprinting and deduplication
 */
export function captureError(err: any, ctx: any = {}): string {
    try {
        const now = Math.floor(Date.now() / 1000);
        const fp = fingerprint(err, ctx);
        
        // Load and clean registry
        let reg = loadRegistry();
        reg = cleanupRegistry(reg);
        
        // Get or create entry
        const entry: RegEntry = reg[fp] || {
            firstSeen: now,
            lastSeen: now,
            count: 0,
            mutedUntil: 0
        };
        
        // Update entry
        entry.count += 1;
        entry.lastSeen = now;
        entry.lastMessage = err?.message || String(err);
        entry.lastStack = err?.stack;
        
        // Determine if this should be "loud" (new error) or "quiet" (known error)
        const RENOTIFY_WINDOW_SEC = Number(process.env['RENOTIFY_WINDOW_SEC'] || 6 * 3600); // 6 hours default
        // const MAX_LOUD_PER_HOUR = Number(process.env.MAX_LOUD_PER_HOUR_PER_FP || 1);
        
        const isNewError = !reg[fp];
        const isWithinRenotifyWindow = now < (entry.mutedUntil || 0);
        const shouldBeLoud = isNewError || !isWithinRenotifyWindow;
        
        if (shouldBeLoud) {
            // This is a new error or time for re-notification
            entry.mutedUntil = now + RENOTIFY_WINDOW_SEC;
            
            publishToOtel(err, {
                fingerprint: fp,
                known: !isNewError,
                severity: isNewError ? 'fatal' : 'error',
                origin: ctx.origin || 'unknown',
                service: ctx.service || process.env['SERVICE_NAME'] || 'app',
                route: ctx.route,
                testId: ctx.testId,
                buildSha: ctx.buildSha,
                count: entry.count,
                suppressed: entry.count - 1
            });
            
            console.log(`${isNewError ? '🚨 NEW ERROR' : '🔄 RE-NOTIFY'} [${fp}] ${entry.lastMessage}`);
            
        } else {
            // This is a known error within the quiet window
            publishToOtel(err, {
                fingerprint: fp,
                known: true,
                severity: 'warn',
                origin: ctx.origin || 'unknown',
                service: ctx.service || process.env['SERVICE_NAME'] || 'app',
                route: ctx.route,
                testId: ctx.testId,
                buildSha: ctx.buildSha,
                count: entry.count,
                suppressed: entry.count - 1
            });
            
            // Only log every 10th occurrence to avoid spam
            if (entry.count % 10 === 0) {
                console.log(`🔄 QUIET [${fp}] ${entry.lastMessage} (${entry.count} total, ${entry.count - 1} suppressed)`);
            }
        }
        
        // Save updated registry
        reg[fp] = entry;
        saveRegistry(reg);
        
        return fp;
        
    } catch (captureError) {
        console.error('Failed to capture error:', captureError);
        console.error('Original error:', err);
        return 'capture-failed';
    }
}

/**
 * Get registry statistics
 */
export function getRegistryStats(): {
    totalErrors: number;
    newErrors: number;
    knownErrors: number;
    totalOccurrences: number;
    oldestError: number;
    newestError: number;
} {
    const reg = loadRegistry();
    const now = Math.floor(Date.now() / 1000);
    
    const entries = Object.values(reg);
    const totalErrors = entries.length;
    const newErrors = entries.filter(e => e.count === 1).length;
    const knownErrors = entries.filter(e => e.count > 1).length;
    const totalOccurrences = entries.reduce((sum, e) => sum + e.count, 0);
    const oldestError = entries.length > 0 ? Math.min(...entries.map(e => e.firstSeen)) : now;
    const newestError = entries.length > 0 ? Math.max(...entries.map(e => e.lastSeen)) : now;
    
    return {
        totalErrors,
        newErrors,
        knownErrors,
        totalOccurrences,
        oldestError,
        newestError
    };
}

/**
 * Get detailed error information by fingerprint
 */
export function getErrorDetails(fingerprint: string): RegEntry | null {
    const reg = loadRegistry();
    return reg[fingerprint] || null;
}

/**
 * List all errors in registry
 */
export function listErrors(): Array<{fingerprint: string; entry: RegEntry}> {
    const reg = loadRegistry();
    return Object.entries(reg).map(([fp, entry]) => ({ fingerprint: fp, entry }));
}

/**
 * Test function for error capture
 */
export function testErrorCapture(): void {
    console.log('Testing error capture...');
    
    const testError1 = new Error('Test database connection failed');
    testError1.stack = `Error: Test database connection failed
    at Database.connect (C:\\otel\\src\\database.ts:45:12)
    at UserService.createUser (C:\\otel\\src\\services.ts:123:8)`;

    const testError2 = new Error('Test database connection failed');
    testError2.stack = `Error: Test database connection failed
    at Database.connect (C:\\otel\\src\\database.ts:45:12)
    at UserService.createUser (C:\\otel\\src\\services.ts:123:8)`;

    // First error should be "loud" (new)
    const fp1 = captureError(testError1, { origin: 'uncaughtException', service: 'test-service' });
    
    // Second error should be "quiet" (known)
    const fp2 = captureError(testError2, { origin: 'uncaughtException', service: 'test-service' });
    
    // Fingerprints should be the same
    console.log(`Fingerprint 1: ${fp1}`);
    console.log(`Fingerprint 2: ${fp2}`);
    console.log(`Same fingerprint: ${fp1 === fp2}`);
    
    // Show registry stats
    const stats = getRegistryStats();
    console.log('Registry stats:', stats);
    
    console.log('Error capture tests completed');
}

// Run tests if called directly
if (require.main === module) {
    testErrorCapture();
}
