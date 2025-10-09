# Native Modules Troubleshooting Guide

This guide helps resolve common issues with native Node.js modules (like `better-sqlite3`) on Windows.

## Quick Diagnosis

Run these commands to check your environment:

```powershell
# Check Node.js version (should be 20.x+)
node -v

# Check pnpm version (should be 9.x+)
pnpm -v

# Check Python availability (should be 3.11+)
py -3 --version

# Check npm Python config
npm config get python

# Test better-sqlite3 directly
node -e "require('better-sqlite3'); console.log('OK')"
```

## Common Issues & Solutions

### 1. Python Not Found or Wrong Version

**Symptoms:**
- `gyp ERR! find Python Python is not set from command line or npm configuration`
- `gyp ERR! stack Error: Can't find Python executable "python"`

**Solutions:**
```powershell
# Install Python 3.11+ via winget
winget install -e --id Python.Python.3.11

# Configure npm to use Python
npm config set python "py -3"

# Verify Python is accessible
py -3 --version
```

### 2. Missing Visual Studio Build Tools

**Symptoms:**
- `gyp ERR! stack Error: `C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe` failed`
- `MSB8020: The build tools for v143 (Platform Toolset = 'v143') cannot be found`

**Solutions:**
```powershell
# Install VS 2022 Build Tools via winget
winget install -e --id Microsoft.VisualStudio.2022.BuildTools `
  --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64"

# Or download manually from:
# https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
# Make sure to include "C++ build tools" workload
```

### 3. Node.js Version Too Old

**Symptoms:**
- Various build errors with native modules
- `error: no template named 'remove_cv_t' in namespace 'std'`

**Solutions:**
```powershell
# Install Node.js 20.x+ via winget
winget install OpenJS.NodeJS

# Or download from: https://nodejs.org/
```

### 4. Permission Issues

**Symptoms:**
- `EPERM: operation not permitted`
- Access denied errors during npm install

**Solutions:**
```powershell
# Run PowerShell as Administrator
# Or clear npm cache
npm cache clean --force
pnpm store prune

# Remove node_modules and reinstall
Remove-Item -Recurse -Force node_modules
pnpm install
```

### 5. Corrupted node_modules or Cache

**Symptoms:**
- Random build failures
- Inconsistent behavior

**Solutions:**
```powershell
# Clean everything and start fresh
Remove-Item -Recurse -Force node_modules
pnpm store prune
pnpm install --frozen-lockfile
pnpm rebuild
```

## Fallback: Use JSON Queue Driver

If native modules continue to fail, you can proceed with the JSON-based queue driver:

```powershell
# Set environment variable to use JSON driver
$env:QUEUE_DRIVER = "json"
$env:QUEUE_SHADOW = "1"

# Run the application
pnpm dev
```

This allows PR-A (flags + DAL + migrator) and PR-B (runner admission + shadow writes) to proceed while native modules are stabilized.

## Automated Setup Script

Use the provided bootstrap script for a complete setup:

```powershell
# Run the comprehensive setup script
pwsh scripts/setup-local.ps1

# If native modules still fail, use fallback mode
pwsh scripts/setup-local.ps1 -SkipNativeModules
```

## Verification Checklist

After setup, verify these work:

- [ ] `node -e "require('better-sqlite3')"` prints "better-sqlite3 OK"
- [ ] `pnpm exec playwright install --with-deps` completes successfully
- [ ] `pnpm run lint` passes without errors
- [ ] `pnpm run build` completes successfully
- [ ] `pnpm run test` passes (if tests exist)

## Environment Variables for Troubleshooting

```powershell
# Enable verbose npm logging
$env:npm_config_loglevel = "verbose"

# Use specific Python executable
$env:npm_config_python = "py -3"

# Force rebuild of native modules
$env:npm_config_build_from_source = "true"

# Skip optional dependencies that might cause issues
$env:npm_config_optional = "false"
```

## Getting Help

If issues persist:

1. Check the [Node.js Windows installation guide](https://nodejs.org/en/download/package-manager/#windows)
2. Review [node-gyp troubleshooting](https://github.com/nodejs/node-gyp#on-windows)
3. Use the fallback JSON driver to continue development
4. File an issue with full error logs and environment details

## Prevention

To avoid these issues in the future:

- Always use Node.js 20.x+ (LTS)
- Keep Python 3.11+ installed and in PATH
- Maintain Visual Studio Build Tools installation
- Use the provided `scripts/setup-local.ps1` for consistent environments
- Consider using the JSON queue driver for development if native modules are problematic
