/** App-local ESLint: Next.js defaults without inheriting repo-root strict style rules. */
// Being the nearest config file to everything under ALFA/APPS, this replaces the root
// config here, as `root: true` did in the old .eslintrc.js.
const nextCoreWebVitals = require('eslint-config-next/core-web-vitals');

module.exports = [
  ...nextCoreWebVitals,
  {
    settings: {
      next: {
        rootDir: 'ALFA/APPS',
      },
    },
  },
];
