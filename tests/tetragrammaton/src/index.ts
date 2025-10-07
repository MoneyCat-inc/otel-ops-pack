export {
  QUADRANT_KEYS,
  type QuadrantKey,
  type OccurrenceOptions,
  type OccurrenceResult,
  type BenchmarkRequest,
  type BenchmarkResponse,
  type BenchmarkScenario,
  type SuiteResult,
  type ValidationIssue,
  type ValidationSummary,
} from './foundation/types';
export {
  countOccurrences,
  computeDensity,
  describeQuadrant,
} from './foundation/textProcessor';
export {
  executeBenchmark,
  buildLabel,
  formatCliOutput,
  parseCliArgs,
  runCli,
} from './interface/cli';
export { validateResponse } from './validation/quadrantValidator';
export {
  runTetragrammatonSuite,
  buildQuadrantMatrix,
  type QuadrantMatrixRow,
} from './integration/orchestrator';
