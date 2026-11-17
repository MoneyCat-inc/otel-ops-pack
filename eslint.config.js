// Flat config (ESLint 10 dropped .eslintrc), migrated rule for rule from .eslintrc.js.
// ALFA/APPS has its own eslint.config.js: ESLint uses the config file nearest to each
// linted file, so these rules do not reach it (what `root: true` did there).
const js = require('@eslint/js');
const globals = require('globals');
const tsParser = require('@typescript-eslint/parser');
const tsPlugin = require('@typescript-eslint/eslint-plugin');

const tsFiles = ['**/*.ts', '**/*.tsx'];

module.exports = [
  {
    // eslintrc skipped dotfiles and dot-directories by default and flat config does not
    // (.claude/worktrees holds whole checkouts). CHAR/DOCS is the generated docs mirror,
    // vendor/ holds minified third-party bundles, third_party/ is a submodule with its
    // own playbook, artifacts/ is run output.
    ignores: ['**/.*', 'CHAR/DOCS/', '**/vendor/', 'third_party/', 'artifacts/'],
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'no-console': 'warn',
      'prefer-const': 'error',
      'no-var': 'error',
      'eqeqeq': ['error', 'always'],
      'curly': ['error', 'all'],
      'indent': ['error', 2],
      'quotes': ['error', 'single'],
      'semi': ['error', 'always'],
    },
  },
  // typescript-eslint's flat configs apply to every file unless scoped; the eslintrc
  // override applied them to *.ts and *.tsx only.
  ...tsPlugin.configs['flat/recommended'].map((config) => ({
    ...config,
    files: tsFiles,
  })),
  {
    files: tsFiles,
    languageOptions: {
      parser: tsParser,
    },
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
];
