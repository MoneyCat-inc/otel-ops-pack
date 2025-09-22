# Lefthook Setup Guide

This guide helps you install and configure Lefthook for local pre-commit hygiene checks.

## What is Lefthook?

Lefthook is a fast and powerful Git hooks manager that runs `tools/hygiene-fast.ps1` before each commit to catch issues early.

## Installation

### Windows (PowerShell)

```powershell
# Option 1: Using Scoop (recommended)
scoop bucket add main
scoop install lefthook

# Option 2: Using Chocolatey
choco install lefthook

# Option 3: Using winget
winget install evilmartians.lefthook

# Option 4: Direct download
# Download from: https://github.com/evilmartians/lefthook/releases
# Extract to a folder in your PATH
```

### macOS

```bash
# Option 1: Using Homebrew (recommended)
brew install lefthook

# Option 2: Using direct installation script
curl -s https://raw.githubusercontent.com/evilmartians/lefthook/master/scripts/install.sh | bash
```

### Linux

```bash
# Option 1: Using package manager (Ubuntu/Debian)
curl -fsSL https://raw.githubusercontent.com/evilmartians/lefthook/master/scripts/install.sh | bash

# Option 2: Using package manager (Arch)
yay -S lefthook

# Option 3: Direct installation script
curl -s https://raw.githubusercontent.com/evilmartians/lefthook/master/scripts/install.sh | bash
```

## Setup

1. **Install Lefthook** using one of the methods above
2. **Navigate to the repository root**:
   ```bash
   cd C:\otel  # or your repository path
   ```
3. **Install the hooks**:
   ```bash
   lefthook install
   ```
4. **Verify installation**:
   ```bash
   lefthook version
   lefthook run pre-commit
   ```

## What Happens on Commit

When you commit, Lefthook automatically runs:

```powershell
pwsh ./tools/hygiene-fast.ps1
```

This script:
- ✅ Runs PSScriptAnalyzer on PowerShell scripts
- ✅ Attempts YAML parsing (skips gracefully if ConvertFrom-Yaml unavailable)
- ❌ **Blocks the commit** if any issues are found
- ✅ **Allows the commit** if everything passes

## Manual Testing

You can manually run the hygiene check without committing:

```powershell
# Run the same check that happens on commit
lefthook run pre-commit

# Or run the hygiene script directly
pwsh ./tools/hygiene-fast.ps1

# Run the full hygiene suite (includes Docker-based checks)
npm run hygiene
```

## Troubleshooting

### "lefthook: command not found"
- Verify Lefthook is installed and in your PATH
- Restart your terminal/command prompt
- Check installation with `lefthook version`

### "PowerShell script execution policy"
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "ConvertFrom-Yaml unavailable"
This is normal and expected. The script gracefully skips YAML parsing if the module isn't available.

### Hooks not running
```bash
# Reinstall hooks
lefthook install

# Check hook files exist
ls .git/hooks/pre-commit
```

### Skip hooks temporarily
```bash
# Skip all hooks for a single commit
git commit -m "message" --no-verify

# Or set environment variable
SKIP=pre-commit git commit -m "message"
```

## Configuration

The hooks are configured in `lefthook.yml`:

```yaml
pre-commit:
  parallel: true
  commands:
    hygiene_fast:
      run: pwsh ./tools/hygiene-fast.ps1
```

You can modify this file to:
- Add more checks
- Change the command
- Adjust parallel execution
- Add skip conditions

## Integration with CI

The same hygiene checks run in CI via `.github/workflows/hygiene.yml`, so local and CI results should match.

## Uninstalling

```bash
# Remove hooks
lefthook uninstall

# Remove Lefthook binary (method depends on installation)
# Scoop: scoop uninstall lefthook
# Homebrew: brew uninstall lefthook
# Chocolatey: choco uninstall lefthook
```

## Next Steps

After setting up Lefthook:

1. **Make a test commit** to verify hooks are working
2. **Address any lint issues** that block commits
3. **Run `npm run hygiene`** to see the full CI pipeline
4. **Check the CI status** in GitHub Actions

## Support

- [Lefthook Documentation](https://github.com/evilmartians/lefthook)
- [Repository Issues](https://github.com/fubumaki/otel-ops-pack/issues)
- [Hygiene Documentation](./REPO_HYGIENE.md)
