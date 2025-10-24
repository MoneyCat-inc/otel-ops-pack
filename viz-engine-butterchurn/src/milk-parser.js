/**
 * .milk preset parser for Butterchurn - CORRECTED SCHEMA
 * ECRR: BossCat Remediation #3 - CRITICAL fix (proper key normalization)
 * 
 * Converts Milkdrop .milk format to Butterchurn JSON format
 * Reference: butterchurn-presets/presets/converted/*.json
 */

// Milkdrop -> Butterchurn key mapping (CORRECTED against actual converted presets)
// Reference: butterchurn-presets/presets/converted/Flexi - mindblob mix.json and others
const KEY_MAP = {
  // Float values (f prefix) - CORRECTED with underscores
  fRating: 'rating',
  fGammaAdj: 'gammaadj',
  fDecay: 'decay',
  fVideoEchoZoom: 'echo_zoom',              // FIXED: echozoom -> echo_zoom
  fVideoEchoAlpha: 'echo_alpha',            // FIXED: echoalpha -> echo_alpha
  fWaveAlpha: 'wave_a',
  fWaveScale: 'wave_scale',
  fWaveSmoothing: 'wave_smoothing',
  fWaveParam: 'wave_mystery',
  fModWaveAlphaStart: 'modwavealphastart',  // FIXED: modwavealphastrt -> modwavealphastart (typo)
  fModWaveAlphaEnd: 'modwavealphaend',
  fWarpAnimSpeed: 'warpanimspeed',
  fWarpScale: 'warpscale',
  fZoomExponent: 'zoomexp',
  fShader: 'fshader',                       // FIXED: shader -> fshader (keep f prefix)
  // Boolean values (b prefix) - CORRECTED with underscores and proper names
  bAdditiveWaves: 'additivewave',           // FIXED: wave_additive -> additivewave (no prefix)
  bWaveDots: 'wave_dots',                   // FIXED: wavedots -> wave_dots
  bWaveThick: 'wave_thick',                 // FIXED: wavethick -> wave_thick
  bModWaveAlphaByVolume: 'modwavealphabyvolume',
  bMaximizeWaveColor: 'wave_brighten',      // FIXED: maximizewavecolor -> wave_brighten
  bTexWrap: 'wrap',                         // FIXED: texwrap -> wrap
  bDarkenCenter: 'darken_center',           // FIXED: darkcenter -> darken_center
  bRedBlueStereo: 'red_blue',               // FIXED: redbluestreo -> red_blue (typo + wrong name)
  bBrighten: 'brighten',
  bDarken: 'darken',
  bSolarize: 'solarize',
  bInvert: 'invert',
  // Integer values (n prefix) - CORRECTED with underscores
  nVideoEchoOrientation: 'echo_orient',     // FIXED: echoorientation -> echo_orient
  nWaveMode: 'wave_mode',
  nMotionVectorsX: 'mv_x',
  nMotionVectorsY: 'mv_y',
  // Direct mappings (no prefix)
  zoom: 'zoom',
  rot: 'rot',
  cx: 'cx',
  cy: 'cy',
  dx: 'dx',
  dy: 'dy',
  warp: 'warp',
  sx: 'sx',
  sy: 'sy',
  wave_r: 'wave_r',
  wave_g: 'wave_g',
  wave_b: 'wave_b',
  wave_x: 'wave_x',
  wave_y: 'wave_y',
  ob_size: 'ob_size',
  ob_r: 'ob_r',
  ob_g: 'ob_g',
  ob_b: 'ob_b',
  ob_a: 'ob_a',
  ib_size: 'ib_size',
  ib_r: 'ib_r',
  ib_g: 'ib_g',
  ib_b: 'ib_b',
  ib_a: 'ib_a',
  mv_dx: 'mv_dx',
  mv_dy: 'mv_dy',
  mv_l: 'mv_l',
  mv_r: 'mv_r',
  mv_g: 'mv_g',
  mv_b: 'mv_b',
  mv_a: 'mv_a'
};

/**
 * Parse .milk preset string to Butterchurn preset object
 * @param {string} milkText - Raw .milk file content
 * @param {string} name - Preset name
 * @returns {object} Butterchurn preset object with correct schema
 */
