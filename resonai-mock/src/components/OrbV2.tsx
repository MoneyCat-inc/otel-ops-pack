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
    '--pulse-frequency': `${pulseFrequency}s`
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

      <style jsx>{`
        .orb-v2-container {
          position: relative;
          width: var(--orb-size);
          height: var(--orb-size);
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .orb-v2-main {
          position: relative;
          width: 100%;
          height: 100%;
          border-radius: 50%;
          background: radial-gradient(
            circle at 30% 30%,
            hsl(var(--resonance-hue), var(--resonance-saturation), calc(var(--resonance-lightness) + 20%)),
            hsl(var(--resonance-hue), var(--resonance-saturation), var(--resonance-lightness)),
            hsl(var(--resonance-hue), calc(var(--resonance-saturation) - 20%), calc(var(--resonance-lightness) - 20%))
          );
          box-shadow: 
            0 0 20px hsla(var(--resonance-hue), var(--resonance-saturation), var(--resonance-lightness), 0.3),
            inset 0 0 20px hsla(var(--resonance-hue), var(--resonance-saturation), calc(var(--resonance-lightness) + 10%), 0.2);
        }

        .orb-v2-shimmer {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          border-radius: 50%;
          background: linear-gradient(
            45deg,
            transparent 30%,
            hsla(var(--resonance-hue), var(--resonance-saturation), calc(var(--resonance-lightness) + 30%), 0.6) 50%,
            transparent 70%
          );
          animation: shimmer 2s ease-in-out infinite;
          animation-delay: calc(var(--shimmer-intensity) * -0.5s);
        }

        .orb-v2-pulse {
          position: absolute;
          top: -10px;
          left: -10px;
          right: -10px;
          bottom: -10px;
          border-radius: 50%;
          border: 2px solid hsla(var(--resonance-hue), var(--resonance-saturation), var(--resonance-lightness), 0.4);
          animation: pulse var(--pulse-frequency) ease-in-out infinite;
        }

        .orb-v2-glow {
          position: absolute;
          top: 20%;
          left: 20%;
          width: 60%;
          height: 60%;
          border-radius: 50%;
          background: radial-gradient(
            circle,
            hsla(var(--resonance-hue), var(--resonance-saturation), calc(var(--resonance-lightness) + 40%), 0.3),
            transparent 70%
          );
        }

        /* Animations */
        @keyframes shimmer {
          0%, 100% {
            transform: rotate(0deg) scale(1);
            opacity: 0.3;
          }
          50% {
            transform: rotate(180deg) scale(1.1);
            opacity: calc(0.3 + var(--shimmer-intensity) * 0.7);
          }
        }

        @keyframes pulse {
          0%, 100% {
            transform: scale(1);
            opacity: 0.4;
          }
          50% {
            transform: scale(1.05);
            opacity: 0.8;
          }
        }

        /* Motion-safe overrides */
        .orb-v2-shimmer.motion-safe {
          animation: none;
          opacity: 0.5;
          transform: rotate(45deg);
        }

        .orb-v2-pulse.motion-safe {
          animation: none;
          opacity: 0.6;
          transform: scale(1.02);
        }

        /* Reduced motion fallbacks */
        @media (prefers-reduced-motion: reduce) {
          .orb-v2-shimmer {
            animation: none;
            opacity: 0.5;
            transform: rotate(45deg);
          }

          .orb-v2-pulse {
            animation: none;
            opacity: 0.6;
            transform: scale(1.02);
          }
        }

        /* High contrast mode support */
        @media (prefers-contrast: high) {
          .orb-v2-main {
            border: 2px solid hsl(var(--resonance-hue), 100%, 20%);
          }
          
          .orb-v2-pulse {
            border-color: hsl(var(--resonance-hue), 100%, 20%);
          }
        }

        /* Focus styles for keyboard navigation */
        .orb-v2-container:focus-visible {
          outline: 2px solid hsl(var(--resonance-hue), var(--resonance-saturation), var(--resonance-lightness));
          outline-offset: 4px;
        }
      `}</style>
    </div>
  );
};

export default OrbV2;
