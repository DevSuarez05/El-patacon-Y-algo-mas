/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: 'src',
  setupFiles: ['<rootDir>/load-env.ts'],
  testTimeout: 60000,
};
