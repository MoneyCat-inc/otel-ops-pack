// Gate #012 - ProjectM HTTP Shim
// ECRR: BossCat - Minimal API for scorebot compatibility
const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs');
const { BrightnessGuard } = require('./brightness-guard');

const app = express();
app.use(express.json({ limit: '5mb' }));

const PORT = process.env.PORT || 7020;  // Gate #012: ProjectM on port 7020
const DISPLAY = process.env.DISPLAY || ':99';
const PM_WIDTH = process.env.PM_WIDTH || '1920';
const PM_HEIGHT = process.env.PM_HEIGHT || '1080';
const PM_FPS = process.env.PM_FPS || '30';
const PM_PRESET_DIR = process.env.PM_PRESET_DIR || '/app/presets';
const PM_AUDIO_FIFO = process.env.PM_AUDIO_FIFO || '/tmp/pm-audio.pcm';
const AUDIO_PATH = process.env.AUDIO_PATH || 'pulse';

let pmProc = null;
let currentPreset = null;
let stats = {
  width: Number(PM_WIDTH),
  height: Number(PM_HEIGHT),
  fps: Number(PM_FPS),
  engine: 'projectm',
  preset: null,
  uptime: 0
};

// Gate #013: Audio stats tracking
let audioStats = {
  samples: 0,
  rms: 0,
  peak: 0,
  ema: 0,
  lastUpdate: Date.now()
};
const EMA_ALPHA = 0.1;  // Exponential moving average smoothing
let audioFifoStream = null;

// Gate #016: Brightness guard
const brightnessGuard = new BrightnessGuard({
  lMin: parseFloat(process.env.GUARD_LMIN || '0.07'),
  guardWindowMs: parseInt(process.env.GUARD_WINDOW_MS || '120'),
  guardMode: process.env.GUARD_MODE || 'auto_switch',
  enabled: process.env.GUARD_ENABLED !== 'false'
});

// Ensure presets directory exists
fs.mkdirSync(PM_PRESET_DIR, { recursive: true });

// Launch ProjectM SDL process
function launchProjectM() {
  if (pmProc) {
    console.log('[pm-spawn] ProjectM already running, pid:', pmProc.pid);
    return;
  }
  
  console.log('[pm-spawn] Launching projectMSDL...');
  console.log('[pm-spawn] Display:', DISPLAY);
  console.log('[pm-spawn] Resolution:', `${PM_WIDTH}x${PM_HEIGHT}`);
  console.log('[pm-spawn] Presets:', PM_PRESET_DIR);
  
  // Spawn ProjectM SDL (assumes it's in PATH from cmake install)
  pmProc = spawn('projectMSDL', ['--preset-path', PM_PRESET_DIR, '--fps', PM_FPS, '--width', PM_WIDTH, '--height', PM_HEIGHT], {
    env: { ...process.env, DISPLAY },
    stdio: ['ignore', 'pipe', 'pipe']
  });
  
  pmProc.stdout.on('data', (data) => {
    console.log(`[projectm] ${data.toString().trim()}`);
  });
  
  pmProc.stderr.on('data', (data) => {
    console.error(`[projectm] ${data.toString().trim()}`);
  });
  
  pmProc.on('exit', (code, signal) => {
    console.log(`[pm-spawn] ProjectM exited: code=${code}, signal=${signal}`);
    pmProc = null;
  });
  
  console.log('[pm-spawn] ProjectM launched, pid:', pmProc.pid);
}

// Launch ProjectM on startup (give Xvfb time to initialize)
setTimeout(() => {
  launchProjectM();
}, 3000);

// Health (Job 1 deliverable)
app.get('/health', (_req, res) => {
  res.json({ 
    ok: true, 
    engine: 'projectm',
    display: DISPLAY,
    pid: pmProc ? pmProc.pid : null
  });
});

// Stats (Job 1 deliverable)
app.get('/stats', (_req, res) => {
  stats.uptime = process.uptime();
  stats.preset = currentPreset;
  res.json(stats);
});

// Gate #012 Job 2: Preset control + visual validation
const { exec } = require('child_process');
const { promisify } = require('util');
const { readdirSync, statSync } = require('fs');
const path = require('path');

