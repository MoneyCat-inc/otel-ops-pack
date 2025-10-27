// BOSSCAT-023A: Distributed AudioSwitch (Cluster-Aware)
// BOSSCAT-025A: Performance-Optimized (Gate #025 Track A)
// Authority: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Cluster-wide audio gating with Redis pub/sub + file-based fallback

const express = require('express');
const { audioSwitch: localSwitch } = require('./audio-switch'); // BOSSCAT-021A (file-based)
const { createClient } = require('redis');
const { performance } = require('node:perf_hooks'); // Gate #025: monotonic timing

const REDIS_URL = process.env.REDIS_URL || '';
const STATE_KEY = process.env.AUDIO_STATE_KEY || 'audioswitch:state';
const VERSION_KEY = process.env.AUDIO_VERSION_KEY || 'audioswitch:version';
const CHANNEL = process.env.AUDIO_PUBSUB_CHANNEL || 'audioswitch:events';
const SOURCE_ID = `${process.env.HOSTNAME || 'host'}:${process.pid}`;
const DEBOUNCE_MS = parseInt(process.env.AUDIOSWITCH_DEBOUNCE_MS || '150', 10); // Gate #025: reduced from 750ms
const DIAG = process.env.AUDIOSWITCH_DIAG === '1'; // Gate #025: noise reduction
const QUORUM_TIMEOUT_MS = 300; // Gate #025: early-ack quorum

let redisClient = null, redisSub = null, connected = false, lastVersion = 0, publishing = false;

async function initRedis() {
  if (!REDIS_URL) {
    if (DIAG) console.log('[audio-cluster] No REDIS_URL - using local file-based switch only');
    return;
  }
  
  try {
    // Gate #025: dedicated clients with keepAlive for low latency
    redisClient = createClient({ 
      url: REDIS_URL,
      socket: { keepAlive: true, reconnectStrategy: (retries) => Math.min(retries * 50, 500) }
    });
    redisSub = redisClient.duplicate();
    await redisClient.connect();
    await redisSub.connect();
    connected = true;
    if (DIAG) console.log('[audio-cluster] Redis connected:', REDIS_URL);
    
    // Initialize state
    const remoteRaw = await redisClient.get(STATE_KEY);
    if (remoteRaw) {
      try {
        const remote = JSON.parse(remoteRaw);
        lastVersion = Number(remote.version || 0);
        if (typeof remote.enabled === 'boolean') {
          if (remote.enabled) localSwitch.enable(remote.reason || 'redis-init');
          else localSwitch.disable(remote.reason || 'redis-init');
        }
        console.log('[audio-cluster] Initialized from Redis:', remote);
      } catch (err) {
        console.warn('[audio-cluster] Failed to parse Redis state:', err.message);
      }
    } else {
      // Adopt local -> publish as version 1
      const v = await redisClient.incr(VERSION_KEY);
      lastVersion = v;
      const st = { ...localSwitch.getState(), version: v, sourceId: SOURCE_ID };
      await redisClient.set(STATE_KEY, JSON.stringify(st));
      await redisClient.publish(CHANNEL, JSON.stringify(st));
      console.log('[audio-cluster] Published initial state to Redis:', st);
    }
    
    // Subscribe for changes
    await redisSub.subscribe(CHANNEL, (msg) => {
      // Gate #025: fast-path scheduling via microtask (avoid setTimeout event-loop delay)
      queueMicrotask(() => {
        const rxTime = performance.now(); // Gate #025: monotonic receive timestamp
        try {
          const s = JSON.parse(msg);
          if (s.sourceId === SOURCE_ID) return; // ignore self
          const v = Number(s.version || 0);
          if (v <= lastVersion) return; // ignore stale
          lastVersion = v;
          if (typeof s.enabled === 'boolean') {
            if (s.enabled) localSwitch.enable(s.reason || 'cluster-enable');
            else localSwitch.disable(s.reason || 'cluster-disable');
            if (DIAG) {
              const delta = s.txTime ? (rxTime - s.txTime).toFixed(1) : 'N/A';
              console.log(`[audio-cluster] RX from ${s.sourceId}: enabled=${s.enabled}, delta=${delta}ms`);
            }
          }
        } catch (err) {
          console.warn('[audio-cluster] Failed to process pub/sub message:', err.message);
        }
      });
    });
    
    console.log('[audio-cluster] Subscribed to channel:', CHANNEL);
  } catch (err) {
    console.warn('[audio-cluster] Redis initialization failed, falling back to local file-based switch:', err.message);
    connected = false;
  }
}

// Initialize on module load (non-blocking)
initRedis().catch((err) => { 
  console.warn('[audio-cluster] Redis init error:', err.message);
  connected = false; 
});

async function publishState() {
  if (!connected || publishing) {
    if (DIAG) console.log('[audio-cluster] Skip publish (connected:', connected, ', publishing:', publishing, ')');
    return;
  }
  publishing = true;
  const txTime = performance.now(); // Gate #025: monotonic transmit timestamp
  try {
    const v = await redisClient.incr(VERSION_KEY);
    lastVersion = v;
    const st = { ...localSwitch.getState(), version: v, sourceId: SOURCE_ID, txTime };
    // Gate #025: parallel set+publish for lower latency
    await Promise.all([
      redisClient.set(STATE_KEY, JSON.stringify(st)),
      redisClient.publish(CHANNEL, JSON.stringify(st))
    ]);
    if (DIAG) console.log('[audio-cluster] Published state v' + v + ' @' + txTime.toFixed(1) + 'ms');
  } catch (err) {
    console.warn('[audio-cluster] Failed to publish state:', err.message);
  } finally {
    publishing = false;
  }
}

// Cluster-aware facade with same API as BOSSCAT-021A
const audioSwitch = {
  isEnabled() { return localSwitch.isEnabled(); },
  getState() { 
    const state = localSwitch.getState();
    return {
      ...state,
      cluster: {
        connected: connected,
        sourceId: SOURCE_ID,
        version: lastVersion
      }
    };
  },
  async enable(reason = 'manual-enable') {
    localSwitch.enable(reason);
    await publishState();
    return audioSwitch.getState();
  },
  async disable(reason = 'manual-disable') {
    localSwitch.disable(reason);
    await publishState();
    return audioSwitch.getState();
  },
};

function audioAdminRouter(adminToken) {
  const router = express.Router();
  router.use((req, res, next) => {
    if (!adminToken) return next();
    if (req.get('X-Admin-Token') === adminToken) return next();
    res.status(401).json({ error: 'unauthorized' });
  });
  router.get('/', (req, res) => res.json(audioSwitch.getState()));
  router.post('/', express.json(), async (req, res) => {
    const { enabled, reason } = req.body || {};
    if (typeof enabled !== 'boolean') return res.status(400).json({ error: 'bad-request', detail: 'enabled boolean required' });
    if (enabled) await audioSwitch.enable(reason);
    else await audioSwitch.disable(reason);
    res.json(audioSwitch.getState());
  });
  return router;
}

module.exports = { audioSwitch, audioAdminRouter };
