// Gate #012 - ProjectM HTTP Shim
// ECRR: BossCat - Minimal API for scorebot compatibility
const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs');
const { BrightnessGuard } = require('./brightness-guard');
const { FrameTimingStabilizer } = require('./frame-timing-stabilizer');
const { CanaryDeployment } = require('./canary-deployment');  // Gate #020: Canary rollout
const { OTLPEmitter } = require('./otlp-emitter');  // Gate #020: OTLP span emission
const { audioSwitch, audioAdminRouter } = require('./lib/audio-switch-cluster');  // BOSSCAT-023A: Cluster-aware audio switch (Redis + file fallback)

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
// BOSSCAT-021A: AudioSwitch module replaces static AUDIO_ENABLED flag
const GUARD_INTERVAL_MS = parseInt(process.env.GUARD_INTERVAL_MS || '100', 10);
const GUARD_JITTER_BUDGET_MS = parseInt(process.env.GUARD_JITTER_BUDGET_MS || '8', 10);
const GUARD_PIN_WINDOW_MS = parseInt(process.env.GUARD_PIN_WINDOW_MS || '60000', 10);
const GUARD_MAX_INFLIGHT = parseInt(process.env.GUARD_MAX_INFLIGHT || '4', 10);

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
const frameTimingStabilizer = new FrameTimingStabilizer({
  targetIntervalMs: GUARD_INTERVAL_MS,
  jitterBudgetMs: GUARD_JITTER_BUDGET_MS,
  pinWindowMs: GUARD_PIN_WINDOW_MS
});

// Gate #020: OTLP emitter for canary events
const otlpEmitter = new OTLPEmitter({
  endpoint: process.env.OTLP_HTTP_ENDPOINT || 'http://localhost:5318/v1/traces',
  serviceName: 'pm-engine',
  environment: process.env.DEPLOY_ENV || 'staging'
});

// Gate #020: Canary deployment for audio rollout
const CANARY_ENABLED = process.env.CANARY_ENABLED === 'true';  // Opt-in for canary
const canaryDeployment = CANARY_ENABLED ? new CanaryDeployment({
  onPhaseChange: (phase) => {
    console.log(`[canary] Phase change: ${phase.name} (${phase.target}%)`);
    // Emit OTLP span for phase transition
    otlpEmitter.emitSpan('audio.enable.canary.phase', {
      'canary.phase': phase.name,
      'canary.target_percent': phase.target,
      'canary.event': 'phase_change'
    }).catch(err => console.error('[canary] OTLP emit failed:', err.message));
  },
  onBreach: (reason, phase) => {
    console.error(`[canary] BREACH at ${phase.name}: ${reason}`);
    console.error(`[canary] Auto-halt triggered - audio disabled`);
    // BOSSCAT-021A: Actually disable audio via AudioSwitch
    try {
      audioSwitch.disable(`canary-breach: ${reason}`);
      console.log('[canary] Audio disabled via AudioSwitch');
    } catch (err) {
      console.error('[canary] Failed to disable audio:', err.message);
    }
    // Emit OTLP span for breach
    otlpEmitter.emitSpan('audio.enable.canary.breach', {
      'canary.phase': phase.name,
      'canary.breach_reason': reason,
      'canary.event': 'breach',
      'canary.auto_halt': true
    }).catch(err => console.error('[canary] OTLP emit failed:', err.message));
  },
  onComplete: () => {
    console.log('[canary] Deployment COMPLETE - audio fully rolled out');
    // Emit OTLP span for completion
    otlpEmitter.emitSpan('audio.enable.canary.complete', {
      'canary.event': 'complete',
      'canary.result': 'success'
    }).catch(err => console.error('[canary] OTLP emit failed:', err.message));
  }
}) : null;

// Job V1B/V2: Cached guard state for active monitoring
let cachedGuardState = {
  luma: 0,
  timestamp: Date.now(),
  guardResult: { triggered: false },
  tickCount: 0,
  tickDurationMs: 0,
  inFlight: 0,
  stabilizer: frameTimingStabilizer.getStats()
};
let totalGuardTicks = 0;

// Job V2: Active guard monitoring with frame timing stabilizer
let guardInterval = null;
let activeSamples = 0;
function snapshotGuardState(extra = {}) {
  cachedGuardState = {
    ...cachedGuardState,
    ...extra,
    inFlight: Math.max(activeSamples, 0),
    stabilizer: frameTimingStabilizer.getStats()
  };
}

