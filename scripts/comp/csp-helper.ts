#!/usr/bin/env tsx
// CSP Helper: Generate nonce and strict-dynamic CSP headers
// Lane: COMP | Owner: AUTO-BOTS-COMP-ALFA
// Authority: BossCat OEM P1-B

import { randomBytes } from 'crypto';

export interface CSPConfig {
  nonce?: string;
  mode?: 'development' | 'production';
  allowInlineStyles?: boolean;
}

export function generateNonce(): string {
  return randomBytes(16).toString('base64');
}

export function buildCSP(config: CSPConfig = {}): string {
  const nonce = config.nonce || generateNonce();
  const mode = config.mode || 'development';
  
  const directives: string[] = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "upgrade-insecure-requests"
  ];
  
  // Style handling
  if (config.allowInlineStyles) {
    directives.push("style-src 'self' 'unsafe-inline'"); // Dev only
  } else {
    directives.push("style-src 'self'");
  }
  
  // Connect-src for development (allow localhost)
  if (mode === 'development') {
    directives.push("connect-src 'self' http://localhost:* ws://localhost:*");
  } else {
    directives.push("connect-src 'self'");
  }
  
  return directives.join('; ');
}

// CLI usage
if (require.main === module) {
  const nonce = generateNonce();
  const csp = buildCSP({ nonce, mode: 'development' });
  
  console.log('🔒 CSP Helper (COMP Lane)\n');
  console.log('Nonce:', nonce);
  console.log('\nCSP Header:');
  console.log(csp);
  console.log('\nUsage in HTML:');
  console.log(`<script nonce="${nonce}" src="/path/to/script.js"></script>`);
}

