import crypto from 'crypto';

/**
 * Error fingerprinting for deduplication and noise reduction
 * Creates stable hashes that ignore variable data like IDs, timestamps, and absolute paths
 */
export function fingerprint(err: {name?:string, message?:string, stack?:string}, ctx: any): string {
    const norm = (s = '') => s
        // Remove hex IDs and hashes
        .replace(/0x[0-9a-f]+/gi, '0x*')
        .replace(/\b[0-9a-f]{8,}\b/gi, '*')
        // Remove timestamps and large numbers
        .replace(/\d{3,}/g, '#')
        // Remove UUIDs
        .replace(/\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi, '*')
        // Remove email addresses
        .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '*')
        // Remove URLs
        .replace(/https?:\/\/[^\s]+/g, '*')
        // Remove file paths (keep relative structure)
        .replace(/[A-Z]:\\[^\\]+\\/g, '$CWD\\')
        .replace(/\/[^\/]+\//g, '/$CWD/')
        // Normalize whitespace
        .replace(/\s+/g, ' ')
        .trim();

    // Extract first 6 stack frames and normalize them
    const stackLines = (err.stack || '').split('\n');
    const relevantFrames = stackLines.slice(0, 6).map(line => {
        // Remove absolute paths, keep relative structure
        return norm(line.replace(process.cwd(), '$CWD'));
    }).join('\n');

    // Create fingerprint base from normalized components
    const components = [
        norm(err.name || 'Error'),
        norm(err.message || ''),
        relevantFrames,
        ctx.origin || 'unknown',
        ctx.service || 'unknown'
    ];

    const base = components.join('|');
    
    // Generate stable hash
    return crypto.createHash('sha1').update(base, 'utf8').digest('hex').slice(0, 16);
}

/**
 * Test function to verify fingerprint stability
 */
export function testFingerprintStability(): boolean {
    const testError1 = new Error('Database connection failed: timeout after 30s');
    testError1.stack = `Error: Database connection failed: timeout after 30s
    at Database.connect (C:\\otel\\src\\database.ts:45:12)
    at UserService.createUser (C:\\otel\\src\\services.ts:123:8)
    at POST /api/users (C:\\otel\\src\\routes.ts:67:5)`;

    const testError2 = new Error('Database connection failed: timeout after 30s');
    testError2.stack = `Error: Database connection failed: timeout after 30s
    at Database.connect (C:\\otel\\src\\database.ts:45:12)
    at UserService.createUser (C:\\otel\\src\\services.ts:123:8)
    at POST /api/users (C:\\otel\\src\\routes.ts:67:5)`;

    const testError3 = new Error('Database connection failed: timeout after 45s');
    testError3.stack = `Error: Database connection failed: timeout after 45s
    at Database.connect (C:\\otel\\src\\database.ts:45:12)
    at UserService.createUser (C:\\otel\\src\\services.ts:123:8)
    at POST /api/users (C:\\otel\\src\\routes.ts:67:5)`;

    const fp1 = fingerprint(testError1, { origin: 'uncaughtException' });
    const fp2 = fingerprint(testError2, { origin: 'uncaughtException' });
    const fp3 = fingerprint(testError3, { origin: 'uncaughtException' });

    // Same errors should have same fingerprint
    const sameFingerprint = fp1 === fp2;
    
    // Different errors should have different fingerprints
    const differentFingerprint = fp1 !== fp3;

    console.log('Fingerprint Tests:');
    console.log(`  Same errors: ${fp1} === ${fp2} = ${sameFingerprint}`);
    console.log(`  Different errors: ${fp1} !== ${fp3} = ${differentFingerprint}`);

    return sameFingerprint && differentFingerprint;
}

// Run tests if called directly
if (require.main === module) {
    testFingerprintStability();
}
