# 🐾 Codex Usage Guide
**Cat Nap Control Room - Low-Latency Observability Pipeline**

## 🚀 **Quick Start Commands**

### **Cloud Model (Always Works)**
```powershell
# Use named profile (recommended)
codex --profile cloud

# Or use direct command
codex -m gpt-5-codex
```

### **GPU Models (When VRAM Available)**
```powershell
# CodeLlama 7B (best for coding)
codex --profile codellama-7b-gpu

# Qwen 7B (balanced performance)
codex --profile qwen-7b-gpu

# DeepSeek Coder (specialized coding)
codex --profile deepseek-coder-gpu
```

## 📊 **GPU Memory Check**
```powershell
# Check available VRAM
nvidia-smi

# You need 2GB+ free VRAM for GPU models
# Current: 775MB free (too low for GPU models)
```

## 🔄 **Easy Switching Strategy**

### **Default Usage**
- **Use `cloud` profile** for most work - always works, no GPU required
- **Use `codellama-7b-gpu`** when you have 2GB+ free VRAM

### **When to Use Each**
- **Cloud**: Always available, best performance, uses API quota
- **GPU**: Free, private, works offline, requires sufficient VRAM

## ⚡ **Performance Comparison**

| Model | Speed | Quality | Cost | Privacy |
|-------|-------|---------|------|---------|
| Cloud | Fast | Best | API cost | Data sent to OpenAI |
| GPU | Medium | Good | Free | 100% local |

## 🛠️ **Troubleshooting**

### **Connection Issues**
```powershell
# Test cloud connection
codex --profile cloud "test"

# Test GPU connection
codex --profile codellama-7b-gpu "test"
```

### **Low VRAM**
- Close Discord, ChatGPT, or other GPU apps
- Use cloud profile until VRAM is freed up
- Check with `nvidia-smi`

### **Configuration Issues**
```powershell
# Verify config
pwsh -File scripts\verify-gpu-codex.ps1

# Fix connection issues
pwsh -File scripts\fix-codex-connection.ps1
```

## 📁 **Configuration Files**

- **Main Config**: `C:\Users\fubum\.codex\config.toml`
- **Profiles**: Defined in config.toml under `[profiles.*]`
- **Auth**: `C:\Users\fubum\.codex\auth.json` (your API keys)

## 🎯 **Best Practices**

1. **Start with cloud profile** for reliability
2. **Switch to GPU when available** for free usage
3. **Check VRAM before using GPU models**
4. **Use named profiles** instead of long commands
5. **Keep Ollama service running** for GPU models

## 🔧 **Quick Commands Reference**

```powershell
# List available profiles
codex --help

# Check current session
/status

# Change model during session
/model

# Exit Codex
Ctrl+C
```

---

**🐾 Ready to code with your Cat Nap Control Room!**
