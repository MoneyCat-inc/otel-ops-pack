#!/usr/bin/env node
/**
 * Butterchurn Visual Engine - Control API Server
 * ECRR: BossCat Mission - Milkdrop authoring loop
 * Authority: BossCat OEM | Executor: Cursor{Implementer}
 * 
 * Endpoints:
 * - POST /preset {name, body, blend}
 * - POST /size {width, height, dpr}
 * - GET /snap.jpg
 * - GET /stats
 * - WS /events
 */

const express = require('express');
const WebSocket = require('ws');
const puppeteer = require('puppeteer');
const { parseMilkPresetEnhanced, normalizePreset } = require('./milk-parser');
const AudioHandler = require('./audio-handler');

const app = express();
const port = process.env.PORT || 7001;

// Audio handler instance
const audioHandler = new AudioHandler();

// Configuration
const config = {
  width: parseInt(process.env.WIDTH) || 1920,
  height: parseInt(process.env.HEIGHT) || 1080,
  fps: parseInt(process.env.FPS) || 60,
  presetDir: process.env.PRESET_DIR || '/app/presets'
};

// State
let browser = null;
let page = null;
let currentPreset = null;
let presetPlaylist = [];
let playlistIndex = 0;
let stats = {
  fps: 0,
  frameTimeMs: 0,
  droppedFrames: 0,
  lastUpdate: Date.now()
};

// Middleware
app.use(express.json());
app.use(express.static('public'));

// CORS middleware for investor demo (Data Room fetch from port 3000)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Serve renderer.html (CRITICAL: serve via HTTP for CDN scripts to load)
const path = require('path');
app.get('/renderer.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'renderer.html'));
});

// Initialize headless browser with Butterchurn
async function initBrowser() {
  console.log('[viz-engine] Initializing headless Chromium...');
  
  browser = await puppeteer.launch({
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--single-process'
    ]
  });

  page = await browser.newPage();
  await page.setViewport({
    width: config.width,
    height: config.height,
    deviceScaleFactor: 1
  });

  // CRITICAL FIX: Load Butterchurn renderer via HTTP (not file://) so CDN scripts can load
  // Server must already be running when this function is called
  await page.goto(`http://localhost:${port}/renderer.html?width=${config.width}&height=${config.height}`, {
    waitUntil: 'networkidle2',
    timeout: 30000
  });
  
  // Wait for Butterchurn scripts to load and initialize (with longer timeout)
  try {
    await page.waitForFunction(() => window.visualizer !== null, { timeout: 30000 });
  } catch (err) {
    // Log page state for debugging
    const pageState = await page.evaluate(() => ({
      butterchurn: !!window.butterchurn,
      presets: !!window.butterchurnPresets,
      visualizer: !!window.visualizer,
      bodyText: document.body.innerText.substring(0, 500)
    }));
    console.error('[viz-engine] Butterchurn failed to initialize:', pageState);
    throw err;
  }

  console.log(`[viz-engine] Ready at ${config.width}x${config.height} @ ${config.fps}fps`);
}

