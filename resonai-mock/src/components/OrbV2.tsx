/**
 * OrbV2 Component
 * 
 * C7: Dashboard Polish & UX
 * Resonance hue-based shimmer overlay with strain pulse animations.
 * Motion-safe with reduced-motion fallbacks.
 */

'use client';

import React, { useEffect, useState } from 'react';

interface OrbV2Props {
  /** Resonance level (0-1) affects shimmer intensity */
  resonance?: number;
  /** Strain level (0-1) affects pulse frequency */
  strain?: number;
  /** Size of the orb in pixels */
  size?: number;
  /** Custom className for styling */
  className?: string;
  /** Whether to show the orb (for conditional rendering) */
  visible?: boolean;
  /** Aria label for accessibility */
  'aria-label'?: string;
}

export const OrbV2: React.FC<OrbV2Props> = ({
  resonance = 0.5,
  strain = 0.2,
  size = 200,
  className = '',
  visible = true,
  'aria-label': ariaLabel = 'Resonance orb visualization'
}) => {
  const [motionSafe, setMotionSafe] = useState(false);

  useEffect(() => {
    // Check for reduced motion preference
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setMotionSafe(mediaQuery.matches);

    const handleChange = (e: MediaQueryListEvent) => {
      setMotionSafe(e.matches);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  if (!visible) return null;

  // Calculate animation parameters based on resonance and strain
  const shimmerIntensity = Math.max(0.3, resonance * 0.8);
  const pulseFrequency = Math.max(0.5, strain * 2);
  const hue = Math.round(200 + resonance * 160); // Blue to purple spectrum
  const saturation = Math.round(60 + resonance * 40); // 60-100%
  const lightness = Math.round(50 + resonance * 30); // 50-80%

  // CSS custom properties for dynamic theming
  const orbStyle = {
    '--orb-size': `${size}px`,
    '--resonance-hue': hue,
    '--resonance-saturation': `${saturation}%`,
    '--resonance-lightness': `${lightness}%`,
    '--shimmer-intensity': shimmerIntensity,
    '--pulse-frequency': `${pulseFrequency}s`,
    width: `${size}px`,
    height: `${size}px`
  } as React.CSSProperties;

  // Dynamic background style for the main orb
  const orbMainStyle = {
    background: `radial-gradient(
      circle at 30% 30%,
      hsl(${hue}, ${saturation}%, ${lightness + 20}%),
      hsl(${hue}, ${saturation}%, ${lightness}%),
      hsl(${hue}, ${Math.max(0, saturation - 20)}%, ${Math.max(0, lightness - 20)}%)
    )`,
    boxShadow: `
      0 0 20px hsla(${hue}, ${saturation}%, ${lightness}%, 0.3),
      inset 0 0 20px hsla(${hue}, ${saturation}%, ${lightness + 10}%, 0.2)
    `
  } as React.CSSProperties;

  return (
    <div
      className={`orb-v2-container ${className}`}
      style={orbStyle}
      role="img"
      aria-label={ariaLabel}
      aria-hidden="false"
    >
      {/* Main orb */}
      <div className="orb-v2-main">
        {/* Shimmer overlay */}
        <div className={`orb-v2-shimmer ${motionSafe ? 'motion-safe' : ''}`} />
        
        {/* Strain pulse ring */}
        <div className={`orb-v2-pulse ${motionSafe ? 'motion-safe' : ''}`} />
        
        {/* Inner glow */}
        <div className="orb-v2-glow" />
      </div>

    </div>
  );
};

export default OrbV2;
