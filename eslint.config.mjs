import js from '@eslint/js';
import globals from 'globals';
import tseslint from 'typescript-eslint';

const sharedStyleRules = {
  curly: ['error', 'all'],
  eqeqeq: ['error', 'always'],
  indent: ['error', 2],
  'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  'no-var': 'error',
  'prefer-const': 'error',
  quotes: ['error', 'single'],
  semi: ['error', 'always'],
};

export default tseslint.config(
  {
    ignores: [
      'node_modules/**',
      'preview/node_modules/**',
      'docs/**',
      'artifacts/**',
      'validation-evidence-*/**',
      'reports/**',
      'experiments/**',
      'test-reviewdog.js',
      'SigNoz _ Home_files/**'
    ],
  },
  {
    files: ['**/*.{js,mjs,cjs}'],
    extends: [js.configs.recommended],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      ...sharedStyleRules,
      'no-console': 'warn',
    },
  },
  {
    files: ['**/*.{ts,tsx}'],
    extends: [...tseslint.configs.recommended],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      parserOptions: {
        tsconfigRootDir: import.meta.dirname,
      },
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
    rules: {
      ...sharedStyleRules,
      'no-console': 'warn',
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
  {
    files: ['.agent/**/*.{js,mjs,cjs}', 'scripts/**/*.{js,mjs,cjs}', '*.mjs', '*.cjs'],
    languageOptions: {
      globals: globals.node,
    },
    rules: {
      'no-console': 'off',
    },
  },
  {
    files: ['tests/**/*.{ts,tsx,js}'],
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  }
);
