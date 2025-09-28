/**
 * Audio Context Manager - Low Latency Setup
 * 
 * INV-03A: AudioContext with latencyHint: 0 for Windows/Firefox optimization
 * Logs baseLatency and sampleRate for verification
 */

'use client';

import { useState, useEffect, useRef } from 'react';

interface AudioContextState {
  isSupported: boolean;
  context: AudioContext | null;
  baseLatency: number;
  sampleRate: number;
  contextState: 'closed' | 'running' | 'suspended' | 'interrupted';
  error: string | null;
  performanceMetrics: {
    creationTime: number;
    recoveryAttempts: number;
    lastError: string | null;
    totalUptime: number;
  };
}

export function useAudioContext() {
  const [state, setState] = useState<AudioContextState>({
    isSupported: false,
    context: null,
    baseLatency: 0,
    sampleRate: 0,
    contextState: 'closed',
    error: null,
    performanceMetrics: {
      creationTime: 0,
      recoveryAttempts: 0,
      lastError: null,
      totalUptime: 0,
    },
  });

  const contextRef = useRef<AudioContext | null>(null);

  // Check browser support
  useEffect(() => {
    const isSupported = !!(window.AudioContext || (window as any).webkitAudioContext);
    setState(prev => ({ ...prev, isSupported }));
  }, []);

  const createContext = async () => {
    if (!state.isSupported) {
      setState(prev => ({ ...prev, error: 'AudioContext not supported' }));
      return;
    }

    try {
      const startTime = performance.now();
      setState(prev => ({ 
        ...prev, 
        error: null,
        performanceMetrics: {
          ...prev.performanceMetrics,
          creationTime: startTime
        }
      }));

      // Create AudioContext with latencyHint: 0 for low latency
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      const context = new AudioContextClass({ 
        latencyHint: 0,  // Lowest latency for real-time processing
        sampleRate: 16000, // Match mic sample rate
      });

      // Resume context if suspended (required for user interaction)
      if (context.state === 'suspended') {
        await context.resume();
      }

      // Log context properties for verification
      console.log({
        baseLatency: context.baseLatency,
        sampleRate: context.sampleRate,
        contextState: context.state,
        maxChannelCount: context.destination.maxChannelCount,
      });

      contextRef.current = context;
      setState(prev => ({
        ...prev,
        context,
        baseLatency: context.baseLatency,
        sampleRate: context.sampleRate,
        contextState: context.state,
      }));

    } catch (error) {
      console.error('AudioContext creation failed:', error);
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Unknown error',
        performanceMetrics: {
          ...prev.performanceMetrics,
          lastError: error instanceof Error ? error.message : 'Unknown error'
        }
      }));
      
      // Auto-recovery attempt
      setTimeout(async () => {
        if (state.performanceMetrics.recoveryAttempts < 3) {
          console.log('Attempting AudioContext recovery...');
          await createContext();
        }
      }, 2000);
    }
  };

  const connectMic = (stream: MediaStream) => {
    if (!contextRef.current) {
      setState(prev => ({ ...prev, error: 'AudioContext not created' }));
      return null;
    }

    try {
      // Create MediaStreamAudioSourceNode
      const source = contextRef.current.createMediaStreamSource(stream);
      
      // Connect to destination (speakers) - remove this for processing-only
      // source.connect(contextRef.current.destination);
      
      console.log('Mic connected to AudioContext');
      return source;
    } catch (error) {
      console.error('Mic connection failed:', error);
      setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Connection failed',
      }));
      return null;
    }
  };

  const suspendContext = () => {
    if (contextRef.current && contextRef.current.state === 'running') {
      contextRef.current.suspend();
      setState(prev => ({ ...prev, contextState: 'suspended' }));
    }
  };

  const resumeContext = async () => {
    if (contextRef.current && contextRef.current.state === 'suspended') {
      await contextRef.current.resume();
      setState(prev => ({ ...prev, contextState: 'running' }));
    }
  };

  const closeContext = () => {
    if (contextRef.current) {
      contextRef.current.close();
      contextRef.current = null;
      setState(prev => ({
        ...prev,
        context: null,
        contextState: 'closed',
      }));
    }
  };

  const cleanup = () => {
    closeContext();
  };

  useEffect(() => {
    return cleanup;
  }, []);

  return {
    ...state,
    createContext,
    connectMic,
    suspendContext,
    resumeContext,
    closeContext,
  };
}

// Audio Context Status Display Component
export function AudioContextDisplay({ state }: { state: AudioContextState }) {
  const getStatusColor = (contextState: string) => {
    switch (contextState) {
      case 'running': return 'text-green-600';
      case 'suspended': return 'text-yellow-600';
      case 'interrupted': return 'text-orange-600';
      case 'closed': return 'text-gray-600';
      default: return 'text-red-600';
    }
  };

  const getLatencyColor = (latency: number) => {
    if (latency <= 0.01) return 'text-green-600'; // < 10ms
    if (latency <= 0.05) return 'text-yellow-600'; // < 50ms
    return 'text-red-600'; // > 50ms
  };

  return (
    <div className="bg-white rounded-lg shadow p-4">
      <h3 className="text-lg font-semibold mb-3">Audio Context Status</h3>
      
      <div className="space-y-2">
        <div className="flex justify-between">
          <span>State:</span>
          <span className={getStatusColor(state.contextState)}>
            {state.contextState.toUpperCase()}
          </span>
        </div>
        
        <div className="flex justify-between">
          <span>Base Latency:</span>
          <span className={getLatencyColor(state.baseLatency)}>
            {(state.baseLatency * 1000).toFixed(1)} ms
          </span>
        </div>
        
        <div className="flex justify-between">
          <span>Sample Rate:</span>
          <span className="text-gray-600">{state.sampleRate} Hz</span>
        </div>
        
        <div className="flex justify-between">
          <span>Supported:</span>
          <span className={state.isSupported ? 'text-green-600' : 'text-red-600'}>
            {state.isSupported ? 'YES' : 'NO'}
          </span>
        </div>
      </div>

      {state.error && (
        <div className="mt-3 p-2 bg-red-50 text-red-800 rounded">
          <strong>Error:</strong> {state.error}
        </div>
      )}
    </div>
  );
}
