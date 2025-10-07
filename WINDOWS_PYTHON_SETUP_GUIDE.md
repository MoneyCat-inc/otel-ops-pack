# 🐾 Windows Python 3.13 Setup Guide

**MoneyCat Inc · Resonai [OTel] · otel-ops-pack**

## Quick Setup for Windows

### Option 1: Microsoft Store (Recommended)
1. Open Microsoft Store
2. Search for "Python 3.13"
3. Install "Python 3.13" (official package)
4. Verify installation: Open PowerShell and run `python --version`

### Option 2: Official Python Website
1. Go to [python.org/downloads](https://www.python.org/downloads/)
2. Download Python 3.13.x (latest stable)
3. **CRITICAL**: During installation, check "Add Python to PATH"
4. Choose "Install Now" or "Customize installation" → "Add Python to environment variables"

### Option 3: Windows Package Manager (winget)
```powershell
# Run as Administrator
winget install Python.Python.3.13
```

### Option 4: Chocolatey
```powershell
# If you have Chocolatey installed
choco install python313
```

## Verification

After installation, verify Python is accessible:

```powershell
# Check Python version
python --version
# Should show: Python 3.13.x

# Check pip
pip --version
# Should show: pip x.x.x from ...

# Test Python import
python -c "import sys; print(sys.version)"
```

## Common Issues & Solutions

### Issue: "python is not recognized"
**Solution**: Python not added to PATH
1. Reinstall Python with "Add to PATH" checked
2. Or manually add to PATH:
   - Open System Properties → Environment Variables
   - Add `C:\Users\[username]\AppData\Local\Programs\Python\Python313\` to PATH
   - Add `C:\Users\[username]\AppData\Local\Programs\Python\Python313\Scripts\` to PATH

### Issue: Multiple Python versions
**Solution**: Use py launcher
```powershell
# Use specific version
py -3.13 --version
py -3.13 -m venv venv
```

### Issue: Permission errors
**Solution**: Run PowerShell as Administrator

## After Python Installation

Once Python 3.13 is installed and accessible, run the BossCat setup script:

```powershell
.\setup_cursor_implementer.ps1
```

The script will now properly detect Python and create the virtual environment.

---

🐾 **BossCat Python Setup Complete**

*This guide ensures Python 3.13 is properly installed for the Resonai [OTel] observability stack.*
