#!/usr/bin/env node
import fs from 'node:fs';

const p = '.github/pull_request_template.md';
const badge = `[![ECRR](https://img.shields.io/badge/✅%20ECRR-Required-7c5cff?style=flat-square)](../AGENTS.md#-agents--ecrr-mantra)

> **Reminder:** Follow the ECRR mantra — Examine → Clean → Report → Role.
`;

const gateHeader = '## ✅ ECRR Gate';

fs.mkdirSync('.github', { recursive: true });
try {
  fs.writeFileSync(p, `${badge}\n\n${gateHeader}\n\n- [ ] **Examine**\n- [ ] **Clean**\n- [ ] **Report**\n- [ ] **Role**\n`, { flag: 'wx' });
  console.log('🆕 Created PR template with ECRR badge + Gate.');
  process.exit(0);
} catch (e) {
  if (e.code !== 'EEXIST') throw e;
}

const orig = fs.readFileSync(p, 'utf8');
let changed = orig;

if (!orig.includes('img.shields.io/badge') || !orig.includes('ECRR_MANTRA.md')) {
  changed = `${badge}\n${changed}`;
}

if (!orig.includes(gateHeader)) {
  changed = changed + `\n\n${gateHeader}\n\n- [ ] **Examine**\n- [ ] **Clean**\n- [ ] **Report**\n- [ ] **Role**\n`;
}

if (changed !== orig) {
  fs.writeFileSync(p, changed);
  console.log('🩹 Updated PR template with ECRR badge + Gate.');
} else {
  console.log('✅ PR template already contains ECRR badge + Gate.');
}
