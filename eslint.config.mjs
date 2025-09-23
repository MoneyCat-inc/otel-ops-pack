import js from '@eslint/js';

export default [
  {
    ignores: [
      'node_modules/**',
      'preview/node_modules/**',
      'docs/**',
      'artifacts/**',
      'validation-evidence-*/**',
      'reports/**',
      'experiments/**',
      'test-reviewdog.js'
    ]
  },
  js.configs.recommended,
  {
    files: ['*.js', '*.mjs', 'scripts/**/*.js', 'scripts/**/*.mjs'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        console: 'readonly',
        process: 'readonly',
        module: 'writable'
      }
    },
    rules: {
      'no-console': 'off'
    }
  }
];