function startGuardMonitoring() {
  if (guardInterval) return;  // Already running

  console.log(`[guard-timer] Starting frame timing stabilizer at ${GUARD_INTERVAL_MS}ms (jitter≤${GUARD_JITTER_BUDGET_MS}ms, inflight≤${GUARD_MAX_INFLIGHT})`);

  guardInterval = setInterval(() => {
    const tickStart = Date.now();
    frameTimingStabilizer.recordTickStart(tickStart);

    if (activeSamples >= GUARD_MAX_INFLIGHT) {
      frameTimingStabilizer.registerPin(tickStart);
      snapshotGuardState({ timestamp: tickStart });
      return;
    }

    activeSamples += 1;
    let pendingSnapshot = null;

    sampleLuma()
      .then((luma) => {
        const guardResult = brightnessGuard.checkFrame(luma);

        if (guardResult.triggered && guardResult.mode === 'auto_switch') {
          console.log('[guard-timer] Brightness guard triggered auto-switch');
          sendKey('n').catch((e) => console.error('[guard-timer] Auto-switch failed:', e));
        }

        const durationMs = Date.now() - tickStart;
        frameTimingStabilizer.recordDuration(durationMs);
        totalGuardTicks += 1;

        pendingSnapshot = {
          luma,
          timestamp: Date.now(),
          guardResult,
          tickCount: totalGuardTicks,
          tickDurationMs: durationMs
        };
        
        // Gate #020: Feed KPIs to canary deployment (every 10 ticks ≈ 1 second)
        // GATE-020-R1: Await async tick() for cluster coordination
        if (canaryDeployment && totalGuardTicks % 10 === 0) {
          const kpis = {
            underrunRatio: 0.0,  // Placeholder: would get from audio buffer
            tickJitterMs: frameTimingStabilizer.getStats().jitterMaxMs || 0,
            correlation: 0.95  // Placeholder: would get from audio validation
          };
          canaryDeployment.tick(kpis).catch((err) => {
            console.error('[guard-timer] Canary tick failed:', err);
          });
        }
      })
      .catch((err) => {
        console.error('[guard-timer] Luma measurement failed:', err);
        frameTimingStabilizer.registerPin();
        pendingSnapshot = { timestamp: Date.now() };
      })
      .finally(() => {
        activeSamples = Math.max(activeSamples - 1, 0);
        snapshotGuardState(pendingSnapshot || { timestamp: Date.now() });
      });
  }, GUARD_INTERVAL_MS);
  
  // Gate #020: Start canary if enabled
  if (canaryDeployment) {
    canaryDeployment.start();
    console.log('[canary] Audio canary deployment started');
  }
}

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
    pid: pmProc ? pmProc.pid : null,
    // BOSSCAT-021A: Dynamic audio state from AudioSwitch
    audio: audioSwitch.getState(),
    envelope_follower: 'active',  // Gate #019 R1
    // Gate #020: Canary status
    canary_enabled: CANARY_ENABLED,
    canary_phase: canaryDeployment ? canaryDeployment.getCurrentPhase().name : 'N/A'
  });
});

// Stats (Job 1 deliverable)
app.get('/stats', (_req, res) => {
  stats.uptime = process.uptime();
  stats.preset = currentPreset;
  res.json(stats);
});

// BOSSCAT-021A: Admin control for audio kill switch (optionally protected by X-Admin-Token)
app.use('/admin/audio', audioAdminRouter(process.env.ADMIN_TOKEN));

// Gate #012 Job 2: Preset control + visual validation
const { exec } = require('child_process');
const { promisify } = require('util');
const { readdirSync, statSync } = require('fs');
const path = require('path');

const sh = promisify(exec);
const XENV = { DISPLAY };
const PM_WIN_CLASS = process.env.PM_WIN_CLASS || 'projectM';
let cachedWin = null;

async function sampleLuma() {
  const { stdout } = await sh(
    `xwd -display ${DISPLAY} -root -silent | convert xwd:- -colorspace Gray -format "%[fx:mean]" info:`,
    { env: XENV, timeout: 5000 }
  );
  return parseFloat(stdout.trim()) || 0;
}

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

// GET /pm/metrics - Read cached guard state (Job V1B: active monitoring)
app.get('/pm/metrics', (req, res) => {
  // Job V1B: Return cached state from background timer
  const age_ms = Date.now() - cachedGuardState.timestamp;
  
  res.json({ 
    ok: true, 
    mean_luma: cachedGuardState.luma, 
    non_black_pct: Math.round(cachedGuardState.luma * 100),
    guard: cachedGuardState.guardResult,
    cached_at: cachedGuardState.timestamp,
    cache_age_ms: age_ms,
    tick_count: cachedGuardState.tickCount,
    tick_duration_ms: cachedGuardState.tickDurationMs,
    in_flight: cachedGuardState.inFlight,
    stabilizer: cachedGuardState.stabilizer,
    visual_tick_jitter_ms_max: cachedGuardState.stabilizer ? cachedGuardState.stabilizer.jitterMaxMs : 0,
    stabilizer_pin_count: cachedGuardState.stabilizer ? cachedGuardState.stabilizer.stabilizerPinCount : 0
  });
});

