#!/usr/bin/env python3
"""
BossCat Rolling Statistics Harness
GPU Pattern-Sifter EPIC - Lane T1
Shared-memory CUDA kernel with CPU parity validation and JSON evidence generation
"""

from __future__ import annotations

import ctypes
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional, Tuple

import numpy as np

BUILD_DIR = Path("build")
CUDA_KERNEL_FILENAME = "rolling_stats_tiled.cu"
DEFAULT_WINDOW = 256
DEFAULT_STRIDE = 64
DEFAULT_ITERATIONS = 10
RNG_SEED = 42
SCHEMA_VERSION = "v1.1"

CUDA_KERNEL_SOURCE = r"""
#include <cuda_runtime.h>
#include <math.h>

extern "C" {

__global__ void rolling_stats_tiled(const float* __restrict__ input,
                                    float* __restrict__ mean_out,
                                    float* __restrict__ std_out,
                                    int n,
                                    int window,
                                    int stride,
                                    int output_size) {
    extern __shared__ float tile[];

    const int tid = threadIdx.x;
    const int out_idx = blockIdx.x * blockDim.x + tid;
    const int block_first_out = blockIdx.x * blockDim.x;
    const int block_input_start = block_first_out * stride;

    if (out_idx >= output_size) {
        return;
    }

    int max_span = window + (blockDim.x - 1) * stride;
    int span = max_span;
    if (block_input_start + span > n) {
        span = n - block_input_start;
    }
    if (span < window) {
        return;
    }

    for (int offset = tid; offset < span; offset += blockDim.x) {
        tile[offset] = input[block_input_start + offset];
    }
    __syncthreads();

    const int local_offset = (out_idx * stride) - block_input_start;

    double sum = 0.0;
    double sumsq = 0.0;

    #pragma unroll 4
    for (int i = 0; i < window; ++i) {
        const double value = static_cast<double>(tile[local_offset + i]);
        sum += value;
        sumsq += value * value;
    }

    const double window_inv = 1.0 / static_cast<double>(window);
    const double mean = sum * window_inv;
    double variance = (sumsq * window_inv) - mean * mean;
    variance = variance > 0.0 ? variance : 0.0;

    mean_out[out_idx] = static_cast<float>(mean);
    std_out[out_idx] = static_cast<float>(sqrt(variance));
}

int launch_rolling_stats(const float* h_input,
                         float* h_mean_output,
                         float* h_stddev_output,
                         int n,
                         int window,
                         int stride,
                         double* timings_ms) {
    if (window <= 0 || stride <= 0 || n <= 0 || n < window) {
        return static_cast<int>(cudaErrorInvalidValue);
    }

    const int output_size = (n - window) / stride + 1;
    if (output_size <= 0) {
        return static_cast<int>(cudaErrorInvalidValue);
    }

    const size_t input_bytes = static_cast<size_t>(n) * sizeof(float);
    const size_t output_bytes = static_cast<size_t>(output_size) * sizeof(float);

    float* d_input = nullptr;
    float* d_mean_output = nullptr;
    float* d_stddev_output = nullptr;

    cudaError_t err = cudaMalloc(&d_input, input_bytes);
    if (err != cudaSuccess) {
        goto cleanup;
    }

    err = cudaMalloc(&d_mean_output, output_bytes);
    if (err != cudaSuccess) {
        goto cleanup;
    }

    err = cudaMalloc(&d_stddev_output, output_bytes);
    if (err != cudaSuccess) {
        goto cleanup;
    }

    cudaEvent_t h2d_start, h2d_stop, kernel_start, kernel_stop, d2h_start, d2h_stop;
    cudaEventCreate(&h2d_start);
    cudaEventCreate(&h2d_stop);
    cudaEventCreate(&kernel_start);
    cudaEventCreate(&kernel_stop);
    cudaEventCreate(&d2h_start);
    cudaEventCreate(&d2h_stop);

    cudaEventRecord(h2d_start);
    err = cudaMemcpy(d_input, h_input, input_bytes, cudaMemcpyHostToDevice);
    cudaEventRecord(h2d_stop);
    cudaEventSynchronize(h2d_stop);
    if (err != cudaSuccess) {
        goto cleanup_events;
    }

    float h2d_ms = 0.0f;
    cudaEventElapsedTime(&h2d_ms, h2d_start, h2d_stop);

    const int block_size = 128;
    const int grid_size = (output_size + block_size - 1) / block_size;
    const size_t shared_bytes = static_cast<size_t>(window + (block_size - 1) * stride) * sizeof(float);

    cudaEventRecord(kernel_start);
    rolling_stats_tiled<<<grid_size, block_size, shared_bytes>>>(
        d_input, d_mean_output, d_stddev_output, n, window, stride, output_size);
    cudaEventRecord(kernel_stop);
    cudaEventSynchronize(kernel_stop);

    err = cudaGetLastError();
    if (err != cudaSuccess) {
        goto cleanup_events;
    }

    float kernel_ms = 0.0f;
    cudaEventElapsedTime(&kernel_ms, kernel_start, kernel_stop);

    cudaEventRecord(d2h_start);
    err = cudaMemcpy(h_mean_output, d_mean_output, output_bytes, cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        goto cleanup_events;
    }
    err = cudaMemcpy(h_stddev_output, d_stddev_output, output_bytes, cudaMemcpyDeviceToHost);
    cudaEventRecord(d2h_stop);
    cudaEventSynchronize(d2h_stop);
    if (err != cudaSuccess) {
        goto cleanup_events;
    }

    float d2h_ms = 0.0f;
    cudaEventElapsedTime(&d2h_ms, d2h_start, d2h_stop);

    if (timings_ms != nullptr) {
        timings_ms[0] = static_cast<double>(h2d_ms);
        timings_ms[1] = static_cast<double>(kernel_ms);
        timings_ms[2] = static_cast<double>(d2h_ms);
    }

cleanup_events:
    cudaEventDestroy(h2d_start);
    cudaEventDestroy(h2d_stop);
    cudaEventDestroy(kernel_start);
    cudaEventDestroy(kernel_stop);
    cudaEventDestroy(d2h_start);
    cudaEventDestroy(d2h_stop);

cleanup:
    if (d_input != nullptr) {
        cudaFree(d_input);
    }
    if (d_mean_output != nullptr) {
        cudaFree(d_mean_output);
    }
    if (d_stddev_output != nullptr) {
        cudaFree(d_stddev_output);
    }

    return static_cast<int>(err);
}

const char* rolling_stats_error_string(int code) {
    return cudaGetErrorString(static_cast<cudaError_t>(code));
}

} // extern "C"
"""


