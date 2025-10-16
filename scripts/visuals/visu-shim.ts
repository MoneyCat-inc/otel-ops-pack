#!/usr/bin/env -S node --enable-source-maps
/**
 * BossCat Visuals Shim (Phase 2)
 * Minimal TypeScript CLI to assist with local control surface usage.
 *
 * Commands:
 *   - verify : prints OK and exits 0
 *   - url    : prints path to control.html
 *   - test   : prints example postMessage commands
 */

import { existsSync } from 'fs';
import { join, resolve } from 'path';

type Cmd = 'verify' | 'url' | 'test' | 'help';

function controlPath(): string {
  const p = resolve(join(process.cwd(), 'docs', 'BossCat', 'visuals', 'control.html'));
  return p;
}

function cmdVerify(): number {
  const p = controlPath();
  const ok = existsSync(p);
  if (!ok) {
    console.error(`[ERR] control.html not found at: ${p}`);
    return 2;
  }
  console.log('[OK] BossCat Visual Control surface present');
  return 0;
}

function cmdUrl(): number {
  const p = controlPath();
  console.log(p);
  return 0;
}

function cmdTest(): number {
  const sample = `// In DevTools console of the control.html window:
window.postMessage({ type: 'bosscat:visu', cmd: 'setBlendTime', arg: 2.0 }, '*');
window.postMessage({ type: 'bosscat:visu', cmd: 'next' }, '*');
window.postMessage({ type: 'bosscat:visu', cmd: 'auto', arg: true }, '*');`;
  console.log(sample);
  return 0;
}

function cmdHelp(): number {
  console.log(`BossCat Visuals Shim
Usage: node scripts/visuals/visu-shim.ts <cmd>
  verify   Verify control surface exists
  url      Print absolute path to control.html
  test     Print example postMessage commands
  help     Show this help
`);
  return 0;
}

function main(argv: string[]): number {
  const cmd = (argv[2] as Cmd) || 'help';
  switch (cmd) {
    case 'verify': return cmdVerify();
    case 'url':    return cmdUrl();
    case 'test':   return cmdTest();
    case 'help':
    default:       return cmdHelp();
  }
}

process.exitCode = main(process.argv);

