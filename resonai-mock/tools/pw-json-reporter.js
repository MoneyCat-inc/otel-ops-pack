// Lightweight reporter: writes one compact JSON summary for SSOT.
const fs = require('fs');
const path = require('path');

class PwJsonReporter {
  onBegin(config, suite) {
    this._start = Date.now();
    this._project = (config.projects || []).map(p => p.name);
  }
  onEnd(result) {
    const durationMs = Date.now() - this._start;
    const outDir = path.resolve('.artifacts/test-reports');
    fs.mkdirSync(outDir, { recursive: true });
    const payload = {
      startedAt: new Date(this._start).toISOString(),
      durationMs,
      status: result.status, // 'passed' | 'failed' | 'timedout' | 'interrupted'
      projects: this._project
    };
    fs.writeFileSync(path.join(outDir, 'playwright-summary.json'),
      JSON.stringify(payload, null, 2));
  }
  onTestEnd(test, result) {
    this._tests = this._tests || [];
    this._tests.push({
      title: test.title,
      location: test.location,
      tags: (test.annotations || []).map(a => a.type),
      status: result.status, // 'passed' | 'failed' | 'timedOut' | 'skipped'
      durationMs: result.duration,
      project: result.workerIndex // coarse project hint
    });
  }
  onExit() {
    if (!this._tests) return;
    const outDir = path.resolve('.artifacts/test-reports');
    fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(
      path.join(outDir, 'playwright-tests.json'),
      JSON.stringify({ tests: this._tests }, null, 2)
    );
  }
}

module.exports = PwJsonReporter;
