/**
 * MetricCard Component
 * 
 * C1: Progress Dashboard
 * Displays current metric value with 7-day delta and trend indicator.
 */

import React from 'react';
import { TrendSpark } from './TrendSpark';
import { useReducedMotion } from '../../hooks/useReducedMotion';

interface MetricCardProps {
  title: string;
  currentValue: number;
  previousValue: number;
  trend: 'up' | 'down' | 'stable';
  unit?: string;
  format?: 'percentage' | 'decimal' | 'integer';
  color?: 'blue' | 'green' | 'purple' | 'orange' | 'red';
  trendData?: number[];
  description?: string;
  className?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  title,
  currentValue,
  previousValue,
  trend,
  unit = '',
  format = 'decimal',
  color = 'blue',
  trendData = [],
  description,
  className = ''
}) => {
  const reducedMotion = useReducedMotion();

  // Calculate delta and percentage change
  const delta = currentValue - previousValue;
  const percentageChange = previousValue !== 0 ? (delta / previousValue) * 100 : 0;

  // Format values based on type
  const formatValue = (value: number): string => {
    switch (format) {
      case 'percentage':
        return `${(value * 100).toFixed(1)}%`;
      case 'integer':
        return Math.round(value).toString();
      case 'decimal':
      default:
        return value.toFixed(2);
    }
  };

  // Color classes
  const colorClasses = {
    blue: {
      bg: 'bg-blue-50',
      border: 'border-blue-200',
      text: 'text-blue-800',
      accent: 'text-blue-600'
    },
    green: {
      bg: 'bg-green-50',
      border: 'border-green-200',
      text: 'text-green-800',
      accent: 'text-green-600'
    },
    purple: {
      bg: 'bg-purple-50',
      border: 'border-purple-200',
      text: 'text-purple-800',
      accent: 'text-purple-600'
    },
    orange: {
      bg: 'bg-orange-50',
      border: 'border-orange-200',
      text: 'text-orange-800',
      accent: 'text-orange-600'
    },
    red: {
      bg: 'bg-red-50',
      border: 'border-red-200',
      text: 'text-red-800',
      accent: 'text-red-600'
    }
  };

  const colors = colorClasses[color];

  // Trend indicator
  const getTrendIcon = () => {
    if (trend === 'up') return '↗';
    if (trend === 'down') return '↘';
    return '→';
  };

  const getTrendColor = () => {
    if (trend === 'up') return 'text-green-600';
    if (trend === 'down') return 'text-red-600';
    return 'text-gray-600';
  };

  return (
    <div 
      className={`p-6 rounded-lg border-2 ${colors.bg} ${colors.border} ${className}`}
      role="region"
      aria-labelledby={`${title.toLowerCase().replace(/\s+/g, '-')}-title`}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 
          id={`${title.toLowerCase().replace(/\s+/g, '-')}-title`}
          className={`text-lg font-semibold ${colors.text}`}
        >
          {title}
        </h3>
        
        {/* Trend indicator */}
        <div className={`flex items-center space-x-1 ${getTrendColor()}`}>
          <span className="text-lg" aria-hidden="true">
            {getTrendIcon()}
          </span>
          <span className="text-sm font-medium">
            {trend === 'up' ? 'Improving' : trend === 'down' ? 'Declining' : 'Stable'}
          </span>
        </div>
      </div>

      {/* Current value */}
      <div className="mb-4">
        <div className={`text-3xl font-bold ${colors.accent} mb-1`}>
          {formatValue(currentValue)}
          {unit && <span className="text-lg ml-1">{unit}</span>}
        </div>
        
        {/* Delta */}
        {previousValue !== 0 && (
          <div className={`text-sm ${delta >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {delta >= 0 ? '+' : ''}{formatValue(delta)} {unit}
            <span className="ml-1">
              ({percentageChange >= 0 ? '+' : ''}{percentageChange.toFixed(1)}%)
            </span>
          </div>
        )}
      </div>

      {/* Trend sparkline */}
      {trendData.length > 0 && (
        <div className="mb-3">
          <TrendSpark
            data={trendData}
            color={colors.accent.replace('text-', '#').replace('-600', '')}
            aria-label={`${title} trend over time`}
          />
        </div>
      )}

      {/* Description */}
      {description && (
        <p className={`text-sm ${colors.text} opacity-75`}>
          {description}
        </p>
      )}
    </div>
  );
};