def detect_cuda() -> bool:
    """Return True when NVIDIA tooling is available on this host."""
    return shutil.which("nvidia-smi") is not None


def detect_wsl() -> bool:
    """Detect if we are running inside Windows Subsystem for Linux."""
    try:
        with open("/proc/version", "r", encoding="utf-8") as handle:
            return "microsoft" in handle.read().lower()
    except FileNotFoundError:
        return False


def query_gpu_model() -> Optional[str]:
    """Attempt to read the active GPU model via nvidia-smi."""
    if shutil.which("nvidia-smi") is None:
        return None
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            line = result.stdout.strip().splitlines()
            if line:
                return line[0].strip()
    except FileNotFoundError:
        return None
    return None


def query_cuda_version() -> Optional[str]:
    """Query the CUDA version exposed by nvidia-smi."""
    if shutil.which("nvidia-smi") is None:
        return None
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=cuda_version", "--format=csv,noheader"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode == 0:
            value = result.stdout.strip().splitlines()
            if value:
                version = value[0].strip()
                return version if version else None
    except FileNotFoundError:
        return None
    return None


def get_git_sha() -> Optional[str]:
    """Return the current Git commit SHA if available."""
    if shutil.which("git") is None:
        return None
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 0:
        sha = result.stdout.strip()
        if len(sha) == 40 and all(ch in "0123456789abcdef" for ch in sha.lower()):
            return sha.lower()
    return None


def ensure_cuda_kernel_source() -> Path:
    """Materialise the shared-memory CUDA kernel in the build directory."""
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    src_path = BUILD_DIR / CUDA_KERNEL_FILENAME
    content = src_path.read_text(encoding="utf-8") if src_path.exists() else None
    if content != CUDA_KERNEL_SOURCE:
        src_path.write_text(CUDA_KERNEL_SOURCE, encoding="utf-8")
    return src_path


