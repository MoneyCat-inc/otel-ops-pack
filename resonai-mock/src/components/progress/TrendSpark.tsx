/**
 * TrendSpark Component
 * 
 * C1: Progress Dashboard
 * SVG mini-charts for trend visualization with reduced motion support.
 */

import React from 'react';
import { useReducedMotion } from '../../hooks/useReducedMotion';

interface TrendSparkProps {
  data: number[];
  width?: number;
  height?: number;
  color?: string;
  strokeWidth?: number;
  className?: string;
  'aria-label'?: string;
}

export const TrendSpark: React.FC<TrendSparkProps> = ({
  data,
  width = 120,
  height = 40,
  color = '#3B82F6',
  strokeWidth = 2,
  className = '',
  'aria-label': ariaLabel
}) => {
  const reducedMotion = useReducedMotion();

  if (data.length === 0) {
    return (
      <div 
        className={`flex items-center justify-center ${className}`}
        style={{ width, height }}
        aria-label={ariaLabel || 'No data available'}
      >
        <span className="text-gray-400 text-sm">No data</span>
      </div>
    );
  }

  // Normalize data to fit within the SVG bounds
  const minValue = Math.min(...data);
  const maxValue = Math.max(...data);
  const range = maxValue - minValue || 1; // Avoid division by zero
  
  const normalizedData = data.map(value => 
    ((value - minValue) / range) * (height - strokeWidth * 2) + strokeWidth
  );

  // Generate SVG path
  const stepX = width / (data.length - 1);
  const pathData = normalizedData
    .map((y, index) => {
      const x = index * stepX;
      return `${index === 0 ? 'M' : 'L'} ${x} ${height - y}`;
    })
    .join(' ');

  return (
    <div className={className} role="img" aria-label={ariaLabel || 'Trend chart'}>
      <svg
        width={width}
        height={height}
        viewBox={`0 0 ${width} ${height}`}
        className="overflow-visible"
      >
        {/* Background grid lines */}
        <defs>
          <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
            <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#E5E7EB" strokeWidth="0.5" opacity="0.3"/>
          </pattern>
        </defs>
        
        {/* Grid background */}
        <rect width={width} height={height} fill="url(#grid)" />
        
        {/* Trend line */}
        <path
          d={pathData}
          fill="none"
          stroke={color}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeLinejoin="round"
          className={reducedMotion ? '' : 'transition-all duration-300'}
        />
        
        {/* Data points */}
        {normalizedData.map((y, index) => {
          const x = index * stepX;
          return (
            <circle
              key={index}
              cx={x}
              cy={height - y}
              r={strokeWidth}
              fill={color}
              className={reducedMotion ? '' : 'transition-all duration-300'}
            />
          );
        })}
      </svg>
    </div>
  );
};
