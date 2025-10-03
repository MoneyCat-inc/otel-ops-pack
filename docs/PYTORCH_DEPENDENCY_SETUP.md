# PyTorch Dependency Setup Guide

This document explains the PyTorch dependency configuration for different deployment scenarios.

## Overview

The repository provides two PyTorch dependency configurations:

- **requirements.txt** - CPU-only PyTorch (recommended for CI/CD)
- **requirements-gpu.txt** - CUDA-accelerated PyTorch (for GPU environments)

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
- Supported Python versions: 3.9 - 3.12 (PyPI wheels available)
- Works on GitHub Actions hosted runners
- No external package indexes required

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
- NVIDIA GPU with CUDA 12.1+ support
- CUDA 12.1 drivers and toolkit installed
- Supported Python versions: 3.9 - 3.11 (CUDA wheels published for these versions)
- Not available on GitHub Actions hosted runners (no GPU access)

## GitHub Actions Integration

### Workflow Configuration

For CI/CD pipelines, use the CPU-only configuration:

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.12'

- name: Install dependencies
  run: |
    python -m pip install --upgrade pip
    pip install -r requirements.txt
```

### Python Version Compatibility

| Python Version | CPU PyTorch (`requirements.txt`) | CUDA PyTorch (`requirements-gpu.txt`) | GitHub Actions |
| -------------- | -------------------------------- | ------------------------------------ | -------------- |
| 3.8            | No (PyTorch 2.5.1 dropped support) | No (no wheels)                       | Avoid (use newer) |
| 3.9            | Yes                               | Yes (requires CUDA toolkit)          | Yes (CPU only) |
| 3.10           | Yes                               | Yes (requires CUDA toolkit)          | Yes (CPU only) |
| 3.11           | Yes                               | Yes (requires CUDA toolkit)          | Yes (CPU only) |
| 3.12           | Yes (tested locally)               | Limited (wheels pending, prefer CPU) | Yes (default image) |

## Troubleshooting

### "No matching distribution found" Error

**Cause**: Trying to install CUDA PyTorch without the proper index or on an unsupported Python version.

**Solution**:
1. Use CPU-only version: `pip install -r requirements.txt`
2. Or use GPU version with index: `pip install -r requirements-gpu.txt -f https://download.pytorch.org/whl/torch_stable.html`
3. Ensure Python version matches the supported range (see table above)

### Python Version Conflicts

**Cause**: Using Python 3.12 with CUDA PyTorch or Python 3.8 with PyTorch 2.5.1.

**Solution**:
1. Use Python 3.9 - 3.11 for CUDA builds
2. Use Python 3.9 - 3.12 for CPU-only PyTorch
3. Upgrade or downgrade Python to a supported version as needed

### GitHub Actions Failures

**Cause**: CI/CD trying to install CUDA dependencies or using an unsupported Python version.

**Solution**:
1. Ensure workflows use `requirements.txt` (CPU-only)
2. Verify Python version compatibility
3. Check that no CUDA-specific installation commands are used in hosted runners

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

1. Default to CPU-only for CI/CD and development
2. Use CUDA only when necessary for GPU-accelerated workloads
3. Test both configurations before deployment
4. Document Python version requirements clearly
5. Pin exact versions to ensure reproducible builds

## References

- [PyTorch Installation Guide](https://pytorch.org/get-started/locally/)
- [PyTorch Index](https://download.pytorch.org/whl/torch_stable.html)
- [CUDA Compatibility Matrix](https://pytorch.org/get-started/previous-versions/)