def compile_cuda_kernel() -> Optional[Path]:
    """Compile the CUDA kernel to a shared library and return its path."""
    if shutil.which("nvcc") is None:
        return None

    kernel_src = ensure_cuda_kernel_source()

    if sys.platform == "win32":
        library_name = "rolling_stats.dll"
    elif sys.platform == "darwin":
        library_name = "librolling_stats.dylib"
    else:
        library_name = "librolling_stats.so"

    output_path = BUILD_DIR / library_name

    need_rebuild = True
    if output_path.exists():
        need_rebuild = kernel_src.stat().st_mtime > output_path.stat().st_mtime

    if not need_rebuild:
        return output_path

    cmd = ["nvcc", "--shared", str(kernel_src), "-o", str(output_path), "-lcudart"]

    if sys.platform == "win32":
        cmd.extend(["-Xcompiler", "/MD"])
    else:
        cmd.extend(["-Xcompiler", "-fPIC"])

    cmd.extend(["-lineinfo"])

    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        print("[t1] nvcc compilation failed:")
        print(result.stdout)
        print(result.stderr)
        return None

    return output_path


class CUDARunner:
    """Thin ctypes wrapper around the compiled CUDA rolling kernel."""

    def __init__(self, library_path: Path) -> None:
        self._lib = ctypes.CDLL(str(library_path))
        self._launch = self._lib.launch_rolling_stats
        self._launch.argtypes = [
            ctypes.POINTER(ctypes.c_float),
            ctypes.POINTER(ctypes.c_float),
            ctypes.POINTER(ctypes.c_float),
            ctypes.c_int,
            ctypes.c_int,
            ctypes.c_int,
            ctypes.POINTER(ctypes.c_double),
        ]
        self._launch.restype = ctypes.c_int

        self._error_string = getattr(self._lib, "rolling_stats_error_string", None)
        if self._error_string is not None:
            self._error_string.argtypes = [ctypes.c_int]
            self._error_string.restype = ctypes.c_char_p

    def run(self, input_data: np.ndarray, mean_out: np.ndarray, std_out: np.ndarray, window: int, stride: int) -> Tuple[float, float, float]:
        timings = (ctypes.c_double * 3)()
        rc = self._launch(
            input_data.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
            mean_out.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
            std_out.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
            ctypes.c_int(int(input_data.size)),
            ctypes.c_int(int(window)),
            ctypes.c_int(int(stride)),
            timings,
        )
        if rc != 0:
            message = f"CUDA error {rc}"
            if self._error_string is not None:
                err_ptr = self._error_string(ctypes.c_int(rc))
                if err_ptr:
                    decoded = err_ptr.decode("utf-8", "ignore")
                    if decoded:
                        message = decoded
            raise RuntimeError(message)
        return float(timings[0]), float(timings[1]), float(timings[2])


def generate_test_data(n: int = 4096, seed: int = RNG_SEED) -> np.ndarray:
    """Generate deterministic mixed-distribution test data."""
    rng = np.random.default_rng(seed)
    segment = n // 3
    data_a = rng.normal(0.0, 1.0, segment)
    data_b = rng.normal(10.0, 2.0, segment)
    data_c = rng.normal(-5.0, 1.5, n - (2 * segment))
    data = np.concatenate([data_a, data_b, data_c]).astype(np.float32)
    return data


def cpu_rolling_stats(input_data: np.ndarray, window: int, stride: int) -> Tuple[np.ndarray, np.ndarray]:
    """Reference rolling statistics using double accumulators."""
    n = input_data.shape[0]
    output_size = (n - window) // stride + 1

    means = np.empty(output_size, dtype=np.float64)
    stddevs = np.empty(output_size, dtype=np.float64)

    for idx in range(output_size):
        start = idx * stride
        window_slice = input_data[start:start + window].astype(np.float64)
        means[idx] = np.mean(window_slice)
        stddevs[idx] = np.std(window_slice, ddof=0)

    return means.astype(np.float32), stddevs.astype(np.float32)


def calculate_parity(gpu_results: Tuple[np.ndarray, np.ndarray], cpu_results: Tuple[np.ndarray, np.ndarray]) -> Dict[str, float]:
    """Return parity metrics between GPU and CPU outputs."""
    gpu_means, gpu_stddevs = gpu_results
    cpu_means, cpu_stddevs = cpu_results

    mean_diff = np.abs(gpu_means - cpu_means)
    std_diff = np.abs(gpu_stddevs - cpu_stddevs)

    return {
        "maxAbsDiff": float(np.max(mean_diff)) if mean_diff.size else 0.0,
        "meanDiff": float(np.mean(mean_diff)) if mean_diff.size else 0.0,
        "stddevMaxDiff": float(np.max(std_diff)) if std_diff.size else 0.0,
        "stddevMeanDiff": float(np.mean(std_diff)) if std_diff.size else 0.0,
    }


