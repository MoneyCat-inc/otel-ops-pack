# 🚀 GPU Quick Reference - ONNX Runtime Execution Providers

**Cat Nap Control Room · Resonai [OTel] · GPU Acceleration Guide**

---

## 🎯 Execution Provider Matrix

| Provider | Platform | Use Case | Install Command |
|----------|----------|----------|-----------------|
| **CPU** | All | Fallback, compatibility | `pip install onnxruntime` |
| **CUDA** | NVIDIA GPU | High performance, CUDA 11.8+ | `pip install onnxruntime-gpu` |
| **TensorRT** | NVIDIA GPU | Optimized inference, INT8/FP16 | `pip install onnxruntime-gpu` + TensorRT |
| **DirectML** | Windows | Windows GPU acceleration | `pip install onnxruntime-directml` |
| **ROCm** | AMD GPU | AMD GPU acceleration | `pip install onnxruntime-gpu` + ROCm |
| **CoreML/MPS** | macOS | Apple Silicon acceleration | `pip install onnxruntime` |

---

## 📦 Install One-Liners

### Standard CPU Runtime
```bash
pip install onnxruntime
```

### NVIDIA GPU Runtime
```bash
pip install onnxruntime-gpu
```

### Windows DirectML Runtime
```bash
pip install onnxruntime-directml
```

### Verify Installation
```bash
python -c "import onnxruntime as ort; print(ort.get_available_providers())"
```

---

## 🔍 Provider Check Snippet

```python
import onnxruntime as ort

def check_providers():
    """Check available ONNX Runtime execution providers"""
    available = ort.get_available_providers()
    
    print("Available Execution Providers:")
    for provider in available:
        print(f"  ✓ {provider}")
    
    # Check specific providers
    gpu_providers = ['CUDAExecutionProvider', 'DmlExecutionProvider', 'TensorrtExecutionProvider']
    has_gpu = any(provider in available for provider in gpu_providers)
    
    print(f"\nGPU Acceleration: {'✓ Available' if has_gpu else '✗ CPU Only'}")
    return available

# Run check
providers = check_providers()
```

### Expected Console Output (GPU Available)
```
Available Execution Providers:
  ✓ CPUExecutionProvider
  ✓ CUDAExecutionProvider
  ✓ DmlExecutionProvider

GPU Acceleration: ✓ Available
```

### Expected Console Output (CPU Only)
```
Available Execution Providers:
  ✓ CPUExecutionProvider

GPU Acceleration: ✗ CPU Only
```

---

## 🛠️ Troubleshooting Guide

### "CUDA Present but ORT on CPU"

**Symptoms:**
- CUDA drivers installed and working
- `nvidia-smi` shows GPU
- ONNX Runtime only shows `CPUExecutionProvider`

**Solutions:**
1. **Wrong Package:** Ensure `onnxruntime-gpu` not `onnxruntime`
   ```bash
   pip uninstall onnxruntime
   pip install onnxruntime-gpu
   ```

2. **Version Mismatch:** Check CUDA/ORT compatibility
   ```bash
   # Check CUDA version
   nvidia-smi
   
   # Check ORT version
   python -c "import onnxruntime; print(onnxruntime.__version__)"
   ```

3. **Driver Issues:** Update NVIDIA drivers
   ```bash
   # Windows: Download from NVIDIA website
   # Linux: nvidia-driver-xxx
   ```

### Driver/Tool Mismatch

**CUDA Toolkit vs Driver Version:**
- CUDA 11.8+ recommended for latest ORT-GPU
- Driver must support CUDA version
- Check compatibility matrix: [NVIDIA CUDA Compatibility](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)

**Windows DirectML Issues:**
```bash
# Check DirectML support
python -c "import onnxruntime as ort; print('DmlExecutionProvider' in ort.get_available_providers())"
```

**macOS CoreML/MPS Issues:**
```bash
# Check Apple Silicon
python -c "import platform; print(f'Architecture: {platform.machine()}')"
```

---

## 🎛️ Provider Selection Strategy

### Automatic Fallback Pattern
```python
def create_session_with_fallback(model_path):
    """Create ONNX session with intelligent provider selection"""
    
    # Preferred order: GPU → CPU fallback
    providers = [
        ['CUDAExecutionProvider', 'CPUExecutionProvider'],
        ['DmlExecutionProvider', 'CPUExecutionProvider'], 
        ['CPUExecutionProvider']
    ]
    
    for provider_list in providers:
        try:
            session = ort.InferenceSession(model_path, providers=provider_list)
            active_provider = session.get_providers()[0]
            print(f"✓ Using {active_provider}")
            return session, active_provider
        except Exception as e:
            print(f"✗ Failed with {provider_list[0]}: {e}")
            continue
    
    raise RuntimeError("No compatible execution provider found")
```

### Performance Benchmarks (Expected)
- **CPU**: Baseline (1.0x)
- **CUDA**: 5-15x faster (depending on model)
- **TensorRT**: 10-30x faster (with optimization)
- **DirectML**: 2-8x faster (Windows GPU)
- **ROCm**: 3-10x faster (AMD GPU)

---

## 🔒 Kill-Switch Integration

**BossCat Compliance:** All GPU operations respect `.agent/LOCK` file

```python
import os

def check_kill_switch():
    """BossCat kill-switch check"""
    if os.path.exists('.agent/LOCK'):
        print("🚫 BossCat kill-switch active - GPU operations disabled")
        return False
    return True

# Always check before GPU operations
if not check_kill_switch():
    exit(0)
```

---

## 📊 ECRR Evidence Collection

**Required Artifacts:**
- Provider detection results → `docs/ecrr/ECRR_REPORTS/gpu_provider_check.json`
- Performance benchmarks → `docs/ecrr/ECRR_REPORTS/gpu_benchmark.json`
- Error logs → `docs/ecrr/ECRR_REPORTS/gpu_errors.json`

**BossCat Console Output:**
```
[BossCat] gpu_infer – provider: CUDAExecutionProvider, 6.8ms (evidence written).
[BossCat] gpu_infer – GPU unavailable, fell back to CPU, 42.1ms (evidence written).
```

---

## 🎯 Local-First Principles

1. **No External Dependencies:** Pure stdio + local files
2. **Deterministic Behavior:** Same results across environments
3. **Graceful Degradation:** CPU fallback always available
4. **Evidence Collection:** All operations produce ECRR artifacts
5. **Kill-Switch Compliance:** Respect `.agent/LOCK` file

---

*🐾 BossCat Approved · ECRR Compliant · Local-First Architecture*
