import {
  countOccurrences,
  computeDensity,
  describeQuadrant,
} from '../foundation/textProcessor';
import type {
  BenchmarkRequest,
  BenchmarkResponse,
  OccurrenceOptions,
  QuadrantKey,
} from '../foundation/types';

function resolveOptions(request: BenchmarkRequest): Required<OccurrenceOptions> & { quadrant: QuadrantKey } {
  const {
    quadrant = 'YOD',
    allowOverlaps = false,
    caseSensitive = true,
    normalizeWhitespace = false,
    captureSegments = true,
  } = request;

  return {
    quadrant,
    allowOverlaps,
    caseSensitive,
    normalizeWhitespace,
    captureSegments,
  };
}

export function buildLabel(quadrant: QuadrantKey, pattern: string, explicit?: string): string {
  if (explicit?.trim()) {
    return explicit.trim();
  }
  return `${describeQuadrant(quadrant)} :: ${pattern}`;
}

export function executeBenchmark(request: BenchmarkRequest): BenchmarkResponse {
  const options = resolveOptions(request);
  const result = countOccurrences(request.text, request.pattern, options);
  const density = computeDensity(result);

  const diagnostics: string[] = [
    `quadrant=${result.quadrant}`,
    `matches=${result.total}`,
    `positions=${result.positions.join(',') || '∅'}`,
    `density=${density}`,
    `overlaps=${options.allowOverlaps ? 'on' : 'off'}`,
    `case=${options.caseSensitive ? 'sensitive' : 'insensitive'}`,
  ];

  return {
    ...result,
    density,
    element: result.quadrant,
    label: buildLabel(result.quadrant, request.pattern, request.label),
    diagnostics,
  };
}

export function formatCliOutput(response: BenchmarkResponse): string {
  const header = `▶ ${response.label}`;
  const lines = [
    header,
    `└─ Quadrant: ${response.element}`,
    `   Matches: ${response.total}`,
    `   Positions: ${response.positions.length ? response.positions.join(', ') : '∅'}`,
    `   Density (per 1k chars): ${response.density}`,
  ];
  return lines.join('\n');
}

export function parseCliArgs(argv: string[]): BenchmarkRequest {
  const mapping: Record<string, keyof BenchmarkRequest | keyof OccurrenceOptions> = {
    '--text': 'text',
    '--pattern': 'pattern',
    '--quadrant': 'quadrant',
    '--overlaps': 'allowOverlaps',
    '--case-sensitive': 'caseSensitive',
    '--normalize': 'normalizeWhitespace',
    '--label': 'label',
  } as const;

  const request: Partial<BenchmarkRequest> = {};

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg in mapping) {
      const key = mapping[arg];
      const next = argv[i + 1];

      if (key === 'allowOverlaps' || key === 'caseSensitive' || key === 'normalizeWhitespace') {
        request[key] = next ? next.toLowerCase() === 'true' : true;
      } else if (next) {
        request[key as keyof BenchmarkRequest] = next as never;
        i += 1;
      }
    }
  }

  if (!request.text || !request.pattern) {
    throw new Error('Both --text and --pattern must be provided.');
  }

  return {
    text: request.text,
    pattern: request.pattern,
    quadrant: (request.quadrant as QuadrantKey) ?? 'YOD',
    allowOverlaps: request.allowOverlaps ?? false,
    caseSensitive: request.caseSensitive ?? true,
    normalizeWhitespace: request.normalizeWhitespace ?? false,
    captureSegments: true,
    label: request.label,
  };
}

export function runCli(argv: string[]): string {
  const args = argv.filter((_, index) => index >= 2);
  const request = parseCliArgs(args);
  const response = executeBenchmark(request);
  return formatCliOutput(response);
}
