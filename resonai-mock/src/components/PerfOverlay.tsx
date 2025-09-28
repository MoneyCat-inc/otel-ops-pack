'use client';

import { useEffect, useState } from 'react';
import { useBattery, useLowPowerMode } from '../hooks/useBattery';

export function PerfOverlay() {
  const battery = useBattery();
  const isLowPowerMode = useLowPowerMode();
  const [fps, setFps] = useState<number>(0);
  const [latency, setLatency] = useState<number>(0);

  useEffect(() => {
    // Simple FPS counter
    let frameCount = 0;
    let lastTime = performance.now();
    
    const countFrames = () => {
      frameCount++;
      const currentTime = performance.now();
      
      if (currentTime - lastTime >= 1000) {
        setFps(Math.round((frameCount * 1000) / (currentTime - lastTime)));
        frameCount = 0;
        lastTime = currentTime;
      }
      
      requestAnimationFrame(countFrames);
    };
    
    countFrames();
  }, []);

  useEffect(() => {
    // Simple latency measurement
    const measureLatency = () => {
      const start = performance.now();
      requestAnimationFrame(() => {
        const end = performance.now();
        setLatency(Math.round(end - start));
      });
    };
    
    const interval = setInterval(measureLatency, 1000);
    return () => clearInterval(interval);
  }, []);

  // Log battery info to console for debugging
  useEffect(() => {
    if (battery.supported) {
      console.log('Battery info:', {
        level: battery.level,
        charging: battery.charging,
        lowPowerMode: isLowPowerMode,
      });
    }
  }, [battery, isLowPowerMode]);

  return (
    <div className="fixed top-4 right-4 bg-black bg-opacity-80 text-white p-3 rounded-lg font-mono text-xs z-50">
      <div className="space-y-1">
        <div>FPS: {fps}</div>
        <div>Latency: {latency}ms</div>
        <div className={isLowPowerMode ? 'text-red-400' : ''}>
          {battery.supported
            ? `Battery: ${Math.round(battery.level * 100)}% ${battery.charging ? '⚡' : ''}`
            : 'Battery: n/a'}
        </div>
        {isLowPowerMode && (
          <div className="text-red-400 text-xs">
            Low Power Mode Available
          </div>
        )}
      </div>
    </div>
  );
}
