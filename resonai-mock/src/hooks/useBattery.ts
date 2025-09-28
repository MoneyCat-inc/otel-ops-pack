/**
 * Battery Awareness Hook
 * 
 * Provides battery level and charging status for performance optimization
 */

'use client';

import { useState, useEffect } from 'react';

interface BatteryInfo {
  level: number; // 0-1
  charging: boolean;
  supported: boolean;
  error?: string;
}

export function useBattery(): BatteryInfo {
  const [batteryInfo, setBatteryInfo] = useState<BatteryInfo>({
    level: 1,
    charging: true,
    supported: false,
  });

  useEffect(() => {
    const checkBattery = async () => {
      try {
        // Check if Battery API is supported
        if ('getBattery' in navigator && typeof navigator.getBattery === 'function') {
          const battery = await navigator.getBattery();
          
          const updateBatteryInfo = () => {
            setBatteryInfo({
              level: battery.level,
              charging: battery.charging,
              supported: true,
            });
          };

          // Set initial values
          updateBatteryInfo();

          // Listen for changes
          battery.addEventListener('levelchange', updateBatteryInfo);
          battery.addEventListener('chargingchange', updateBatteryInfo);

          // Cleanup
          return () => {
            battery.removeEventListener('levelchange', updateBatteryInfo);
            battery.removeEventListener('chargingchange', updateBatteryInfo);
          };
        } else {
          setBatteryInfo({
            level: 1,
            charging: true,
            supported: false,
            error: 'Battery API not supported',
          });
        }
      } catch (error) {
        setBatteryInfo({
          level: 1,
          charging: true,
          supported: false,
          error: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    };

    checkBattery();
  }, []);

  return batteryInfo;
}

/**
 * Battery Status Component
 * Shows battery level and charging status
 */
export function BatteryStatus({ className = '' }: { className?: string }) {
  const battery = useBattery();

  if (!battery.supported) {
    return (
      <div className={`text-xs text-gray-500 ${className}`}>
        Battery: n/a
      </div>
    );
  }

  const batteryPercentage = Math.round(battery.level * 100);
  const isLowBattery = battery.level < 0.2 && !battery.charging;
  
  return (
    <div className={`text-xs ${isLowBattery ? 'text-red-600' : 'text-gray-600'} ${className}`}>
      Battery: {batteryPercentage}%
      {battery.charging && ' 🔌'}
      {isLowBattery && ' ⚠️'}
    </div>
  );
}

/**
 * Low Power Mode Detection
 * Returns true if battery is low and not charging
 */
export function useLowPowerMode(): boolean {
  const battery = useBattery();
  return battery.supported && battery.level < 0.2 && !battery.charging;
}
