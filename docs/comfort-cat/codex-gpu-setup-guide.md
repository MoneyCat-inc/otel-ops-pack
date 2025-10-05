# Codex GPU Setup Guide for RTX 2080

## Overview

This guide configures Codex CLI to run coding models on your local NVIDIA GeForce RTX 2080 (8GB VRAM) instead of using cloud-based models. This provides faster inference, privacy, and no API costs for coding tasks.

## Hardware Specifications

- **GPU**: NVIDIA GeForce RTX 2080
- **VRAM**: 8GB
- **CUDA**: Version 13.0
- **Driver**: 581.42

## Installation Steps

### 1. Install Ollama

Run the automated installation script:

```powershell
pwsh -File scripts\install-ollama-gpu.ps1
```

Or install manually:
1. Download from https://ollama.ai/download/windows
2. Run the installer
3. Restart your terminal

### 2. Download Coding Models

The script automatically downloads models optimized for 8GB VRAM:

- **Code Llama 7B** (`codellama:7b`) - Fast, general-purpose coding model
- **Qwen 2.5 7B** (`qwen2.5:7b`) - Excellent coding performance with good reasoning
- **DeepSeek Coder 6.7B** (`deepseek-coder:6.7b`) - Specialized for coding tasks

### 3. Configuration

Your `~/.codex/config.toml` is automatically configured with:

#### Model Providers
```toml
[model_providers.ollama]
name = "Ollama Local GPU"
base_url = "http://localhost:11434/v1"
```

#### GPU-Optimized Profiles
```toml
[profiles.codellama-7b-gpu]
model_provider = "ollama"
model = "codellama:7b"
model_reasoning_effort = "high"
approval_policy = "on-failure"

[profiles.qwen-7b-gpu]
model_provider = "ollama"
model = "qwen2.5:7b"
model_reasoning_effort = "high"
approval_policy = "on-failure"

[profiles.deepseek-coder-gpu]
model_provider = "ollama"
model = "deepseek-coder:6.7b"
model_reasoning_effort = "high"
approval_policy = "on-failure"
```

## Usage

### Start Ollama Service

```powershell
ollama serve
```

### Run Codex with GPU Models

```powershell
# Use Code Llama 7B (fastest)
codex --profile codellama-7b-gpu

# Use Qwen 2.5 7B (balanced performance)
codex --profile qwen-7b-gpu

# Use DeepSeek Coder (specialized for coding)
codex --profile deepseek-coder-gpu
```

### In VS Code/Cursor

1. Open Codex extension settings
2. Set the profile to one of the GPU profiles
3. The extension will automatically use your local GPU

## Performance Expectations

### RTX 2080 (8GB VRAM) Performance

| Model | VRAM Usage | Speed | Quality |
|-------|------------|-------|---------|
| Code Llama 7B | ~4-5GB | Fast | Good |
| Qwen 2.5 7B | ~4-5GB | Medium | Excellent |
| DeepSeek Coder 6.7B | ~3-4GB | Fast | Very Good |

### Context Length Optimization

For large projects, increase context length:

```powershell
# Set larger context window (default is usually 2048)
ollama run codellama:7b --ctx-size 8192
```

## Monitoring GPU Usage

```powershell
# Monitor GPU memory and usage
nvidia-smi

# Monitor continuously
nvidia-smi -l 1
```

## Troubleshooting

### Common Issues

1. **Ollama not found**: Restart terminal or add to PATH
2. **Out of memory**: Use smaller models or reduce context size
3. **Slow performance**: Check GPU utilization with `nvidia-smi`

### Performance Tuning

1. **Increase context size** for large codebases:
   ```toml
   [profiles.codellama-7b-gpu]
   model = "codellama:7b"
   context_length = 8192
   ```

2. **Adjust batch size** for faster inference:
   ```powershell
   ollama run codellama:7b --num-predict 512 --num-ctx 4096
   ```

3. **Enable GPU acceleration** (if not automatic):
   ```powershell
   set CUDA_VISIBLE_DEVICES=0
   ollama serve
   ```

## Model Comparison

### Code Llama 7B
- **Best for**: General coding, fast iteration
- **Strengths**: Speed, good code generation
- **Use when**: Working on smaller projects, quick prototyping

### Qwen 2.5 7B
- **Best for**: Complex reasoning, code review
- **Strengths**: Excellent understanding, good explanations
- **Use when**: Need detailed analysis or explanations

### DeepSeek Coder 6.7B
- **Best for**: Specialized coding tasks
- **Strengths**: Code-specific training, efficient
- **Use when**: Focus on pure coding tasks

## ECRR Compliance

This GPU setup maintains ECRR compliance:

- **Examine**: GPU usage monitoring
- **Clean**: Automatic model management
- **Report**: Performance metrics collection
- **Role**: BossCat integration for automation

## BossCat Integration

The GPU profiles integrate with BossCat automation:

```toml
# BossCat can automatically switch profiles based on task complexity
[bosscat.gpu_profiles]
simple_tasks = "codellama-7b-gpu"
complex_tasks = "qwen-7b-gpu"
specialized_coding = "deepseek-coder-gpu"
```

## Security Considerations

- **Local inference**: No data sent to external APIs
- **Model isolation**: Models run in controlled environment
- **GPU memory**: Automatically managed by Ollama
- **Network**: Only local connections (localhost:11434)

## Maintenance

### Regular Tasks

1. **Update Ollama**: `ollama update`
2. **Update models**: `ollama pull codellama:7b`
3. **Monitor VRAM**: Check with `nvidia-smi`
4. **Clean old models**: `ollama rm <model>`

### Performance Monitoring

```powershell
# Check model status
ollama list

# Test model performance
ollama run codellama:7b "Generate a Python function to sort a list"
```

---

## 🎯 Quick Start Summary

1. **Install**: `pwsh -File scripts\install-ollama-gpu.ps1`
2. **Start**: `ollama serve`
3. **Use**: `codex --profile codellama-7b-gpu`
4. **Monitor**: `nvidia-smi`

Your RTX 2080 is now ready for local GPU-accelerated coding with Codex!

*Generated by BossCat OEM - Executive Overseer Manager*