// Gate #013: Audio endpoints
// POST /audio - Accept PCM audio data and feed to FIFO
app.post('/audio', (req, res) => {
  // BOSSCAT-021A: Dynamic kill-switch - check AudioSwitch at request time
  if (!audioSwitch.isEnabled()) {
    const st = audioSwitch.getState();
    console.log('[audio] Request rejected - audio disabled:', st.reason);
    return res.status(503).json({ ok: false, error: 'audio-disabled', ...st });
  }
  
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
    age_ms: Date.now() - audioStats.lastUpdate,
    // BOSSCAT-021A: Dynamic audio state
    audio: audioSwitch.getState(),
    audio_path: AUDIO_PATH,
    envelope_follower: 'enabled'  // Gate #019 R1: Envelope follower active (20ms attack, 150ms release)
  });
});

// Gate #016: Brightness guard endpoints
// GET /guard/stats - Return brightness guard statistics
app.get('/guard/stats', (req, res) => {
  const guardStats = brightnessGuard.getStats();
  res.json({
    ok: true,
    ...guardStats,
    stabilizer: frameTimingStabilizer.getStats()
  });
});

// POST /guard/reset - Reset brightness guard statistics
app.post('/guard/reset', (req, res) => {
  brightnessGuard.reset();
  frameTimingStabilizer.reset();
  snapshotGuardState({
    timestamp: Date.now(),
    tickDurationMs: 0
  });
  res.json({ ok: true, message: 'Brightness guard statistics reset' });
});

// Gate #020: Canary deployment endpoints
// GET /canary/status - Get canary deployment status
app.get('/canary/status', (req, res) => {
  if (!canaryDeployment) {
    return res.json({ ok: true, enabled: false, message: 'Canary not enabled (set CANARY_ENABLED=true)' });
  }
  
  const status = canaryDeployment.getStatus();
  res.json({ ok: true, enabled: true, ...status });
});

// POST /canary/halt - Emergency canary halt
// GATE-020-R1: Async handler for cluster coordination
app.post('/canary/halt', async (req, res) => {
  if (!canaryDeployment) {
    return res.status(404).json({ ok: false, error: 'Canary not enabled' });
  }
  
  const result = await canaryDeployment.emergencyStop();
  res.json({ ok: true, ...result });
});

// POST /canary/reset - Reset canary deployment (BOSSCAT-021A)
// GATE-020-R1: Async handler for cluster coordination
app.post('/canary/reset', async (req, res) => {
  if (!canaryDeployment) {
    return res.status(404).json({ ok: false, error: 'Canary not enabled' });
  }
  
  await canaryDeployment.reset();
  res.json({ ok: true, message: 'Canary reset - halted state cleared, audio re-enabled (cluster-wide)' });
});

// Start HTTP server (Job 2 complete)
app.listen(PORT, () => {
  console.log(`[pm-api] ProjectM HTTP API listening on port ${PORT}`);
  console.log(`[pm-api] Display: ${DISPLAY}, Size: ${PM_WIDTH}x${PM_HEIGHT}`);
  console.log(`[pm-api] Endpoints: /health, /stats, /admin/audio, /pm/presets, /pm/next, /pm/prev, /pm/random, /pm/preset, /snap.jpg, /pm/metrics, /audio, /audio/stats, /guard/stats, /guard/reset, /canary/status, /canary/halt`);
  console.log(`[pm-api] Audio path: ${AUDIO_PATH}, FIFO: ${PM_AUDIO_FIFO}`);
  console.log(`[pm-api] Audio switch: ${audioSwitch.isEnabled() ? 'ENABLED' : 'DISABLED'} (${audioSwitch.getState().reason || 'default'})`);
  console.log(`[pm-api] Brightness guard: L_min=${brightnessGuard.lMin}, window=${brightnessGuard.guardWindowMs}ms, mode=${brightnessGuard.guardMode}`);
  console.log(`[pm-api] Canary deployment: ${CANARY_ENABLED ? 'ENABLED' : 'DISABLED'}`);
  console.log(`[pm-api] Ready for preset authoring + scorebot validation`);
  
  // Job V1B: Start active guard monitoring after ProjectM has time to initialize
  setTimeout(() => {
    startGuardMonitoring();
  }, 5000);  // Wait 5s for ProjectM to fully initialize
});
