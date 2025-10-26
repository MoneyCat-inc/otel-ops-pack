const fs = require('fs');
const path = require('path');
const express = require('express');

class AudioSwitch {
  constructor(stateFile, defaultEnabled = true) {
    this.stateFile = stateFile;
    this.state = { enabled: defaultEnabled, reason: null, changedAt: new Date().toISOString() };
    this._load();
  }
  _load() {
    try {
      const txt = fs.readFileSync(this.stateFile, 'utf8');
      const st = JSON.parse(txt);
      if (typeof st.enabled === 'boolean') this.state = st;
    } catch {
      fs.mkdirSync(path.dirname(this.stateFile), { recursive: true });
      this._persist();
    }
  }
  _persist() {
    fs.writeFileSync(this.stateFile, JSON.stringify(this.state, null, 2));
  }
  isEnabled() { return !!this.state.enabled; }
  getState()  { return this.state; }
  enable(reason = 'manual-enable') {
    this.state = { enabled: true, reason, changedAt: new Date().toISOString() };
    this._persist();
    return this.state;
  }
  disable(reason = 'manual-disable') {
    this.state = { enabled: false, reason, changedAt: new Date().toISOString() };
    this._persist();
    return this.state;
  }
}

const stateFile = process.env.AUDIO_STATE_FILE || path.join(process.cwd(), 'config', 'audio-state.json');
const audioSwitch = new AudioSwitch(stateFile, process.env.AUDIO_ENABLED !== 'false');

function audioAdminRouter(adminToken) {
  const router = express.Router();
  router.use((req, res, next) => {
    if (!adminToken) return next(); // allow on trusted networks when unset
    if (req.get('X-Admin-Token') === adminToken) return next();
    res.status(401).json({ error: 'unauthorized' });
  });
  router.get('/', (req, res) => res.json(audioSwitch.getState()));
  router.post('/', express.json(), (req, res) => {
    const { enabled, reason } = req.body || {};
    if (typeof enabled !== 'boolean') return res.status(400).json({ error: 'bad-request', detail: 'enabled boolean required' });
    const st = enabled ? audioSwitch.enable(reason) : audioSwitch.disable(reason);
    res.json(st);
  });
  return router;
}

module.exports = { audioSwitch, audioAdminRouter };

