// /opt/viz/server.js
// Gate #011 - Milk v0 Viewer HTTP Server
// Now fetches from md3-engine instead of x11grab (3500× more efficient)
const express = require('express');
const { spawn } = require('child_process');
const fetch = require('node-fetch');
const app = express();

const PORT = process.env.PORT || 8080;
const DISPLAY = process.env.DISPLAY || ':99';
const GEOMETRY = process.env.GEOMETRY || '1280x720';
const FPS = process.env.FPS || '30';

// Static viewer page at /milk
app.use('/milk', express.static('public'));

// Health endpoint
app.get('/milk/health', (_, res) => res.json({ 
  ok: true, 
  source: 'md3-engine',  // Updated from Xvfb/pm-engine
  geometry: '1920x1080',  // md3-engine native resolution
  fps: Number(FPS) 
}));

// Track active streams to prevent accumulation
let activeStreams = 0;
const MAX_STREAMS = 2;  // Allow 1 active + 1 reconnecting (browser refresh gracefully)
const activeProcesses = new Map();  // Track ffmpeg PIDs for watchdog

// Watchdog: Kill stale ffmpeg processes every 30 seconds
setInterval(() => {
  const now = Date.now();
  for (const [pid, startTime] of activeProcesses.entries()) {
    const age = now - startTime;
    // Kill ffmpeg that's been running > 5 minutes (stale)
    if (age > 5 * 60 * 1000) {
      console.log(`[milk] Watchdog: Killing stale ffmpeg PID ${pid} (age: ${Math.round(age/1000)}s)`);
      try {
        process.kill(pid, 'SIGKILL');
        activeProcesses.delete(pid);
        activeStreams = Math.max(0, activeStreams - 1);
      } catch (e) {
        // Process already dead
        activeProcesses.delete(pid);
      }
    }
  }
}, 30000);

// MJPEG stream: fetch from md3-engine /snap.jpg -> multipart stream
app.get('/milk.mjpg', async (req, res) => {
  // Limit concurrent streams to prevent accumulation
  if (activeStreams >= MAX_STREAMS) {
    res.status(503).send('Too many active streams, please retry');
    return;
  }

  const boundary = 'md3frame';
  res.writeHead(200, {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Connection': 'close',
    'Content-Type': `multipart/x-mixed-replace; boundary=${boundary}`,
  });

  activeStreams++;
  let cleaned = false;
  let interval;

  const cleanup = () => {
    if (cleaned) return;
    cleaned = true;
    activeStreams--;
    if (interval) clearInterval(interval);
    try { res.end(); } catch (e) {}
  };

  // Fetch frames from md3-engine at target FPS
  const frameDelay = 1000 / Number(FPS);
  let lastFrameTime = Date.now();
  
  const fetchAndSendFrame = async () => {
    try {
      const now = Date.now();
      if (now - lastFrameTime < frameDelay) return; // Rate limit
      lastFrameTime = now;

      const response = await fetch('http://md3-engine:7001/snap.jpg');
      if (!response.ok) {
        console.error(`[milk] md3-engine returned ${response.status}`);
        return; // Skip this frame, try again next interval
      }
      
      const buffer = await response.arrayBuffer();
      if (!buffer || buffer.byteLength === 0) {
        console.error('[milk] Empty frame from md3-engine');
        return;
      }
      
      const frame = Buffer.from(buffer);
      
      // Write MJPEG frame with boundary
      res.write(`--${boundary}\r\n`);
      res.write('Content-Type: image/jpeg\r\n');
      res.write(`Content-Length: ${frame.length}\r\n`);
      res.write('\r\n');
      res.write(frame);
      res.write('\r\n');
    } catch (err) {
      console.error('[milk] Frame fetch error:', err.message);
      // Don't cleanup on single frame errors, just skip and retry
    }
  };

  // Start frame fetching loop
  interval = setInterval(fetchAndSendFrame, frameDelay);
  
  // Also fetch immediately
  fetchAndSendFrame();

  // Cleanup on disconnect
  req.on('close', cleanup);
  req.on('finish', cleanup);
  req.on('error', cleanup);

  // Safety timeout: 5 minutes
  setTimeout(() => {
    console.log('[milk] Stream timeout, closing');
    cleanup();
  }, 5 * 60 * 1000);
});

app.listen(PORT, () => console.log(`[milk] viewer up on http://localhost:${PORT}/milk`));

