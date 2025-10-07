import { executeBenchmark } from '../interface/cli';
import { validateResponse } from '../validation/quadrantValidator';
import type {
  BenchmarkScenario,
  BenchmarkResponse,
  QuadrantKey,
  SuiteResult,
  ValidationSummary,
} from '../foundation/types';

export interface QuadrantMatrixRow {
  quadrant: QuadrantKey;
  label: string;
  matches: number;
  density: number;
  valid: boolean;
  diagnostics: string[];
}

function blankCoverage(): Record<QuadrantKey, number> {
  return {
    YOD: 0,
    HE: 0,
    VAV: 0,
    FINAL_HE: 0,
  };
}

export function runTetragrammatonSuite(scenarios: BenchmarkScenario[]): SuiteResult {
  if (!scenarios.length) {
    throw new Error('At least one benchmark scenario is required.');
  }

  const responses: BenchmarkResponse[] = [];
  const validations: ValidationSummary[] = [];
  const coverageByQuadrant = blankCoverage();

  scenarios.forEach((scenario) => {
    const response = executeBenchmark(scenario);
    responses.push(response);
    const validation = validateResponse(response, scenario.expectedTotal);
    validations.push(validation);
    coverageByQuadrant[response.quadrant] += response.total;
  });

  const totalMatches = responses.reduce((total, response) => total + response.total, 0);
  const passRate = validations.length
    ? Number((validations.filter((item) => item.isValid).length / validations.length).toFixed(3))
    : 1;

  return {
    responses,
    validations,
    aggregate: {
      totalMatches,
      coverageByQuadrant,
      passRate,
    },
  };
}

export function buildQuadrantMatrix(result: SuiteResult): QuadrantMatrixRow[] {
  return result.responses.map((response, index) => {
    const validation = result.validations[index];
    return {
      quadrant: response.quadrant,
      label: response.label,
      matches: response.total,
      density: response.density,
      valid: validation.isValid,
      diagnostics: [...response.diagnostics],
    };
  });
}
