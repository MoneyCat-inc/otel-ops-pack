import js from '@eslint/js';
import tseslint from 'typescript-eslint';

const projectGlobs = [
  'scripts/**/*.{js,mjs,cjs,ts}',
  'tools/**/*.{js,mjs,cjs,ts}',
  'lib/**/*.{js,ts,tsx}',
  'app/**/*.{js,ts,tsx}',
  'config/**/*.{js,mjs,cjs,ts}',
  'tests/**/*.{js,ts,tsx}',
  'preview/**/*.{js,mjs,cjs,ts,tsx}',
  '*.config.{js,cjs,mjs,ts}'
];

const tsGlobs = [
  'scripts/**/*.ts',
  'tools/**/*.ts',
  'lib/**/*.{ts,tsx}',
  'app/**/*.{ts,tsx}',
  'config/**/*.ts',
  'tests/**/*.{ts,tsx}',
  'preview/**/*.{ts,tsx}',
  '*.config.ts'
];

export default tseslint.config(
  {
    ignores: [
      'node_modules/**',
      'dist/**',
      'third_party/**',
      'artifacts/**',
      '.agent/**',
      'archive/**',
      'validation-evidence-*/**',
      'logs/**',
      'reports/**',
      'docs/**',
      'patches/**',
      'SigNoz _ Home_files/**',
      'test-reviewdog.js',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: projectGlobs,
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        console: 'readonly',
        module: 'readonly',
        process: 'readonly',
        __dirname: 'readonly',
        require: 'readonly',
        fetch: 'readonly',
        URL: 'readonly',
        setTimeout: 'readonly',
        window: 'readonly',
        document: 'readonly',
      },
    },
    rules: {
      'no-console': ['warn', { allow: ['error', 'warn', 'log'] }],
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-require-imports': 'off',
    },
  },
  {
    files: tsGlobs,
    rules: {
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-require-imports': 'off',
    },
  }
);
