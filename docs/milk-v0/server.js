// /opt/viz/server.js
// Gate #011 - Milk v0 Viewer HTTP Server
const express = require('express');
const { spawn } = require('child_process');
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
  display: DISPLAY, 
  geometry: GEOMETRY, 
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

// MJPEG stream: ffmpeg x11grab -> mpjpeg muxer -> direct pipe
app.get('/milk.mjpg', (req, res) => {
  // Limit concurrent streams to prevent process accumulation
  if (activeStreams >= MAX_STREAMS) {
    res.status(503).send('Too many active streams, please retry');
    return;
  }

  const boundary = 'ffmjpeg';
  res.writeHead(200, {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Connection': 'close',
    'Content-Type': `multipart/x-mixed-replace; boundary=${boundary}`,
  });

  const ff = spawn('ffmpeg', [
    '-hide_banner', '-loglevel', 'error',
    '-f', 'x11grab',
    '-video_size', GEOMETRY,
    '-framerate', FPS,
    '-i', `${DISPLAY}.0`,
    '-c:v', 'mjpeg',
    '-q:v', '15',  // Fast streaming quality
    '-pix_fmt', 'yuvj420p',  // MJPEG color space
    '-r', FPS,  // Output frame rate
    '-vsync', 'cfr',  // Constant frame rate
    '-preset', 'ultrafast',  // Prioritize speed over compression
    '-tune', 'zerolatency',  // Minimize buffering
    '-f', 'mpjpeg',
    '-boundary_tag', boundary,
    'pipe:1'
  ]);

  activeStreams++;
  activeProcesses.set(ff.pid, Date.now());  // Register for watchdog
  let cleaned = false;

  const cleanup = () => {
    if (cleaned) return;
    cleaned = true;
    activeStreams--;
    activeProcesses.delete(ff.pid);  // Unregister from watchdog
    
    try {
      if (!ff.killed) {
        ff.kill('SIGKILL');  // Force kill immediately (SIGINT too gentle)
      }
    } catch (e) {
      console.error('[milk] Cleanup error:', e.message);
    }
    
    try { res.end(); } catch (e) {}
  };

  // Pipe with error handling
  ff.stdout.on('error', cleanup);
  ff.stdout.pipe(res);

  // Cleanup on all disconnect events
  req.on('close', cleanup);
  req.on('finish', cleanup);
  req.on('error', cleanup);
  ff.on('close', cleanup);
  ff.on('error', cleanup);

  // Safety timeout: kill after 5 minutes
  const timeout = setTimeout(() => {
    console.log('[milk] Stream timeout, killing ffmpeg');
    cleanup();
  }, 5 * 60 * 1000);
  
  req.on('close', () => clearTimeout(timeout));
});

app.listen(PORT, () => console.log(`[milk] viewer up on http://localhost:${PORT}/milk`));

