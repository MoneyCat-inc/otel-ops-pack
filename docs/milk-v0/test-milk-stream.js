// docs/milk-v0/test-milk-stream.js
// Gate #011 Job M2 - Milk v0 stream validation test
const https = require('http');

const MILK_URL = process.env.MILK_URL || 'http://localhost:8080';
const DURATION_MS = 30000; // 30 seconds
const MIN_FRAMES = 20; // Minimum frames for sanity check

async function testMilkStream() {
  console.log(`[test] Testing Milk v0 stream at ${MILK_URL}/milk.mjpg`);
  
  let frameCount = 0;
  let boundary = null;
  let startTime = Date.now();
  
  return new Promise((resolve, reject) => {
    const req = https.get(`${MILK_URL}/milk.mjpg`, (res) => {
      console.log(`[test] Status: ${res.statusCode}`);
      
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      
      // Check Content-Type
      const contentType = res.headers['content-type'];
      console.log(`[test] Content-Type: ${contentType}`);
      
      if (!contentType.includes('multipart')) {
        reject(new Error(`Expected multipart, got ${contentType}`));
        return;
      }
      
      // Extract boundary
      const boundaryMatch = contentType.match(/boundary=([^;]+)/);
      if (boundaryMatch) {
        boundary = boundaryMatch[1];
        console.log(`[test] Boundary: ${boundary}`);
      }
      
      // Count frames
      let buffer = '';
      res.on('data', (chunk) => {
        buffer += chunk.toString('binary');
        // Count JPEG boundaries
        const matches = buffer.match(new RegExp(`--${boundary}`, 'g'));
        if (matches) {
          frameCount = matches.length;
        }
      });
      
      res.on('end', () => {
        const duration = (Date.now() - startTime) / 1000;
        const fps = frameCount / duration;
        
        console.log(`[test] Duration: ${duration.toFixed(1)}s`);
        console.log(`[test] Frames detected: ${frameCount}`);
        console.log(`[test] Estimated FPS: ${fps.toFixed(1)}`);
        
        if (frameCount >= MIN_FRAMES) {
          console.log(`[test] ✅ PASS - Frame count meets threshold (≥${MIN_FRAMES})`);
          resolve({ frameCount, fps, duration });
        } else {
          console.log(`[test] ❌ FAIL - Frame count below threshold (${frameCount} < ${MIN_FRAMES})`);
          reject(new Error(`Insufficient frames: ${frameCount} < ${MIN_FRAMES}`));
        }
      });
    });
    
    req.on('error', reject);
    
    // Auto-stop after duration
    setTimeout(() => {
      req.destroy();
      resolve({ frameCount, duration: DURATION_MS / 1000 });
    }, DURATION_MS);
  });
}

// Run test
testMilkStream()
  .then((result) => {
    console.log('[test] ✅ Stream validation PASSED');
    process.exit(0);
  })
  .catch((err) => {
    console.error('[test] ❌ Stream validation FAILED:', err.message);
    process.exit(1);
  });

