import {
  QUADRANT_KEYS,
  type QuadrantKey,
  type OccurrenceOptions,
  type OccurrenceResult,
} from './types';

export const QUADRANT_META: Record<QuadrantKey, { role: string; element: string }> = {
  YOD: { role: 'Foundation', element: 'Yod' },
  HE: { role: 'Interface', element: 'He' },
  VAV: { role: 'Validation', element: 'Vav' },
  FINAL_HE: { role: 'Integration', element: 'Final He' },
};

const DEFAULT_OPTIONS: Required<Pick<OccurrenceOptions, 'allowOverlaps' | 'caseSensitive' | 'normalizeWhitespace' | 'captureSegments'>> = {
  allowOverlaps: false,
  caseSensitive: true,
  normalizeWhitespace: false,
  captureSegments: true,
};

function normalizeWhitespace(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

function coerceQuadrant(quadrant?: QuadrantKey): QuadrantKey {
  if (quadrant && QUADRANT_KEYS.includes(quadrant)) {
    return quadrant;
  }
  return 'YOD';
}

function normaliseInput(value: string, options: OccurrenceOptions): string {
  const trimmed = options.normalizeWhitespace ? normalizeWhitespace(value) : value;
  return options.caseSensitive === false ? trimmed.toLowerCase() : trimmed;
}

export function countOccurrences(text: string, pattern: string, options: OccurrenceOptions = {}): OccurrenceResult {
  const settings = { ...DEFAULT_OPTIONS, ...options };
  const processedText = settings.normalizeWhitespace ? normalizeWhitespace(text) : text;
  const processedPattern = settings.normalizeWhitespace ? normalizeWhitespace(pattern) : pattern;

  if (!processedPattern.length) {
    throw new Error('Search pattern must not be empty.');
  }

  const quadrant = coerceQuadrant(settings.quadrant);
  const searchHaystack = normaliseInput(processedText, settings);
  const searchNeedle = normaliseInput(processedPattern, settings);

  const positions: number[] = [];
  const segments: string[] = [];

  let index = searchHaystack.indexOf(searchNeedle, 0);
  while (index >= 0) {
    positions.push(index);
    if (settings.captureSegments) {
      segments.push(processedText.slice(index, index + processedPattern.length));
    }

    const offset = settings.allowOverlaps ? index + 1 : index + Math.max(searchNeedle.length, 1);
    index = searchHaystack.indexOf(searchNeedle, offset);
  }

  return {
    quadrant,
    total: positions.length,
    positions,
    pattern: processedPattern,
    text,
    segments,
    processedText,
  };
}

export function computeDensity(result: OccurrenceResult): number {
  if (!result.processedText.length) {
    return 0;
  }
  const density = (result.total / result.processedText.length) * 1000;
  return Number.isFinite(density) ? parseFloat(density.toFixed(3)) : 0;
}

export function describeQuadrant(quadrant: QuadrantKey): string {
  const meta = QUADRANT_META[quadrant];
  return `${meta.element} — ${meta.role}`;
}