const sh = promisify(exec);
const XENV = { DISPLAY };
const PM_WIN_CLASS = process.env.PM_WIN_CLASS || 'projectM';
let cachedWin = null;

// Find ProjectM window ID
async function findWin() {
  if (cachedWin) return cachedWin;
  try {
    const { stdout } = await sh(`xdotool search --class ${PM_WIN_CLASS}`, { env: XENV });
    cachedWin = stdout.trim().split('\n').filter(Boolean).pop();
    return cachedWin;
  } catch (e) {
    return null;
  }
}

// Send key to ProjectM window
async function sendKey(key) {
  const win = await findWin();
  if (!win) throw new Error('ProjectM window not found');
  await sh(`xdotool key --window ${win} ${key}`, { env: XENV });
}

// List .milk files in directory (recursive)
function listMilk(dir) {
  const out = [];
  function walk(d) {
    try {
      for (const f of readdirSync(d)) {
        const p = path.join(d, f);
        if (statSync(p).isDirectory()) walk(p);
        else if (p.toLowerCase().endsWith('.milk')) out.push(path.relative(dir, p));
      }
    } catch (e) {
      // Directory doesn't exist or not readable
    }
  }
  walk(dir);
  return out.sort();
}

// GET /pm/presets - List available presets
app.get('/pm/presets', (req, res) => {
  const root = PM_PRESET_DIR;
  const presets = listMilk(root);
  res.json({ presets, count: presets.length });
});

