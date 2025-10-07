import {
  buildLabel,
  buildQuadrantMatrix,
  countOccurrences,
  describeQuadrant,
  executeBenchmark,
  formatCliOutput,
  parseCliArgs,
  runCli,
  runTetragrammatonSuite,
  validateResponse,
  type BenchmarkResponse,
  type BenchmarkScenario,
  type QuadrantKey,
} from '../src';

function makeScenario(
  quadrant: QuadrantKey,
  text: string,
  pattern: string,
  overrides: Partial<BenchmarkScenario> = {},
): BenchmarkScenario {
  return {
    quadrant,
    text,
    pattern,
    allowOverlaps: false,
    caseSensitive: false,
    normalizeWhitespace: false,
    captureSegments: true,
    ...overrides,
  };
}

describe('Quadrant YOD — Foundation', () => {
  const foundationCases = [
    {
      name: 'counts match at index 0',
      text: 'abcabc',
      pattern: 'abc',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 2,
      expectedPositions: [0, 3],
    },
    {
      name: 'counts match at end of text',
      text: 'boss-cat',
      pattern: 'cat',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 1,
      expectedPositions: [5],
    },
    {
      name: 'counts multiple separated occurrences',
      text: 'resonai bosscat resonai',
      pattern: 'resonai',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 2,
      expectedPositions: [0, 16],
    },
    {
      name: 'counts overlapping occurrences when enabled',
      text: 'aaaa',
      pattern: 'aa',
      options: { quadrant: 'YOD' as const, allowOverlaps: true },
      expectedTotal: 3,
      expectedPositions: [0, 1, 2],
    },
    {
      name: 'ignores overlapping matches by default',
      text: 'aaaa',
      pattern: 'aa',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 2,
      expectedPositions: [0, 2],
    },
    {
      name: 'respects case-insensitive flag',
      text: 'YodHeVavHe',
      pattern: 'he',
      options: { quadrant: 'YOD' as const, caseSensitive: false },
      expectedTotal: 2,
      expectedPositions: [3, 8],
    },
    {
      name: 'respects case-sensitive default',
      text: 'YodHeVavHe',
      pattern: 'he',
      options: { quadrant: 'YOD' as const, caseSensitive: true },
      expectedTotal: 0,
      expectedPositions: [],
    },
    {
      name: 'normalizes whitespace before searching',
      text: 'alpha   beta   alpha   beta',
      pattern: 'alpha beta',
      options: { quadrant: 'YOD' as const, normalizeWhitespace: true, allowOverlaps: true },
      expectedTotal: 2,
      expectedPositions: [0, 11],
    },
    {
      name: 'returns zero when pattern missing',
      text: 'observability',
      pattern: 'xyz',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 0,
      expectedPositions: [],
    },
    {
      name: 'captures entire text when pattern matches fully',
      text: 'tetragrammaton',
      pattern: 'tetragrammaton',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 1,
      expectedPositions: [0],
    },
    {
      name: 'captures segments alongside positions',
      text: 'boss boss boss',
      pattern: 'boss',
      options: { quadrant: 'YOD' as const },
      expectedTotal: 3,
      expectedPositions: [0, 5, 10],
      verifySegments: (segments: string[]) => expect(segments).toEqual(['boss', 'boss', 'boss']),
    },
  ] as const;

  test.each(foundationCases)('YOD %s', ({ name: _name, text, pattern, options, expectedTotal, expectedPositions, verifySegments }) => {
    const result = countOccurrences(text, pattern, options);
    expect(result.total).toBe(expectedTotal);
    expect(result.positions).toEqual(expectedPositions);
    expect(result.quadrant).toBe('YOD');
    if (options.normalizeWhitespace) {
      expect(result.processedText.includes('  ')).toBe(false);
    }
    verifySegments?.(result.segments);
  });

  test('YOD rejects empty pattern', () => {
    expect(() => countOccurrences('abc', '')).toThrow('Search pattern must not be empty.');
  });
});