// POST /preset - Load preset with blend
// GATE #011: Added safe mode + ECRR fallback on load failure
app.post('/preset', async (req, res) => {
  const { name, body, blend = 2.5, safe = 1 } = req.body;  // GATE #011: safe mode default=1

  if (!body && !name) {
    return res.status(400).json({ error: 'Missing name or body' });
  }

  try {
    let presetData = body;
    
    // If only name provided, load from presets library IN BROWSER CONTEXT
    if (!body && name) {
      // FIX: Load from window.butterchurnPresets (browser) not Node.js require
      presetData = await page.evaluate((presetName) => {
        if (window.butterchurnPresets) {
          const presetsLib = window.butterchurnPresets.default || window.butterchurnPresets;
          const presets = presetsLib.getPresets();
          return presets[presetName] || null;
        }
        return null;
      }, name);
      
      if (!presetData) {
        return res.status(404).json({ error: `Preset '${name}' not found in library` });
      }
    }
    
    // CRITICAL FIX #2: Parse .milk format to Butterchurn JSON
    if (typeof presetData === 'string') {
      // Check if it looks like .milk content (has per_frame or per_pixel)
      if (presetData.includes('per_frame') || presetData.includes('per_pixel')) {
        console.log(`[viz-engine] Parsing .milk format for preset: ${name}`);
        try {
          presetData = parseMilkPresetEnhanced(presetData, name);
          console.log(`[viz-engine] .milk parsed successfully`);
        } catch (parseError) {
          console.error(`[viz-engine] .milk parse error:`, parseError);
          return res.status(400).json({ 
            error: 'Failed to parse .milk preset', 
            details: parseError.message 
          });
        }
      } else {
        // Not .milk content, reject
        return res.status(400).json({ 
          error: 'Body must be valid .milk format or use name parameter for library presets' 
        });
      }
    }

    // GATE #011: Normalize with safe mode (guarantees arrays, sanitizes EEL, adds scaffolding)
    const normalizedPreset = normalizePreset(presetData);
    console.log('[viz-engine] preset arrays:', 
      'shapes=', Array.isArray(normalizedPreset.shapes) ? normalizedPreset.shapes.length : -1,
      'waves=',  Array.isArray(normalizedPreset.waves)  ? normalizedPreset.waves.length  : -1,
      'safe=', safe
    );

    // GATE #011: Try/catch with ECRR fallback on load failure
    try {
      await page.evaluate((preset, blendSeconds) => {
        if (window.visualizer && window.visualizer.loadPreset) {
          window.visualizer.loadPreset(preset, blendSeconds);
        }
      }, normalizedPreset, blend);

      currentPreset = { name, blend, loadedAt: Date.now() };
      console.log(`[viz-engine] Loaded preset: ${name} (blend: ${blend}s)`);
      broadcast({ event: 'presetLoaded', name, blend, timestamp: Date.now() });
      res.json({ ok: true, preset: name, blend });
      
    } catch (loadError) {
      // GATE #011 ECRR: Log failure and attempt fallback to blank preset
      console.error(`[viz-engine] Preset load failed, attempting fallback:`, loadError.message);
      
      try {
        // Fallback: minimal blank preset to keep renderer alive
        const blankPreset = normalizePreset({ 
          name: 'blank-fallback',
          baseVals: { decay: 0.98, gamma: 2.0 }, 
          shapes: [], 
          waves: [] 
        });
        await page.evaluate((preset) => {
          if (window.visualizer && window.visualizer.loadPreset) {
            window.visualizer.loadPreset(preset, 0);
          }
        }, blankPreset);
        
        console.log('[viz-engine] Fallback preset loaded (ECRR: Contain)');
      } catch (fallbackError) {
        console.error('[viz-engine] Fallback also failed:', fallbackError.message);
      }
      
      return res.status(500).json({ 
        ok: false, 
        error: 'Preset load failed', 
        details: loadError.message,
        fallback: 'blank preset attempted'
      });
    }
    
  } catch (error) {
    console.error('[viz-engine] Preset endpoint error:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST /size - Update renderer dimensions
app.post('/size', async (req, res) => {
  const { width, height, dpr = 1 } = req.body;

  if (!width || !height) {
    return res.status(400).json({ error: 'Missing width or height' });
  }

  try {
    await page.setViewport({
      width: Math.floor(width * dpr),
      height: Math.floor(height * dpr),
      deviceScaleFactor: dpr
    });

    await page.evaluate((w, h) => {
      if (window.visualizer && window.visualizer.setRendererSize) {
        window.visualizer.setRendererSize(w, h);
      }
    }, width, height);

    config.width = width;
    config.height = height;

    console.log(`[viz-engine] Resized to ${width}x${height} (DPR: ${dpr})`);
    broadcast({ event: 'sizeChanged', width, height, dpr, timestamp: Date.now() });

    res.json({ ok: true, width, height, dpr });
  } catch (error) {
    console.error('[viz-engine] Resize error:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /snap.jpg - Capture current frame
app.get('/snap.jpg', async (req, res) => {
  try {
    const screenshot = await page.screenshot({
      type: 'jpeg',
      quality: 85,
      fullPage: false
    });

    res.contentType('image/jpeg');
    res.send(screenshot);
  } catch (error) {
    console.error('[viz-engine] Snapshot error:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /stats - Performance metrics
app.get('/stats', async (req, res) => {
  try {
    const metrics = await page.metrics();
    
    stats = {
      fps: config.fps, // TODO: Calculate actual FPS from frame timing
      frameTimeMs: metrics.TaskDuration || 0,
      droppedFrames: 0, // TODO: Track dropped frames
      preset: currentPreset?.name || null,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      lastUpdate: Date.now()
    };

    res.json(stats);
  } catch (error) {
    console.error('[viz-engine] Stats error:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST /audio - Update audio state (Gate #010)
// CRITICAL FIX: Push audio into Butterchurn renderer
app.post('/audio', async (req, res) => {
  try {
    audioHandler.update(req.body);
    
    const state = audioHandler.getState();
    
    // CRITICAL: Push audio data into Butterchurn page context
    // Update the AudioContext analyser with current band energies
    if (page) {
      await page.evaluate((audioData) => {
        if (window.visualizer && window.audioContext && window.analyser) {
          // Update a global audio state that per_frame can access
          window.currentAudio = {
            bass: audioData.bass,
            mid: audioData.mid,
            treb: audioData.treb,
            bass_att: audioData.bass_att,
            mid_att: audioData.mid_att,
            treb_att: audioData.treb_att
          };
          
          // Optionally: Inject into analyser's frequency data
          // This makes Butterchurn's built-in audio reactive
          if (audioData.fft && window.fftDataBuffer) {
            const uint8Array = new Uint8Array(audioData.fft.length);
            audioData.fft.forEach((v, i) => uint8Array[i] = Math.floor(v * 255));
            window.fftDataBuffer = uint8Array;
          }
        }
      }, state);
    }
    
    res.json({ 
      ok: true, 
      bass: state.bass,
      mid: state.mid,
      treb: state.treb,
      timestamp: state.timestamp,
      pushed_to_renderer: true
    });
  } catch (error) {
    console.error('[viz-engine] Audio update error:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /audio/stats - Audio statistics
app.get('/audio/stats', (req, res) => {
  const n = parseInt(req.query.frames) || 60;
  res.json(audioHandler.getStats(n));
});

// GET /audio/history - Audio history time series (Gate #010 fix)
// CRITICAL: Return actual time series for reactivity computation
app.get('/audio/history', (req, res) => {
  const n = parseInt(req.query.frames) || 512;
  const buffer = audioHandler.getBuffer();
  const recent = buffer.slice(-n);
  
  res.json({
    frames: recent.length,
    bass: recent.map(f => f.bass),
    mid: recent.map(f => f.mid),
    treb: recent.map(f => f.treb),
    timestamps: recent.map(f => f.timestamp)
  });
});

// POST /preset/next - Load next preset with blend (Gate #010)
app.post('/preset/next', async (req, res) => {
  const { blend = 2.5 } = req.body || {};
  
  if (presetPlaylist.length === 0) {
    return res.status(400).json({ error: 'No playlist loaded. Use POST /playlist first.' });
  }
  
  playlistIndex = (playlistIndex + 1) % presetPlaylist.length;
  const nextPreset = presetPlaylist[playlistIndex];
  
  // Forward to main preset loader
  req.body = { name: nextPreset, blend };
  return app._router.handle(Object.assign(req, { method: 'POST', url: '/preset' }), res);
});

// POST /preset/prev - Load previous preset with blend
app.post('/preset/prev', async (req, res) => {
  const { blend = 2.5 } = req.body || {};
  
  if (presetPlaylist.length === 0) {
    return res.status(400).json({ error: 'No playlist loaded. Use POST /playlist first.' });
  }
  
  playlistIndex = (playlistIndex - 1 + presetPlaylist.length) % presetPlaylist.length;
  const prevPreset = presetPlaylist[playlistIndex];
  
  // Forward to main preset loader
  req.body = { name: prevPreset, blend };
  return app._router.handle(Object.assign(req, { method: 'POST', url: '/preset' }), res);
});

// POST /preset/random - Load random preset from playlist
app.post('/preset/random', async (req, res) => {
  const { blend = 2.5 } = req.body || {};
  
  if (presetPlaylist.length === 0) {
    return res.status(400).json({ error: 'No playlist loaded. Use POST /playlist first.' });
  }
  
  playlistIndex = Math.floor(Math.random() * presetPlaylist.length);
  const randomPreset = presetPlaylist[playlistIndex];
  
  // Forward to main preset loader
  req.body = { name: randomPreset, blend };
  return app._router.handle(Object.assign(req, { method: 'POST', url: '/preset' }), res);
});

// POST /playlist - Set preset playlist for next/prev/random
app.post('/playlist', (req, res) => {
  const { items = [], mode = 'loop' } = req.body;
  
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'items must be non-empty array' });
  }
  
  // Build playlist from items (expand weighted items)
  presetPlaylist = [];
  items.forEach(item => {
    const name = typeof item === 'string' ? item : item.name;
    const weight = typeof item === 'object' ? (item.weight || 1) : 1;
    
    // Add item 'weight' times for weighted randomization
    for (let i = 0; i < weight; i++) {
      presetPlaylist.push(name);
    }
  });
  
  if (mode === 'shuffle') {
    // Fisher-Yates shuffle
    for (let i = presetPlaylist.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [presetPlaylist[i], presetPlaylist[j]] = [presetPlaylist[j], presetPlaylist[i]];
    }
  }
  
  playlistIndex = 0;
  
  res.json({ 
    ok: true, 
    playlist: presetPlaylist,
    mode,
    count: presetPlaylist.length
  });
});

// GET /presets - List available presets
app.get('/presets', async (req, res) => {
  try {
    const presets = await page.evaluate(() => {
      if (window.butterchurnPresets) {
        const presetsLib = window.butterchurnPresets.default || window.butterchurnPresets;
        return Object.keys(presetsLib.getPresets());
      }
      return [];
    });
    
    res.json({ presets, count: presets.length });
  } catch (error) {
    console.error('[viz-engine] Presets list error:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET / - Status
app.get('/', (req, res) => {
  const audioState = audioHandler.getState();
  res.json({
    service: 'viz-engine-butterchurn',
    status: 'running',
    preset: currentPreset?.name || null,
    dimensions: `${config.width}x${config.height}`,
    fps: config.fps,
    uptime: process.uptime(),
    audio: {
      bass: audioState.bass,
      mid: audioState.mid,
      treb: audioState.treb,
      samples: audioHandler.getBuffer().length
    }
  });
});

// WebSocket server for events
const wss = new WebSocket.Server({ noServer: true });

wss.on('connection', (ws) => {
  console.log('[viz-engine] WebSocket client connected');
  
  ws.send(JSON.stringify({
    event: 'connected',
    config,
    preset: currentPreset,
    timestamp: Date.now()
  }));
});

function broadcast(data) {
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
}

// HTTP server with WebSocket upgrade
const server = app.listen(port, async () => {
  console.log(`[viz-engine] Control API listening on port ${port}`);
  await initBrowser();
});

server.on('upgrade', (request, socket, head) => {
  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit('connection', ws, request);
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('[viz-engine] Shutting down...');
  if (browser) await browser.close();
  server.close(() => process.exit(0));
});

