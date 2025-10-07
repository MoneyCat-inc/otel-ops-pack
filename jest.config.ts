import type { Config } from 'jest';

const config: Config = {
  testEnvironment: 'node',
  roots: ['<rootDir>/tests/tetragrammaton/__tests__'],
  transform: {
    '^.+\\.(ts|tsx)$': ['ts-jest', { tsconfig: 'tests/tetragrammaton/tsconfig.json' }],
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'json'],
  moduleNameMapper: {
    '^@tetragrammaton/(.*)$': '<rootDir>/tests/tetragrammaton/src/$1',
  },
  collectCoverageFrom: ['tests/tetragrammaton/src/**/*.{ts,tsx}'],
};

export default config;
