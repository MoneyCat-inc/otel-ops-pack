#!/usr/bin/env node

/**
 * Error Radar Test Suite
 * Validates error detection, fingerprinting, and capture functionality
 */

const { captureError } = require('./capture.ts');
const { fingerprint } = require('./fingerprint.ts');
const { publishToOtel } = require('./publisher.ts');
const { bootstrapErrorRadar } = require('./error-radar.ts');

console.log('🧪 Error Radar Test Suite');
console.log('==========================\n');

// Test 1: Fingerprint Stability
console.log('Test 1: Fingerprint Stability');
console.log('-------------------------------');

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

console.log(`Fingerprint 1: ${fp1}`);
console.log(`Fingerprint 2: ${fp2}`);
console.log(`Fingerprint 3: ${fp3}`);
console.log(`Same errors same fingerprint: ${fp1 === fp2 ? '✅ PASS' : '❌ FAIL'}`);
console.log(`Different errors different fingerprint: ${fp1 !== fp3 ? '✅ PASS' : '❌ FAIL'}`);

// Test 2: Error Capture and Deduplication
console.log('\nTest 2: Error Capture and Deduplication');
console.log('----------------------------------------');

console.log('Capturing first error (should be loud)...');
const capturedFp1 = captureError(testError1, { 
    origin: 'uncaughtException', 
    service: 'test-service' 
});

console.log('Capturing same error again (should be quiet)...');
const capturedFp2 = captureError(testError1, { 
    origin: 'uncaughtException', 
    service: 'test-service' 
});

console.log('Capturing different error (should be loud)...');
const capturedFp3 = captureError(testError3, { 
    origin: 'uncaughtException', 
    service: 'test-service' 
});

console.log(`First capture fingerprint: ${capturedFp1}`);
console.log(`Second capture fingerprint: ${capturedFp2}`);
console.log(`Third capture fingerprint: ${capturedFp3}`);
console.log(`Same error same fingerprint: ${capturedFp1 === capturedFp2 ? '✅ PASS' : '❌ FAIL'}`);
console.log(`Different error different fingerprint: ${capturedFp1 !== capturedFp3 ? '✅ PASS' : '❌ FAIL'}`);

// Test 3: Error Radar Bootstrap
console.log('\nTest 3: Error Radar Bootstrap');
console.log('------------------------------');

try {
    bootstrapErrorRadar({ 
        serviceName: 'test-service',
        enableProcessWarnings: true,
        enableUnhandledRejections: true,
        enableUncaughtExceptions: false // Don't actually exit on uncaught exceptions in test
    });
    console.log('✅ Error radar bootstrap successful');
} catch (error) {
    console.log(`❌ Error radar bootstrap failed: ${error.message}`);
}

// Test 4: Registry Statistics
console.log('\nTest 4: Registry Statistics');
console.log('----------------------------');

try {
    const { getRegistryStats } = require('./capture');
    const stats = getRegistryStats();
    
    console.log(`Total Errors: ${stats.totalErrors}`);
    console.log(`New Errors: ${stats.newErrors}`);
    console.log(`Known Errors: ${stats.knownErrors}`);
    console.log(`Total Occurrences: ${stats.totalOccurrences}`);
    
    if (stats.totalErrors > 0) {
        console.log('✅ Registry statistics working');
    } else {
        console.log('⚠️ No errors in registry yet');
    }
} catch (error) {
    console.log(`❌ Registry statistics failed: ${error.message}`);
}

// Test 5: Publisher Test
console.log('\nTest 5: Publisher Test');
console.log('----------------------');

try {
    const testError = new Error('Test publisher error');
    testError.stack = `Error: Test publisher error
    at test (test-file.js:1:1)`;
    
    publishToOtel(testError, {
        fingerprint: 'test-publisher-fp',
        known: false,
        origin: 'test',
        service: 'test-service'
    });
    
    console.log('✅ Publisher test successful (check console for output)');
} catch (error) {
    console.log(`❌ Publisher test failed: ${error.message}`);
}

// Test 6: Edge Cases
console.log('\nTest 6: Edge Cases');
console.log('-------------------');

// Test with no stack trace
const noStackError = new Error('No stack trace error');
noStackError.stack = undefined;
const fpNoStack = fingerprint(noStackError, { origin: 'test' });
console.log(`No stack fingerprint: ${fpNoStack} ✅`);

// Test with circular reference
const circularError = new Error('Circular reference error');
circularError.circular = circularError;
const fpCircular = fingerprint(circularError, { origin: 'test' });
console.log(`Circular reference fingerprint: ${fpCircular} ✅`);

// Test with very long message
const longMessage = 'a'.repeat(10000);
const longError = new Error(longMessage);
const fpLong = fingerprint(longError, { origin: 'test' });
console.log(`Long message fingerprint: ${fpLong} ✅`);

console.log('\n🎯 Test Suite Summary');
console.log('=====================');
console.log('All tests completed. Check output above for results.');
console.log('Check .agent/error_index.json for captured errors.');
console.log('Check SigNoz UI for published error events.');

// Cleanup test data
console.log('\n🧹 Cleanup');
console.log('-----------');
console.log('To clean up test data, delete .agent/error_index.json');
console.log('and restart the error radar system.');
