/** App-local ESLint: Next.js defaults without inheriting repo-root strict style rules. */
module.exports = {
  root: true,
  extends: ['next/core-web-vitals'],
  settings: {
    next: {
      rootDir: 'ALFA/APPS',
    },
  },
};
