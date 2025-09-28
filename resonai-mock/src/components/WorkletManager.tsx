/**
 * Worklet Manager - AudioWorklet Integration
 * 
 * INV-03A: Manages worklet loading and message passing
 * Connects worklets to AudioContext and handles UI updates
 */

'use client';

import { useState, useEffect, useRef } from 'react';

interface WorkletData {
  pitch: number;
  confidence: number;
  rms: number;
  highFreq: number;
  lowFreq: number;
  f1: number;
  f2: number;
  f3: number;
  timestamp: number;
}

interface WorkletState {
  isLoaded: boolean;
  isActive: boolean;
  processors: {
    pitch: AudioWorkletNode | null;
    energy: AudioWorkletNode | null;
    lpc: AudioWorkletNode | null;
  };
  data: WorkletData;
  error: string | null;
}

export function useWorkletManager(audioContext: AudioContext | null) {
  const [state, setState] = useState<WorkletState>({
    isLoaded: false,
    isActive: false,
    processors: {
      pitch: null,
      energy: null,
      lpc: null,
    },
    data: {
      pitch: 0,
      confidence: 0,
      rms: 0,
      highFreq: 0,
      lowFreq: 0,
      f1: 0,
      f2: 0,
      f3: 0,
      timestamp: 0,
    },
    error: null,
  });

  const processorsRef = useRef<WorkletState['processors']>({
    pitch: null,
    energy: null,
    lpc: null,
  });

  const loadWorklets = async () => {
    if (!audioContext) {
      setState(prev => ({ ...prev, error: 'AudioContext not available' }));
      return;
    }

    try {
      setState(prev => ({ ...prev, error: null }));

      // Load worklet modules
      await Promise.all([
        audioContext.audioWorklet.addModule('/worklets/pitch-processor.js'),
        audioContext.audioWorklet.addModule('/worklets/energy-processor.js'),
        audioContext.audioWorklet.addModule('/worklets/lpc-processor.js'),
      ]);

      // Create worklet processors
      const pitchProcessor = new AudioWorkletNode(audioContext, 'pitch-processor');
      const energyProcessor = new AudioWorkletNode(audioContext, 'energy-processor');
      const lpcProcessor = new AudioWorkletNode(audioContext, 'lpc-processor');

      // Set up message handlers
      pitchProcessor.port.onmessage = (event) => {
        if (event.data.type === 'pitch') {
          setState(prev => ({
            ...prev,
            data: {
              ...prev.data,
              pitch: event.data.pitch,
              confidence: event.data.confidence,
              timestamp: event.data.timestamp,
            },
          }));
        }
      };

      energyProcessor.port.onmessage = (event) => {
        if (event.data.type === 'energy') {
          setState(prev => ({
            ...prev,
            data: {
              ...prev.data,
              rms: event.data.rms,
              highFreq: event.data.highFreq,
              lowFreq: event.data.lowFreq,
              timestamp: event.data.timestamp,
            },
          }));
        }
      };

      lpcProcessor.port.onmessage = (event) => {
        if (event.data.type === 'formants') {
          setState(prev => ({
            ...prev,
            data: {
              ...prev.data,
              f1: event.data.f1,
              f2: event.data.f2,
              f3: event.data.f3,
              timestamp: event.data.timestamp,
            },
          }));
        }
      };

      processorsRef.current = {
        pitch: pitchProcessor,
        energy: energyProcessor,
        lpc: lpcProcessor,
      };

      setState(prev => ({
        ...prev,
        isLoaded: true,
        processors: processorsRef.current,
      }));

      console.log('Worklets loaded successfully');

    } catch (error) {
      console.error('Worklet loading failed:', error);
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Unknown error',
      }));
    }
  };

  const connectWorklets = (source: MediaStreamAudioSourceNode) => {
    if (!state.isLoaded || !source) {
      setState(prev => ({ ...prev, error: 'Worklets not loaded or source not available' }));
      return;
    }

    try {
      // Connect source to all processors
      source.connect(processorsRef.current.pitch!);
      source.connect(processorsRef.current.energy!);
      source.connect(processorsRef.current.lpc!);

      setState(prev => ({ ...prev, isActive: true }));
      console.log('Worklets connected and active');

    } catch (error) {
      console.error('Worklet connection failed:', error);
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Connection failed',
      }));
    }
  };

  const disconnectWorklets = () => {
    if (processorsRef.current.pitch) {
      processorsRef.current.pitch.disconnect();
    }
    if (processorsRef.current.energy) {
      processorsRef.current.energy.disconnect();
    }
    if (processorsRef.current.lpc) {
      processorsRef.current.lpc.disconnect();
    }

    setState(prev => ({ ...prev, isActive: false }));
    console.log('Worklets disconnected');
  };

  const configureWorklets = (config: any) => {
    if (processorsRef.current.pitch) {
      processorsRef.current.pitch.port.postMessage({
        type: 'configure',
        ...config,
      });
    }
    if (processorsRef.current.energy) {
      processorsRef.current.energy.port.postMessage({
        type: 'configure',
        ...config,
      });
    }
    if (processorsRef.current.lpc) {
      processorsRef.current.lpc.port.postMessage({
        type: 'configure',
        ...config,
      });
    }
  };

  useEffect(() => {
    if (audioContext && !state.isLoaded) {
      loadWorklets();
    }
  }, [audioContext]);

  return {
    ...state,
    loadWorklets,
    connectWorklets,
    disconnectWorklets,
    configureWorklets,
  };
}

// Worklet Data Display Component
export function WorkletDataDisplay({ data }: { data: WorkletData }) {
  return (
    <div className="bg-white rounded-lg shadow p-4">
      <h3 className="text-lg font-semibold mb-3">Audio Analysis</h3>
      
      <div className="grid grid-cols-2 gap-4">
        <div>
          <h4 className="font-medium text-gray-700 mb-2">Pitch</h4>
          <div className="space-y-1">
            <div className="flex justify-between">
              <span>Frequency:</span>
              <span className="font-mono">{data.pitch.toFixed(1)} Hz</span>
            </div>
            <div className="flex justify-between">
              <span>Confidence:</span>
              <span className="font-mono">{(data.confidence * 100).toFixed(1)}%</span>
            </div>
          </div>
        </div>

        <div>
          <h4 className="font-medium text-gray-700 mb-2">Energy</h4>
          <div className="space-y-1">
            <div className="flex justify-between">
              <span>RMS:</span>
              <span className="font-mono">{data.rms.toFixed(3)}</span>
            </div>
            <div className="flex justify-between">
              <span>High Freq:</span>
              <span className="font-mono">{data.highFreq.toFixed(3)}</span>
            </div>
            <div className="flex justify-between">
              <span>Low Freq:</span>
              <span className="font-mono">{data.lowFreq.toFixed(3)}</span>
            </div>
          </div>
        </div>

        <div className="col-span-2">
          <h4 className="font-medium text-gray-700 mb-2">Formants</h4>
          <div className="grid grid-cols-3 gap-2">
            <div className="text-center">
              <div className="text-sm text-gray-600">F1</div>
              <div className="font-mono">{data.f1.toFixed(0)} Hz</div>
            </div>
            <div className="text-center">
              <div className="text-sm text-gray-600">F2</div>
              <div className="font-mono">{data.f2.toFixed(0)} Hz</div>
            </div>
            <div className="text-center">
              <div className="text-sm text-gray-600">F3</div>
              <div className="font-mono">{data.f3.toFixed(0)} Hz</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
