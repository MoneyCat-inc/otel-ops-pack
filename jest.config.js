module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.[jt]s?(x)', '**/?(*.)+(spec|test).[jt]s?(x)'],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/tests/',
    '/third_party/',
    '/artifacts/',
    '/validation-evidence-*/',
    '/logs/',
    '/reports/',
    '/docs/',
    '/patches/',
    '/SigNoz _ Home_files/',
  ],
  passWithNoTests: true,
  collectCoverage: false,
};
