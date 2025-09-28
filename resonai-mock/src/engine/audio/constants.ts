/**
 * Audio Engine Constants - Safety Guardrails Configuration
 * 
 * T3: Safety Guardrails
 * Centralized configuration for strain detection thresholds and parameters.
 */

export interface StrainConstants {
  // Loudness detection
  LOUD_DB_THRESH: number;        // Loudness threshold in dBFS
  LOUD_MS: number;               // Duration threshold for loudness (ms)
  
  // Jitter detection
  JITTER_DELTA_CENTS: number;    // Jitter change threshold (cents)
  JITTER_WINDOW_MS: number;      // Window for jitter trend analysis (ms)
  
  // General thresholds
  MIN_VOICED_MS: number;         // Minimum voiced duration for detection (ms)
  COOLDOWN_SEC: number;          // Cooldown duration (seconds)
  
  // Signal processing
  EWMA_ALPHA: number;            // Exponential moving average smoothing factor
  FRAME_INTERVAL_MS: number;     // Expected frame interval (ms)
  
  // UI/UX
  PROGRESS_UPDATE_INTERVAL_MS: number; // Progress ring update interval
  ANIMATION_DURATION_MS: number;       // Animation duration for reduced motion
}

/**
 * Default strain detection constants
 * These values are tuned for vocal strain detection in speech practice
 */
export const STRAIN_CONSTANTS: StrainConstants = {
  // Loudness detection (-12 dBFS is moderately loud)
  LOUD_DB_THRESH: -12,
  LOUD_MS: 1200,                 // 1.2 seconds
  
  // Jitter detection (20 cents is noticeable pitch instability)
  JITTER_DELTA_CENTS: 20,
  JITTER_WINDOW_MS: 1500,        // 1.5 second window
  
  // General thresholds
  MIN_VOICED_MS: 800,            // 800ms minimum voiced
  COOLDOWN_SEC: 45,              // 45 second cooldown
  
  // Signal processing
  EWMA_ALPHA: 0.1,              // Smoothing factor
  FRAME_INTERVAL_MS: 100,        // 100ms frame intervals
  
  // UI/UX
  PROGRESS_UPDATE_INTERVAL_MS: 1000, // Update every second
  ANIMATION_DURATION_MS: 300,         // 300ms animations
};

/**
 * Conservative strain constants (more sensitive)
 * Use for users who are prone to vocal strain
 */
export const CONSERVATIVE_STRAIN_CONSTANTS: StrainConstants = {
  ...STRAIN_CONSTANTS,
  LOUD_DB_THRESH: -15,           // More sensitive to loudness
  LOUD_MS: 800,                  // Shorter duration threshold
  JITTER_DELTA_CENTS: 15,        // More sensitive to jitter
  JITTER_WINDOW_MS: 1000,        // Shorter analysis window
  MIN_VOICED_MS: 600,            // Shorter minimum voiced time
  COOLDOWN_SEC: 60,             // Longer cooldown
};

/**
 * Relaxed strain constants (less sensitive)
 * Use for experienced users or when testing
 */
export const RELAXED_STRAIN_CONSTANTS: StrainConstants = {
  ...STRAIN_CONSTANTS,
  LOUD_DB_THRESH: -9,            // Less sensitive to loudness
  LOUD_MS: 2000,                 // Longer duration threshold
  JITTER_DELTA_CENTS: 30,        // Less sensitive to jitter
  JITTER_WINDOW_MS: 2000,        // Longer analysis window
  MIN_VOICED_MS: 1000,           // Longer minimum voiced time
  COOLDOWN_SEC: 30,              // Shorter cooldown
};

/**
 * Strain constant presets for different user profiles
 */
export const STRAIN_PRESETS = {
  default: STRAIN_CONSTANTS,
  conservative: CONSERVATIVE_STRAIN_CONSTANTS,
  relaxed: RELAXED_STRAIN_CONSTANTS,
} as const;

export type StrainPreset = keyof typeof STRAIN_PRESETS;

/**
 * Validate strain constants
 */
export function validateStrainConstants(constants: Partial<StrainConstants>): boolean {
  const required = [
    'LOUD_DB_THRESH',
    'LOUD_MS',
    'JITTER_DELTA_CENTS',
    'JITTER_WINDOW_MS',
    'MIN_VOICED_MS',
    'COOLDOWN_SEC',
    'EWMA_ALPHA',
    'FRAME_INTERVAL_MS'
  ];
  
  return required.every(key => 
    constants[key as keyof StrainConstants] !== undefined &&
    typeof constants[key as keyof StrainConstants] === 'number' &&
    constants[key as keyof StrainConstants]! > 0
  );
}

/**
 * Get strain constants with validation
 */
export function getStrainConstants(preset: StrainPreset = 'default'): StrainConstants {
  const constants = STRAIN_PRESETS[preset];
  
  if (!validateStrainConstants(constants)) {
    console.warn('Invalid strain constants, falling back to defaults');
    return STRAIN_CONSTANTS;
  }
  
  return constants;
}

/**
 * Merge custom constants with defaults
 */
export function mergeStrainConstants(
  custom: Partial<StrainConstants>,
  preset: StrainPreset = 'default'
): StrainConstants {
  const defaults = getStrainConstants(preset);
  const merged = { ...defaults, ...custom };
  
  if (!validateStrainConstants(merged)) {
    console.warn('Invalid merged strain constants, using defaults');
    return defaults;
  }
  
  return merged;
}
