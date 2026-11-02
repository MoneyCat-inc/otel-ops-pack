'use strict';
/**
 * Jest transform for TypeScript sources: one-file transpile through esbuild.
 *
 * Until 2026-11 this called `ts.transpileModule`. TypeScript 7 (locked since
 * Dependabot #699) ships no transpile API: its package's "." export is only
 * lib/version.cjs, so the old transform threw on every suite. esbuild is
 * already resolved in the lockfile (via tsx) and is now declared directly.
 *
 * Semantics kept from the old transform: CommonJS output, ES2020 target,
 * classic React JSX (ts.JsxEmit.React), inline source maps, one file at a
 * time (isolatedModules). Class fields keep TypeScript's pre-ES2022
 * assignment semantics, which is what transpileModule emitted for ES2020.
 */
const crypto = require('node:crypto');
const esbuild = require('esbuild');

const OPTIONS = {
  format: 'cjs',
  target: 'es2020',
  platform: 'node',
  sourcemap: 'inline',
  logLevel: 'silent',
  tsconfigRaw: {
    compilerOptions: {
      jsx: 'react',
      target: 'ES2020',
      useDefineForClassFields: false,
      esModuleInterop: true,
    },
  },
};

const CACHE_SALT = crypto
  .createHash('sha1')
  .update('jest-ts-transform/esbuild/')
  .update(esbuild.version)
  .update(JSON.stringify(OPTIONS))
  .digest('hex');

function loaderFor(sourcePath) {
  return sourcePath.endsWith('.tsx') ? 'tsx' : 'ts';
}

exports.process = (sourceText, sourcePath) => {
  const result = esbuild.transformSync(sourceText, {
    ...OPTIONS,
    loader: loaderFor(sourcePath),
    sourcefile: sourcePath,
  });
  return { code: result.code };
};

exports.getCacheKey = (sourceText, sourcePath, options) => {
  return crypto
    .createHash('sha1')
    .update(CACHE_SALT)
    .update('\0')
    .update(sourcePath)
    .update('\0')
    .update(sourceText)
    .update('\0')
    .update((options && options.configString) || '')
    .update('\0')
    .update(options && options.instrument ? 'instrument' : '')
    .digest('hex');
};
