/**
 * SafetyStrip Component
 * 
 * C1: Progress Dashboard
 * Timeline visualization of safety events (strain detection).
 */

import React from 'react';
import { useReducedMotion } from '../../hooks/useReducedMotion';

interface SafetyEvent {
  date: string;
  strainCount: number;
  strainRate: number;
  reasons?: string[];
}

interface SafetyStripProps {
  events: SafetyEvent[];
  className?: string;
}

export const SafetyStrip: React.FC<SafetyStripProps> = ({
  events,
  className = ''
}) => {
  const reducedMotion = useReducedMotion();

  if (events.length === 0) {
    return (
      <div className={`p-6 rounded-lg border-2 border-gray-200 bg-gray-50 ${className}`}>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Safety Timeline</h3>
        <div className="flex items-center justify-center py-8">
          <span className="text-gray-500">No safety events recorded</span>
        </div>
      </div>
    );
  }

  // Calculate max strain count for scaling
  const maxStrainCount = Math.max(...events.map(e => e.strainCount), 1);
  
  // Group events by week for better visualization
  const weeklyEvents = groupEventsByWeek(events);

  return (
    <div className={`p-6 rounded-lg border-2 border-orange-200 bg-orange-50 ${className}`}>
      <h3 className="text-lg font-semibold text-orange-800 mb-4">Safety Timeline</h3>
      
      {/* Timeline */}
      <div className="space-y-3">
        {weeklyEvents.map((week, index) => (
          <div key={week.weekStart} className="flex items-center space-x-4">
            {/* Week label */}
            <div className="w-20 text-sm text-orange-700 font-medium">
              {formatWeekLabel(week.weekStart)}
            </div>
            
            {/* Timeline bar */}
            <div className="flex-1 relative">
              <div className="h-8 bg-orange-100 rounded-full overflow-hidden">
                {/* Safety events as colored segments */}
                {week.days.map((day, dayIndex) => {
                  const intensity = day.strainCount / maxStrainCount;
                  const width = 100 / week.days.length;
                  
                  return (
                    <div
                      key={day.date}
                      className="absolute h-full"
                      style={{
                        left: `${dayIndex * width}%`,
                        width: `${width}%`,
                        backgroundColor: intensity > 0.5 
                          ? '#DC2626' // red-600
                          : intensity > 0.2 
                          ? '#F59E0B' // amber-500
                          : '#10B981', // emerald-500
                        opacity: intensity > 0 ? 0.8 : 0.3,
                        transition: reducedMotion ? 'none' : 'all 0.3s ease'
                      }}
                      title={`${day.date}: ${day.strainCount} strain events`}
                      aria-label={`${day.date}: ${day.strainCount} strain events`}
                    />
                  );
                })}
              </div>
              
              {/* Event markers */}
              <div className="absolute top-0 left-0 w-full h-full pointer-events-none">
                {week.days.map((day, dayIndex) => {
                  if (day.strainCount === 0) return null;
                  
                  const left = (dayIndex * 100) / week.days.length;
                  
                  return (
                    <div
                      key={`marker-${day.date}`}
                      className="absolute w-2 h-2 bg-white rounded-full border border-orange-300"
                      style={{
                        left: `${left}%`,
                        top: '50%',
                        transform: 'translate(-50%, -50%)',
                        transition: reducedMotion ? 'none' : 'all 0.3s ease'
                      }}
                      aria-hidden="true"
                    />
                  );
                })}
              </div>
            </div>
            
            {/* Week summary */}
            <div className="w-24 text-sm text-orange-700">
              {week.totalStrainCount} events
            </div>
          </div>
        ))}
      </div>
      
      {/* Legend */}
      <div className="mt-4 pt-4 border-t border-orange-200">
        <div className="flex items-center space-x-6 text-sm text-orange-700">
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 bg-emerald-500 rounded"></div>
            <span>Low risk</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 bg-amber-500 rounded"></div>
            <span>Moderate risk</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-3 h-3 bg-red-600 rounded"></div>
            <span>High risk</span>
          </div>
        </div>
      </div>
      
      {/* Summary stats */}
      <div className="mt-4 pt-4 border-t border-orange-200">
        <div className="grid grid-cols-3 gap-4 text-sm">
          <div className="text-center">
            <div className="font-semibold text-orange-800">
              {events.reduce((sum, e) => sum + e.strainCount, 0)}
            </div>
            <div className="text-orange-600">Total Events</div>
          </div>
          <div className="text-center">
            <div className="font-semibold text-orange-800">
              {(events.reduce((sum, e) => sum + e.strainRate, 0) / events.length * 100).toFixed(1)}%
            </div>
            <div className="text-orange-600">Avg Rate</div>
          </div>
          <div className="text-center">
            <div className="font-semibold text-orange-800">
              {events.filter(e => e.strainCount > 0).length}
            </div>
            <div className="text-orange-600">Active Days</div>
          </div>
        </div>
      </div>
    </div>
  );
};

// Helper functions
function groupEventsByWeek(events: SafetyEvent[]): Array<{
  weekStart: string;
  days: SafetyEvent[];
  totalStrainCount: number;
}> {
  const weeks = new Map<string, SafetyEvent[]>();
  
  for (const event of events) {
    const date = new Date(event.date);
    const weekStart = new Date(date);
    weekStart.setDate(date.getDate() - date.getDay()); // Start of week (Sunday)
    const weekKey = weekStart.toISOString().split('T')[0];
    
    if (!weeks.has(weekKey)) {
      weeks.set(weekKey, []);
    }
    weeks.get(weekKey)!.push(event);
  }
  
  return Array.from(weeks.entries()).map(([weekStart, days]) => ({
    weekStart,
    days: days.sort((a, b) => a.date.localeCompare(b.date)),
    totalStrainCount: days.reduce((sum, day) => sum + day.strainCount, 0)
  })).sort((a, b) => a.weekStart.localeCompare(b.weekStart));
}

function formatWeekLabel(weekStart: string): string {
  const date = new Date(weekStart);
  const month = date.toLocaleDateString('en-US', { month: 'short' });
  const day = date.getDate();
  return `${month} ${day}`;
}
