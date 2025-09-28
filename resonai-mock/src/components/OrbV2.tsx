/**
 * OrbV2 Component
 * 
 * C7: Dashboard Polish & UX
 * Resonance hue-based shimmer overlay with strain pulse animations.
 * Motion-safe with reduced-motion fallbacks. CSP-compliant class-based styling.
 */

'use client';

import React, { useEffect, useState } from 'react';
import { useReducedMotion } from '../hooks/useReducedMotion';

interface OrbV2Props {
  /** Resonance level (0-1) affects hue selection */
  resonance?: number;
  /** Strain level (0-1) affects pulse animation */
  strain?: number;
  /** Resonance bucket for direct hue selection */
  bucket?: 'front' | 'central' | 'back';
  /** Custom className for styling */
  className?: string;
  /** Whether to show the orb (for conditional rendering) */
  visible?: boolean;
  /** Aria label for accessibility */
  'aria-label'?: string;
}

const HUE_STEPS = 12;

function hueClassFrom(resonance?: number, bucket?: OrbV2Props['bucket']): string {
  if (bucket) return `orb-v2--${bucket}`;
  const v = typeof resonance === 'number' ? Math.max(0, Math.min(1, resonance)) : 0.5;
  const idx = Math.min(HUE_STEPS - 1, Math.round(v * (HUE_STEPS - 1)));
  return `orb-v2--h${idx}`;
}

export const OrbV2: React.FC<OrbV2Props> = ({
  resonance = 0.5,
  strain = 0.2,
  bucket,
  className = '',
  visible = true,
  'aria-label': ariaLabel
}) => {
  const motionSafe = useReducedMotion();

  if (!visible) return null;

  const hueClass = hueClassFrom(resonance, bucket);
  const hasStrain = strain > 0.3; // Threshold for showing strain pulse
  
  // Generate aria-label if not provided
  const generatedAriaLabel = ariaLabel || (bucket
    ? `Resonance ${bucket}`
    : `Resonance brightness ${(resonance ?? 0.5).toFixed(2)}`);

  return (
    <div
      className={[
        'orb-v2',
        hueClass,
        !motionSafe ? 'orb-v2__shimmer' : '',
        hasStrain && !motionSafe ? 'orb-v2__pulse--strain' : '',
        className
      ].filter(Boolean).join(' ')}
      role="img"
      aria-label={generatedAriaLabel}
      aria-hidden="false"
    >
      {/* Main orb */}
      <div className="orb-v2-main">
        {/* Shimmer overlay */}
        <div className="orb-v2-shimmer" />
        
        {/* Strain pulse ring */}
        <div className="orb-v2-pulse" />
        
        {/* Inner glow */}
        <div className="orb-v2-glow" />
      </div>
    </div>
  );
};

export default OrbV2;