// POST /pm/next - Next preset
app.post('/pm/next', async (req, res) => {
  try {
    await sendKey('n');
    res.json({ ok: true, action: 'next' });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

// POST /pm/prev - Previous preset
app.post('/pm/prev', async (req, res) => {
  try {
    await sendKey('p');
    res.json({ ok: true, action: 'prev' });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

// POST /pm/random - Random preset
app.post('/pm/random', async (req, res) => {
  try {
    await sendKey('r');
    res.json({ ok: true, action: 'random' });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

// POST /pm/preset - Load specific preset by name
app.post('/pm/preset', async (req, res) => {
  const { name } = req.body || {};
  if (!name) return res.status(400).json({ ok: false, error: 'name required' });
  
  const root = PM_PRESET_DIR;
  const all = listMilk(root);
  const idx = all.findIndex(p => p === name || p.endsWith('/' + name) || p.endsWith(name));
  
  if (idx === -1) {
    return res.status(404).json({ ok: false, error: `preset not found: ${name}` });
  }
  
  try {
    // Quick hop strategy: random + next steps (bounded)
    await sendKey('r');
    for (let i = 0; i < Math.min(15, idx + 2); i++) {
      await sendKey('n');
      await new Promise(r => setTimeout(r, 50));  // Small delay between keys
    }
    currentPreset = all[idx];
    res.json({ ok: true, preset: all[idx], index: idx });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

// GET /snap.jpg - Capture current frame
app.get('/snap.jpg', async (req, res) => {
  try {
    const cmd = `xwd -display ${DISPLAY} -root -silent | convert xwd:- -quality 90 jpg:-`;
    const child = exec(cmd, { env: XENV, maxBuffer: 10 * 1024 * 1024 });
    res.setHeader('Content-Type', 'image/jpeg');
    child.stdout.pipe(res);
    child.on('error', (e) => {
      console.error('[snap] capture error:', e);
      if (!res.headersSent) res.status(500).json({ error: String(e) });
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// GET /pm/metrics - Fast local luminance check with brightness guard
app.get('/pm/metrics', async (req, res) => {
  try {
    const { stdout } = await sh(
      `xwd -display ${DISPLAY} -root -silent | convert xwd:- -colorspace Gray -format "%[fx:mean]" info:`,
      { env: XENV, timeout: 5000 }
    );
    const mean = parseFloat(stdout.trim()) || 0;
    const nonBlackPct = Math.round(mean * 100);
    
    // Gate #016: Feed luma to brightness guard
    const guardResult = brightnessGuard.checkFrame(mean);
    
    // If guard triggered and mode is auto_switch, trigger preset change
    if (guardResult.triggered && guardResult.mode === 'auto_switch') {
      console.log('[pm-metrics] Brightness guard triggered auto-switch');
      // Trigger async (don't block response)
      sendKey('n').catch(e => console.error('[pm-metrics] Auto-switch failed:', e));
    }
    
    res.json({ 
      ok: true, 
      mean_luma: mean, 
      non_black_pct: nonBlackPct,
      guard: guardResult
    });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

// Gate #013: Audio endpoints
// POST /audio - Accept PCM audio data and feed to FIFO
app.post('/audio', (req, res) => {
  if (AUDIO_PATH !== 'pulse') {
    return res.status(503).json({ ok: false, error: 'Audio path not configured for pulse' });
  }
  
  try {
    let pcmData;
    
    // Accept either raw PCM body or JSON with base64
    if (req.is('application/octet-stream') || req.is('audio/pcm')) {
      pcmData = req.body;
    } else if (req.body && req.body.base64) {
      pcmData = Buffer.from(req.body.base64, 'base64');
    } else {
      return res.status(400).json({ ok: false, error: 'Expected raw PCM or JSON with base64 field' });
    }
    
    // Calculate audio stats (RMS, peak, EMA)
    if (pcmData && pcmData.length >= 2) {
      const samples = pcmData.length / 2;  // s16le = 2 bytes per sample
      let sumSquares = 0;
      let peak = 0;
      
      for (let i = 0; i < pcmData.length; i += 2) {
        const sample = pcmData.readInt16LE(i) / 32768.0;  // Normalize to [-1, 1]
        const absSample = Math.abs(sample);
        sumSquares += sample * sample;
        if (absSample > peak) peak = absSample;
      }
      
      const rms = Math.sqrt(sumSquares / samples);
      audioStats.rms = rms;
      audioStats.peak = peak;
      audioStats.ema = audioStats.ema * (1 - EMA_ALPHA) + rms * EMA_ALPHA;
      audioStats.samples += samples;
      audioStats.lastUpdate = Date.now();
    }
    
    // Write to FIFO (non-blocking)
    if (!audioFifoStream) {
      audioFifoStream = fs.createWriteStream(PM_AUDIO_FIFO, { flags: 'a' });
      audioFifoStream.on('error', (err) => {
        console.error('[audio] FIFO write error:', err);
        audioFifoStream = null;
      });
    }
    
    if (audioFifoStream) {
      audioFifoStream.write(pcmData);
    }
    
    res.json({ ok: true, bytes: pcmData.length, samples: pcmData.length / 2 });
  } catch (e) {
    console.error('[audio] Error processing audio:', e);
    res.status(500).json({ ok: false, error: String(e) });
  }
});

// GET /audio/stats - Return rolling audio stats
app.get('/audio/stats', (req, res) => {
  res.json({
    ok: true,
    ...audioStats,
    age_ms: Date.now() - audioStats.lastUpdate
  });
});

// Gate #016: Brightness guard endpoints
// GET /guard/stats - Return brightness guard statistics
app.get('/guard/stats', (req, res) => {
  res.json({ ok: true, ...brightnessGuard.getStats() });
});

// POST /guard/reset - Reset brightness guard statistics
app.post('/guard/reset', (req, res) => {
  brightnessGuard.reset();
  res.json({ ok: true, message: 'Brightness guard statistics reset' });
});

// Start HTTP server (Job 2 complete)
app.listen(PORT, () => {
  console.log(`[pm-api] ProjectM HTTP API listening on port ${PORT}`);
  console.log(`[pm-api] Display: ${DISPLAY}, Size: ${PM_WIDTH}x${PM_HEIGHT}`);
  console.log(`[pm-api] Endpoints: /health, /stats, /pm/presets, /pm/next, /pm/prev, /pm/random, /pm/preset, /snap.jpg, /pm/metrics, /audio, /audio/stats, /guard/stats, /guard/reset`);
  console.log(`[pm-api] Audio path: ${AUDIO_PATH}, FIFO: ${PM_AUDIO_FIFO}`);
  console.log(`[pm-api] Brightness guard: L_min=${brightnessGuard.lMin}, window=${brightnessGuard.guardWindowMs}ms, mode=${brightnessGuard.guardMode}`);
  console.log(`[pm-api] Ready for preset authoring + scorebot validation`);
});

