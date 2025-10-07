export const QUADRANT_KEYS = ['YOD', 'HE', 'VAV', 'FINAL_HE'] as const;
export type QuadrantKey = typeof QUADRANT_KEYS[number];

export interface OccurrenceOptions {
  quadrant?: QuadrantKey;
  allowOverlaps?: boolean;
  caseSensitive?: boolean;
  normalizeWhitespace?: boolean;
  captureSegments?: boolean;
}

export interface OccurrenceResult {
  quadrant: QuadrantKey;
  total: number;
  positions: number[];
  pattern: string;
  text: string;
  segments: string[];
  processedText: string;
}

export interface BenchmarkRequest extends OccurrenceOptions {
  text: string;
  pattern: string;
  label?: string;
}

export interface BenchmarkResponse extends OccurrenceResult {
  label: string;
  density: number;
  element: QuadrantKey;
  diagnostics: string[];
}

export type ValidationSeverity = 'error' | 'warning' | 'info';

export interface ValidationIssue {
  quadrant: QuadrantKey;
  severity: ValidationSeverity;
  message: string;
}

export interface ValidationSummary {
  quadrant: QuadrantKey;
  isValid: boolean;
  expected?: number;
  issues: ValidationIssue[];
}

export interface BenchmarkScenario extends BenchmarkRequest {
  expectedTotal?: number;
}

export interface SuiteAggregate {
  totalMatches: number;
  coverageByQuadrant: Record<QuadrantKey, number>;
  passRate: number;
}

export interface SuiteResult {
  responses: BenchmarkResponse[];
  validations: ValidationSummary[];
  aggregate: SuiteAggregate;
}
