# Resonai Frontend Code Map

## Architecture Overview

```mermaid
flowchart LR
  UI[Next.js App Router\npages & components] -->|dispatch| Coach[Coach & HUD]
  Coach -->|metrics| Metrics[Metrics: time-in-target,\nsmoothness, expressiveness]
  UI -->|request mic| Mic[Mic Manager\n(getUserMedia constraints)]
  Mic --> AC[AudioContext factory\n(latencyHint: 0)]
  AC --> Worklets[AudioWorklets\npitch + spectral]
  Worklets --> Detectors[Detectors\nCREPE (ONNX)+YIN/pYIN]
  Detectors --> Stream[Realtime stream {f0Hz, conf, RMS, centroid}]
  Stream --> Coach
  Coach --> Flows[Flow Runner (JSON)\nOnboard→Warmup→Glide→Phrase→Reflection]
  Flows --> IDB[IndexedDB stores: flows, sessions]
  UI --> Analytics[Client Analytics\n(sendBeacon buffer)]
  Analytics --> API[/api/events (rate-limited, ring buffer)]
  Sec[COOP/COEP + CSP + SW] --- UI
```

**Guardrails**

- Enforce COOP/COEP, strict CSP, and service-worker header preservation for SAB/WASM threads.
- Mic requests disable EC/NS/AGC; use `AudioContext({ latencyHint: 0 })` (Windows/Firefox) with 128-frame quanta.
- Primary detector is CREPE-tiny (ONNX Runtime Web, SIMD+threads) with YIN/pYIN fallback; smooth via short median then Kalman/Viterbi.
- Flow runner drives Onboard→Warmup→Glide→Phrase→Reflection; sessions stored in IndexedDB with export/delete offline.
- Analytics tee uses `/api/events` ring buffer (rate limited) and forwards to SigNoz via OTLP/HTTP 5318.

## Repository Template (rooted at `app/`)

```
app/
  layout.tsx              Root shell, metadata, nav, reduced-motion hooks
  page.tsx                Landing page + "Start practice"
  try/page.tsx            Instant Practice HUD + flow runner
  analytics/page.tsx      Live KPIs (TTV p50/p90, mic-grant %, activation %)
  api/
    events/route.ts       Ring buffer (rate limited) + OTLP tee
    healthz/route.ts      CI readiness (200 OK)
components/
  MicPrimerDialog.tsx     Primer vs native prompt (ARIA)
  HUD/PracticeHUD.tsx     Pitch/brightness/confidence/in-range
  HUD/DiagnosticsHUD.tsx  Optional dev HUD
  Flows/FlowRunner.tsx    Step engine + reflection form
audio/
  mic.ts                  getUserMedia with EC/NS/AGC=false
  context.ts              AudioContext factory (latencyHint: 0)
  worklets/pitch.worklet.js      ACF/YIN plumbing
  worklets/spectral.worklet.js   FFT centroid, H1-H2
  detectors/crepe/index.ts       ONNX Runtime Web (SIMD+threads)
  detectors/yin/index.ts         Fallback detector
  smooth/median.ts               3–5 frame median
  smooth/kalman.ts               Low process noise tracker
metrics/
  timeInTarget.ts               % within band/trajectory
  smoothness.ts                 Jitter EMA proxy
  expressiveness.ts             Detrended variance 0–1
  loudness.ts                   RMS/LUFS guardrails
flows/
  schema.ts                     v1 Flow JSON types
  presets/DailyPractice_v1.json Onboard→Warmup→Glide→Phrase→Reflection
lib/
  analytics.ts                  sendBeacon buffer + schema enforcement
  db.ts                         IndexedDB helpers (flows, sessions)
  flags.ts                      Deterministic cohorts (djb2 + rollout %)
  coi.ts                        COOP/COEP helpers for headers/SW
middleware.ts                  Cohort gating + cache policy
public/worklets/*              Ships worklet scripts
public/icons/*                 PWA assets
tests/
  e2e/*.spec.ts                 Smoke, isolation headers, mic flow, a11y, analytics
  helpers/fakeMic.ts            Deterministic MediaStream for CI
.github/workflows/
  e2e-win.yml                   Windows/Firefox PR lane
  e2e-nightly.yml               Nightly isolation/CSP regression guard
```

