# GPU Sidecar Implementation Plan

## Phase 0 – Prerequisites & Baseline
- Validate NVIDIA driver + CUDA runtime available inside Windows + WSL2 (`nvidia-smi`, `wsl.exe --distribution Ubuntu -- nvidia-smi`).
- Enable Docker Desktop GPU support and create a base image (`Dockerfile.gpu-base`) from `nvcr.io/nvidia/cuda:12.4.1-runtime-ubuntu22.04` with `nvcomp`, `rapidsai/cudf`, `tritonserver`, `morpheus` Python deps.
- Extend `scripts/verify-integration.ps1` to assert GPU presence and OTLP hot path health before sidecars attach.

## Phase 1 – GPU Compression Sidecar
1. **Buffer writer (collector hot path):**
   - Update `config.yaml` exporter list with `file` exporter targeting `C:/otel/gpu-buffers/logs` and `C:/otel/gpu-buffers/traces`.
   - Ensure pipelines keep existing exporters to SigNoz; attach new `file` exporter via `routingprocessor` so primary OTLP exporter is unaffected.
2. **Compression sidecar service:**
   - Create `sidecars/compression/` with Python service using `nvcomp` bindings.
   - Service polls buffer directory, batches payloads (10k log lines or 2 MB threshold), compresses with adaptive codec selection, stores results in `C:/otel/gpu-buffers/compressed` plus metadata JSON.
3. **Re-ingest path:**
   - Provide `scripts/replay-compressed.ps1` to send compressed batches back through collector via `otlphttp` once decompressed or to local ClickHouse bulk loader.
4. **Fallback logic:**
   - Add watchdog that detects GPU errors; on failure toggles collector feature flag (via `Set-ItemProperty` or env var) to stop writing GPU buffer and revert to CPU path.

## Phase 2 – GPU Pre-Aggregation Sidecar (Metrics & Logs)
1. **Data feed:**
   - Mirror metrics/logs into `C:/otel/gpu-buffers/analytics` using `filelog` exporter with JSON lines.
2. **cuDF aggregator:**
   - Implement `sidecars/aggregation/` Python service (RAPIDS) reading batches → group-by / rollup (e.g., log severity per service, metrics percentiles).
   - Publish derived metrics via OTLP HTTP (`http://localhost:14318/v1/metrics`) using lightweight exporter (e.g., `opentelemetry-exporter-otlp-proto-http`).
3. **Observability hooks:**
   - Emit custom metrics for GPU processing time, queue depth, fallback counts; ingest into SigNoz dashboards.

## Phase 3 – ML Inference Sidecar (Optional)
- Deploy Triton Inference Server container (`docker-compose.gpu.yml`) loading RAPIDS cyBERT model.
- Collector writes candidate log batches to `C:/otel/gpu-buffers/inference`.
- Inference sidecar publishes enriched logs with anomaly scores via OTLP HTTP to collector ingestion endpoint `http://localhost:14318/v1/logs`.

## Phase 4 – Health, Automation & Docs
- Extend `scripts/schedule-canary.ps1` to emit synthetic logs/metrics, then verify GPU sidecars processed them (compressed output, aggregation dashboards).
- Create `scripts/check-gpu-sidecars.ps1` to validate services running, GPU memory usage < 60%, queue depth < threshold.
- Update documentation (`docs/WIRING_GUIDE.md`, `docs/QUERY_RECIPES.md`, new `docs/GPU_SIDECAR.md`) with setup steps, fallback strategy, SigNoz queries (`log.attributes.gpu_sidecar == true`).
- Build SigNoz dashboard JSON for:
  - GPU compression throughput vs CPU baseline
  - Aggregation latency histogram
  - Fallback events, GPU utilization

## Phase 5 – Rollout & Verification
- Stage rollout behind feature flag `GPU_SIDECAR_ENABLED` in collector environment file.
- Run A/B comparison (GPU on/off) capturing CPU load, ingestion latency.
- Record verification artifacts under `artifacts/gpu-sidecar/*.json` and update `scripts/verify-wiring.ps1` to include GPU path checks.