def clean_structure(value: Any) -> Any:
    """Recursively strip None values and convert numpy types."""
    if isinstance(value, dict):
        return {k: clean_structure(v) for k, v in value.items() if v is not None}
    if isinstance(value, (list, tuple)):
        return [clean_structure(v) for v in value if v is not None]
    if isinstance(value, np.generic):
        return value.item()
    return value


def hash_payload(payload: np.ndarray) -> str:
    """Return a sha256 hash for the provided numpy payload."""
    digest = hashlib.sha256(payload.tobytes()).hexdigest()
    return digest


class RollingStatsBenchmark:
    """Coordinator for CPU and CUDA rolling-statistics benchmarks."""

    def __init__(self) -> None:
        self.cuda_available = detect_cuda()
        self.cuda_version = query_cuda_version()
        self.gpu_model = query_gpu_model()
        self.wsl_detected = detect_wsl()
        self.cuda_runner: Optional[CUDARunner] = None

        if self.cuda_available:
            library_path = compile_cuda_kernel()
            if library_path is not None:
                try:
                    self.cuda_runner = CUDARunner(library_path)
                except OSError as exc:
                    print(f"[t1] Failed to load CUDA library: {exc}")
                    self.cuda_runner = None

    def execute(self, window: int = DEFAULT_WINDOW, stride: int = DEFAULT_STRIDE, iterations: int = DEFAULT_ITERATIONS, deployment_override: Optional[Dict[str, Any]] = None) -> Tuple[Dict[str, Any], Dict[str, Any]]:
        input_data = generate_test_data()
        cpu_timings_ms = []
        cpu_means = None
        cpu_stddevs = None

        for _ in range(iterations):
            start = time.perf_counter()
            cpu_means, cpu_stddevs = cpu_rolling_stats(input_data, window, stride)
            cpu_timings_ms.append((time.perf_counter() - start) * 1000.0)

        assert cpu_means is not None and cpu_stddevs is not None
        cpu_ms = float(np.mean(cpu_timings_ms))

        gpu_means = None
        gpu_stddevs = None
        h2d_ms = 0.0
        kernel_ms = 0.0
        d2h_ms = 0.0
        provider_final = "cpu"
        fell_back_to_cpu = True
        parity = {
            "maxAbsDiff": 0.0,
            "meanDiff": 0.0,
            "stddevMaxDiff": 0.0,
            "stddevMeanDiff": 0.0,
        }

        if self.cuda_runner is not None:
            try:
                output_size = cpu_means.shape[0]
                gpu_means = np.empty(output_size, dtype=np.float32)
                gpu_stddevs = np.empty(output_size, dtype=np.float32)

                h2d_total = 0.0
                kernel_total = 0.0
                d2h_total = 0.0

                # Warm-up + measured iterations
                for _ in range(iterations):
                    h2d, kernel, d2h = self.cuda_runner.run(input_data, gpu_means, gpu_stddevs, window, stride)
                    h2d_total += h2d
                    kernel_total += kernel
                    d2h_total += d2h

                h2d_ms = h2d_total / iterations
                kernel_ms = kernel_total / iterations
                d2h_ms = d2h_total / iterations

                parity = calculate_parity((gpu_means, gpu_stddevs), (cpu_means, cpu_stddevs))
                provider_final = "cuda"
                fell_back_to_cpu = False
            except Exception as exc:
                print(f"[t1] CUDA execution failed: {exc}")
                gpu_means = None
                gpu_stddevs = None
                provider_final = "cpu"
                fell_back_to_cpu = True

        providers = ["cpu"]
        if self.cuda_runner is not None:
            providers = ["cuda", "cpu"]

        env = {
            "providers": providers,
            "wsl_detected": self.wsl_detected,
        }
        if self.cuda_version:
            env["cudaVersion"] = self.cuda_version
        if self.gpu_model:
            env["gpu_model"] = self.gpu_model

        note = None
        if fell_back_to_cpu and self.cuda_runner is None:
            note = "cuda-not-available"
        elif fell_back_to_cpu:
            note = "cuda-error"

        deployment = {
            "environment": "development",
            "version": os.getenv("T1_BUILD_VERSION", "dev-local"),
            "deployed_at": datetime.now(timezone.utc).isoformat(),
        }

        if deployment_override:
            deployment.update({k: v for k, v in deployment_override.items() if v is not None})

        if deployment.get("environment") == "production" and "gitSha" not in deployment:
            git_sha = get_git_sha()
            if git_sha is not None:
                deployment["gitSha"] = git_sha

        timings = {
            "h2dMs": float(h2d_ms),
            "kernelMs": float(kernel_ms),
            "d2hMs": float(d2h_ms),
            "gpuMs": float(h2d_ms + kernel_ms + d2h_ms),
            "cpuMs": float(cpu_ms),
            "accMs": float(h2d_ms + kernel_ms + d2h_ms) if provider_final == "cuda" else float(cpu_ms),
        }

        evidence = {
            "ok": True,
            "ts": datetime.now(timezone.utc).isoformat(),
            "algo": "rolling",
            "params": {
                "window": int(window),
                "stride": int(stride),
                "iterations": int(iterations),
                "schema_version": SCHEMA_VERSION,
                "seed": RNG_SEED,
            },
            "timings": timings,
            "parity": parity,
            "env": env,
            "run": {
                "providerFinal": provider_final,
                "fellBackToCpu": fell_back_to_cpu,
                "gpu_fallback": fell_back_to_cpu,
                "note": note,
            },
            "hashes": {
                "inputSha256": hash_payload(input_data),
            },
            "deployment": deployment,
        }

        evidence = clean_structure(evidence)

        context = {
            "gpu_available": self.cuda_runner is not None,
            "timings": timings,
            "parity": parity,
            "providers": providers,
            "gpu_model": self.gpu_model,
            "cuda_version": self.cuda_version,
        }

        return evidence, context