## Core Contracts

```ts
// flows/schema.ts
export type StepKind = 'info' | 'drill' | 'reflection';

export interface FlowV1 {
  version: 1;
  flowName: string;
  steps: Array<
    | { id: string; type: 'info'; title: string; content: string; next?: string }
    | {
        id: string;
        type: 'drill';
        title: string;
        copy: string;
        durationSec?: number;
        target?: {
          pitchRange?: ['low', 'high'];
          intonation?: 'rising' | 'falling';
          phraseText?: string;
        };
        metrics: Array<
          | 'voicedTimePct'
          | 'jitterEma'
          | 'timeInTargetPct'
          | 'smoothness'
          | 'endRiseDetected'
          | 'expressiveness'
        >;
        successThreshold?: Record<string, number | boolean>;
        next?: string;
      }
    | { id: string; type: 'reflection'; title: string; copy: string; prompts: string[] }
  >;
}

// lib/db.ts (session summary)
export interface SessionSummary {
  id?: number;
  ts: number;
  medianF0: number | null;
  inBandPct?: number;
  prosodyVar?: number;
  voicedTimePct?: number;
  jitterEma?: number;
  comfort?: 1 | 2 | 3 | 4 | 5;
  fatigue?: 1 | 2 | 3 | 4 | 5;
  euphoria?: 1 | 2 | 3 | 4 | 5;
  orb?: string;
}

// lib/analytics.ts
export interface AnalyticsEvent {
  event: string;
  props: Record<string, unknown>;
  ts: number;
  session_id: string;
  user_id?: string;
  variant?: string;
  schema: 'v1';
}

// detectors/types.ts
export interface DetectorFrame {
  f0Hz: number | null;
  confidence: number;
  voiced: boolean;
  rms: number;
  centroidHz?: number;
}
```

## Subsystem Expectations

- **Security**: `crossOriginIsolated` true everywhere; SW preserves headers; strict CSP (no inline styles).
- **Audio Path**: mic constraints applied, AudioContext latencyHint 0, worklets run allocation-free and emit RMS/centroid.
- **Detectors**: CREPE tiny via ONNX Runtime Web, fallback YIN/pYIN, median + Kalman/Viterbi smoothing.
- **Coaching & Metrics**: time-in-target, smoothness, expressiveness computed O(1)/frame; loudness guardrails cap device variability.
- **Flows & Storage**: v1 JSON drives Onboard→Warmup→Glide→Phrase→Reflection; sessions persisted/exportable offline.
- **Analytics & CI**: `/api/events` tee to SigNoz OTLP HTTP 5318; `/analytics` shows TTV p50/p90, mic-grant %, activation %; Playwright Windows/Firefox lane enforces smoke/isolation/mic/a11y/analytics.

## Definition of Done

- `crossOriginIsolated === true` online/offline; SW keeps COOP/COEP.
- Mic constraints + `AudioContext({ latencyHint: 0 })`; stable 128-frame processing.
- CREPE tiny + YIN/pYIN fallback; median + Kalman/Viterbi smoothing.
- Flow JSON v1 runs end-to-end; metrics live; sessions saved/exportable.
- Analytics tee working; `/analytics` dashboard green for KPIs.
- Playwright PR + nightly suites green with artifacts.
- Readiness checklist satisfied (latency, fairness, privacy, NVDA).

## Quick Next Steps

1. Adopt this map as the foundation when restructuring under `app/`.
2. Wire `/try` flow runner to the DailyPractice preset and metrics HUD.
3. Ensure isolation headers (Next `headers()` + SW) and enable isolation spec in Playwright CI.
4. Set up SigNoz integration for analytics pipeline monitoring.
5. Implement canary testing for mic flow and audio worklets.
6. Create accessibility testing suite for screen reader compatibility.