describe('Quadrant HE — Interface', () => {
  const executeCases = [
    {
      name: 'builds automatic label when missing',
      request: makeScenario('HE', 'Yod He Vav He', 'He', { caseSensitive: false }),
      assertion: (response: BenchmarkResponse) => {
        expect(response.label).toContain(describeQuadrant('HE'));
        expect(response.label).toContain('He');
      },
    },
    {
      name: 'honors explicit label override',
      request: makeScenario('HE', 'BossCat oversight', 'cat', { label: 'Custom Label' }),
      assertion: (response: BenchmarkResponse) => {
        expect(response.label).toBe('Custom Label');
      },
    },
    {
      name: 'reports overlaps in diagnostics',
      request: makeScenario('HE', 'aaaa', 'aa', { allowOverlaps: true }),
      assertion: (response: BenchmarkResponse) => {
        expect(response.diagnostics).toContain('overlaps=on');
        expect(response.total).toBe(3);
      },
    },
    {
      name: 'reports case-insensitive diagnostics',
      request: makeScenario('HE', 'he he he', 'he', { caseSensitive: false }),
      assertion: (response: BenchmarkResponse) => {
        expect(response.diagnostics).toContain('case=insensitive');
        expect(response.total).toBeGreaterThan(0);
      },
    },
    {
      name: 'normalizes whitespace for CLI presentation',
      request: makeScenario('HE', 'alpha   beta   alpha   beta', 'alpha beta', { normalizeWhitespace: true }),
      assertion: (response: BenchmarkResponse) => {
        expect(response.processedText).toBe('alpha beta alpha beta');
      },
    },
    {
      name: 'computes density proportionally',
      request: makeScenario('HE', 'repeated repeated repeated', 'repeated', {}),
      assertion: (response: BenchmarkResponse) => {
        const recomputed = Number((response.total * 1000 / response.processedText.length).toFixed(3));
        expect(response.density).toBe(recomputed);
      },
    },
  ] as const;

  test.each(executeCases)('HE %s', ({ name: _name, request, assertion }) => {
    const response = executeBenchmark(request);
    assertion(response);
  });

  test('HE formatCliOutput includes summary lines', () => {
    const response = executeBenchmark(makeScenario('HE', 'BossCat is vigilant', 'cat', { caseSensitive: false }));
    const output = formatCliOutput(response);
    expect(output.split('\n')).toHaveLength(5);
    expect(output).toContain('Quadrant: HE');
    expect(output).toContain(String(response.total));
  });

  test('HE parseCliArgs toggles boolean flags', () => {
    const args = ['node', 'cli', '--text', 'aaaa', '--pattern', 'aa', '--quadrant', 'HE', '--overlaps', 'true', '--case-sensitive', 'false'];
    const request = parseCliArgs(args.slice(2));
    expect(request.allowOverlaps).toBe(true);
    expect(request.caseSensitive).toBe(false);
    expect(request.quadrant).toBe('HE');
  });

  test('HE parseCliArgs throws when missing required args', () => {
    expect(() => parseCliArgs(['--pattern', 'abc'])).toThrow('Both --text and --pattern must be provided.');
  });

  test('HE runCli integrates full pipeline', () => {
    const output = runCli(['node', 'cli', '--text', 'abcabc', '--pattern', 'abc', '--quadrant', 'HE']);
    expect(output).toContain('Quadrant: HE');
    expect(output).toContain('Matches: 2');
  });
});
describe('Quadrant VAV — Validation', () => {
  const base = () => executeBenchmark(makeScenario('VAV', 'tetragrammaton tetragrammaton', 'tetra', { caseSensitive: false }));

  test('VAV validates correct response', () => {
    const response = base();
    const summary = validateResponse(response, response.total);
    expect(summary.isValid).toBe(true);
    expect(summary.issues.at(-1)?.severity).toBe('info');
  });

  test('VAV flags expected total mismatch', () => {
    const response = base();
    const summary = validateResponse(response, response.total + 1);
    expect(summary.isValid).toBe(false);
    expect(summary.issues.some((issue) => issue.message.includes('Expected'))).toBe(true);
  });

  test('VAV flags unsorted positions', () => {
    const response = base();
    const reversed: BenchmarkResponse = {
      ...response,
      positions: [...response.positions].reverse(),
    };
    const summary = validateResponse(reversed);
    expect(summary.isValid).toBe(false);
    expect(summary.issues.some((issue) => issue.message.includes('sorted'))).toBe(true);
  });

  test('VAV flags density divergence as warning', () => {
    const response = base();
    const mutated: BenchmarkResponse = {
      ...response,
      density: response.density + 1,
    };
    const summary = validateResponse(mutated);
    expect(summary.isValid).toBe(true);
    expect(summary.issues.some((issue) => issue.severity === 'warning')).toBe(true);
  });

  test('VAV flags segment mismatch', () => {
    const response = base();
    const mutated: BenchmarkResponse = {
      ...response,
      pattern: 'boss',
    };
    const summary = validateResponse(mutated);
    expect(summary.isValid).toBe(false);
    expect(summary.issues.some((issue) => issue.message.includes('does not match pattern'))).toBe(true);
  });

  test('VAV flags negative position', () => {
    const response = base();
    const mutated: BenchmarkResponse = {
      ...response,
      positions: [-1],
      total: 1,
    };
    const summary = validateResponse(mutated);
    expect(summary.isValid).toBe(false);
    expect(summary.issues.some((issue) => issue.message.includes('negative'))).toBe(true);
  });

  test('VAV flags declared total mismatch', () => {
    const response = base();
    const mutated: BenchmarkResponse = {
      ...response,
      total: response.total + 2,
    };
    const summary = validateResponse(mutated);
    expect(summary.isValid).toBe(false);
    expect(summary.issues.some((issue) => issue.message.includes('position count'))).toBe(true);
  });

  test('VAV accepts zero matches', () => {
    const response = executeBenchmark(makeScenario('VAV', 'observability', 'xyz', {}));
    const summary = validateResponse(response, 0);
    expect(summary.isValid).toBe(true);
    expect(summary.issues).toHaveLength(0);
  });

  test('VAV handles expected zero without mismatch', () => {
    const response = executeBenchmark(makeScenario('VAV', 'BossCat', 'zzz', {}));
    const summary = validateResponse(response, 0);
    expect(summary.isValid).toBe(true);
    expect(summary.issues.length).toBe(0);
  });

  test('VAV validates large dataset', () => {
    const text = 'abc'.repeat(100);
    const response = executeBenchmark(makeScenario('VAV', text, 'abc', {}));
    const summary = validateResponse(response, response.total);
    expect(summary.isValid).toBe(true);
    expect(summary.issues.at(-1)?.severity).toBe('info');
  });
});
describe('Quadrant Final He — Integration', () => {
  const suiteScenarios: BenchmarkScenario[] = [
    makeScenario('YOD', 'abcabc', 'abc', {}),
    makeScenario('HE', 'he he he', 'he', { caseSensitive: false }),
    makeScenario('VAV', 'validation value', 'va', { caseSensitive: false }),
    makeScenario('FINAL_HE', 'integration integrates integration', 'integration', { caseSensitive: false }),
  ];

  test('Integration aggregates total matches across quadrants', () => {
    const result = runTetragrammatonSuite(suiteScenarios);
    const expected = suiteScenarios.reduce((sum, scenario) => sum + countOccurrences(scenario.text, scenario.pattern, scenario).total, 0);
    expect(result.aggregate.totalMatches).toBe(expected);
  });

  test('Integration coverage per quadrant matches totals', () => {
    const result = runTetragrammatonSuite(suiteScenarios);
    suiteScenarios.forEach((scenario) => {
      const expected = countOccurrences(scenario.text, scenario.pattern, scenario).total;
      expect(result.aggregate.coverageByQuadrant[scenario.quadrant]).toBe(expected);
    });
  });

  test('Integration computes pass rate when all validations succeed', () => {
    const result = runTetragrammatonSuite(suiteScenarios);
    expect(result.aggregate.passRate).toBe(1);
  });

  test('Integration pass rate reflects validation failure', () => {
    const scenarios = [
      ...suiteScenarios,
      makeScenario('FINAL_HE', 'aaab', 'aa', { allowOverlaps: false, expectedTotal: 3 }),
    ];
    const result = runTetragrammatonSuite(scenarios);
    expect(result.aggregate.passRate).toBeLessThan(1);
    expect(result.validations.some((summary) => summary.isValid === false)).toBe(true);
  });

  test('Integration buildQuadrantMatrix preserves diagnostics', () => {
    const result = runTetragrammatonSuite(suiteScenarios);
    const matrix = buildQuadrantMatrix(result);
    expect(matrix).toHaveLength(suiteScenarios.length);
    expect(matrix[0].diagnostics).toEqual(result.responses[0].diagnostics);
  });

  test('Integration aggregates repeated quadrants', () => {
    const scenarios = [
      makeScenario('HE', 'aaaa', 'aa', { allowOverlaps: true }),
      makeScenario('HE', 'bbbb', 'bb', {}),
      makeScenario('VAV', 'validation', 'val', {}),
    ];
    const result = runTetragrammatonSuite(scenarios);
    const expectedHeTotal = scenarios
      .filter((scenario) => scenario.quadrant === 'HE')
      .reduce((sum, scenario) => sum + countOccurrences(scenario.text, scenario.pattern, scenario).total, 0);
    expect(result.aggregate.coverageByQuadrant.HE).toBe(expectedHeTotal);
  });

  test('Integration requires at least one scenario', () => {
    expect(() => runTetragrammatonSuite([])).toThrow('At least one benchmark scenario is required.');
  });

  test('Integration preserves scenario order in responses', () => {
    const result = runTetragrammatonSuite(suiteScenarios);
    const expectedLabels = suiteScenarios.map((scenario) => buildLabel(scenario.quadrant, scenario.pattern));
    result.responses.forEach((response, index) => {
      expect(response.label).toContain(expectedLabels[index].split(' :: ').at(0) ?? '');
    });
  });

  test('Integration handles normalized whitespace scenario', () => {
    const scenarios = [
      makeScenario('FINAL_HE', 'alpha   beta   alpha   beta', 'alpha beta', { normalizeWhitespace: true }),
    ];
    const result = runTetragrammatonSuite(scenarios);
    expect(result.responses[0].processedText).toBe('alpha beta alpha beta');
  });

  test('Integration diagnostics remain stable across runs', () => {
    const first = runTetragrammatonSuite(suiteScenarios);
    const second = runTetragrammatonSuite(suiteScenarios);
    const firstDiagnostics = first.responses.map((item) => item.diagnostics.join('|'));
    const secondDiagnostics = second.responses.map((item) => item.diagnostics.join('|'));
    expect(secondDiagnostics).toEqual(firstDiagnostics);
  });
});




