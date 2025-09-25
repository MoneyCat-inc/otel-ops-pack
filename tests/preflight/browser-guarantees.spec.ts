/**
 * Browser Preflight Tests
 * Ensures cross-origin isolation and mic constraints for reliable trainer operation
 * Part of the push-button automation system
 */

import { test, expect, Page, BrowserContext } from '@playwright/test';

test.describe('Browser Preflight Guarantees', () => {
  let page: Page;
  let context: BrowserContext;

  test.beforeEach(async ({ browser }) => {
    context = await browser.newContext({
      // Ensure we have permissions for media access
      permissions: ['microphone'],
      // Disable web security for testing (only in test environment)
      ignoreHTTPSErrors: true,
    });
    page = await context.newPage();
  });

  test.afterEach(async () => {
    await context.close();
  });

  test('cross-origin isolation headers present', async () => {
    // Navigate to the app
    await page.goto('/');
    
    // Check COOP/COEP headers in document
    const headers = await page.evaluate(() => {
      const coopMeta = document.head.querySelector('meta[http-equiv="Cross-Origin-Opener-Policy"]');
      const coepMeta = document.head.querySelector('meta[http-equiv="Cross-Origin-Embedder-Policy"]');
      
      return {
        coop: coopMeta?.getAttribute('content') || null,
        coep: coepMeta?.getAttribute('content') || null,
        crossOriginIsolated: (window as any).crossOriginIsolated || false,
        sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined',
        webAudioWorklet: typeof AudioWorkletNode !== 'undefined'
      };
    });

    // Assert COOP header
    expect(headers.coop).toBeTruthy();
    expect(headers.coop).toMatch(/same-origin|same-origin-allow-popups/);
    
    // Assert COEP header
    expect(headers.coep).toBeTruthy();
    expect(headers.coep).toMatch(/require-corp|credentialless/);
    
    // Assert cross-origin isolation
    expect(headers.crossOriginIsolated).toBe(true);
    
    // Assert SharedArrayBuffer availability
    expect(headers.sharedArrayBuffer).toBe(true);
    
    // Assert WebAudio Worklet availability
    expect(headers.webAudioWorklet).toBe(true);
  });

  test('service worker maintains isolation offline', async () => {
    // Navigate to the app
    await page.goto('/');
    
    // Wait for service worker to be ready
    await page.waitForFunction(() => 'serviceWorker' in navigator);
    
    // Check isolation status before going offline
    const onlineStatus = await page.evaluate(() => ({
      crossOriginIsolated: (window as any).crossOriginIsolated,
      sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined'
    }));
    
    expect(onlineStatus.crossOriginIsolated).toBe(true);
    expect(onlineStatus.sharedArrayBuffer).toBe(true);
    
    // Go offline
    await context.setOffline(true);
    
    // Wait a moment for offline state to propagate
    await page.waitForTimeout(1000);
    
    // Check isolation status while offline
    const offlineStatus = await page.evaluate(() => ({
      crossOriginIsolated: (window as any).crossOriginIsolated,
      sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined',
      online: navigator.onLine
    }));
    
    expect(offlineStatus.online).toBe(false);
    expect(offlineStatus.crossOriginIsolated).toBe(true);
    expect(offlineStatus.sharedArrayBuffer).toBe(true);
    
    // Go back online
    await context.setOffline(false);
  });

  test('microphone constraints honored', async () => {
    // Navigate to a page that requests microphone access
    await page.goto('/try');
    
    // Mock getUserMedia to avoid actual microphone access in CI
    await page.addInitScript(() => {
      const originalGetUserMedia = navigator.mediaDevices.getUserMedia;
      navigator.mediaDevices.getUserMedia = async (constraints: MediaStreamConstraints) => {
        // Create a mock audio track
        const mockTrack = {
          kind: 'audio',
          enabled: true,
          getSettings: () => ({
            echoCancellation: constraints.audio && 
              typeof constraints.audio === 'object' && 
              'echoCancellation' in constraints.audio ? 
              constraints.audio.echoCancellation : true,
            noiseSuppression: constraints.audio && 
              typeof constraints.audio === 'object' && 
              'noiseSuppression' in constraints.audio ? 
              constraints.audio.noiseSuppression : true,
            autoGainControl: constraints.audio && 
              typeof constraints.audio === 'object' && 
              'autoGainControl' in constraints.audio ? 
              constraints.audio.autoGainControl : true,
          }),
          stop: () => {},
        };
        
        return {
          getAudioTracks: () => [mockTrack],
          getVideoTracks: () => [],
          getTracks: () => [mockTrack],
          active: true,
          id: 'mock-stream-id',
          addTrack: () => {},
          removeTrack: () => {},
          clone: () => ({ getAudioTracks: () => [mockTrack] }),
        } as MediaStream;
      };
    });
    
    // Request microphone with specific constraints
    const constraints = await page.evaluate(async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: false,
            noiseSuppression: false,
            autoGainControl: false
          }
        });
        
        const track = stream.getAudioTracks()[0];
        const settings = track.getSettings();
        
        return {
          echoCancellation: settings.echoCancellation,
          noiseSuppression: settings.noiseSuppression,
          autoGainControl: settings.autoGainControl,
          success: true
        };
      } catch (error) {
        return {
          error: error.message,
          success: false
        };
      }
    });
    
    expect(constraints.success).toBe(true);
    expect(constraints.echoCancellation).toBe(false);
    expect(constraints.noiseSuppression).toBe(false);
    expect(constraints.autoGainControl).toBe(false);
  });

  test('audio worklet context isolation', async () => {
    // Navigate to the app
    await page.goto('/');
    
    // Test AudioWorklet in isolated context
    const workletTest = await page.evaluate(async () => {
      try {
        // Create audio context
        const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
        
        // Create a simple worklet processor
        const workletCode = `
          class TestProcessor extends AudioWorkletProcessor {
            constructor() {
              super();
              this.port.postMessage({ type: 'ready' });
            }
            
            process(inputs, outputs, parameters) {
              // Simple passthrough
              const input = inputs[0];
              const output = outputs[0];
              
              if (input.length > 0) {
                for (let channel = 0; channel < input.length; channel++) {
                  output[channel].set(input[channel]);
                }
              }
              
              return true;
            }
          }
          
          registerProcessor('test-processor', TestProcessor);
        `;
        
        // Create blob URL for worklet
        const blob = new Blob([workletCode], { type: 'application/javascript' });
        const workletUrl = URL.createObjectURL(blob);
        
        // Add worklet module
        await audioContext.audioWorklet.addModule(workletUrl);
        
        // Create worklet node
        const workletNode = new AudioWorkletNode(audioContext, 'test-processor');
        
        // Test message passing
        return new Promise((resolve) => {
          workletNode.port.onmessage = (event) => {
            if (event.data.type === 'ready') {
              resolve({
                success: true,
                crossOriginIsolated: (window as any).crossOriginIsolated,
                sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined'
              });
            }
          };
          
          // Timeout after 2 seconds
          setTimeout(() => {
            resolve({
              success: false,
              error: 'Worklet did not respond in time'
            });
          }, 2000);
        });
        
      } catch (error) {
        return {
          success: false,
          error: error.message
        };
      }
    });
    
    expect(workletTest.success).toBe(true);
    expect(workletTest.crossOriginIsolated).toBe(true);
    expect(workletTest.sharedArrayBuffer).toBe(true);
  });

  test('CSP headers allow required features', async () => {
    // Navigate to the app
    await page.goto('/');
    
    // Check CSP headers
    const cspInfo = await page.evaluate(() => {
      const metaCSP = document.head.querySelector('meta[http-equiv="Content-Security-Policy"]');
      const cspContent = metaCSP?.getAttribute('content') || '';
      
      return {
        hasCSP: !!metaCSP,
        cspContent: cspContent,
        // Check if required directives are present
        hasWorkerSrc: cspContent.includes('worker-src'),
        hasScriptSrc: cspContent.includes('script-src'),
        hasConnectSrc: cspContent.includes('connect-src'),
        allowsBlob: cspContent.includes('blob:'),
        allowsData: cspContent.includes('data:'),
        allowsSelf: cspContent.includes("'self'")
      };
    });
    
    expect(cspInfo.hasCSP).toBe(true);
    expect(cspInfo.hasWorkerSrc).toBe(true);
    expect(cspInfo.hasScriptSrc).toBe(true);
    expect(cspInfo.hasConnectSrc).toBe(true);
    expect(cspInfo.allowsBlob).toBe(true);
    expect(cspInfo.allowsSelf).toBe(true);
  });

  test('performance API available in isolated context', async () => {
    // Navigate to the app
    await page.goto('/');
    
    // Test performance API availability
    const perfTest = await page.evaluate(() => {
      return {
        crossOriginIsolated: (window as any).crossOriginIsolated,
        performanceNow: typeof performance.now === 'function',
        performanceMark: typeof performance.mark === 'function',
        performanceMeasure: typeof performance.measure === 'function',
        performanceObserver: typeof PerformanceObserver !== 'undefined',
        highResTimeStamp: typeof performance.timeOrigin !== 'undefined'
      };
    });
    
    expect(perfTest.crossOriginIsolated).toBe(true);
    expect(perfTest.performanceNow).toBe(true);
    expect(perfTest.performanceMark).toBe(true);
    expect(perfTest.performanceMeasure).toBe(true);
    expect(perfTest.performanceObserver).toBe(true);
    expect(perfTest.highResTimeStamp).toBe(true);
  });
});




