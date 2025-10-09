import { computeDensity } from '../foundation/textProcessor';
import type {
  BenchmarkResponse,
  ValidationIssue,
  ValidationSummary,
} from '../foundation/types';

function isSortedAscending(values: number[]): boolean {
  for (let i = 1; i < values.length; i++) {
    if (values[i] < values[i - 1]) {
      return false;
    }
  }
  return true;
}

export function validateResponse(response: BenchmarkResponse, expected?: number): ValidationSummary {
  const issues: ValidationIssue[] = [];

  if (response.positions.length !== response.total) {
    issues.push({
      quadrant: response.quadrant,
      severity: 'error',
      message: `Declared total (${response.total}) does not match position count (${response.positions.length}).`,
    });
  }

  if (!isSortedAscending(response.positions)) {
    issues.push({
      quadrant: response.quadrant,
      severity: 'error',
      message: 'Match positions must be sorted in ascending order.',
    });
  }

  if (expected !== undefined && expected !== response.total) {
    issues.push({
      quadrant: response.quadrant,
      severity: 'error',
      message: `Expected ${expected} matches but observed ${response.total}.`,
    });
  }

  const patternLength = response.pattern.length;
  for (const position of response.positions) {
    if (position < 0) {
      issues.push({
        quadrant: response.quadrant,
        severity: 'error',
        message: `Match position ${position} is negative.`,
      });
      continue;
    }

    const segment = response.processedText.slice(position, position + patternLength);
    if (!segment) {
      issues.push({
        quadrant: response.quadrant,
        severity: 'error',
        message: `Match at index ${position} falls outside processed text bounds.`,
      });
    } else if (segment !== response.pattern) {
      issues.push({
        quadrant: response.quadrant,
        severity: 'error',
        message: `Segment '${segment}' at index ${position} does not match pattern '${response.pattern}'.`,
      });
    }
  }

  const recomputedDensity = computeDensity(response);
  if (Math.abs(recomputedDensity - response.density) > 0.001) {
    issues.push({
      quadrant: response.quadrant,
      severity: 'warning',
      message: `Reported density (${response.density}) diverges from computed (${recomputedDensity}).`,
    });
  }

  if (!issues.length && response.total > 0) {
    issues.push({
      quadrant: response.quadrant,
      severity: 'info',
      message: `${response.total} occurrences validated for '${response.pattern}'.`,
    });
  }

  const isValid = issues.every((issue) => issue.severity !== 'error');

  return {
    quadrant: response.quadrant,
    isValid,
    expected,
    issues,
  };
}
