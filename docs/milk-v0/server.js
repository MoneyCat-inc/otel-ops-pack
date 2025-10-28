// /opt/viz/server.js
// Gate #011 - Milk v0 Viewer HTTP Server
// Rollback: x11grab from pm-engine (with GPU acceleration for lower CPU)
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

// MJPEG stream: ffmpeg x11grab -> mpjpeg muxer -> direct pipe
app.get('/milk.mjpg', (req, res) => {
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
    '-pix_fmt', 'yuvj420p',
    '-r', FPS,
    '-vsync', 'cfr',  // Constant frame rate
    '-preset', 'ultrafast',
    '-tune', 'zerolatency',
    '-f', 'mpjpeg',
    '-boundary_tag', boundary,
    'pipe:1'
  ]);

  ff.stdout.pipe(res);

  const cleanup = () => {
    try { ff.kill('SIGKILL'); } catch (e) {}
    try { res.end(); } catch (e) {}
  };
  
  req.on('close', cleanup);
  req.on('finish', cleanup);
  req.on('error', cleanup);
  ff.on('close', () => { try { res.end(); } catch (e) {} });
});

app.listen(PORT, () => console.log(`[milk] viewer up on http://localhost:${PORT}/milk`));

