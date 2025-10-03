# PyTorch Dependency Setup Guide

This document explains the PyTorch dependency configuration for different deployment scenarios.

## Overview

The repository provides two PyTorch dependency configurations:

- **`requirements.txt`** - CPU-only PyTorch (recommended for CI/CD)
- **`requirements-gpu.txt`** - CUDA-accelerated PyTorch (for GPU environments)

## CPU-Only Configuration (Default)

**File**: `requirements.txt`

**Use case**: CI/CD pipelines, development, servers without GPU

**Installation**:
```bash
pip install -r requirements.txt
```

**PyTorch versions**:
- `torch==2.5.1` (CPU-only)
- `torchaudio==2.5.1` (CPU-only)
- `torchvision==0.20.1` (CPU-only)

**Compatibility**:
- ✅ Python 3.8 - 3.12
- ✅ GitHub Actions runners
- ✅ Available on PyPI
- ✅ No external indexes required

## GPU Configuration (CUDA)

**File**: `requirements-gpu.txt`

**Use case**: GPU-accelerated training, inference on NVIDIA hardware

**Installation**:
```bash
pip install -r requirements-gpu.txt -f https://download.pytorch.org/whl/torch_stable.html
```

**PyTorch versions**:
- `torch==2.5.1+cu121` (CUDA 12.1)
- `torchaudio==2.5.1+cu121` (CUDA 12.1)
- `torchvision==0.20.1+cu121` (CUDA 12.1)

**Requirements**:
- ✅ NVIDIA GPU with CUDA 12.1+ support
- ✅ Compatible CUDA drivers installed
- ✅ Python >=3.8,<3.12 (CUDA builds may not support 3.12+)
- ❌ Not suitable for GitHub Actions (no GPU access)

## GitHub Actions Integration

### Workflow Configuration

For CI/CD pipelines, use the CPU-only configuration:

```yaml
- name: Set up Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.11'  # Use 3.11 for better CUDA compatibility if needed

- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt  # CPU-only version
```

### Python Version Compatibility

| Python Version | CPU PyTorch | CUDA PyTorch | GitHub Actions |
|----------------|-------------|--------------|----------------|
| 3.8            | ✅          | ✅           | ✅             |
| 3.9            | ✅          | ✅           | ✅             |
| 3.10           | ✅          | ✅           | ✅             |
| 3.11           | ✅          | ✅           | ✅             |
| 3.12           | ✅          | ❌           | ✅             |

## Troubleshooting

### "No matching distribution found" Error

**Cause**: Trying to install CUDA PyTorch without the proper index

**Solution**:
1. Use CPU-only version: `pip install -r requirements.txt`
2. Or use GPU version with index: `pip install -r requirements-gpu.txt -f https://download.pytorch.org/whl/torch_stable.html`

### Python Version Conflicts

**Cause**: Using Python 3.12 with CUDA PyTorch

**Solution**:
1. Use Python 3.11 or earlier for CUDA builds
2. Use Python 3.12 with CPU-only PyTorch

### GitHub Actions Failures

**Cause**: CI/CD trying to install CUDA dependencies

**Solution**:
1. Ensure workflows use `requirements.txt` (CPU-only)
2. Verify Python version compatibility
3. Check that no CUDA-specific installation commands are used

## Migration Guide

### From CUDA to CPU-only

1. Replace `requirements.txt` content:
   ```bash
   # Old (CUDA)
   torch==2.5.1+cu121
   
   # New (CPU-only)
   torch==2.5.1
   ```

2. Remove any PyTorch index specifications from workflows

3. Test with Python 3.12 to ensure compatibility

### From CPU-only to CUDA

1. Use `requirements-gpu.txt`:
   ```bash
   pip install -r requirements-gpu.txt -f https://download.pytorch.org/whl/torch_stable.html
   ```

2. Ensure CUDA environment is properly configured

3. Verify GPU availability and driver compatibility

## Best Practices

1. **Default to CPU-only** for CI/CD and development
2. **Use CUDA only when necessary** for GPU-accelerated workloads
3. **Test both configurations** before deployment
4. **Document Python version requirements** clearly
5. **Pin exact versions** to ensure reproducible builds

## References

- [PyTorch Installation Guide](https://pytorch.org/get-started/locally/)
- [PyTorch Index](https://download.pytorch.org/whl/torch_stable.html)
- [CUDA Compatibility Matrix](https://pytorch.org/get-started/previous-versions/)
