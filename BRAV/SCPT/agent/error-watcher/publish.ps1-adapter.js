#!/usr/bin/env node

/**
 * PowerShell Error Capture Adapter
 * Allows PowerShell scripts to publish errors to the error radar system
 */

const { captureError } = require('./dist/capture');

// Parse command line arguments
const args = process.argv.slice(2);
const options = {};

for (let i = 0; i < args.length; i += 2) {
    const key = args[i]?.replace('--', '');
    const value = args[i + 1];
    if (key && value) {
        options[key] = value;
    }
}

// Create error object from PowerShell data
const errorMessage = options.message || 'PowerShell Error';
const stackTrace = options.stack || '';

const error = new Error(errorMessage);
error.stack = stackTrace || `Error: ${errorMessage}\n    at PowerShell Script (${options.file || 'unknown'}:${options.line || 0})`;

// Capture the error
const fingerprint = captureError(error, {
    origin: 'powershell',
    service: options.service || 'powershell-script',
    file: options.file,
    line: options.line,
    severity: options.severity || 'error'
});

// Output fingerprint for PowerShell to capture
console.log(fingerprint);
