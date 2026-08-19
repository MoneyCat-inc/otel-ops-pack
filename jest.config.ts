import type { Config } from 'jest';

const config: Config = {
  testEnvironment: 'node',
  injectGlobals: true,
  roots: ['<rootDir>/ALFA/TEST/unit'],
  testMatch: ['**/*.test.ts'],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/\\.next/',
    'memx\\.normalize\\.test\\.ts',
  ],
  modulePathIgnorePatterns: ['<rootDir>/.next/'],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'json'],
  transform: {
    '^.+\\.tsx?$': '<rootDir>/jest-ts-transform.cjs',
  },
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/ALFA/LIBS/$1',
    '^@tetragrammaton/(.*)$': '<rootDir>/ALFA/TEST/unit/tetragrammaton/src/$1',
  },
};

export default config;
