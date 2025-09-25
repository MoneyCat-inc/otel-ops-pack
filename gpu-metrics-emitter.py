# gpu-metrics-emitter.py
import time
import argparse
from typing import Iterable

from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.metrics import (
    get_meter,
    set_meter_provider,
    Observation,        # <- return Observation(...) from callbacks
    CallbackOptions,
)

import pynvml as nv

def init_meter(endpoint="http://localhost:4318/v1/metrics", export_interval_ms=10000):
    exporter = OTLPMetricExporter(endpoint=endpoint, timeout=10)
    reader = PeriodicExportingMetricReader(exporter, export_interval_millis=export_interval_ms)
    provider = MeterProvider(
        resource=Resource.create({"service.name": "gpu-emitter", "service.namespace": "resonai"}),
        metric_readers=[reader],
    )
    set_meter_provider(provider)
    return get_meter("resonai.gpu", "0.1.0")

def _wrap_nvml():
    nv.nvmlInit()
    count = nv.nvmlDeviceGetCount()
    handles = [nv.nvmlDeviceGetHandleByIndex(i) for i in range(count)]
    return count, handles

def gpu_util_cb(_: CallbackOptions) -> Iterable[Observation]:
    count, handles = _wrap_nvml()
    for i, h in enumerate(handles):
        try:
            util = nv.nvmlDeviceGetUtilizationRates(h).gpu
            name = nv.nvmlDeviceGetName(h).decode() if hasattr(nv.nvmlDeviceGetName(h), "decode") else nv.nvmlDeviceGetName(h)
            yield Observation(util, {"gpu.index": i, "gpu.name": name})
        except Exception:
            continue

def gpu_mem_used_cb(_: CallbackOptions) -> Iterable[Observation]:
    _, handles = _wrap_nvml()
    for i, h in enumerate(handles):
        try:
            mem = nv.nvmlDeviceGetMemoryInfo(h)
            yield Observation(int(mem.used), {"gpu.index": i})
        except Exception:
            continue

def gpu_mem_total_cb(_: CallbackOptions) -> Iterable[Observation]:
    _, handles = _wrap_nvml()
    for i, h in enumerate(handles):
        try:
            mem = nv.nvmlDeviceGetMemoryInfo(h)
            yield Observation(int(mem.total), {"gpu.index": i})
        except Exception:
            continue

def gpu_temp_cb(_: CallbackOptions) -> Iterable[Observation]:
    _, handles = _wrap_nvml()
    for i, h in enumerate(handles):
        try:
            t = nv.nvmlDeviceGetTemperature(h, nv.NVML_TEMPERATURE_GPU)
            yield Observation(int(t), {"gpu.index": i})
        except Exception:
            continue

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GPU Metrics Emitter for OTel")
    parser.add_argument("--endpoint", default="http://localhost:4318/v1/metrics", help="OTLP HTTP endpoint")
    parser.add_argument("--duration", type=int, default=120, help="Duration in seconds to run")
    parser.add_argument("--interval", type=int, default=10, help="Export interval in seconds")
    
    args = parser.parse_args()
    
    print(f"🚀 Starting GPU metrics emitter...")
    print(f"   Endpoint: {args.endpoint}")
    print(f"   Duration: {args.duration}s")
    print(f"   Interval: {args.interval}s")
    
    meter = init_meter(endpoint=args.endpoint, export_interval_ms=args.interval * 1000)

    # Define observable instruments with callbacks (no .add_callback calls!)
    meter.create_observable_gauge(
        "gpu.utilization.percent",
        callbacks=[gpu_util_cb],
        unit="percent",
        description="GPU SM utilization",
    )
    meter.create_observable_gauge(
        "gpu.memory.used.bytes",
        callbacks=[gpu_mem_used_cb],
        unit="By",
        description="Used VRAM",
    )
    meter.create_observable_gauge(
        "gpu.memory.total.bytes",
        callbacks=[gpu_mem_total_cb],
        unit="By",
        description="Total VRAM",
    )
    meter.create_observable_gauge(
        "gpu.temperature.celsius",
        callbacks=[gpu_temp_cb],
        unit="Cel",
        description="GPU temperature",
    )

    print(f"✅ GPU metrics instruments registered")
    print(f"⏳ Running for {args.duration} seconds...")
    
    # Keep the process alive for a bounded time while the reader pulls
    time.sleep(args.duration)
    
    print(f"🏁 GPU metrics emitter completed")