import { test as base, expect } from '@playwright/test';

type DeterministicBucket = {
  lastBeacon?: {
    url: string;
    hasData: boolean;
    preview: string;
    timestamp: number;
  };
  lastMicConstraints?: unknown;
  originalSendBeacon?: ((url: string, data?: BodyInit | null) => boolean) | null;
  originalGetUserMedia?: ((constraints?: MediaStreamConstraints) => Promise<MediaStream>) | null;
  crossOriginIsolated?: boolean;
};

type DeterministicWindow = Window & { __deterministic__?: DeterministicBucket };

declare global {
  interface Window {
    __deterministic__?: DeterministicBucket;
  }
}

export const test = base.extend({
  context: async ({ context }, use) => {
    await context.addInitScript(() => {
      const globalWindow = window as unknown as DeterministicWindow;
      const bucket: DeterministicBucket = (globalWindow.__deterministic__ =
        globalWindow.__deterministic__ ?? {});

      try {
        Object.defineProperty(globalWindow, 'crossOriginIsolated', {
          configurable: true,
          get: () => true,
        });
        bucket.crossOriginIsolated = true;
      } catch {
        bucket.crossOriginIsolated = false;
      }

      const originalSendBeacon = navigator.sendBeacon
        ? navigator.sendBeacon.bind(navigator)
        : null;
      bucket.originalSendBeacon = originalSendBeacon;

      navigator.sendBeacon = ((url: string, data?: BodyInit | null) => {
        let preview = 'Ø';
        if (typeof data === 'string') {
          preview = data.slice(0, 120);
        } else if (data instanceof Blob) {
          preview = `[blob ${data.size} bytes]`;
        } else if (data instanceof ArrayBuffer || ArrayBuffer.isView(data)) {
          preview = '[binary payload]';
        } else if (data) {
          try {
            preview = JSON.stringify(data).slice(0, 120);
          } catch {
            preview = '[unserializable payload]';
          }
        }

        bucket.lastBeacon = {
          url,
          hasData: Boolean(data),
          preview,
          timestamp: Date.now(),
        };
        return true;
      }) as typeof navigator.sendBeacon;

      const navAny = navigator as unknown as {
        mediaDevices?: {
          getUserMedia?: (constraints?: MediaStreamConstraints) => Promise<MediaStream>;
        };
      };

      if (!navAny.mediaDevices) {
        navAny.mediaDevices = {} as typeof navAny.mediaDevices;
      }

      const mediaDevices = navAny.mediaDevices!;
      const originalGetUserMedia = mediaDevices.getUserMedia
        ? mediaDevices.getUserMedia.bind(mediaDevices)
        : null;
      bucket.originalGetUserMedia = originalGetUserMedia;

      mediaDevices.getUserMedia = async (constraints?: MediaStreamConstraints) => {
        bucket.lastMicConstraints = constraints ?? null;
        if (originalGetUserMedia) {
          try {
            return await originalGetUserMedia(constraints);
          } catch {
            // Fall through to stub stream when the native call flakes.
          }
        }

        const MediaStreamCtor = (window as unknown as { MediaStream?: new () => MediaStream }).MediaStream;
        if (MediaStreamCtor) {
          return new MediaStreamCtor();
        }

        return {
          id: 'deterministic-stub',
          active: false,
          getAudioTracks: () => [],
          getTracks: () => [],
          getVideoTracks: () => [],
          getTrackById: () => null,
          addTrack: () => undefined,
          removeTrack: () => undefined,
          clone: () => {
            const MediaStreamFallback = (window as unknown as { MediaStream?: new () => MediaStream }).MediaStream;
            return MediaStreamFallback ? new MediaStreamFallback() : ({} as MediaStream);
          },
        } as unknown as MediaStream;
      };
    });

    await use(context);
  },
});

export { expect } from '@playwright/test';
