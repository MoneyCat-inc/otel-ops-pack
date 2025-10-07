# 🐾 BossCat Environment Setup Guide

**MoneyCat Inc · Resonai [OTel] · otel-ops-pack**  
**ECRR Framework: Examine → Clean → Report → Role**

## Overview

This environment setup script prepares your local development environment for BossCat's CI workflow execution. It installs Python 3.13, Node.js dependencies, k6, and Locust, then creates the required artifact and report directories following the ECRR compliance framework.

## Prerequisites

- **Windows**: PowerShell 7+ or Windows PowerShell 5.1+
- **Linux/macOS**: Bash shell
- Internet connection for downloading dependencies
- Administrative privileges (for some package installations)

## Quick Start

### Windows (PowerShell)
```powershell
# Run the PowerShell version
.\setup_cursor_implementer.ps1

# With verbose output
.\setup_cursor_implementer.ps1 -Verbose

# Skip specific components
.\setup_cursor_implementer.ps1 -SkipPython -SkipK6
```

### Linux/macOS (Bash)
```bash
# Make executable and run
chmod +x setup_cursor_implementer.sh
./setup_cursor_implementer.sh

# Skip sudo operations (if you prefer manual installation)
./setup_cursor_implementer.sh --skip-sudo

# Skip specific components
./setup_cursor_implementer.sh --skip-python --skip-k6

# Show help
./setup_cursor_implementer.sh --help
```

## What the Script Does

### 1. **Examine** - Environment Detection
- Detects your operating system (Windows/Linux/macOS)
- Verifies you're in the project root (checks for `AGENTS.md`)
- Validates current directory structure

### 2. **Clean** - Python 3.13 Setup
- **Windows**: Prompts for manual Python 3.13 installation if not found
- **Linux**: Installs Python 3.13 via deadsnakes PPA
- **macOS**: Installs Python 3.13 via Homebrew
- Creates virtual environment (`venv/`)
- Installs dependencies from `requirements.txt` and `requirements-dev.txt`
- Adds BossCat development tools: `flake8`, `black`, `locust`, `pytest`, `pytest-cov`

### 3. **Report** - Node.js and Testing Tools
- **Windows**: Prompts for manual Node.js installation if not found
- **Linux**: Installs Node.js via NodeSource repository
- **macOS**: Installs Node.js via Homebrew
- Runs `npm install` and `npm audit fix`
- Installs k6 for performance testing
- Validates all tool installations

### 4. **Role** - Directory Structure Setup
Creates required BossCat directories:
```
artifacts/
├── benchmarks/
├── reports/
└── snapshots/

docs/
├── BossCat/
│   └── reports/
├── ecrr/
│   └── ECRR_REPORTS/
├── observability/
│   └── snapshots/
├── cheatsheets/
└── IONA_ERRORS.md
```

### 5. **ECRR Compliance Verification**
Validates compliance with the ECRR framework:
- ✅ ECRR reports directory
- ✅ Artifacts directory  
- ✅ BossCat reports directory
- ✅ IONA error ledger
- ✅ Comfort-cat creative references

### 6. **Final Status Report**
- Displays ECRR compliance score (0-100%)
- Shows installed tool versions
- Provides next steps for CI workflow execution

## Comfort-Cat Creative References

The script validates and creates stub files for the comfort-cat creative framework:
- `docs/comfort-cat/copy.md` - Voice & copy guidelines
- `docs/comfort-cat/type.md` - Typography standards  
- `docs/comfort-cat/motion.md` - Animation principles

These files are required for BossCat compliance and follow the "Cat Nap Control Room" aesthetic.

## Troubleshooting

### Python 3.13 Not Found
**Windows**: Download from [python.org](https://www.python.org/downloads/) and ensure "Add to PATH" is checked.

**Linux**: The script will attempt to install via deadsnakes PPA. If it fails:
```bash
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install python3.13 python3.13-venv python3.13-dev
```

**macOS**: Install Homebrew first, then run:
```bash
brew install python@3.13
```

### Node.js Not Found
**All Platforms**: Download from [nodejs.org](https://nodejs.org/) or use a version manager like nvm.

### k6 Installation Issues
**Windows**: Download from [k6.io](https://k6.io/docs/get-started/installation/)

**Linux**: 
```bash
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

**macOS**: `brew install k6`

### Permission Issues
**Windows**: Run PowerShell as Administrator
**Linux/macOS**: Use `sudo` for system-wide installations

## Post-Setup Verification

After running the setup script, verify your environment:

```powershell
# Windows
.\venv\Scripts\Activate.ps1
python --version
node --version
k6 version
locust --version

# Linux/macOS
source venv/bin/activate
python3.13 --version
node --version
k6 version
locust --version
```

## Next Steps

1. **Activate Python Environment**:
   - Windows: `.\venv\Scripts\Activate.ps1`
   - Linux/macOS: `source venv/bin/activate`

2. **Run BossCat Health Check**:
   ```powershell
   pwsh -File scripts\quick-monitor.ps1
   ```

3. **Start SigNoz UI**: Navigate to `http://localhost:8080`

4. **Execute CI Workflow**: Run the setup script again to verify everything works

## ECRR Compliance Score

The script provides a compliance score based on:
- Directory structure completeness (40%)
- Required files presence (40%) 
- Tool installation success (20%)

**Target Score**: 100% for full BossCat compliance

## Support

For issues with the setup script:
1. Check the troubleshooting section above
2. Verify you're running from the project root
3. Ensure you have the required permissions
4. Review the ECRR compliance output for specific failures

---

🐾 **BossCat Environment Setup Complete**

*This setup follows the ECRR framework and prepares your environment for the Resonai [OTel] observability stack with full BossCat compliance.*
