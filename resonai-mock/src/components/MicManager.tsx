/**
 * Mic Manager - Clean Audio Input
 * 
 * INV-03A: Mic capture with EC/NS/AGC disabled for clean input
 * Verifies constraints via track.getSettings()
 */

'use client';

import { useState, useEffect, useRef } from 'react';

interface MicSettings {
  echoCancellation: boolean;
  noiseSuppression: boolean;
  autoGainControl: boolean;
  sampleRate: number;
  channelCount: number;
}

interface MicState {
  isSupported: boolean;
  hasPermission: boolean;
  isActive: boolean;
  stream: MediaStream | null;
  settings: MicSettings | null;
  error: string | null;
}

export function useMicManager() {
  const [state, setState] = useState<MicState>({
    isSupported: false,
    hasPermission: false,
    isActive: false,
    stream: null,
    settings: null,
    error: null,
  });

  const streamRef = useRef<MediaStream | null>(null);

  // Check browser support
  useEffect(() => {
    const isSupported = !!(
      navigator.mediaDevices &&
      typeof navigator.mediaDevices.getUserMedia === 'function' &&
      window.AudioContext
    );
    
    setState(prev => ({ ...prev, isSupported }));
  }, []);

  const requestMic = async () => {
    if (!state.isSupported) {
      setState(prev => ({ ...prev, error: 'Browser does not support getUserMedia' }));
      return;
    }

    try {
      setState(prev => ({ ...prev, error: null }));

      // Request mic with clean constraints (EC/NS/AGC disabled)
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false,
          sampleRate: 16000, // Optimal for voice processing
          channelCount: 1,   // Mono for voice
        }
      });

      // Verify actual settings
      const track = stream.getAudioTracks()[0];
      const settings = track.getSettings();
      
      const micSettings: MicSettings = {
        echoCancellation: settings.echoCancellation ?? false,
        noiseSuppression: settings.noiseSuppression ?? false,
        autoGainControl: settings.autoGainControl ?? false,
        sampleRate: settings.sampleRate ?? 16000,
        channelCount: settings.channelCount ?? 1,
      };

      // Log settings for verification
      console.table(micSettings);

      streamRef.current = stream;
      setState(prev => ({
        ...prev,
        hasPermission: true,
        isActive: true,
        stream,
        settings: micSettings,
      }));

    } catch (error) {
      console.error('Mic request failed:', error);
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Unknown error',
      }));
    }
  };

  const stopMic = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    
    setState(prev => ({
      ...prev,
      isActive: false,
      stream: null,
    }));
  };

  const cleanup = () => {
    stopMic();
  };

  useEffect(() => {
    return cleanup;
  }, []);

  return {
    ...state,
    requestMic,
    stopMic,
  };
}

// Mic Settings Display Component
export function MicSettingsDisplay({ settings }: { settings: MicSettings | null }) {
  if (!settings) return null;

  const isClean = !settings.echoCancellation && 
                  !settings.noiseSuppression && 
                  !settings.autoGainControl;

  return (
    <div className="bg-white rounded-lg shadow p-4">
      <h3 className="text-lg font-semibold mb-3">Microphone Settings</h3>
      
      <div className="space-y-2">
        <div className="flex justify-between">
          <span>Echo Cancellation:</span>
          <span className={settings.echoCancellation ? 'text-red-600' : 'text-green-600'}>
            {settings.echoCancellation ? 'ON' : 'OFF'}
          </span>
        </div>
        
        <div className="flex justify-between">
          <span>Noise Suppression:</span>
          <span className={settings.noiseSuppression ? 'text-red-600' : 'text-green-600'}>
            {settings.noiseSuppression ? 'ON' : 'OFF'}
          </span>
        </div>
        
        <div className="flex justify-between">
          <span>Auto Gain Control:</span>
          <span className={settings.autoGainControl ? 'text-red-600' : 'text-green-600'}>
            {settings.autoGainControl ? 'ON' : 'OFF'}
          </span>
        </div>
        
        <div className="flex justify-between">
          <span>Sample Rate:</span>
          <span className="text-gray-600">{settings.sampleRate} Hz</span>
        </div>
        
        <div className="flex justify-between">
          <span>Channels:</span>
          <span className="text-gray-600">{settings.channelCount}</span>
        </div>
      </div>

      <div className={`mt-3 p-2 rounded ${isClean ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'}`}>
        <strong>Status:</strong> {isClean ? '✅ Clean Input' : '⚠️ Processing Enabled'}
      </div>
    </div>
  );
}
