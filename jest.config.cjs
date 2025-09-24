/** @type {import('jest').Config} */
module.exports = {
  testMatch: ['**/?(*.)+(test).[jt]s?(x)'],
  testPathIgnorePatterns: ['/node_modules/', '/tests/smoke/'],
  transform: {},
  verbose: false
};