def run_benchmark(window: int = DEFAULT_WINDOW, stride: int = DEFAULT_STRIDE, iterations: int = DEFAULT_ITERATIONS, deployment_override: Optional[Dict[str, Any]] = None) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Public helper to execute the benchmark and obtain evidence."""
    benchmark = RollingStatsBenchmark()
    return benchmark.execute(window=window, stride=stride, iterations=iterations, deployment_override=deployment_override)


def run_validator(evidence_path: Path) -> bool:
    """Invoke the TypeScript evidence validator when available."""
    if not Path("scripts/validate_evidence.ts").exists():
        return True

    if shutil.which("npx") is None:
        print("[t1] npx not available, skipping schema validation")
        return False

    try:
        result = subprocess.run(
            ["npx", "tsx", "scripts/validate_evidence.ts", str(evidence_path)],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print("[t1] npx command not found at runtime, skipping schema validation")
        return False

    if result.returncode == 0:
        print("[t1] Evidence validation passed")
        return True

    print("[t1] Evidence validation failed:")
    print(result.stdout)
    print(result.stderr)
    return False


def main() -> None:
    if sys.platform == "win32":
        import codecs
        sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
        sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())

    print("[t1] BossCat Rolling Statistics Harness")
    print("[t1] GPU Pattern-Sifter EPIC - Lane T1")

    evidence, context = run_benchmark()

    print("\n[t1] Performance Results:")
    print(f"  GPU: {context['timings']['gpuMs']:.2f} ms")
    print(f"  CPU: {context['timings']['cpuMs']:.2f} ms")
    print(f"  Parity (maxAbsDiff): {context['parity']['maxAbsDiff']:.2e}")
    print(f"  Provider: {evidence['run']['providerFinal']}")

    if evidence['run']['fellBackToCpu']:
        print("  Note: fell back to CPU execution")

    evidence_path = Path("CHAR/ECRR/ECRR_REPORTS/rolling_stats_evidence.json")
    evidence_path.parent.mkdir(parents=True, exist_ok=True)
    evidence_path.write_text(json.dumps(evidence, indent=2), encoding="utf-8")

    print(f"\n[t1] Evidence saved to {evidence_path}")
    run_validator(evidence_path)

    if evidence['parity']['maxAbsDiff'] > 1e-5:
        print(f"[t1] Parity threshold exceeded: {evidence['parity']['maxAbsDiff']:.2e} > 1e-5")
        sys.exit(1)

    print("[t1] Parity threshold satisfied")


if __name__ == "__main__":
    main()


