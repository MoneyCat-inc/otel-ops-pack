# Architecture Diagram - Visualization Telemetry Flow

> **Split-lane record (2026-09-02).** The visualizer lane (VIZR / MILK / ProjectM) was extracted to
> `viz-engine` in Pack 3B (2026-07-24; that repo is now archived). Nothing in this pack's telemetry
> pipeline depends on it; kept as the record of the 2025 lane.

**Lane**: VIZR  
**Author**: LumiPulse-MkII (Lumi)  
**Last Updated**: 2025-11-02  
**Status**: Active

---

## Telemetry Flow Architecture

```text
                    ┌─────────────────────────────────┐
                    │  Audio Input (Loopback/Mic)    │
                    └─────────────┬───────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────────┐
                    │   PulseAudio / Audio Bridge     │
                    └─────────────┬───────────────────┘
                                  │
                                  ▼
        ┌─────────────────────────────────────────────────┐
        │      ProjectM Visualization Engine (GPU)        │
        │  ┌────────────────────────────────────────┐     │
        │  │  Preset Engine (Milkdrop Shaders)     │     │
        │  │  - Beat detection                      │     │
        │  │  - FFT analysis                        │     │
        │  │  - Preset rendering (WebGL/OpenGL)     │     │
        │  └─────────────┬──────────────────────────┘     │
        │                │                                 │
        │                ▼                                 │
        │  ┌────────────────────────────────────────┐     │
        │  │  VirtualGL Rendering Pipeline          │     │
        │  │  - GPU acceleration                    │     │
        │  │  - Frame buffer                        │     │
        │  │  - Display :99 (Xvfb)                  │     │
        │  └─────────────┬──────────────────────────┘     │
        └────────────────┼───────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────────┐
        │     OTel Instrumentation (Traces & Metrics)    │
        │  - Render latency (target: <16ms @ 60fps)     │
        │  - Preset switch time (target: <2.5s)         │
        │  - GPU utilization %                          │
        │  - Audio buffer health                        │
        └─────────────┬──────────────────────────────────┘
                      │
                      ▼
        ┌────────────────────────────────────────────────┐
        │        Docker OTel Collector                   │
        │  - Batch processing (200ms timeout)           │
        │  - Metric aggregation                         │
        │  - Trace sampling                             │
        └─────────────┬──────────────────────────────────┘
                      │
                      ▼
        ┌────────────────────────────────────────────────┐
        │              SigNoz Backend                    │
        │  - OTLP gRPC (5317)                           │
        │  - OTLP HTTP (5318)                           │
        │  - Query Service                              │
        └─────────────┬──────────────────────────────────┘
                      │
                      ▼
        ┌────────────────────────────────────────────────┐
        │         SigNoz UI (localhost:8080)             │
        │  - Real-time metrics dashboards               │
        │  - Trace visualization                        │
        │  - Alerting on performance degradation        │
        └────────────────────────────────────────────────┘
```

---

## Component Details

### Audio Input Layer

- **Source**: System audio loopback or microphone
- **Format**: 44.1kHz / 48kHz, 16-bit stereo
- **Latency**: <10ms (target)
- **Buffer**: Configurable (512-2048 samples)

### ProjectM Visualization Engine

- **Container**: `viz-engine-projectm-gpu`
- **GPU**: NVIDIA CUDA-enabled (compute capability ≥3.0)
- **Memory**: 4-8GB recommended
- **CPU**: 2-4 cores
- **Preset Format**: `.milk` (Milkdrop format)

### VirtualGL Pipeline

- **Purpose**: GPU-accelerated rendering in headless environment
- **Display**: `:99` (Xvfb virtual framebuffer)
- **Protocol**: GLX (OpenGL Extension to X Window System)
- **Performance**: Direct rendering enabled

### OTel Instrumentation Points

| Metric | Type | Target | Description |
|--------|------|--------|-------------|
| `vizr.render.latency_ms` | Histogram | <16ms | Per-frame render time |
| `vizr.preset.switch_ms` | Histogram | <2500ms | Preset transition time |
| `vizr.gpu.utilization_pct` | Gauge | 60-80% | GPU usage |
| `vizr.audio.buffer_health` | Gauge | >0.8 | Audio buffer fill level |
| `vizr.fps` | Gauge | 60 | Frames per second |

### SigNoz Dashboards

**Visualization Performance Dashboard**:

- Real-time FPS tracking
- Preset switch latency (p50, p95, p99)
- GPU utilization trends
- Audio sync health

**Alerts**:

- FPS < 30 for >5s (performance degradation)
- Preset switch > 5s (slow transitions)
- GPU utilization > 95% (resource exhaustion)

---

## Data Flow Characteristics

### Latency Targets

| Stage | Target | Actual | Status |
|-------|--------|--------|--------|
| **Audio Input** | <10ms | ~5ms | ✅ |
| **FFT Analysis** | <5ms | ~3ms | ✅ |
| **Render Frame** | <16ms | ~12ms | ✅ |
| **Preset Switch** | <2.5s | ~2.2s | ✅ |
| **OTel Batch** | <200ms | ~150ms | ✅ |

### Throughput

- **Audio Samples**: 44,100/s (44.1kHz)
- **Render Frames**: 60/s (60 FPS target)
- **Metrics Points**: ~100/s
- **Traces**: ~10/s (preset switches + errors)

---

## Failure Modes & Mitigation

### GPU Failure

- **Detection**: `nvidia-smi` fails or GPU utilization = 0%
- **Mitigation**: Fallback to CPU rendering (degraded mode)
- **Recovery**: Restart container with GPU validation

### Audio Desync

- **Detection**: Audio buffer < 20% or >95%
- **Mitigation**: Adjust buffer size (1024 → 2048 samples)
- **Recovery**: Reconnect audio loopback

### Preset Crash

- **Detection**: Rendering stops, container logs show segfault
- **Mitigation**: Skip bad preset, continue with next
- **Recovery**: Validate preset file, check for shader errors

---

## Monitoring Queries

### SigNoz Queries

```text
# Render latency (p95)
quantile(0.95, vizr.render.latency_ms)

# Preset switch performance
histogram_quantile(0.95, vizr.preset.switch_ms)

# GPU utilization
avg(vizr.gpu.utilization_pct)

# FPS tracking
rate(vizr.fps[1m])
```

---

## Related Documentation

- **GPU Setup**: `docs/gpu/RUN_AND_VERIFY.md`
- **VirtualGL Guide**: `viz-engine-projectm-gpu/README.md`
- **Docker Compose**: `docker-compose.viz.yml`
- **ECRR Framework**: `docs/comfort-cat/ECRR_FRAMEWORK.md`

---

**Maintained by**: LumiPulse-MkII (Lumi) ✨  
**Human Backup**: Alex Romero  
**Version**: 1.0

*"Every pixel rendered, every beat visualized—the pipeline flows with luminous precision."* ✨

