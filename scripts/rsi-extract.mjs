/**
 * RSI (Rhetorical Style Integrity) Metrics Extractor v0.1
 * 
 * Extracts linguistic fingerprint and style drift signals from documentation.
 * Budget: ~70 LOC (within ≤80 LOC constraint)
 * Lane: DOCS
 * Authority: BossCat OEM Directive 008
 * 
 * Metrics:
 * - LII (Linguistic Individuality Index): lexical diversity
 * - ΔPPL: Function-word ratio deviation from baseline
 */

import fs from 'fs';
import path from 'path';

const inputFile = process.argv[2] || 'CHANGELOG.md';
const txt = fs.readFileSync(inputFile, 'utf8');

// Tokenize (simple word extraction)
const tokens = txt.toLowerCase().match(/[a-z]+/g) || [];
const types = new Set(tokens);

// Function words (common grammatical words)
const functionWords = new Set([
  'the', 'a', 'an', 'of', 'to', 'in', 'and', 'or', 'for', 'on', 'with',
  'as', 'by', 'is', 'are', 'was', 'were', 'that', 'this', 'it', 'at'
]);

const fwCount = tokens.filter(w => functionWords.has(w)).length;

// LII: type-token ratio (lexical diversity)
const LII = types.size / Math.max(1, tokens.length);

// Load baseline (or initialize)
let baseline = { fwRatio: 0.55, updatedAt: null };
const baselinePath = 'artifacts/rsi/baseline.json';
try {
  baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
} catch {}

// Calculate current function-word ratio
const fwRatio = fwCount / Math.max(1, tokens.length);

// ΔPPL: deviation from baseline (proxy for perplexity drift)
const deltaPPL = Math.abs(fwRatio - baseline.fwRatio);

// Output metrics (with ICF fields for status panel)
const metrics = {
  LII: parseFloat(LII.toFixed(4)),
  deltaPPL: parseFloat(deltaPPL.toFixed(4)),
  fwRatio: parseFloat(fwRatio.toFixed(4)),
  tokens: tokens.length,
  types: types.size,
  inputFile: path.basename(inputFile),
  timestamp: new Date().toISOString(),
  // Not computed: no convergence tracking is implemented, so publish null rather
  // than a fabricated value — the status panel renders '-' for null (P0-3,
  // ECRR_BOSSCAT_AUDIT_DRIFT_20260829).
  convergence_rate_7d: null,
  warnings_7d: deltaPPL > 0.50 ? 1 : 0,  // Simple threshold for now
  delta_perplexity: parseFloat(deltaPPL.toFixed(4)),
  lii: parseFloat(LII.toFixed(4))
};

// Ensure output directory exists
fs.mkdirSync('artifacts/rsi', { recursive: true });

// Write metrics
fs.writeFileSync('artifacts/rsi/rsi.json', JSON.stringify(metrics, null, 2));

// Update baseline (exponential moving average, α=0.1)
const alpha = 0.1;
baseline.fwRatio = baseline.fwRatio * (1 - alpha) + fwRatio * alpha;
baseline.updatedAt = metrics.timestamp;
fs.writeFileSync(baselinePath, JSON.stringify(baseline, null, 2));

console.log('✅ RSI metrics extracted');
console.log(`   LII: ${metrics.LII} | ΔPPL: ${metrics.deltaPPL} | FW: ${metrics.fwRatio}`);
console.log(`   Output: artifacts/rsi/rsi.json`);