function parseMilkPreset(milkText, name) {
  const preset = {
    name: name || 'custom-preset',
    // Butterchurn requires these fields
    version: 1,
    // Base values with normalized keys
    baseVals: {},
    // EEL equation strings
    init_eqs_eel: '',
    frame_eqs_eel: '',
    pixel_eqs_eel: ''
  };

  // Extract base values and normalize keys
  const baseValRegex = /^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([0-9.-]+)/gm;
  let match;
  
  while ((match = baseValRegex.exec(milkText)) !== null) {
    const rawKey = match[1];
    const value = parseFloat(match[2]);
    
    // Map to Butterchurn key or keep original if no mapping
    const normalizedKey = KEY_MAP[rawKey] || rawKey;
    preset.baseVals[normalizedKey] = value;
  }

  // Extract per_frame equations
  const perFrameMatch = milkText.match(/per_frame[^=]*=([^]*?)(?=per_pixel|wavecode|shapecode|$)/i);
  if (perFrameMatch) {
    preset.frame_eqs_eel = perFrameMatch[1].trim();
  }

  // Extract per_pixel equations
  const perPixelMatch = milkText.match(/per_pixel[^=]*=([^]*?)(?=wavecode|shapecode|$)/i);
  if (perPixelMatch) {
    preset.pixel_eqs_eel = perPixelMatch[1].trim();
  }

  // Extract preset init equations
  const initMatch = milkText.match(/\/\*\s*preset\s+init\s*\*\/([^]*?)(?=\/\*\s*per_frame|$)/i);
  if (initMatch) {
    preset.init_eqs_eel = initMatch[1].trim();
  }

  return preset;
}

/**
 * Convert .milk format equations to Butterchurn format
 * Handles multi-line per_frame_N and per_pixel_N syntax
 */
function convertEquations(milkText, eqType) {
  const equations = [];
  const regex = new RegExp(`${eqType}_(\\d+)\\s*=\\s*(.+)`, 'g');
  let match;

  while ((match = regex.exec(milkText)) !== null) {
    equations.push(match[2].trim());
  }

  return equations.join(';\n');
}

/**
 * Enhanced parser that handles per_frame_N and per_pixel_N syntax
 * Outputs Butterchurn-compatible schema with normalized keys
 */
function parseMilkPresetEnhanced(milkText, name) {
  const preset = parseMilkPreset(milkText, name);

  // Extract per_frame_N equations (override if present)
  const frameEqs = convertEquations(milkText, 'per_frame');
  if (frameEqs) {
    preset.frame_eqs_eel = frameEqs;
  }

  // Extract per_pixel_N equations (override if present)
  const pixelEqs = convertEquations(milkText, 'per_pixel');
  if (pixelEqs) {
    preset.pixel_eqs_eel = pixelEqs;
  }

  // Ensure required fields exist (Butterchurn schema validation) - CORRECTED keys
  if (!preset.baseVals.decay) preset.baseVals.decay = 0.98;
  if (!preset.baseVals.gammaadj) preset.baseVals.gammaadj = 2.0;
  if (!preset.baseVals.echo_zoom) preset.baseVals.echo_zoom = 1.0;       // FIXED: echozoom -> echo_zoom
  if (!preset.baseVals.echo_alpha) preset.baseVals.echo_alpha = 0.5;     // FIXED: echoalpha -> echo_alpha

  return preset;
}

/**
 * BOSSCAT FIX: Consolidate numbered equation lines into single strings
 * Fixes: per_frame_1, per_frame_2 → per_frame (single string)
 */
function joinNumbered(prefix, obj) {
  const lines = [];
  const keys = Object.keys(obj).filter(k => k.startsWith(prefix))
                               .sort((a,b) => {
                                 const ai = parseInt(a.slice(prefix.length), 10) || 0;
                                 const bi = parseInt(b.slice(prefix.length), 10) || 0;
                                 return ai - bi;
                               });
  for (const k of keys) {
    if (obj[k] != null && String(obj[k]).trim()) {
      lines.push(String(obj[k]).trim().replace(/;?$/, ';'));
    }
  }
  return lines.join('\n');
}

/**
 * BOSSCAT FIX: Ensure numeric types (prevent string-to-NaN drift)
 */
