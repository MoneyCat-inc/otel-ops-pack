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
    '-video_size', GEOMETRY,
    '-framerate', FPS,
    '-f', 'x11grab', '-i', `${DISPLAY}.0`,
    '-vf', `fps=${FPS}`,
    '-an',
    '-c:v', 'mjpeg',
    '-q:v', '5',
    '-f', 'mpjpeg',
    '-boundary_tag', boundary,
    'pipe:1'
  ]);

  ff.stdout.pipe(res);

  const end = () => { try { ff.kill('SIGINT'); } catch (e) {} };
  req.on('close', end);
  req.on('finish', end);
  ff.on('close', () => { try { res.end(); } catch (e) {} });
});

app.listen(PORT, () => console.log(`[milk] viewer up on http://localhost:${PORT}/milk`));

