import type { Attributes } from "@opentelemetry/api";
import type { ResourceAttributes } from "@opentelemetry/resources";
import { Resource } from "@opentelemetry/resources";
import {
  AggregationTemporality,
  MeterProvider,
  PeriodicExportingMetricReader,
  ObservableResult,
} from "@opentelemetry/sdk-metrics";
import { OTLPMetricExporter } from "@opentelemetry/exporter-metrics-otlp-http";

type GaugeCallback = (observer: ObservableResult) => void;

export interface MemxSnapshots {
  wasmHeapBytes?: () => number | undefined;
  sabUsage?: () =>
    | number
    | undefined
    | {
        used: number;
        capacity?: number;
        ring?: string;
      };
  strainPct?: () =>
    | number
    | undefined
    | {
        value: number;
        kind?: string;
      };
}

export interface MemxOtelOptions {
  endpoint?: string;
  stream?: boolean;
  exportIntervalMillis?: number;
  resourceAttributes?: ResourceAttributes;
  snapshots?: MemxSnapshots;
}

export interface MemxOtelHandle {
  recordLag: (durationMs: number, attributes?: Attributes) => void;
  meterProvider: MeterProvider;
  meter: ReturnType<MeterProvider["getMeter"]>;
  shutdown: () => Promise<void>;
}

const DEFAULT_RESOURCE_ATTRIBUTES: ResourceAttributes = {
  "service.name": "resonai-frontend",
  "telemetry.sdk.language": "webjs",
};

const DEFAULT_EXPORT_INTERVAL_MS = 5000;

interface GaugeCallbacks {
  wasmHeap?: GaugeCallback;
  sabUsed?: GaugeCallback;
  sabCapacity?: GaugeCallback;
  strain?: GaugeCallback;
}

function sanitizeNumber(value: unknown): number | undefined {
  if (typeof value !== "number") return undefined;
  if (!Number.isFinite(value)) return undefined;
  return value;
}

function buildGaugeCallbacks(snapshots?: MemxSnapshots): GaugeCallbacks {
  const callbacks: GaugeCallbacks = {};

  if (snapshots?.wasmHeapBytes) {
    callbacks.wasmHeap = (observer) => {
      const value = sanitizeNumber(snapshots.wasmHeapBytes?.());
      if (value !== undefined) {
        observer.observe(value, { component: "wasm" });
      }
    };
  }

  if (snapshots?.sabUsage) {
    callbacks.sabUsed = (observer) => {
      const snapshot = snapshots.sabUsage?.();
      if (snapshot === undefined) return;

      if (typeof snapshot === "number") {
        const used = sanitizeNumber(snapshot);
        if (used !== undefined) {
          observer.observe(used, { component: "audio", ring: "worklet_io" });
        }
        return;
      }

      const used = sanitizeNumber((snapshot as { used: number }).used);
      if (used !== undefined) {
        observer.observe(used, {
          component: "audio",
          ring: (snapshot as { ring?: string }).ring ?? "worklet_io",
        });
      }
    };

    callbacks.sabCapacity = (observer) => {
      const snapshot = snapshots.sabUsage?.();
      if (snapshot && typeof snapshot === "object" && "capacity" in snapshot) {
        const capacity = sanitizeNumber((snapshot as { capacity?: number }).capacity);
        if (capacity !== undefined) {
          observer.observe(capacity, {
            component: "audio",
            ring: (snapshot as { ring?: string }).ring ?? "worklet_io",
          });
        }
      }
    };
  }

  if (snapshots?.strainPct) {
    callbacks.strain = (observer) => {
      const snapshot = snapshots.strainPct?.();
      if (snapshot === undefined) return;

      if (typeof snapshot === "number") {
        const value = sanitizeNumber(snapshot);
        if (value !== undefined) {
          observer.observe(value, { component: "audio", kind: "none" });
        }
        return;
      }

      const value = sanitizeNumber((snapshot as { value: number }).value);
      if (value !== undefined) {
        observer.observe(value, {
          component: "audio",
          kind: (snapshot as { kind?: string }).kind ?? "none",
        });
      }
    };
  }

  return callbacks;
}

export function initMemxOtel(options: MemxOtelOptions = {}): MemxOtelHandle {
  const resource = Resource.default().merge(
    new Resource({
      ...DEFAULT_RESOURCE_ATTRIBUTES,
      ...(options.resourceAttributes ?? {}),
    }),
  );

  const meterProvider = new MeterProvider({ resource });

  if (options.stream && options.endpoint) {
    const exporter = new OTLPMetricExporter({
      url: `${options.endpoint.replace(/\/$/, "")}/v1/metrics`,
      temporalityPreference: AggregationTemporality.CUMULATIVE,
    });

    const reader = new PeriodicExportingMetricReader({
      exporter,
      exportIntervalMillis: options.exportIntervalMillis ?? DEFAULT_EXPORT_INTERVAL_MS,
    });

    meterProvider.addMetricReader(reader);
  }

  const meter = meterProvider.getMeter("resonai.memx");

  const lagHistogram = meter.createHistogram("resonai_memx_worklet_ui_lag", {
    description: "Lag between UI thread and AudioWorklet",
    unit: "ms",
  });

  const wasmHeapGauge = meter.createObservableGauge("resonai_memx_wasm_heap_bytes", {
    description: "Observed linear memory usage in the MEMX WASM module",
    unit: "By",
  });

  const sabUsedGauge = meter.createObservableGauge("resonai_memx_sab_used_bytes", {
    description: "Observed occupancy of SharedArrayBuffer used by the AudioWorklet ring",
    unit: "By",
  });

  const sabCapacityGauge = meter.createObservableGauge("resonai_memx_sab_capacity_bytes", {
    description: "Total capacity of the SharedArrayBuffer ring",
    unit: "By",
  });

  const strainGauge = meter.createObservableGauge("resonai_memx_strain_pct", {
    description: "Percent of frames exceeding the configured MEMX strain threshold",
    unit: "%",
  });

  const callbacks = buildGaugeCallbacks(options.snapshots);

  if (callbacks.wasmHeap) wasmHeapGauge.addCallback(callbacks.wasmHeap);
  if (callbacks.sabUsed) sabUsedGauge.addCallback(callbacks.sabUsed);
  if (callbacks.sabCapacity) sabCapacityGauge.addCallback(callbacks.sabCapacity);
  if (callbacks.strain) strainGauge.addCallback(callbacks.strain);

  return {
    recordLag: (durationMs: number, attributes: Attributes = {}) => {
      const value = sanitizeNumber(durationMs);
      if (value === undefined || value < 0) return;

      lagHistogram.record(value, { component: "audio", ...attributes });
    },
    meterProvider,
    meter,
    shutdown: async () => {
      await meterProvider.shutdown();
    },
  };
}
