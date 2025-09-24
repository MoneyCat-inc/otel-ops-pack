const fs = require('node:fs');
const path = require('node:path');

const FLOW_DIR = path.join(process.cwd(), 'practice-flows', 'presets');
const ALLOWED_ENDPOINTS = new Set(['/api/events']);
const FORBIDDEN_PROP_KEYS = [
  'audio',
  'blob',
  'pcm',
  'wav',
  'base64',
  'recording',
  'transcript',
  'useremail',
  'email',
  'phone',
  'phonenumber',
  'ssn',
  'user_id',
  'userid'
];

function loadFlows() {
  const files = fs.readdirSync(FLOW_DIR).filter((file) => file.endsWith('.json'));
  if (files.length === 0) {
    throw new Error('No practice flows found in presets directory');
  }

  return files.map((file) => {
    const fullPath = path.join(FLOW_DIR, file);
    const raw = fs.readFileSync(fullPath, 'utf8');
    return { file, data: JSON.parse(raw) };
  });
}

function collectForbiddenProps(props, prefix = []) {
  const issues = [];
  if (!props || typeof props !== 'object') {
    return issues;
  }

  for (const [key, value] of Object.entries(props)) {
    const normalized = key.toLowerCase();
    if (FORBIDDEN_PROP_KEYS.some((pattern) => normalized.includes(pattern))) {
      issues.push(prefix.concat([key]).join('.'));
    }

    if (value && typeof value === 'object') {
      issues.push(...collectForbiddenProps(value, prefix.concat([key])));
    }

    if (typeof value === 'string') {
      const lowerValue = value.toLowerCase();
      if (lowerValue.includes('data:audio') || lowerValue.includes('audio/')) {
        issues.push(prefix.concat([key]).join('.'));
      }
    }
  }

  return issues;
}

describe('practice flow privacy gate', () => {
  const flows = loadFlows();

  test('each flow declares export/delete data controls', () => {
    flows.forEach(({ file, data }) => {
      expect(data.dataControls).toBeDefined();
      expect(data.dataControls.export).toBe(true);
      expect(data.dataControls.delete).toBe(true);
      expect(typeof data.dataControls.retentionHours).toBe('number');
      expect(data.dataControls.retentionHours).toBeGreaterThanOrEqual(0);
    });
  });

  test('drill steps only reference allowlisted analytics endpoint', () => {
    flows.forEach(({ file, data }) => {
      const drillSteps = (data.steps || []).filter((step) => step.type === 'drill');
      expect(drillSteps.length).toBeGreaterThan(0);

      drillSteps.forEach((step) => {
        const analytics = step.analytics || [];
        analytics.forEach((entry, idx) => {
          expect(ALLOWED_ENDPOINTS.has(entry.endpoint)).toBe(true);
          expect(typeof entry.event).toBe('string');
          const issues = collectForbiddenProps(entry.props, [step.id, `analytics[${idx}]`]);
          if (issues.length > 0) {
            throw new Error(
              `Forbidden analytics props detected in ${file} -> ${issues.join(', ')}`
            );
          }
        });

        const networkFields = Object.keys(step).filter((key) => {
          const lower = key.toLowerCase();
          return ['fetch', 'request', 'url', 'endpoint'].includes(lower) && lower !== 'analytics';
        });
        if (networkFields.length > 0) {
          throw new Error(`Unexpected network fields in step ${step.id} of ${file}: ${networkFields.join(', ')}`);
        }
      });
    });
  });
});