function ensureNumber(v, fallback) {
  if (v === undefined || v === null || v === '') return fallback;
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

/**
 * GATE #011 FIX: Sanitize EEL code (strip illegal tokens)
 * Butterchurn's minified EEL compiler rejects 'return' and other function keywords
 */
function sanitizeEel(code) {
  if (!code || typeof code !== 'string') return '';
  return code
    .replace(/\breturn\b/gi, '')         // Strip 'return' keyword (breaks EEL evaluator)
    .replace(/\bfunction\b/gi, '')       // Strip 'function' keyword
    .replace(/;+$/g, '')                 // Remove trailing semicolons
    .trim();
}

/**
 * GATE #011 FIX: Ensure minimal wave/shape stubs (prevents undefined.length crash)
 */
function ensureVizScaffold(preset) {
  // Add minimal no-op wave if empty (Butterchurn iterates waves array)
  if (!preset.waves || preset.waves.length === 0) {
    preset.waves = [{
      baseVals: {
        enabled: 0,        // Disabled = won't render
        samples: 512,
        sep: 0,
        scaling: 1.0,
        spectrum: 0,
        smoothing: 0.5,
        r: 1, g: 1, b: 1, a: 0,  // alpha=0 = invisible
        usedots: 0,
        thick: 0,
        additive: 0
      },
      init_eqs_eel: '',
      frame_eqs_eel: '',
      point_eqs_eel: ''
    }];
  }
  
  // Add minimal no-op shape if empty (Butterchurn iterates shapes array)
  if (!preset.shapes || preset.shapes.length === 0) {
    preset.shapes = [{
      baseVals: {
        enabled: 0,        // Disabled = won't render
        sides: 4,
        additive: 0,
        thickoutline: 0,
        textured: 0,
        x: 0.5, y: 0.5,
        rad: 0.1,
        r: 0, g: 0, b: 0, a: 0  // alpha=0 = invisible
      },
      init_eqs_eel: '',
      frame_eqs_eel: ''
    }];
  }
  
  return preset;
}

/**
 * BOSSCAT FIX: Normalize preset to guarantee Butterchurn-safe structure
 * - Consolidates equation lines into single strings
 * - Guarantees arrays for waves/shapes
 * - Backfills critical defaults
 * - Coerces numbers to prevent NaN propagation
 */
function normalizePreset(preset) {
  // 1) Equation strings (consolidate numbered lines) + GATE #011: SANITIZE
  const init_eqs   = sanitizeEel(preset.init_eqs_eel   || preset.init_eqs   || '');
  const per_frame  = sanitizeEel(preset.frame_eqs_eel  || preset.per_frame  || '');
  const per_pixel  = sanitizeEel(preset.pixel_eqs_eel  || preset.per_pixel  || '');

  // 2) Arrays (butterchurn iterates these - undefined.length was the crash)
  let shapes = Array.isArray(preset.shapes) ? preset.shapes : [];
  let waves  = Array.isArray(preset.waves)  ? preset.waves  : [];

  // 3) Base defaults (butterchurn-safe baseline)
  const base = Object.assign({
    // Core parameters
    gamma: 2.0,
    decay: 0.98,
    zoom:  1.0,
    rot:   0.0,
    cx:    0.5,
    cy:    0.5,
    dx:    0.0,
    dy:    0.0,
    sx:    1.0,
    sy:    1.0,
    // Fixed mappings from KEY_MAP
    wrap:  1,          // bTexWrap → wrap
    echo_zoom: 1.0,    // fVideoEchoZoom → echo_zoom
    echo_alpha: 0.0,   // fVideoEchoAlpha → echo_alpha
    echo_orient: 0,    // nVideoEchoOrientation → echo_orient
    red_blue: 0,       // bRedBlueStereo → red_blue
    additivewave: 0,   // bAdditiveWaves → additivewave
    wave_mode: 0,
    wave_thick: 0,
    darken_center: 0,
    invert: 0,
    brighten: 0,
    darken: 0,
    solarize: 0,
    fshader: 0
  }, preset.baseVals || {});

  // 4) Number coercion on common scalars (prevent string drift)
  const numberKeys = ['gamma', 'decay', 'zoom', 'rot', 'cx', 'cy', 'dx', 'dy', 'sx', 'sy', 
                      'echo_zoom', 'echo_alpha', 'wave_a', 'wave_r', 'wave_g', 'wave_b'];
  for (const k of numberKeys) {
    if (k in base) base[k] = ensureNumber(base[k], base[k]);
  }

  // 5) Boolean → integer (0/1) coercion
  const boolKeys = ['wrap', 'red_blue', 'additivewave', 'wave_mode', 'wave_thick', 
                    'darken_center', 'invert', 'brighten', 'darken', 'solarize', 'fshader'];
  for (const k of boolKeys) {
    if (k in base) base[k] = base[k] ? 1 : 0;
  }

  // GATE #011: Assemble preset with sanitized equations
  const normalized = {
    name: preset.name || 'custom',
    baseVals: base,
    init_eqs_eel: init_eqs,
    frame_eqs_eel: per_frame,
    pixel_eqs_eel: per_pixel,
    shapes,
    waves
  };
  
  // GATE #011: Add minimal scaffolding to prevent undefined.length
  return ensureVizScaffold(normalized);
}

module.exports = {
  parseMilkPreset,
  parseMilkPresetEnhanced,
  normalizePreset,
  sanitizeEel,
  ensureVizScaffold
};

