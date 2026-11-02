'use strict';
/**
 * Jest transform for TypeScript sources: one-file transpile through esbuild.
 *
 * Until 2026-11 this called `ts.transpileModule`. TypeScript 7 (locked since
 * Dependabot #699) ships no transpile API: its package's "." export is only
 * lib/version.cjs, so the old transform threw on every suite. esbuild is
 * already resolved in the lockfile (via tsx) and is now declared directly.
 *
 * Parity with the old transform's output: CommonJS, ES2020 target, "use
 * strict" prologue (alwaysStrict), classic React JSX (ts.JsxEmit.React),
 * dynamic import() lowered to require() as TypeScript did for CommonJS, raw
 * UTF-8 string literals, class fields with the pre-ES2022 assignment
 * semantics transpileModule emitted for ES2020, one file at a time
 * (isolatedModules). esbuild's CommonJS interop behaves like esModuleInterop.
 * The source map is returned to Jest as `map` (external), which Jest prefers
 * over an inline comment.
 */
const crypto = require('node:crypto');
const fs = require('node:fs');
const esbuild = require('esbuild');

const OPTIONS = {
  format: 'cjs',
  target: 'es2020',
  platform: 'node',
  sourcemap: 'external',
  charset: 'utf8',
  logLevel: 'silent',
  supported: { 'dynamic-import': false },
  tsconfigRaw: {
    compilerOptions: {
      alwaysStrict: true,
      jsx: 'react',
      target: 'ES2020',
      useDefineForClassFields: false,
    },
  },
};

// Any change to this file, to esbuild, or to the options invalidates Jest's
// transform cache; Jest's default key never looks at the transformer itself.
const CACHE_SALT = crypto
  .createHash('sha1')
  .update('jest-ts-transform/esbuild/')
  .update(esbuild.version)
  .update(JSON.stringify(OPTIONS))
  .update(fs.readFileSync(__filename))
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
  return { code: result.code, map: result.map };
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
