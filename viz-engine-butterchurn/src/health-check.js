#!/usr/bin/env node
/**
 * Health check for viz-engine
 * ECRR: BossCat Mission - Container health monitoring
 */

const http = require('http');

const options = {
  hostname: 'localhost',
  port: process.env.PORT || 7001,
  path: '/',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0); // Healthy
  } else {
    console.error(`[health] Unhealthy status: ${res.statusCode}`);
    process.exit(1);
  }
});

req.on('error', (err) => {
  console.error(`[health] Error: ${err.message}`);
  process.exit(1);
});

req.on('timeout', () => {
  console.error('[health] Timeout');
  req.destroy();
  process.exit(1);
});

req.end();

